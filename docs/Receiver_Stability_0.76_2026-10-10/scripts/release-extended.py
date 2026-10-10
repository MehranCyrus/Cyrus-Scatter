from pathlib import Path
import sys,json,time
sys.path.insert(0,'tools/procedural_lab');from runtime_driver import run_script
h=Path('build/mcp-qualification/receiver076-release');w=Path('build/receiver076');results=[]
for name,code in [('variants','R76Variants()'),('live-start','R76LiveStart()'),('live-end','R76LiveEnd()'),('performance','R76Performance()')]:
 t=time.monotonic();value=run_script(h,code,300);results.append(dict(name=name,passed=value.startswith('SUCCESS'),result=value,seconds=time.monotonic()-t));(w/'extended.json').write_text(json.dumps(results,indent=2));print(name,value,flush=True)
 if not results[-1]['passed']:break
