"""Compare numeric interaction worker counts on the same captured fixture.

Run only after other campaign compute jobs have finished. This is not a Max
frame-rate test and cannot choose a general policy from one machine.
"""
from pathlib import Path
import json
import statistics
import subprocess

root = Path(__file__).resolve().parents[3]
run = root / 'build/interactions08741-20261027-01'
out = run / 'worker-count-comparison'
out.mkdir(parents=True, exist_ok=False)
fixture = json.loads((run / 'baseline-host-01/terrace-replay-corrected/fixture.json').read_text(encoding='utf-8'))
paths = {}
for threads in (8, 10, 12):
    fixture['diagnostic_compute_threads'] = threads
    paths[threads] = out / ('fixture-' + str(threads) + '.json')
    paths[threads].write_text(json.dumps(fixture), encoding='utf-8')
executable = run / 'kernel-dynamic-01/interactions_tests.exe'
rows = []
for repeat, order in enumerate(((8, 10, 12), (12, 8, 10), (10, 12, 8)), 1):
    for threads in order:
        process = subprocess.run([str(executable), '--fixture', str(paths[threads]), '2'],
                                 capture_output=True, text=True)
        if process.returncode:
            raise RuntimeError(f'{threads} workers failed: {process.stderr[-2000:]}')
        value = json.loads(process.stdout)
        samples = [value['initial'], *value['steps']]
        row = {'threads': threads, 'repeat': repeat,
               'fit_ms': [s['fit_ms'] for s in samples],
               'digest': [s['pose_digest_fnv64'] for s in samples],
               'affected': [s['affected'] for s in samples],
               'hidden_roots': [s['hidden_roots'] for s in samples],
               'fitted_guides': [s['fitted_guides'] for s in samples]}
        rows.append(row)
        print(threads, repeat, [round(v) for v in row['fit_ms']], flush=True)
for field in ('digest', 'affected', 'hidden_roots', 'fitted_guides'):
    if not all(row[field] == rows[0][field] for row in rows):
        raise AssertionError('Worker count changed ' + field)
summary = {'scope': 'Alternating one-machine captured numeric replay; not Max presented FPS, UI latency or a general thread recommendation.',
           'samples': rows,
           'median_fit_ms': {str(threads): [statistics.median(row['fit_ms'][i] for row in rows if row['threads'] == threads)
                                               for i in range(3)] for threads in paths}}
(out / 'results.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps(summary['median_fit_ms']), flush=True)
