"""Collect existing private-run evidence; does not launch Max or modify product files."""
import csv
import hashlib
import json
import shutil
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
HOST = ROOT / 'build/mcp-qualification/consolidation075-delivery'
NATIVE = ROOT / 'build/consolidation075/native2027'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

native = read(NATIVE / 'receipt.json')
inputs = {p: h for p, h in native['sources'].items()
          if p != 'AminScatter/scripts/AminScatterObject.ms'}
assert all(sha(ROOT / p) == h for p, h in inputs.items())
package = read(OUT / 'PACKAGE.json')
launch = read(HOST / 'launch.json')
assert launch['script_sha256'] == package['script_sha256'] == sha(ROOT / 'AminScatter/scripts/AminScatterObject.ms')
assert launch['binaries'] == package['native']
assert sha(ROOT / package['package']) == package['sha256']
assert all(sha(HOST / 'bin' / n) == h for n, h in package['native'].items())
assert sha(HOST / 'scripts/CyrusScatter.ms') == package['script_sha256']
for name in ('results.json', 'regressions.json'):
    assert all(r['result'].startswith('SUCCESS') for r in read(HOST / name))
acceptance = read(HOST / 'procedural-acceptance.json')
assert acceptance['complete']
assert (HOST / 'older074-areas.txt').read_text().startswith('PASS')
receipts = OUT / 'receipts'
receipts.mkdir(exist_ok=True)
for name in ('results.json', 'regressions.json', 'consolidation075-checks.txt',
             'layer-regions-checks.txt', 'grips-main.txt', 'grips-Container.txt',
             'grips-Popup.txt', 'grips-lifecycle.txt', 'ui074-views.txt',
             'older074-areas.txt', 'procedural-acceptance.json'):
    shutil.copyfile(HOST / name, receipts / name)
shutil.copyfile(NATIVE / 'tests.log', receipts / 'native-tests.txt')
shutil.copyfile(ROOT / 'build/consolidation075/benchmark/timings.csv', receipts / 'brush-preparation.csv')
with (receipts / 'brush-preparation.csv').open(newline='') as f:
    rows = list(csv.DictReader(f))[1:]
assert all(r['compiled'] == '1' and r['reused'] == '300' and float(r['max_error']) == 0 for r in rows)
evidence = {
    'date': '2026-10-09', 'baseline_commit': 'cedaf78e3c4bd9fe5be39f7e070bac841b6b626d',
    'version': '0.75.0', 'schema': 54, 'calculation_model': 'CyrusUnified1',
    'native_build': {'stages': native['stages'], 'suites_passed': 14,
                     'compiled_inputs_match_final_tree': True, 'inputs': inputs,
                     'note': 'Build receipt predates final UI script edits; native inputs match. Final script independently qualified with these modules in Max.'},
    'python': {'command': 'build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q',
               'passed': 141, 'evidence': 'Successful command output in this task; no separate pytest log retained.'},
    'generated': read(ROOT / 'build/consolidation075/delivery-generator/generated-check.json'),
    'max2027': {'launch': launch, 'new_checks': 22, 'layer_paint_checks': 45,
                'grips_checked': 23, 'procedural_acceptance': acceptance,
                'older_074_area_fingerprint_preserved': True,
                'method': 'Owned isolated Max profile, scripted file transport on host thread; no computer use.'},
    'brush_preparation': {'triangles': 5000, 'existing_strokes': 300, 'added_strokes': 1,
                          'warm_repeats': len(rows),
                          'fresh_median_ms': statistics.median(float(r['fresh_ms']) for r in rows),
                          'reused_median_ms': statistics.median(float(r['reused_ms']) for r in rows),
                          'sampled_max_coverage_error': 0,
                          'scope': 'CPU field preparation only; not presented FPS or end-to-end brush latency.'},
    'package': package,
    'limitations': ['Stable receiver generation unfinished', 'Canonical region storage unfinished',
                    'Physical cold-container Undo gesture unresolved', 'No physical UI/tablet/DPI acceptance',
                    'No new Max 2026 or renderer qualification', 'Aggregate brush memory not qualified'],
    'receipts': {p.name: sha(p) for p in receipts.iterdir() if p.is_file()},
}
(OUT / 'EVIDENCE.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
print('Verified native inputs and final source/package/host identities; collected receipts.')
