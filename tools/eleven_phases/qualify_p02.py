"""Serialize the P02 witnesses and inherited P01 regressions in one owned host."""
from pathlib import Path
import argparse
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
a = p.parse_args()
for fixture in ('phase02_reset_hold.ms', 'phase02_undo.ms', 'phase02_curves.ms', 'phase02_bezier.ms', 'phase02_lifecycle.ms',
                'phase02_live_begin.ms', 'phase02_live_apply.ms', 'phase02_live_verify.ms',
                'phase01_undo.ms', 'phase02.py', 'phase02_files.py',
                'phase01.py', 'phase01_panels.py', 'phase01_limited.py', 'phase01_passive.py', 'phase02_reset_hold.ms'):
    if fixture in ('phase02_live_apply.ms', 'phase02_live_verify.ms'):
        marker = a.folder / ('phase02-live-setup-ready.txt' if fixture == 'phase02_live_apply.ms' else 'phase02-live-ready.txt')
        deadline = time.monotonic() + 20
        while not marker.exists() and time.monotonic() < deadline:
            time.sleep(.1)
        assert marker.exists(), 'Live result did not settle within 20 seconds'
    print('Qualifying ' + fixture, flush=True)
    result = subprocess.run([sys.executable, str(HERE / 'request.py'), str(a.folder), str(HERE / fixture)])
    if result.returncode:
        raise SystemExit(result.returncode)
print('P02 and inherited P01 witnesses complete', flush=True)
