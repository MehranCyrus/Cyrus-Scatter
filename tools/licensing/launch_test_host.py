"""Launch only a disposable licensed Max profile from a frozen candidate."""
import argparse,json,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--name',required=True)
a=p.parse_args()
if Path(a.name).name!=a.name or a.name in ('.','..'):raise SystemExit('Expected an owned profile name')
candidate=a.candidate.resolve();build=json.loads((candidate/'build.json').read_text())
folder=ROOT/'build/mcp-qualification'/a.name
process,meta=launch(folder,candidate/'source/AminScatter/scripts/AminScatterObject.ms',candidate/'native',
                    transport=True,max_year=build['year'],silent_startup=True)
print(json.dumps(meta),flush=True)
deadline=time.monotonic()+240
while time.monotonic()<deadline:
    if (folder/'startup-error.txt').exists():raise SystemExit((folder/'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (folder/'ready.json').exists():print('Private licensed host ready',flush=True);break
    if process.poll() is not None:raise SystemExit('Owned Max exited during startup')
    time.sleep(.5)
else:raise SystemExit('Startup timed out; inspect this owned process before continuing')
