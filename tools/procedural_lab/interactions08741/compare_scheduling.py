"""Compare static and dynamic contact-job scheduling on one captured scene."""
from pathlib import Path
import json
import statistics
import subprocess

root = Path(__file__).resolve().parents[3]
run = root / 'build/interactions08741-20261027-01'
fixture = run / 'baseline-host-01/terrace-replay-corrected/fixture.json'
executables = {'static': run / 'native-07/interactions_tests.exe',
               'dynamic': run / 'kernel-dynamic-01/interactions_tests.exe'}
rows = []
for repeat, order in enumerate((('static', 'dynamic'), ('dynamic', 'static'), ('static', 'dynamic')), 1):
    for name in order:
        process = subprocess.run([str(executables[name]), '--fixture', str(fixture), '2'],
                                 capture_output=True, text=True)
        if process.returncode:
            raise RuntimeError(name + ': ' + process.stderr[-2000:])
        value = json.loads(process.stdout)
        samples = [value['initial'], *value['steps']]
        row = {'kind': name, 'repeat': repeat,
               'fit_ms': [s['fit_ms'] for s in samples],
               'digest': [s['pose_digest_fnv64'] for s in samples],
               'affected': [s['affected'] for s in samples],
               'hidden_roots': [s['hidden_roots'] for s in samples],
               'fitted_guides': [s['fitted_guides'] for s in samples],
               'quality_warning_guides': [s['quality_warning_guides'] for s in samples]}
        rows.append(row)
        print(name, repeat, [round(x) for x in row['fit_ms']], flush=True)
for field in ('digest', 'affected', 'hidden_roots', 'fitted_guides', 'quality_warning_guides'):
    if not all(row[field] == rows[0][field] for row in rows):
        raise AssertionError('Scheduling changed ' + field)
summary = {'scope': 'Three alternating pairs of one captured numeric terrace fixture on one machine; not Max frame rate or measured end-user latency.',
           'samples': rows,
           'median_fit_ms': {name: [statistics.median(row['fit_ms'][i] for row in rows if row['kind'] == name)
                                    for i in range(3)] for name in executables}}
(run / 'kernel-dynamic-01/scheduling-comparison.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps(summary['median_fit_ms']), flush=True)
