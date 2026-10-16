"""Owned Max 2027 navigation/scaling host; default scale is deliberately retained."""
from pathlib import Path
import argparse,hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--native',required=True,type=Path);p.add_argument('--script',type=Path,default=ROOT/'AminScatter/scripts/AminScatterObject.ms');p.add_argument('--scale',type=float,choices=(0.,1.,1.5))
a=p.parse_args();assert a.name.startswith('foundation-ui0852-')
native=a.native.resolve();receipt=json.loads((native/'receipt.json').read_text())
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
for name,digest in receipt['binaries'].items():assert sha(ROOT/name)==digest,name
folder=ROOT/'build/mcp-qualification'/a.name
extra='' if a.scale is None else f'CustomControlsOptions.UIUserScaleFactor={a.scale}'
process,record=launch(folder,a.script.resolve(),native,extra=extra,transport=True,max_year=2027,silent_startup=True,script_assets=('CyrusGallery.dll',))
record['native_receipt_sha256']=sha(native/'receipt.json');record['requested_scale']=a.scale
(folder/'launch.json').write_text(json.dumps(record,indent=2)+'\n')
print('Owned PID',process.pid,flush=True)
end=time.monotonic()+240
while time.monotonic()<end:
 if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text(encoding='utf-8'))
 if (folder/'ready.json').exists():print('Ready',folder,flush=True);break
 if process.poll() is not None:raise RuntimeError('Owned host exited')
 time.sleep(.5)
else:raise TimeoutError('Inspect the existing owned host; do not relaunch blindly')
