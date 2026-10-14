"""Run staged host-event witnesses with bounded waits outside Max's UI thread."""
from pathlib import Path
import argparse
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
p.add_argument('phase', choices=['03', '04'])
p.add_argument('--start-stage', type=int, default=1)
a = p.parse_args()
count = 6 if a.phase == '03' else 12
wait_after = [2, 3, 5] if a.phase == '03' else [2, 3, 5, 7, 10, 11]
for stage in range(a.start_stage, count + 1):
    print('Live phase ' + a.phase + ' stage ' + str(stage), flush=True)
    subprocess.run([sys.executable, str(HERE / 'request.py'), str(a.folder),
                    str(HERE / ('phase' + a.phase + '_live.ms'))], check=True)
    if stage in wait_after:
        marker = a.folder / ('phase' + a.phase + '-live-ready.txt')
        deadline = time.monotonic() + 20
        while not marker.exists() and time.monotonic() < deadline:
            time.sleep(.1)
        assert marker.exists(), 'Live result did not settle within 20 seconds'
