"""Alternate preserved baseline and current generation benchmarks three times.

Uses frozen executables, never recompiles or restores retired product code.
Each executable reports one cold and twenty warm runs per workload. The
comparison covers the equivalent flat Rounded CPU fixture, not Max or GPU cost.
"""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import statistics
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline', type=Path, required=True)
parser.add_argument('--candidate', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=False)
identities = {}
for name in ('baseline', 'candidate'):
    directory = getattr(args, name).resolve()
    receipt = json.loads((directory / 'receipt.json').read_text(encoding='utf-8'))
    if receipt['exit_code'] != 0:
        raise ValueError('Successful benchmark receipt required')
    identities[name] = {'directory': str(directory), 'exe_sha256': hashlib.sha256((directory / 'benchmark.exe').read_bytes()).hexdigest(),
                        'receipt_sha256': hashlib.sha256((directory / 'receipt.json').read_bytes()).hexdigest(),
                        'build': receipt['build'], 'benchmark_source_sha256': receipt['benchmark_sha256']}
noise = []
for _ in range(10000):
    a = time.perf_counter_ns(); b = time.perf_counter_ns(); noise.append((b-a) / 1e6)
report = {'identities': identities, 'clock': {'resolution_seconds': time.get_clock_info('perf_counter').resolution,
          'median_back_to_back_ms': statistics.median(noise), 'p95_back_to_back_ms': sorted(noise)[9499]},
          'scope': 'SDK-free equivalent Rounded/flat/one-source fixture. Timings omit current field preparation outside the timed scatter call; baseline repeats its inline preparation. No claim of Max total time, renderer time or presented FPS.',
          'criterion': 'Flag a repeatable regression only if all three paired medians or all three paired p95 values exceed baseline by 10% plus the greater of clock p95 and the baseline range for that metric across repetitions.',
          'runs': [], 'comparisons': []}
receipt_path = args.output / 'comparison.json'
receipt_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
for repeat in range(3):
    run = {}
    for name in (('baseline', 'candidate') if repeat % 2 == 0 else ('candidate', 'baseline')):
        directory = Path(identities[name]['directory'])
        completed = subprocess.run([str(directory / 'benchmark.exe')], cwd=directory, capture_output=True, text=True, timeout=120)
        (args.output / f'{repeat+1}-{name}.csv').write_text(completed.stdout, encoding='utf-8')
        if completed.returncode:
            raise RuntimeError(completed.stderr)
        run[name] = list(csv.DictReader(io.StringIO(completed.stdout)))
        if hashlib.sha256((directory / 'benchmark.exe').read_bytes()).hexdigest() != identities[name]['exe_sha256']:
            raise ValueError('Frozen benchmark identity changed')
    report['runs'].append(run)
    receipt_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
for i, row in enumerate(report['runs'][0]['baseline']):
    comparison = {'candidates': int(row['candidates']), 'bands': int(row['bands']), 'metrics': {}}
    comparison['same_accepted_count'] = all(run['baseline'][i]['accepted'] == run['candidate'][i]['accepted'] for run in report['runs'])
    for metric in ('warm_median_ms', 'warm_p95_ms'):
        before = [float(run['baseline'][i][metric]) for run in report['runs']]
        after = [float(run['candidate'][i][metric]) for run in report['runs']]
        floor = max(report['clock']['p95_back_to_back_ms'], max(before) - min(before))
        comparison['metrics'][metric] = {'baseline': before, 'candidate': after, 'absolute_noise_ms': floor,
                                        'repeatable_regression': all(b > a * 1.1 + floor for a, b in zip(before, after))}
    report['comparisons'].append(comparison)
report['passed'] = all(item['same_accepted_count'] and not any(m['repeatable_regression'] for m in item['metrics'].values()) for item in report['comparisons'])
receipt_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'passed': report['passed'], 'workloads': len(report['comparisons']), 'receipt': str(receipt_path)}))
raise SystemExit(0 if report['passed'] else 1)
