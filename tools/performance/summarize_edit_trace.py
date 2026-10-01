"""Make an HTML/JSON report from an edit trace. No speedup or exact input-latency claims."""
from pathlib import Path
import argparse
import csv
import html
import json
import math
import statistics
from collections import Counter, defaultdict


def interval_total(intervals):
    """Wall time covered by intervals, counting overlaps once."""
    total = 0.0
    right = None
    for start, end in sorted(intervals):
        if right is None or start > right:
            total += end - start
            right = end
        elif end > right:
            total += end - right
            right = end
    return total


def stage_totals(spans):
    grouped = defaultdict(list)
    for span in spans:
        grouped[(span['actor'], span['stage'])].append(span)
    stages = []
    for (actor, stage), entries in sorted(grouped.items()):
        times = [s['duration_ms'] for s in entries]
        child_excluded = [s['child_excluded_ms'] for s in entries]
        stages.append(dict(
            actor=actor, stage=stage, count=len(times),
            median_ms=statistics.median(times), total_inclusive_ms=sum(times),
            max_ms=max(times),
            total_child_excluded_ms=(sum(child_excluded) if all(t is not None for t in child_excluded) else None),
        ))
    return stages


def summarize(folder):
    folder = Path(folder)
    with (folder / 'trace.csv').open(encoding='utf-8-sig', newline='') as stream:
        rows = list(csv.DictReader(stream))
    meta = json.loads((folder / 'trace-summary.json').read_text(encoding='utf-8-sig'))
    warnings = []
    for key in ('dropped_rows', 'collector_errors', 'unclosed_spans', 'unfinished_edit', 'stage_errors'):
        if meta.get(key):
            warnings.append(f'{key}: {meta[key]}')
    starts, spans, edits, input_events = {}, [], [], []
    span_ids = set()
    active_edit = None
    unassigned = 0
    pairing_complete = True

    def window_for(row):
        nonlocal unassigned
        if row['edit_id'] in ('0', ''):
            return None
        if (active_edit is not None
                and row['edit_id'] == active_edit['edit_id']
                and row['edit_label'] == active_edit['label']
                and row['elapsed_ms'] >= active_edit['begin_ms']):
            return active_edit['window_id']
        unassigned += 1
        return None

    for row in rows:
        t = float(row['elapsed_ms'])
        if not math.isfinite(t) or t < 0:
            raise ValueError('Invalid timestamp')
        row['elapsed_ms'] = t
        if row['kind'] == 'start':
            if row['span_id'] in span_ids:
                raise ValueError('Duplicate span id')
            span_ids.add(row['span_id'])
            row['window_id'] = window_for(row)
            starts[row['span_id']] = row
        elif row['kind'] == 'end':
            start = starts.pop(row['span_id'], None)
            if start is None:
                pairing_complete = False
                warnings.append('End without start: ' + row['span_id'])
                continue
            ms = float(row['duration_ms'])
            if not math.isfinite(ms) or ms < 0 or abs(t-start['elapsed_ms']-ms) > .1:
                raise ValueError('Invalid span duration')
            if any(row[k] != start[k] for k in ('actor', 'stage', 'edit_id', 'edit_label', 'parent_span_id')):
                raise ValueError('Span identity changed')
            detail = row['detail']
            try:
                parsed = json.loads(detail)
            except (ValueError, TypeError):
                parsed = None
            error = detail if detail.startswith('EXCEPTION:') else (parsed[0] if isinstance(parsed,list) and parsed else '')
            spans.append(dict(row, start_ms=start['elapsed_ms'], duration_ms=ms,
                              window_id=start['window_id'], error=error, metadata=parsed))
        elif row['kind'] == 'edit_begin':
            active_edit = dict(window_id=len(edits)+1, edit_id=row['edit_id'],
                               label=row['edit_label'], begin_ms=t, result_seen_ms=None)
            edits.append(active_edit)
        elif row['kind'] == 'result_seen':
            if (active_edit is None or row['edit_id'] != active_edit['edit_id']
                    or row['edit_label'] != active_edit['label']):
                warnings.append('Result visible marker has no matching active edit: ' + row['edit_id'])
            else:
                if t < active_edit['begin_ms']:
                    raise ValueError('Result visible precedes Begin edit')
                active_edit['result_seen_ms'] = t
                active_edit = None
        elif row['kind'] == 'input_received':
            row['window_id'] = window_for(row)
            input_events.append(row)
    if starts:
        warnings.append(f'{len(starts)} spans missing end rows')
    if any(s['error'] for s in spans):
        warnings.append('One or more traced stages reported an error')
    reused = [key for key, count in Counter(e['edit_id'] for e in edits).items() if count > 1]
    if reused:
        warnings.append('Recorder reused edit IDs (' + ', '.join(reused)
                        + '); recovered separate windows using marker order, labels and timestamps. Raw IDs are preserved.')
    if unassigned:
        warnings.append(f'{unassigned} stage starts/input notifications could not be assigned to matching edit markers')

    # Subtract immediate child intervals, not their summed durations: deeper
    # descendants already sit inside those children. This is wall time, not CPU time.
    by_id = {s['span_id']: s for s in spans}
    children = defaultdict(list)
    tree_complete = pairing_complete and not starts and not any(meta.get(k) for k in ('dropped_rows', 'collector_errors', 'unclosed_spans'))
    for span in spans:
        parent_id = span['parent_span_id']
        if parent_id in ('0', ''):
            continue
        parent = by_id.get(parent_id)
        if parent is None:
            warnings.append('Missing parent span: ' + parent_id)
            tree_complete = False
            continue
        if (parent_id == span['span_id'] or span['start_ms'] < parent['start_ms']-.1
                or span['elapsed_ms'] > parent['elapsed_ms']+.1):
            raise ValueError('Child span is outside its parent')
        children[parent_id].append((max(parent['start_ms'], span['start_ms']),
                                    min(parent['elapsed_ms'], span['elapsed_ms'])))
    for span in spans:
        span['child_excluded_ms'] = (max(0.0, span['duration_ms']-interval_total(children[span['span_id']]))
                                     if tree_complete else None)
    for edit in edits:
        work = [s for s in spans if s['window_id'] == edit['window_id']]
        seen = edit['result_seen_ms']
        edit.update(
            manual_window_ms=seen-edit['begin_ms'] if seen is not None else None,
            first_stage_ms=min(s['start_ms'] for s in work) if work else None,
            last_stage_ms=max(s['elapsed_ms'] for s in work) if work else None,
            traced_work_window_ms=(max(s['elapsed_ms'] for s in work)-min(s['start_ms'] for s in work) if work else None),
            covered_work_ms=interval_total((s['start_ms'], s['elapsed_ms']) for s in work),
            preview_builds=sum(s['stage'] == 'preview_rebuild' for s in work),
            analyzer_runs=sum(s['stage'] == 'analyzer_run' for s in work),
            input_notifications=sum(r['window_id'] == edit['window_id'] for r in input_events),
            stages=stage_totals(work),
        )
        if seen is None:
            warnings.append('Edit lacks Result visible marker: window ' + str(edit['window_id']))
        elif any(s['elapsed_ms'] > seen for s in work):
            warnings.append('Traced work ended after Result visible: window ' + str(edit['window_id']))
    if not edits:
        warnings.append('No named edits: stage timings cannot be assigned to a specific artist action')
    return dict(folder=str(folder.resolve()), summary=meta, warnings=list(dict.fromkeys(warnings)),
                stages=stage_totals(spans), edits=edits, spans=spans, input_events=input_events,
                unmarked_stage_count=sum(s['edit_id'] in ('0', '') for s in spans))


def render(data, destination):
    esc = lambda v: html.escape(str(v))
    def table(items, keys):
        return '<table><tr>'+''.join('<th>'+esc(k)+'</th>' for k in keys)+'</tr>'+''.join('<tr>'+''.join('<td>'+esc(round(r[k],2) if isinstance(r[k],float) else r[k])+'</td>' for k in keys)+'</tr>' for r in items)+'</table>'
    text = '<!doctype html><meta charset="utf-8"><title>Cyrus edit trace</title><style>body{font:16px/1.5 system-ui;max-width:1200px;margin:35px auto;padding:20px;background:#111923;color:#e5eff9}table{border-collapse:collapse;width:100%;margin:20px 0}td,th{text-align:left;border-bottom:1px solid #405062;padding:9px}pre{white-space:pre-wrap;overflow-wrap:anywhere}h2{color:#80d9bd}</style><h1>Cyrus spline-edit trace</h1>'
    text += '<p>All durations below are milliseconds. Script-stage timings are inclusive: Analyzer calls can contain layer rebuilds, and Grass placements can contain clover placements. Do not add nested durations. Child-excluded time removes recorded child intervals; it includes all remaining uninstrumented work and waits and is not pure algorithm or CPU time.</p>'
    text += '<p>Input timestamps record callback receipt, not the original input or mouse release. Manual windows include artist preparation and reaction time. Traced-work windows include gaps between stages; covered work counts overlapping stage intervals once. No completed-GPU-frame measurement.</p>'
    notes = data['warnings'] or ['No trace integrity warnings.']
    text += '<h2>Integrity notes</h2><ul>'+''.join('<li>'+esc(x)+'</li>' for x in notes)+'</ul>'
    text += '<h2>Named edits</h2>'+table(data['edits'],['window_id','edit_id','label','manual_window_ms','traced_work_window_ms','covered_work_ms','preview_builds','analyzer_runs'])
    text += '<p>Window IDs identify marker occurrences. Raw edit IDs are retained for older recordings that reused an ID.</p>'
    stage_keys = ['actor','stage','count','median_ms','total_inclusive_ms','max_ms','total_child_excluded_ms']
    for edit in data['edits']:
        text += '<h2>Window '+esc(edit['window_id'])+': '+esc(edit['label'])+'</h2>'+table(edit['stages'],stage_keys)
    text += '<h2>Whole-session stage costs</h2><p>Includes '+esc(data['unmarked_stage_count'])+' unmarked stages outside named edits.</p>'+table(data['stages'],stage_keys)
    text += '<details><summary>Every stage and input notification</summary><pre>'+esc(json.dumps(data,indent=2))+'</pre></details>'
    destination = Path(destination)
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_text(text,encoding='utf-8')
    destination.with_suffix('.json').write_text(json.dumps(data,indent=2),encoding='utf-8')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    render(summarize(args.folder),args.out)
    print(args.out.resolve())
