"""Summarize measured CPU stages, without interpreting redraw time as FPS."""
import argparse
import csv
import json
from pathlib import Path
import statistics

p = argparse.ArgumentParser()
p.add_argument('hosts', nargs='+')
args = p.parse_args()
base = Path(__file__).resolve().parents[2] / 'build/vector-brush-078'
for host in args.hosts:
    folder = (base / host).resolve()
    if folder.parent != base or not (folder / 'launch.json').is_file():
        raise SystemExit('Owned host directory required')
    rows = list(csv.DictReader((folder / 'drawing-timings.csv').open()))
    if len(rows) != 300:
        raise SystemExit('Incomplete drawing workload')
    def number(value):
        return float(value.replace('d', 'e').rstrip('L'))
    result = {'samples': len(rows), 'stages': {}}
    columns = ('author_ms', 'border_ms', 'editors_ms', 'redraw_ms')
    for key in (*columns, 'total_ms'):
        values = sorted(sum(number(r[k]) for k in columns) if key == 'total_ms' else number(r[key]) for r in rows)
        result['stages'][key] = {'median': statistics.median(values), 'p95': values[int(.95 * (len(values)-1))], 'max': max(values)}
    (folder / 'drawing-summary.json').write_text(json.dumps(result, indent=2) + '\n')
    print(host, json.dumps(result))
