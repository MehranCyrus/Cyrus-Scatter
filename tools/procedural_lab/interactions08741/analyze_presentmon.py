"""Summarize owned Max ETW presentation rows in a recorded QPC interval."""
from argparse import ArgumentParser
from collections import Counter
from pathlib import Path
import csv
import json
import math
import statistics

parser = ArgumentParser()
parser.add_argument('--csv', type=Path, required=True)
parser.add_argument('--interval', type=Path, required=True)
parser.add_argument('--pid', type=int, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
interval = json.loads(args.interval.read_text(encoding='utf-8'))
ranges = interval.get('intervals', [interval])
ranges = [(float(x['begin_qpc_ms']), float(x['end_qpc_ms'])) for x in ranges]
if not ranges or any(begin >= end for begin, end in ranges):
    raise ValueError('Positive observed QPC intervals are required')
with args.csv.open(encoding='utf-8-sig', newline='') as source:
    reader = csv.DictReader(source)
    # PresentMon 2.x calls the --qpc_time_ms column CPUStartQPCTime.
    # Refuse unknown schemas instead of silently reporting zero samples.
    time_key = next((key for key in ('CPUStartQPCTime', 'CPUStartQPCTimeInMs')
                     if key in (reader.fieldnames or [])), None)
    if time_key is None:
        raise ValueError('PresentMon QPC-millisecond column is missing')
    rows = [r for r in reader if int(r['ProcessID']) == args.pid
            and r.get(time_key) not in ('', 'NA', None)
            and any(begin <= float(r[time_key]) <= end for begin, end in ranges)]
if not rows:
    raise ValueError('No process presentation samples in the recorded interval')
chains = Counter(r['SwapChainAddress'] for r in rows)
main = chains.most_common(1)[0][0] if chains else None
selected = [r for r in rows if r['SwapChainAddress'] == main]


def summarize(key):
    values = sorted(float(r[key]) for r in selected if r.get(key) not in ('', 'NA', None))
    return {'samples': len(values), 'median_ms': statistics.median(values),
            'p95_ms': values[max(0, math.ceil(.95*len(values))-1)], 'max_ms': values[-1]} if values else {'samples': 0}


report = {'scope': 'Whole Max process; dominant swap chain within recorded QPC intervals. Presentation data is not isolated plugin GPU time or calibrated input-to-photon latency.',
          'pid': args.pid, 'intervals_qpc_ms': ranges,
          'selected_swap_chain': main, 'chain_counts': dict(chains), 'presents': len(selected),
          'present_modes': dict(Counter(r['PresentMode'] for r in selected)),
          'metrics': {key: summarize(key) for key in ('FrameTime', 'DisplayedTime', 'DisplayLatency', 'CPUBusy', 'GPUTime')}}
args.output.write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
