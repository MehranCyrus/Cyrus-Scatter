from pathlib import Path
import sys,json,time,shutil
R=Path.cwd();W=R/'build/courtyard-study075';H=R/'build/mcp-qualification/courtyard-study075'
sys.path.insert(0,str(R/'tools/procedural_lab'))
from runtime_driver import run_script
def call(code,timeout=300):
 result=run_script(H,code,timeout=timeout)
 if not result.startswith('SUCCESS '):raise RuntimeError(result)
 return result
# Adapt fixture directory guard to this owned profile only; keep every assertion.
for name in ['Max_Source_Containers_Output.ms','Max_Procedural_07_Regression.ms']:
 text=(R/'tools/procedural_lab'/name).read_text().replace('"/procedural07-ui-"','"/courtyard-study075"')
 (W/name).write_text(text)
cases=[('container-edges','U73ContainerEdges()'),('exact-bake','fileIn @"'+(W/'Max_Source_Containers_Output.ms').as_posix()+'"'),('bindings','fileIn @"'+(R/'docs/System_Qualification_0.75_2026-10-09/Control_Bindings.ms').as_posix()+'"'),('layout','fileIn @"'+(R/'tools/procedural_lab/Max_Layout_075.ms').as_posix()+'";L75Run()'),('output-failure-regressions','fileIn @"'+(W/'Max_Procedural_07_Regression.ms').as_posix()+'"')]
receipts=[]
for name,code in cases:
 t=time.monotonic();row={'name':name,'command':code}
 try:row['result']=call(code);row['passed']=True
 except TimeoutError:raise
 except Exception as e:row['passed']=False;row['error']=str(e)
 row['elapsed_s']=time.monotonic()-t
 dest=H/('isolated-'+name);dest.mkdir(exist_ok=True)
 for p in H.iterdir():
  if p.is_file() and p.suffix in ('.json','.txt','.tsv') and not p.name.startswith(('dev-','probe-')):shutil.copy2(p,dest/p.name)
 receipts.append(row);(W/'isolated-stage2-results.json').write_text(json.dumps(receipts,indent=2));print(name,row['passed'],row.get('error',''),flush=True)
call('loadMaxFile @"'+(R/'Test Scene/Courtyard_Study_075/Courtyard_075.max').as_posix()+'" quiet:true useFileUnits:true;CYRebind()',180)
print('Restored courtyard',flush=True)
