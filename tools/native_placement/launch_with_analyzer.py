"""Stage exact Scatter and independently versioned Analyzer in an owned host."""
import argparse, ctypes, hashlib, json, shutil, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('host')
p.add_argument('--native', type=Path, required=True)
p.add_argument('--analyzer', type=Path, required=True)
p.add_argument('--scale',type=float,choices=(1.0,1.5),default=1.0)
a = p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
payload = ROOT/'build/mcp-qualification'/(a.host+'-payload')
host = ROOT/'build/mcp-qualification'/a.host
assert not host.exists() and not payload.exists()
records = []
for directory in (a.native.resolve(), a.analyzer.resolve()):
    receipt = json.loads((directory/'receipt.json').read_text(encoding='utf-8'))
    assert receipt['max_year'] == 2027 and all(s['exit_code'] == 0 for s in receipt['stages'])
    assert not receipt.get('preview_fault_lab') and not receipt.get('placement_qualification')
    for name, expected in receipt['sources'].items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == expected, name
    for name, expected in receipt['binaries'].items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == expected, name
    records.append(receipt)
payload.mkdir()
for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusGallery.dll'):
    shutil.copy2(a.native/name, payload/name)
shutil.copy2(a.analyzer/'CyrusSurfaceAnalyzer.dlx',payload/'CyrusSurfaceAnalyzer.dlx')
shutil.copy2(ROOT/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms',payload/'CyrusSurfaceAnalyzer.ms')
(payload/'source-receipts.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
process, record = launch(host, ROOT/'AminScatter/scripts/AminScatterObject.ms',payload,
    extra=f'CustomControlsOptions.UIUserScaleFactor={a.scale};fileIn (MCPFixtureDir+"scripts/CyrusSurfaceAnalyzer.ms")',
    transport=True,max_year=2027,silent_startup=True,
    extra_modules=('CyrusSurfaceAnalyzer.dlx',),script_assets=('CyrusGallery.dll','CyrusSurfaceAnalyzer.ms'))
print(json.dumps({'pid':process.pid,'profile':str(host)}),flush=True)
record['qualification_ui_scale']=a.scale;record['os_display_settings_modified']=False
(host/'launch.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
observation = {'pid':process.pid,'ready':False,'exited':False}
end = time.monotonic()+120
while time.monotonic()<end:
    if (host/'ready.json').exists(): observation['ready']=True;break
    if (host/'startup-error.txt').exists():
        observation['startup_error']=(host/'startup-error.txt').read_text(encoding='utf-8-sig');break
    code=process.poll()
    if code is not None: observation.update(exited=True,exit_code=code);break
    time.sleep(.2)
else: observation['observation_timeout_live']=True
(host/'startup-observation.json').write_text(json.dumps(observation,indent=2)+'\n',encoding='utf-8')
print(json.dumps(observation),flush=True)
sys.exit(0 if observation['ready'] else 1)
