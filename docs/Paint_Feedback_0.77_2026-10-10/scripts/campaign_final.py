from pathlib import Path
import sys,json,time,hashlib,shutil
R=Path.cwd();W=R/'build/paint077';H=R/'build/mcp-qualification/paint077-final'
sys.path.insert(0,str(R/'tools/procedural_lab'));from runtime_driver import run_script
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
rows=[]
def call(label,code,timeout=300):
 t=time.monotonic();result=run_script(H,code,timeout)
 row={'name':label,'result':result,'passed':result.startswith('SUCCESS '),'seconds':time.monotonic()-t}
 rows.append(row);(W/'campaign-final.json').write_text(json.dumps(rows,indent=2));print(label,row['passed'],result if not row['passed'] else '',flush=True)
 if not row['passed']:raise RuntimeError(result)
def file(name):return 'fileIn @"'+(R/name).as_posix()+'"'
for name in ('Max_Procedural_07_Acceptance.ms','Max_Courtyard_Fixes_075.ms','Max_Unified_073_Advanced.ms','Max_Unified_073_Analyzer_Assignment.ms','Max_Layer_Regions_074.ms','Max_System_075.ms','Max_Unified_073_Persistence.ms','Max_Brush_076.ms','Max_Receiver_Stability_076.ms'):
 call('load-'+name,file('tools/procedural_lab/'+name),60)
code=(R/'tools/procedural_lab/Max_Consolidation_075.ms').read_text().replace('r.uiVersion()=="0.75"','r.uiVersion()=="0.77"').replace('Current source reports 0.75','Current source reports 0.77')
(W/'consolidation-version-adapted.ms').write_text(code)
call('load-workflow',file('build/paint077/consolidation-version-adapted.ms'))
for label,code in [('receiver-stability','R76Membership();R76Save();R76Reopen();R76Edit();R76Paint()'),('brush-limits','B76Limit()'),('regions','LRSetup();LRRun();LRViews();LRReopen();LRAdditional()'),('proxy','F75Checks=#();F75Proxy()'),('update','F75Update()'),('analyzer-freshness','F75Analyzer()'),('core','P07Acceptance()'),('manual-spacing','C75Manual();C75Workflow();C75Spacing()'),('sources','Q75Sources()'),('relax','U73Advanced()'),('analyzer-assignment','U73AnalyzerAssignment()'),('edit','U73EditPersistence()')]:call(label,code)
for name in ('Max_Source_Containers_Output.ms','Max_Procedural_07_Regression.ms'):
 s=(R/'tools/procedural_lab'/name).read_text().replace('"/procedural07-ui-"','"/paint077"')
 (W/name).write_text(s);call(name,file('build/paint077/'+name))
shutil.copy2(R/'tools/procedural_lab/Max_Analyzer_Playback_073_Regression.ms',H/'analyzer-fixture.ms')
call('playback',(R/'build/courtyard-fixes075/playback.ms').read_text(),300)
call('corona-production',(R/'build/courtyard-fixes075/render_check.ms').read_text(),180)
