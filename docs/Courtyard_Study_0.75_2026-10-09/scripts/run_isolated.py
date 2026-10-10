from pathlib import Path
import sys,json,time,shutil,hashlib
R=Path.cwd(); W=R/'build/courtyard-study075'; H=R/'build/mcp-qualification/courtyard-study075'
sys.path.insert(0,str(R/'tools/procedural_lab'))
from runtime_driver import run_script
def call(code,timeout=300):
 result=run_script(H,code,timeout=timeout)
 if not result.startswith('SUCCESS '):raise RuntimeError(result)
 return result
definitions=['tools/procedural_lab/Max_Procedural_07_Acceptance.ms','tools/procedural_lab/Max_Unified_073_Advanced.ms','tools/procedural_lab/Max_Unified_073_Analyzer_Assignment.ms','tools/procedural_lab/Max_Layer_Regions_074.ms','tools/procedural_lab/Max_Consolidation_075.ms','tools/procedural_lab/Max_System_075.ms','tools/procedural_lab/Max_Unified_073_Persistence.ms','docs/Arrangement_Research_0.75_2026-10-09/Probe.ms','build/courtyard-study075/extra_features.ms']
for f in definitions:call('fileIn @"'+(R/f).as_posix()+'"',60)
cases=[('core','P07Acceptance()'),('regions','LRSetup();LRRun();LRViews();LRReopen();LRAdditional()'),('manual-spacing','C75Manual();C75Workflow();C75Spacing()'),('sources','Q75Sources()'),('relax','U73Advanced()'),('analyzer','U73AnalyzerAssignment()'),('edit','U73EditPersistence()'),('arrangement','ARResults=#();ARBasic();ARLine();ARAnalyzer()'),('extra','CYExtra()')]
receipts=[]
for name,code in cases:
 t=time.monotonic();row={'name':name,'command':code}
 try: row['result']=call(code);row['passed']=True
 except TimeoutError:raise
 except Exception as e:row['passed']=False;row['error']=str(e)
 row['elapsed_s']=time.monotonic()-t
 dest=H/('isolated-'+name);dest.mkdir(exist_ok=True)
 for p in H.iterdir():
  if p.is_file() and p.suffix in ('.json','.txt','.tsv') and not p.name.startswith(('dev-','probe-')):shutil.copy2(p,dest/p.name)
 receipts.append(row);(W/'isolated-results.json').write_text(json.dumps(receipts,indent=2));print(name,row['passed'],row.get('error',''),flush=True)
call('loadMaxFile @"'+(R/'Test Scene/Courtyard_Study_075/Courtyard_075.max').as_posix()+'" quiet:true useFileUnits:true;CYRebind()',180)
print('Restored courtyard',flush=True)
