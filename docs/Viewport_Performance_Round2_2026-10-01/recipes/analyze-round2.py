from pathlib import Path
import csv
import json
import statistics
import numpy as np
from PIL import Image

work = Path(__file__).resolve().parent
def write(name, data):
    (work / name).write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

profile = json.loads((work / 'profile/stages.json').read_text(encoding='utf-8-sig'))
stages = {'scope': 'Instrumented per-callback stage timings; held uses a forced true predicate.'}
for held in (False, True):
    rows = [np.diff([0] + times).tolist() for flag, times in profile['cumulative_ms'] if flag == held]
    stages['simulated_held' if held else 'normal'] = {'samples': len(rows), 'median_ms': {
        key: statistics.median(row[i] for row in rows) for i, key in enumerate(profile['stages'])}}
write('profile/stage-summary.json', stages)
with (work / 'gestures.csv').open(encoding='utf-8-sig', newline='') as f:
    rows = list(csv.DictReader(f))
gestures = {'scope': 'Real mouse input, four pan strokes per version, one held callback per stroke; smoke evidence only, not FPS or a statistically powered benchmark.',
            'method': 'Pan tool, two outward/return pairs from (1100,650) to (1280,650); 0.61 first, camera restored before 0.62. Same isolated scene/session.'}
for phase in ('061', '062'):
    values = [float(row['scatter_callback_ms']) for row in rows if row['phase'] == phase]
    gestures[phase] = {'samples': len(values), 'median_ms': statistics.median(values),
                       'min_ms': min(values), 'max_ms': max(values)}
gestures['callback_median_reduction_pct'] = 100 * (1 - gestures['062']['median_ms'] / gestures['061']['median_ms'])
counts = json.loads((work / 'gesture-counts.json').read_text(encoding='utf-8-sig'))
assert counts['before'] == counts['after']
gestures['populations_and_counters_unchanged'] = True
write('gesture-summary.json', gestures)
a = np.asarray(Image.open(work / 'images/held-061.png').convert('RGB')).astype(np.int16)
b = np.asarray(Image.open(work / 'images/held-062.png').convert('RGB')).astype(np.int16)
assert a.shape == b.shape
def compare(a, b):
    d = np.abs(a-b)
    changed = np.any(d != 0, axis=2)
    y, x = np.where(changed)
    return {'pixels': int(changed.size), 'changed_pixels': int(changed.sum()),
            'changed_pct': float(100 * changed.mean()), 'mean_abs_channel_difference': float(d.mean()),
            'max_channel_difference': int(d.max()),
            'changed_bounds_xyxy': [int(x.min()),int(y.min()),int(x.max()),int(y.max())] if len(x) else None}
visual = {'scope': 'Same-camera saved viewport DIBs from the controlled held-input comparison.',
          'size': [a.shape[1], a.shape[0]], 'whole_viewport': compare(a,b),
          'below_statistics_overlay_y140': compare(a[140:], b[140:])}
write('image-comparison.json', visual)
print(json.dumps({'gestures': gestures, 'visual': visual, 'profile': stages}, indent=2))
