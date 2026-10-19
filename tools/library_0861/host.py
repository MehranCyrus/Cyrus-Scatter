"""Owned, source-matched 0.86.1 host qualification; never installs or restarts artist Max."""
from pathlib import Path
import argparse,hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send
p=argparse.ArgumentParser();p.add_argument('operation',choices=('launch','send'));p.add_argument('--year',required=True,type=int,choices=(2024,2026,2027));p.add_argument('--name',required=True);p.add_argument('--native',type=Path);p.add_argument('--script',type=Path);a=p.parse_args()
assert a.name.startswith('library-surface0861-')
host=ROOT/'build/mcp-qualification'/a.name
if a.operation=='send':
 assert (host/'ready.json').exists() and not (host/'startup-error.txt').exists()
 assert json.loads((host/'launch.json').read_text())['max_year']==a.year
 send(host,a.script.resolve(),a.script.stem)
else:
 assert Path(f'C:/Program Files/Autodesk/3ds Max {a.year}/3dsmax.exe').is_file(),'Requested Max executable is not installed; SDK compilation is not host qualification.'
 native=a.native.resolve();receipt=json.loads((native/'receipt.json').read_text())
 assert receipt['max_year']==a.year and all(s['exit_code']==0 for s in receipt['stages'])
 for name,digest in receipt['sources'].items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
 process,metadata=launch(host,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,transport=True,max_year=a.year,silent_startup=True,script_assets=('CyrusGallery.dll',))
 print(json.dumps({'pid':process.pid,'profile':str(host)}),flush=True)
 end=time.monotonic()+180
 while time.monotonic()<end:
  if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text(encoding='utf-8-sig'))
  if (host/'ready.json').exists():print('Owned host ready',flush=True);break
  if process.poll() is not None:raise RuntimeError('Owned host exited before readiness')
  time.sleep(.3)
 else:raise TimeoutError('Observe existing owned process before retrying')
