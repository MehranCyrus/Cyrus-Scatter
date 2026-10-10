from pathlib import Path
import sys,json,time
R=Path.cwd();W=R/'build/receiver076';H=R/'build/mcp-qualification/receiver076-release'
sys.path.insert(0,str(R/'tools/procedural_lab'));from runtime_driver import run_script
checks=[]
def call(name,code):
 t=time.monotonic();result=run_script(H,code,300);checks.append(dict(name=name,result=result,seconds=time.monotonic()-t,passed=result.startswith('SUCCESS ')))
 (W/'focused.json').write_text(json.dumps(checks,indent=2));print(name,result,flush=True)
 if not checks[-1]['passed']:raise RuntimeError(result)
for name in ['Max_Receiver_Stability_076.ms','Max_Layer_Regions_074.ms']:
 call('load-'+name,'fileIn @"'+(R/'tools/procedural_lab'/name).as_posix()+'"')
for name,code in [('membership','R76Membership()'),('save','R76Save()'),('reopen','R76Reopen()'),('edit','R76Edit()'),('edit-save','R76Save()'),('edit-reopen','R76Reopen()'),('painting','R76Paint()')]:call(name,code)
