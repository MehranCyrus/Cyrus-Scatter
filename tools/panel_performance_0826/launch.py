"""Launch an owned Max 2027 host; optional process-local native UI scaling."""
from pathlib import Path
import argparse,hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--scale',type=float,default=0.)
a=p.parse_args();assert a.name.startswith('foundation-roadmap-panel0826-') and a.scale in (0.,1.,1.5,2.)
native=ROOT/'build/panel-0826-20261015-01/native-03'
receipt=json.loads((native/'receipt.json').read_text())
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
for path,digest in receipt['sources'].items():
    if not path.endswith('.ms'):assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
folder=ROOT/'build/mcp-qualification'/a.name
extra=f'CustomControlsOptions.UIUserScaleFactor={a.scale}' if a.scale else ''
process,metadata=launch(folder,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,extra=extra,transport=True,max_year=2027,silent_startup=True)
metadata['qualification_ui_scale']=a.scale;metadata['os_display_settings_modified']=False
(folder/'launch.json').write_text(json.dumps(metadata,indent=2)+'\n');print(json.dumps(metadata),flush=True)
end=time.monotonic()+240
while time.monotonic()<end:
    if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text())
    if (folder/'ready.json').exists():print('Owned host ready',flush=True);break
    if process.poll() is not None:raise RuntimeError('Host exited before readiness')
    time.sleep(.5)
else:raise TimeoutError('Owned host readiness; inspect before retrying')
