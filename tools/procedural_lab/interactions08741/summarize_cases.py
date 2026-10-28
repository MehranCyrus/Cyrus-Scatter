"""Create a durable, honest model-level summary from host campaign receipts."""
from argparse import ArgumentParser
from pathlib import Path
import csv
import json
import statistics

parser = ArgumentParser()
parser.add_argument('--host', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
files = sorted((args.host / 'cases').glob('*.json'), key=lambda p: p.stat().st_mtime_ns)
cases, superseded = {}, []
for path in files:
    value = json.loads(path.read_text(encoding='utf-8'))
    if value.get('status') == 'running':
        continue
    key = value['model_key']
    old = cases.get(key)
    if old is not None:
        # A fixture failure must not supersede an actual completed model test.
        if old['value'].get('phase') == 'complete' and value.get('phase') != 'complete':
            superseded.append({'file': path.name, 'status': value.get('status'), 'phase': value.get('phase')})
            continue
        superseded.append({'file': old['file'], 'status': old['value'].get('status'), 'phase': old['value'].get('phase')})
    cases[key] = {'file': path.name, 'value': value}


def mid(values):
    return round(statistics.median(values), 3) if values else None


rows = []
for model_key, wrapped in sorted(cases.items()):
    d = wrapped['value']
    attempts = d.get('attempts', [])
    contacts = [x for x in attempts if x.get('status') == 'contact']
    audit_rows = [r for x in contacts for r in x.get('audit', {}).get('results', [])]
    errors = [x.get('interaction_error') or x.get('error') or x.get('status')
              for x in attempts if x.get('status') not in ('contact',)]
    complete = d.get('phase') == 'complete'
    passed = (complete and len(attempts) == 3 and len(contacts) == 3 and
              all(x.get('audit', {}).get('passed') for x in contacts) and d.get('away_restored') is True)
    max_strain = max((x.get('maximum_stem_edge_change', 0) for x in audit_rows), default=None)
    row = {
        'model_key': model_key, 'name': d.get('name'), 'category': d.get('category'),
        'case_file': wrapped['file'], 'result': 'pass' if passed else ('needs_review' if complete else 'failed'),
        'source_file_sha256': d.get('source_scene_sha256'), 'prepared_source_fingerprint': d.get('source_fingerprint'),
        'vertices': d.get('source_vertices'), 'triangles': d.get('source_triangles'), 'guides': d.get('guides'),
        'prepare_seconds': d.get('prepare_seconds'), 'attempts': len(attempts), 'contacts': len(contacts),
        'full_audits_passed': sum(bool(x.get('audit', {}).get('passed')) for x in contacts),
        'away_restored': d.get('away_restored'),
        'median_fit_ms': mid([x['statistics']['fit_ms'] for x in contacts if 'fit_ms' in x.get('statistics', {})]),
        'median_sync_ms': mid([x['sync_ms'] for x in contacts if 'sync_ms' in x]),
        'median_command_ms': mid([x['command_ms'] for x in contacts if 'command_ms' in x]),
        'maximum_stem_edge_change': round(max_strain, 6) if max_strain is not None else None,
        'maximum_root_anchor_error_m': max((x.get('root_anchor_error_m', 0) for x in audit_rows), default=None),
        'penetrating_vertex_obstacle_pairs': sum(x.get('penetrating_vertex_obstacle_pairs', 0) for x in audit_rows),
        'touching_triangle_obstacle_pairs': sum(x.get('touching_triangle_obstacle_pairs', 0) for x in audit_rows),
        'errors': errors or ([d.get('error')] if d.get('error') else []), 'settings': d.get('settings'),
    }
    rows.append(row)

args.output.mkdir(parents=True, exist_ok=True)
document = {'scope': 'One copied source at a time, three sphere contact directions, full visible mesh audit and away restoration. Timings are synchronous CPU/host durations, not presented FPS.',
            'host': str(args.host.resolve()), 'distinct_models': len(rows),
            'completed': sum(x['result'] != 'failed' for x in rows),
            'passes': sum(x['result'] == 'pass' for x in rows), 'results': rows,
            'superseded_or_fixture_attempts': superseded}
(args.output / 'model-summary.json').write_text(json.dumps(document, indent=2), encoding='utf-8')
columns = [x for x in rows[0] if x not in ('settings', 'errors')] if rows else []
with (args.output / 'model-summary.csv').open('w', newline='', encoding='utf-8') as stream:
    writer = csv.DictWriter(stream, fieldnames=columns, extrasaction='ignore')
    writer.writeheader()
    writer.writerows(rows)
print(json.dumps({k: document[k] for k in ('distinct_models', 'completed', 'passes')}, indent=2))
