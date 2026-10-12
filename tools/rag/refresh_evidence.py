"""Mechanical citation relocation; no authority, enrollment or semantic approval."""
import copy
import hashlib


class ReviewRequired(ValueError):
    issue = 'evidence_review'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def lines(raw):
    text = raw.decode('utf-8')
    if '\0' in text:
        raise ReviewRequired('Binary content requires review')
    return text.splitlines(keepends=True)


def locate(before, after, start, end):
    """Only one exact full-line occurrence is acceptable; never fuzzy matching."""
    if not 1 <= start <= end <= len(before):
        raise ReviewRequired('Invalid baseline evidence interval')
    needle = before[start - 1:end]
    if not ''.join(needle).strip():
        raise ReviewRequired('Empty evidence is not a safe relocation anchor')
    hits = [i for i in range(len(after) - len(needle) + 1) if after[i:i + len(needle)] == needle]
    if len(hits) != 1:
        raise ReviewRequired('Evidence changed or has ambiguous exact occurrences')
    return [hits[0] + 1, hits[0] + len(needle)]


def successor(corpus, datasets, old_bytes, new_bytes):
    """Full current parents may change; partial ranges and all labels stay exact.

    This proves textual continuity only. Newly retrieved prose is untrusted data;
    it is never promoted to a human-reviewed behavioral guarantee here.
    """
    updated = copy.deepcopy(corpus)
    labels = copy.deepcopy(datasets)
    sources = {s['path']: s for s in updated['sources']}
    if len(sources) != len(updated['sources']) or set(sources) != set(old_bytes) or set(sources) != set(new_bytes):
        raise ReviewRequired('The enrolled parent set must remain identical')
    changed = []
    texts = {}
    for path, source in sources.items():
        old, new = old_bytes[path], new_bytes[path]
        if sha(old) != source['sha256']:
            raise ReviewRequired('Baseline snapshot does not match its enrolled parent')
        prior, current = lines(old), lines(new)
        texts[path] = (prior, current)
        if old == new:
            continue
        if source['knowledge_status'] != 'current' or source['role'] in ('historical_evidence', 'delivered_artifact'):
            raise ReviewRequired('Historical, unknown or delivered evidence requires explicit review: ' + path)
        ranges = source['ranges']
        source['ranges'] = [[1, len(current)]] if ranges == [[1, len(prior)]] else [locate(prior, current, a, b) for a, b in ranges]
        if not current or any(a <= last[1] for last, (a, b) in zip(source['ranges'], source['ranges'][1:])):
            raise ReviewRequired('Source ranges became empty, reordered or overlapping')
        source['sha256'] = sha(new)
        source['review_status'] = 'Mechanically refreshed; prior semantic review does not certify the changed parent bytes.'
        source['applicability'] = {**source.get('applicability', {}),
            'automatic_refresh': 'Exact retained labels and strict retrieval comparisons only; new content is untrusted and not human-reviewed.'}
        changed.append(path)

    def rebind(value):
        if isinstance(value, dict):
            if {'path', 'sha256', 'start_line', 'end_line'} <= value.keys():
                path = value['path']
                if path not in sources or value['sha256'] != sha(old_bytes[path]):
                    raise ReviewRequired('Evaluation evidence does not match the approved source set')
                if path in changed:
                    value['start_line'], value['end_line'] = locate(*texts[path], value['start_line'], value['end_line'])
                    value['sha256'] = sources[path]['sha256']
                if not any(a <= value['start_line'] <= value['end_line'] <= b for a, b in sources[path]['ranges']):
                    raise ReviewRequired('Relocated evidence is outside the enrolled ranges')
            else:
                for child in value.values():
                    rebind(child)
        elif isinstance(value, list):
            for child in value:
                rebind(child)
    rebind(labels)
    return updated, labels, changed
