"""Launch only a hash-matched build in an owned disposable Max profile."""
from pathlib import Path
import argparse, hashlib, json, shutil, sys, time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--native',type=Path,required=True);p.add_argument('--year',type=int,default=2027);p.add_argument('--visible',action='store_true');a=p.parse_args()
assert a.name.startswith('foundation-viewport0817-') and Path(a.name).name==a.name
native=a.native.resolve();receipt=json.loads((native/'receipt.json').read_text())
assert receipt['max_year']==a.year
def digest(path):
    h=hashlib.sha256()
    with Path(path).open('rb') as f:
        for b in iter(lambda:f.read(8*1024*1024),b''):h.update(b)
    return h.hexdigest()
for name,h in receipt['sources'].items():assert digest(ROOT/name)==h,name
for name,h in receipt['binaries'].items():assert digest(native/Path(name).name)==h,name
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
folder=ROOT/'build/mcp-qualification'/a.name
process,metadata=launch(folder,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,transport=True,max_year=a.year,silent_startup=True,visible=a.visible)
print(json.dumps(metadata),flush=True)
deadline=time.monotonic()+180
while time.monotonic()<deadline:
    if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (folder/'ready.json').exists():print('Owned viewport host ready',flush=True);break
    if process.poll() is not None:raise RuntimeError('Host exited before readiness')
    time.sleep(.5)
else:raise TimeoutError('Inspect this owned host before retrying')
