"""Execute the final focused host sequence against a fresh matched launch."""
from pathlib import Path
import sys,argparse,json,subprocess
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();out=a.profile.resolve()
assert out.parent==ROOT/'build/mcp-qualification' and out.name.startswith('foundation-terrace0815-candidate')
data={'steps':[]};path=out/'focused-qualification.json'
def save():path.write_text(json.dumps(data,indent=2)+'\n')
for name in ['container_native_fresh.ms','capacity_host.py','containers_final.py','render_scale_probe.py']:
    source=ROOT/'tools/terrace_0815'/name
    code=source.read_text() if source.suffix=='.ms' else 'python.ExecuteFile @"'+source.as_posix()+'"'
    result=run_script(out,code,timeout=300);data['steps'].append({'name':name,'result':result});save();print(name+': '+result[:100],flush=True)
    if not result.startswith('SUCCESS '):raise RuntimeError(result)
subprocess.run([sys.executable,str(ROOT/'tools/terrace_0815/regressions.py'),str(out)],check=True)
data['complete']=True;save()
