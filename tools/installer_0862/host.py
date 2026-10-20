"""Short owned Max profile with a separately recorded qualification transport."""
from pathlib import Path
import argparse,hashlib,json,shutil,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'));from private_host import launch
p=argparse.ArgumentParser();p.add_argument('--year',type=int,choices=(2024,2026,2027),required=True);p.add_argument('--name',required=True);p.add_argument('--short',required=True);a=p.parse_args()
assert a.name.startswith('density0862-installer-') and a.short.startswith('if') and a.short.isalnum()
folder=ROOT/'build'/a.short;host=ROOT/'build/mcp-qualification'/a.name;host.mkdir(exist_ok=False)
native=Path(f'D:/CyrusScatterBuilds/compatibility-0862-20261019/native{a.year}') if a.year!=2027 else Path('D:/CyrusScatterBuilds/ui-polish-0862-20261019/pair03')
receipt=json.loads((native/'receipt.json').read_text())
for key in ('sources','binaries'):
 for name,digest in receipt[key].items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
process,meta=launch(folder,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,transport=True,max_year=a.year,silent_startup=True,script_assets=('CyrusGallery.dll',),extra='MCPFixtureDir=@"'+host.as_posix()+'/"')
shutil.copytree(ROOT/'AminScatter/patterns',folder/'scripts/Patterns');shutil.copytree(ROOT/'AminScatter/patterns',host/'scripts/Patterns')
meta['short_profile']=str(folder);(host/'launch.json').write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta),flush=True)
deadline=time.monotonic()+240
while time.monotonic()<deadline:
 if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text())
 if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text())
 if (host/'ready.json').exists():print('Owned host ready',flush=True);break
 if process.poll()!=None:raise RuntimeError('Observe owned process exit')
 time.sleep(.3)
else:raise TimeoutError('Observe the existing owned process before considering another launch')
