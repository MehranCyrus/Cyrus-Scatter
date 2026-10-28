"""Measure complete evidence retention and payload size; no model-token claim."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time

from context import execute, index_binding
from context_projection import render


def wire(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'))


def run(root, index, output):
    if output.exists():
        raise ValueError('Benchmark output must be a fresh file')
    raw_cases = (root / 'tools/rag/harness-task-cases.json').read_bytes()
    cases = json.loads(raw_cases)['cases']
    selected, selection = index_binding(root, index)
    rows = []
    for case in cases:
        start = time.monotonic()
        arguments = {'query': case['query'], 'mode': case['mode'], 'top_k': 1}
        raw = execute(root, selected, selection, 'knowledge_search', arguments)
        projected = render(raw, selection, max_chars=100000)
        found = raw.get('results', [])
        retained = projected.get('results', [])
        expected = bool(found and found[0]['path'] == case['expected_path'])
        for old, new in zip(found, retained):
            assert all(new[key] == value for key, value in old.items()
                       if key not in ['search_text', 'excerpt', 'excerpt_truncated'])
        assert len(found) == len(retained)
        # The real MCP transport intentionally includes text and structured copies.
        transport = {'content': [{'type': 'text', 'text': wire(raw)}],
                     'structuredContent': raw, 'isError': not raw.get('ok', False)}
        rows.append({'id': case['id'], 'query': case['query'], 'expected_owner': expected,
                     'ok': raw.get('ok', False), 'result_count': len(found),
                     'full_structured_chars': len(wire(raw)),
                     'full_mcp_transport_chars': len(wire(transport)),
                     'compact_chars': len(wire(projected)),
                     'original_text_chars': sum(len(x['original_text']) for x in found),
                     'originals_and_qualifiers_retained': True,
                     'seconds': round(time.monotonic() - start, 4)})
    old = sum(x['full_structured_chars'] for x in rows)
    compact = sum(x['compact_chars'] for x in rows)
    result = {'schema': 'cyrus.context-benchmark/1', 'scope': selection,
              'case_definition_sha256': hashlib.sha256(raw_cases).hexdigest(),
              'status': 'passed' if all(x['ok'] and x['expected_owner'] for x in rows) else 'needs_review',
              'cases': rows, 'case_count': len(rows),
              'full_structured_chars': old, 'compact_chars': compact,
              'structured_character_reduction_percent': round(100 * (1 - compact / old), 2),
              'median_seconds': statistics.median(x['seconds'] for x in rows),
              'limits': ['Development queries, not unseen holdout.',
                         'One warm-session pass; no controlled latency distribution.',
                         'Transport-copy exposure depends on the actual client.',
                         'Character sizes are not billed tokens; no model answer/patch evaluation was run.']}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--index', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = run(args.root.resolve(), args.index, args.output)
    print(json.dumps({key: result[key] for key in ['status', 'case_count', 'full_structured_chars',
        'compact_chars', 'structured_character_reduction_percent', 'median_seconds']}))
    return 0 if result['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
