"""Verify final-pair logs, retain authoring history, and qualify indexed library."""
from pathlib import Path
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--native',type=Path,required=True);p.add_argument('--hosts',nargs='+',required=True);a=p.parse_args()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
script=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms');native=a.native.resolve();receipt=read(native/'receipt.json')
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
for name,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==digest,name
records=[]
for name in a.hosts:
 assert name.startswith('density0862-reliability-surface0866-');host=ROOT/'build/mcp-qualification'/name
 pair=read(host/'source-pair.json');assert pair['receipt_sha256']==sha(native/'receipt.json')
 for path in sorted(host.glob('*-result.json')):
  d=read(path);assert d['status']=='passed' and d['script_sha256']==script,path
  for key,digest in d['logs'].items():
   if path.name=='edge-result.json':log=Path(d['run'])/(key+'.txt')
   elif path.name.startswith('preset-'):log=path.parent/(path.name.removesuffix('-result.json')+'-'+key+'.txt')
   else:log=path.parent/(('regression' if path.name=='amount-result.json' else path.name.removesuffix('-result.json'))+'-'+key+'.txt')
   assert sha(log)==digest and 'PASS: complete' in log.read_text(encoding='utf-8-sig'),log
  records.append({'path':str(path.relative_to(ROOT)),'sha256':sha(path),**d})
names={Path(d['path']).name for d in records}
assert {'surface-result.json','lifecycle-result.json','amount-result.json','receiver-map-result.json','elevation-result.json','edge-result.json'}<=names
surface=next(d for d in records if Path(d['path']).name=='surface-result.json');assert len(surface['phases'])>=21
library=ROOT/'AminScatter/library';inventory=read(library/'inventory.json')
for e in inventory['entries']:assert 'preset-'+e['id']+'-millimeters-plain-result.json' in names
qualification=ROOT/'docs/plans/preset-gallery-improvements/QUALIFICATION_0866.json'
qualification.write_text(json.dumps({'version':'0.86.6','corrected_previous_feature_baseline':'0.86.5','max_year':2027,'status':'passed within listed scope; package checks recorded separately','native_receipt':str(native/'receipt.json'),'native_receipt_sha256':sha(native/'receipt.json'),'script_sha256':script,'records':records,'limits':['Scripted generated UI handlers and actual Painter SDK callbacks; no physical mouse/tablet certification','Curved Paint requires manifold nondegenerate indexed geometry, maximum 100000 triangles/200000 vertices, with bounded contour/solver work','Geodesic distance contour approximation uses radius-relative 0.5 percent refinement; feather boundary source sampling uses 2 percent of fade width','Edited closed-surface spline curves select the smaller enclosed region; unchanged guarded snapshots restore exact coverage','Arbitrary remeshing does not retain face correspondence; terrain preset transfer remains local-XY, curved preset transfer requires matching topology','No all-scene, production-renderer or older-host certification']},indent=2)+'\n')
for name,digest in inventory['files'].items():assert sha(library/name)==digest,name
inventory['previous_delivery_qualification']={'version':inventory['version'],'receipt':inventory['qualification_receipt'],'sha256':inventory['qualification_receipt_sha256']}
inventory['version']='0.86.6';inventory['qualification_status']='passed: final-pair Max 2027 brush, library, Amount/map, lifecycle and recovery witnesses'
inventory['qualification_receipt']=str(qualification.relative_to(ROOT)).replace('\\','/');inventory['qualification_receipt_sha256']=sha(qualification)
readme=library/'README.md'
try:readme_text=readme.read_text(encoding='utf-8')
except UnicodeDecodeError:readme_text=readme.read_text(encoding='cp1252')
lines=readme_text.replace('0.87.0','0.86.6').splitlines();lines[0]='# Cyrus planting presets — 0.86.6 / Max 2027';readme.write_text('\n'.join(lines)+'\n',encoding='utf-8')
inventory['files']={name:sha(library/name) for name in inventory['files']}
(library/'inventory.json').write_text(json.dumps(inventory,indent=2)+'\n')
print('Qualified',len(records),'final-pair records and',len(inventory['entries']),'library entries; original authoring identities retained.')
