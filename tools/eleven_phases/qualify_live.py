"""Run staged host-event witnesses with bounded waits outside Max's UI thread."""
from pathlib import Path
import argparse
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
p.add_argument('phase', choices=['03', '04', '05', '05-dependencies', '05-recovery'])
p.add_argument('--start-stage', type=int, default=1)
a = p.parse_args()
count = {'03': 6, '04': 12, '05': 6, '05-dependencies': 6, '05-recovery': 3}[a.phase]
wait_after = {'03': [2, 3, 5], '04': [2, 3, 5, 7, 10, 11], '05': [1, 2, 3, 4, 5], '05-dependencies': [1, 2, 3, 4, 5], '05-recovery': [1, 2]}[a.phase]
fixture = 'phase' + a.phase.replace('-', '_') + ('.ms' if '-' in a.phase else '_live.ms')
for stage in range(a.start_stage, count + 1):
    print('Live phase ' + a.phase + ' stage ' + str(stage), flush=True)
    subprocess.run([sys.executable, str(HERE / 'request.py'), str(a.folder),
                    str(HERE / fixture)], check=True)
    if stage in wait_after:
        marker = a.folder / ('phase' + a.phase[:2] + '-live-ready.txt')
        deadline = time.monotonic() + 20
        while not marker.exists() and time.monotonic() < deadline:
            time.sleep(.1)
        assert marker.exists(), 'Live result did not settle within 20 seconds'
