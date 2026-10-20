"""Require the final scoped witnesses, preserve old library bytes, and stage delivery."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/reliability-0870-20261019';stage=BASE/'library08';native=Path('D:/CyrusScatterBuilds/reliability-0870-20261019/native10')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
script=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms');receipt=read(native/'receipt.json')
assert script==receipt['sources']['AminScatter/scripts/AminScatterObject.ms'] and all(s['exit_code']==0 for s in receipt['stages'])
host=lambda n:ROOT/'build/mcp-qualification'/('density0862-reliability-0870-'+n)
records=[]
def admit(path):
 d=read(path);assert d['status']=='passed' and d['script_sha256']==script,path
 for key,digest in d['logs'].items():
  if path.name=='edge-result.json':log=Path(d['run'])/(key+'.txt')
  elif path.name.startswith('preset-'):log=path.parent/(path.name.removesuffix('-result.json')+'-'+key+'.txt')
  else:log=path.parent/(('regression' if path.name=='amount-result.json' else path.name.removesuffix('-result.json'))+'-'+key+'.txt')
  assert sha(log)==digest and 'PASS: complete' in log.read_text(encoding='utf-8-sig'),log
 records.append({'path':str(path.relative_to(ROOT)),'sha256':sha(path),**d})
for name in ('lifecycle','amount','elevation','receiver-map'):admit(host('05')/(name+'-result.json'))
admit(host('06')/'edge-result.json')
entries=read(stage/'inventory.json')['entries']
for e in entries:
 for unit in ('feet','millimeters'):admit(host('05')/('preset-'+e['id']+'-'+unit+'-plain-result.json'))
for identifier in ('formal','borders','valley','mountain'):
 for unit in ('centimeters','meters'):admit(host('06')/('preset-'+identifier+'-'+unit+'-transformed-result.json'))
for variant in ('tiny','huge'):
 for identifier in ('formal','valley'):admit(host('06')/('preset-'+identifier+'-meters-'+variant+'-result.json'))
for identifier in ('formal','valley','mountain'):admit(host('06')/('preset-'+identifier+'-centimeters-heightfield-result.json'))
for identifier in ('formal','borders'):admit(host('06')/('preset-'+identifier+'-centimeters-folded-result.json'))
qualification=ROOT/'docs/plans/preset-gallery-improvements/QUALIFICATION_0870.json'
qualification.write_text(json.dumps({'version':'0.87.0','max_year':2027,'status':'passed within listed scope; package checks recorded separately','native_receipt':str(native/'receipt.json'),'native_receipt_sha256':sha(native/'receipt.json'),'script_sha256':script,'records':records,'limits':['No arbitrary procedural graph export or renderer/camera context','Paint requires single-valued local XY','Windows foreground activation was requested but not observed while another application was foreground','No production-renderer, mixed-monitor or all-scene certification','Earlier centimetre/metre baseline campaigns retain pair09 identity; final transformed cm/m and plain ft/mm witnesses listed here']},indent=2)+'\n')
original=ROOT/'AminScatter/library';baseline=read(BASE/'library08-baseline.json');preserved=BASE/'original-library-preserved'
assert not preserved.exists()
for name,digest in baseline.items():assert sha(original/name)==digest,name
shutil.copytree(original,preserved)
for name,digest in baseline.items():assert sha(preserved/name)==digest,name
inventory=read(stage/'inventory.json')
readme=stage/'README.md';readme.write_text(readme.read_text().replace('0.87.0 candidate','0.87.0 — Max 2027'))
inventory['qualification_status']='passed: scoped final-pair Max 2027 destination, physical-unit, history, map and recovery witnesses'
inventory['qualification_receipt']='docs/plans/preset-gallery-improvements/QUALIFICATION_0870.json';inventory['qualification_receipt_sha256']=sha(qualification)
inventory['preserved_original_bytes']=str(preserved)
inventory['files']={n:sha(stage/n) for n in inventory['files'] if not n.endswith('.library.json')}
(stage/'inventory.json').write_text(json.dumps(inventory,indent=2)+'\n')
for name,digest in inventory['files'].items():
 assert sha(stage/name)==digest,name
 target=original/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/name,target);assert sha(target)==digest
shutil.copy2(stage/'inventory.json',original/'inventory.json')
print('Qualified',len(records),'final-pair records; original library preserved; staged',len(inventory['files']),'delivery files.')
