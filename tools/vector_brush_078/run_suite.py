"""Serialize the current regression campaign in one already-ready private host."""
from pathlib import Path
import argparse,json,subprocess,sys
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--host',required=True);a=p.parse_args()
folder=(root/'build/vector-brush-078'/a.host).resolve()
if folder.parent!=root/'build/vector-brush-078':raise SystemExit('Campaign host name required')
log=[]
for name in ('button_workflow','layout_diagnostic','layout_modes','acceptance','extended','inspection','performance','playback'):
    print('START '+name,flush=True)
    run=subprocess.run([sys.executable,str(root/'tools/vector_brush_078/request.py'),str(root/f'tools/vector_brush_078/{name}.ms'),'--host',a.host,'--timeout','240'],capture_output=True,text=True)
    log.append({'fixture':name,'exit_code':run.returncode,'output':run.stdout+run.stderr})
    (folder/'suite.json').write_text(json.dumps(log,indent=2)+'\n')
    print(run.stdout+run.stderr,flush=True)
    if run.returncode:raise SystemExit(run.returncode)
    if name=='layout_modes':
        from validate_layout import validate
        result=validate(folder/'layout-measurements.json');print(json.dumps(result),flush=True)
        if not result['passed']:raise SystemExit('Native layout failed')
print('ALL HOST FIXTURES PASSED',flush=True)
