"""P05 conversion and inherited P01-P04 witnesses on a matched owned host."""
from pathlib import Path
import argparse
import shutil
import subprocess
import sys
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
a = p.parse_args()
folder = a.folder.resolve()
assert folder.parent == ROOT / 'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-p05-')
archive = folder / ('p05-before-regression-' + uuid.uuid4().hex)
archive.mkdir()
for path in folder.glob('phase05-*'):
    if path.is_file():
        shutil.copy2(path, archive / path.name)
(folder / 'phase05-dependencies-stage.txt').unlink(missing_ok=True)
def request(fixture):
    subprocess.run([sys.executable, str(HERE / 'request.py'), str(folder), str(HERE / fixture), '--timeout', '120'], check=True)
def live(phase):
    subprocess.run([sys.executable, str(HERE / 'qualify_live.py'), str(folder), phase], check=True)
for fixture in ['phase05.py', 'phase05_transforms.py', 'phase02_reset_hold.ms', 'phase05_undo.ms', 'phase05_reset.ms']:
    request(fixture)
live('05')
live('05-dependencies')
live('05-recovery')
for fixture in ['phase04.py', 'phase02_reset_hold.ms', 'phase04_undo.ms', 'phase04_edges.ms', 'phase04_edit_saved.ms']:
    request(fixture)
live('04')
subprocess.run([sys.executable, str(HERE / 'qualify_p03.py'), str(folder)], check=True)
print('P01 through P05 witnesses complete; physical UI has separate receipts', flush=True)
