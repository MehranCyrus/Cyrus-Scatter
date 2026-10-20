"""Launch/command only recorded private hosts for the 0.86.7.1 campaign."""
from pathlib import Path
import argparse,json,shutil,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import ready,send
p=argparse.ArgumentParser()
p.add_argument('operation',choices=['launch','send'])
p.add_argument('--name',required=True)
p.add_argument('--year',type=int,choices=[2024,2026,2027],default=2027)
p.add_argument('--native',type=Path)
p.add_argument('--scale',type=float,choices=[1.,1.5,2.],default=1.)
p.add_argument('--script',type=Path)
a=p.parse_args()
if not a.name.startswith('update08671-'):raise ValueError('Owned campaign name required')
folder=ROOT/'build/mcp-qualification'/a.name
if a.operation=='send':
    metadata=json.loads((folder/'launch.json').read_text())
    if metadata['max_year']!=a.year:raise ValueError('Host year differs')
    ready(folder);send(folder,a.script.resolve(),a.script.stem)
else:
    process,metadata=launch(folder,a.script or ROOT/'AminScatter/scripts/AminScatterObject.ms',
        a.native,extra=f'CustomControlsOptions.UIUserScaleFactor={a.scale}',transport=True,max_year=a.year,silent_startup=True,
        script_assets=('CyrusGallery.dll',)+(('LibraryBinding.txt',) if (a.native/'LibraryBinding.txt').exists() else ()))
    shutil.copytree(ROOT/'AminScatter/patterns',folder/'scripts/Patterns')
    print(json.dumps({'pid':process.pid,'profile':str(folder)}),flush=True)
    ready(folder);print('Owned host ready',flush=True)
