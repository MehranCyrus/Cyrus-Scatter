"""Explicitly requested older-host qualification in disposable 0.86.2 profiles."""
from pathlib import Path
import argparse, hashlib, json, shutil, sys, time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--year', required=True, type=int, choices=(2024, 2026, 2027))
p.add_argument('--name', required=True)
p.add_argument('--native', required=True, type=Path)
p.add_argument('--scale', type=float, default=1.)
a = p.parse_args()
assert a.name.startswith('density0862-compat-')
assert Path(f'C:/Program Files/Autodesk/3ds Max {a.year}/3dsmax.exe').is_file(), 'SDK alone is not a runnable host'
native = a.native.resolve()
receipt = json.loads((native/'receipt.json').read_text())
assert receipt['max_year'] == a.year and all(s['exit_code'] == 0 for s in receipt['stages'])
assert not receipt.get('preview_fault_lab') and not receipt.get('placement_qualification')
for key in ('sources', 'binaries'):
    for name, digest in receipt[key].items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == digest, name
host = ROOT/'build/mcp-qualification'/a.name
process, metadata = launch(host, ROOT/'AminScatter/scripts/AminScatterObject.ms', native,
    transport=True, max_year=a.year, silent_startup=True, script_assets=('CyrusGallery.dll',),
    extra='CustomControlsOptions.UIUserScaleFactor='+str(a.scale))
shutil.copytree(ROOT/'AminScatter/patterns', host/'scripts/Patterns')
print(json.dumps(metadata), flush=True)
deadline = time.monotonic()+240
while time.monotonic() < deadline:
    if (host/'startup-error.txt').exists(): raise RuntimeError((host/'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (host/'ready.json').exists(): print('Owned host ready', flush=True); break
    if process.poll() is not None: raise RuntimeError('Owned host exited before readiness')
    time.sleep(.3)
else: raise TimeoutError('Observe the existing owned process before retrying')
