"""Launch a matched Scatter pair in an owned Max 2027 orientation profile."""
from pathlib import Path
import argparse,hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--native',required=True);p.add_argument('--scale',type=float,default=1.)
a=p.parse_args();assert a.name.startswith('foundation-roadmap-orientation0830-') and a.scale in (1.,1.5)
native=ROOT/a.native;receipt=json.loads((native/'receipt.json').read_text(encoding='utf-8'))
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
for path,digest in receipt['sources'].items():
 if path!='AminScatter/scripts/AminScatterObject.ms':assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
host=ROOT/'build/mcp-qualification'/a.name
process,metadata=launch(host,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,transport=True,max_year=2027,silent_startup=True,extra=f'CustomControlsOptions.UIUserScaleFactor={a.scale}')
metadata['native_receipt_sha256']=hashlib.sha256((native/'receipt.json').read_bytes()).hexdigest();metadata['scale']=a.scale
metadata['native_build_script_sha256']=receipt['sources']['AminScatter/scripts/AminScatterObject.ms']
(host/'launch.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8');print('Owned host PID',process.pid,flush=True)
end=time.monotonic()+240
while time.monotonic()<end:
 if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text(encoding='utf-8'))
 if (host/'ready.json').exists():print('Owned host ready',flush=True);break
 if process.poll() is not None:raise RuntimeError('Host exited before readiness')
 time.sleep(.5)
else:raise TimeoutError('Readiness timeout; inspect the existing owned process')
