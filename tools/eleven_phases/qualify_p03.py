"""Run P03 and inherited P01/P02 host regressions on the current matched build."""
from pathlib import Path
import argparse
import subprocess
import sys

HERE = Path(__file__).resolve().parent
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
a = p.parse_args()
for fixture in ['phase02_reset_hold.ms', 'phase03_undo.ms', 'phase03_saved_baseline.ms',
                'phase03_interactions.ms', 'phase03_performance.ms']:
    subprocess.run([sys.executable, str(HERE / 'request.py'), str(a.folder), str(HERE / fixture)], check=True)
subprocess.run([sys.executable, str(HERE / 'qualify_live.py'), str(a.folder), '03'], check=True)
subprocess.run([sys.executable, str(HERE / 'request.py'), str(a.folder), str(HERE / 'phase03.py'), '--timeout', '120'], check=True)
subprocess.run([sys.executable, str(HERE / 'qualify_p02.py'), str(a.folder)], check=True)
print('P01 through P03 witnesses complete', flush=True)
