import sys,json,argparse,time,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
parser=argparse.ArgumentParser();parser.add_argument('--host',required=True);parser.add_argument('--native',required=True);parser.add_argument('--year',type=int,choices=(2026,2027),default=2027);parser.add_argument('--probe',action='store_true');args=parser.parse_args()
for value in (args.host,args.native):
    if Path(value).name!=value or value in ('.','..'):raise SystemExit('Use a directory name inside this campaign')
extras=()
if args.probe:
    name='CyrusPrivatePaintProbe.dlx'
    shutil.copy2(root/f'build/vector-brush-078/callback-probe-{args.year}'/name,root/'build/vector-brush-078'/args.native/name)
    extras=(name,)
p,meta=launch(root/'build/vector-brush-078'/args.host,root/'AminScatter/scripts/AminScatterObject.ms',root/'build/vector-brush-078'/args.native,transport=True,max_year=args.year,extra_modules=extras)
print(json.dumps(meta,indent=2),flush=True)
folder=Path(meta['output']);deadline=time.monotonic()+240
while time.monotonic()<deadline:
    if (folder/'startup-error.txt').exists():raise SystemExit((folder/'startup-error.txt').read_text())
    if (folder/'ready.json').exists():print('Private host ready',flush=True);break
    if p.poll() is not None:raise SystemExit('Private Max exited before readiness')
    time.sleep(.5)
else:raise SystemExit('Startup timed out; inspect this owned process before doing more work')
