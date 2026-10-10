from pathlib import Path
import sys,json,time,hashlib,shutil
R=Path.cwd();W=R/'build/courtyard-fixes075';H=R/'build/mcp-qualification/courtyard-fixes075-release'
sys.path.insert(0,str(R/'tools/procedural_lab'));from runtime_driver import run_script
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for name in ('max2027-release','analyzer2027-release'):
 receipt=json.loads((W/name/'receipt.json').read_text())
 assert all(x['exit_code']==0 for x in receipt['stages'])
 for path,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(R/path)==digest,path
rows=[]
def call(label,code,timeout=300):
 t=time.monotonic();result=run_script(H,code,timeout)
 row={'name':label,'result':result,'passed':result.startswith('SUCCESS '),'seconds':time.monotonic()-t}
 rows.append(row);(W/'release-campaign.json').write_text(json.dumps(rows,indent=2));print(label,row['passed'],result if not row['passed'] else '',flush=True)
 if not row['passed']:raise RuntimeError(result)
def file(name):return 'fileIn @"'+(R/name).as_posix()+'"'
call('courtyard-performance', (W/'after_probe.ms').read_text(),420)
for name in ('Max_Procedural_07_Acceptance.ms','Max_Courtyard_Fixes_075.ms','Max_Unified_073_Advanced.ms','Max_Unified_073_Analyzer_Assignment.ms','Max_Layer_Regions_074.ms','Max_Consolidation_075.ms','Max_System_075.ms','Max_Unified_073_Persistence.ms'):
 call('load-'+name,file('tools/procedural_lab/'+name),60)
for label,code in [('proxy','F75Checks=#();F75Proxy()'),('update','F75Update()'),('analyzer-freshness','F75Analyzer()'),('core','P07Acceptance()'),('regions','LRSetup();LRRun();LRViews();LRReopen();LRAdditional()'),('manual-spacing','C75Manual();C75Workflow();C75Spacing()'),('sources','Q75Sources()'),('relax','U73Advanced()'),('analyzer-assignment','U73AnalyzerAssignment()'),('edit','U73EditPersistence()')]:call(label,code)
for name in ('Max_Source_Containers_Output.ms','Max_Procedural_07_Regression.ms'):
 s=(R/'tools/procedural_lab'/name).read_text().replace('"/procedural07-ui-"','"/courtyard-fixes075-release"')
 (W/name).write_text(s);call(name,file('build/courtyard-fixes075/'+name))
shutil.copy2(R/'tools/procedural_lab/Max_Analyzer_Playback_073_Regression.ms',H/'analyzer-fixture.ms')
call('playback',(W/'playback.ms').read_text(),300)
call('corona-production',(W/'render_check.ms').read_text(),180)
for name in ('max2027-release','analyzer2027-release'):
 receipt=json.loads((W/name/'receipt.json').read_text())
 for path,digest in receipt['sources'].items():assert sha(R/path)==digest,path
print('Final source identities unchanged',flush=True)
