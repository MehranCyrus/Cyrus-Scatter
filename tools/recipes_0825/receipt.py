"""Pin final recipe evidence and exact inputs; does not launch Max or install."""
from pathlib import Path
import hashlib,importlib.util,json,re
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/recipes-0825-20261015-01';STAGE=OUT/'script-11'
HOST=ROOT/'build/mcp-qualification/foundation-roadmap-recipes0825-20261015-05'
COLD=ROOT/'build/mcp-qualification/foundation-roadmap-recipes0825-20261015-04'
DOC=ROOT/'docs/plans/recipes-0825'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
spec=importlib.util.spec_from_file_location('offline',ROOT/'tools/procedural_lab/offline_build.py');offline=importlib.util.module_from_spec(spec);spec.loader.exec_module(offline)
stage=read(STAGE/'receipt.json');native=read(OUT/'native-06/receipt.json')
assert stage['sources']==offline.source_hashes('AminScatter')
assert stage['max_year']==2027 and not stage['preview_fault_lab'] and all(s['exit_code']==0 for s in stage['stages'])
evidence={};checks=0
for host,names in [(HOST,['recipes-qualification.json','recipe-ui.json','recipe-library-performance.json','recipe-reopen.json'])]:
 for name in names:
  p=host/name;d=read(p);assert d['status']=='passed' and all(x['passed'] for x in d['checks']),str(p)
  evidence[p.relative_to(ROOT).as_posix()]={'sha256':sha(p),'checks':len(d['checks'])};checks+=len(d['checks'])
for name in ['recipe-undo.txt','recipe-orphan.txt','recipe-bindings.txt','recipe-failure.txt','recipe-live.txt','recipe-bounds.txt']:
 p=HOST/name;s=p.read_text(encoding='utf-8-sig');assert 'PASSED' in s and not re.search(r'^(FAIL|FAILED)',s,re.M),name
 count=len(re.findall(r'^PASS:',s,re.M));checks+=count;evidence[p.relative_to(ROOT).as_posix()]={'sha256':sha(p),'checks':count,'text':s}
p=HOST/'recipe-idle.txt';idle=p.read_text(encoding='utf-8-sig');assert 'unchanged=true' in idle and float(re.search(r'seconds=([0-9.]+)',idle)[1])>=60
checks+=1;evidence[p.relative_to(ROOT).as_posix()]={'sha256':sha(p),'text':idle}
assert read(OUT/'python-final.json')['exit_code']==0 and '163 passed' in (OUT/'python-final.log').read_text()
generated=read(OUT/'generated-final-03/receipt.json') if (OUT/'generated-final-03/receipt.json').exists() else None
# check_generated stores its single report under generated_report.json on some editions.
if generated is None:
 for p in (OUT/'generated-final-03').glob('*.json'):
  candidate=read(p)
  if candidate.get('check')=='unified_073_generator_integration':generated=candidate;break
assert generated and generated['passed'] and generated['generated_sha256']==stage['sources']['AminScatter/scripts/AminScatterObject.ms']
loaded=[]
for host in [HOST]:
 p=host/('runtime.json' if (host/'runtime.json').exists() else 'launch.json');runtime=read(p)
 assert runtime['script_sha256']==stage['sources']['AminScatter/scripts/AminScatterObject.ms']
 modules=(host/'loaded.tsv').read_text(encoding='utf-8-sig').lower()
 for name,digest in runtime['binaries'].items():
  assert sha(host/'bin'/name)==sha(STAGE/name)==digest
  assert str(host/'bin'/name).lower() in modules
 loaded.append({'host':str(host),'runtime_receipt':str(p),'runtime_receipt_sha256':sha(p),'script_sha256':runtime['script_sha256'],'binaries':runtime['binaries']})
extra=[ROOT/'AminScatter/tools/ui/templates/recipes.ms',ROOT/'tools/build_max.py',*sorted((ROOT/'tools/recipes_0825').glob('*.py')),*sorted((ROOT/'tools/recipes_0825').glob('*.ms'))]
sources={**stage['sources'],**{p.relative_to(ROOT).as_posix():sha(p) for p in extra}}
result={'version':'0.82.5','max_year':2027,'schema':58,'evaluation_contract':'CyrusUnified1','recipe_format':1,'native_recipe_capability':1,'native_build':str(OUT/'native-06'),'native_receipt_sha256':sha(OUT/'native-06/receipt.json'),'script_stage':str(STAGE),'script_stage_receipt_sha256':sha(STAGE/'receipt.json'),'source_hashes':sources,'loaded':loaded,'evidence':evidence,'host_assertions':checks,'native_suites':33,'python_tests':163,'generated':generated,'idle_seconds':float(re.search(r'seconds=([0-9.]+)',idle)[1]),'library_timings_ms':read(HOST/'recipe-library-performance.json')['timings_ms'],'phase6':'paused','installed':False,'normal_profile_modified':False,'evidence_limits':['Scripted native/UI handlers; no pointer, DPI/tablet, long-session, renderer or presented-FPS certification.','An earlier storage-churn campaign measured 119 ms p95 and cold reads up to 4.5 seconds; timings are local, not guaranteed latency.','One Live setup request completed after a 120-second wait timeout; no concurrent request or cancellation.','Earlier position/source-only probes were replaced by complete eight-field witnesses in final qualification.','Unsupported authored Edit/radius/nonstatic controller data blocks full save. Scene assets remain external.']}
(OUT/'final-receipt.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');(DOC/'QUALIFICATION.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('Qualified exact pair; host assertions:',checks,'idle seconds:',result['idle_seconds'])
