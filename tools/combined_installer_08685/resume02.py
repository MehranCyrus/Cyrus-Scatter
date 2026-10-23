"""Explicit fixture successor after an observed complete failed request."""
from pathlib import Path
import hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2];W=ROOT/'build/combined-installer-08685-20261022'
sys.path.insert(0,str(ROOT/'tools/quality_validation'))
from host import bind_suite,run
from results import artifact_identity
def read(p):return json.loads(Path(p).read_text(encoding='utf-8'))
folder=W/'host02-2024'
before=read(folder/'batch.json');assert before[-1]['scenario']=='R1-M06' and before[-1]['status']=='fail'
assert all(x['status']=='pass' for x in before[:-1])
metadata=bind_suite(folder)
paths={n:Path(p) for n,p in metadata['paths'].items()};paths['driver:resume']=Path(__file__)
identity,hashes=artifact_identity(paths);metadata.update(artifact_id=identity,hashes=hashes,paths={n:str(p) for n,p in paths.items()})
(folder/'qualification.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
old=read(ROOT/'build/installer-panels-08684-20261022/host-final03/batch-final.json')
ids=[x['scenario'] for x in old if x['scenario'] not in ['UI84-SDKORDER','INSTALL84-HOST','R6-M01']]
manifest=read(ROOT/'tools/quality_validation/scenarios.json')
scenarios=[{'id':'R1-M06-SETTLED02','fixture':'tools/quality_validation/analyzer_live_compatibility02.ms','assertions':['R1-M06-SETTLED02-01']}]
for name in ids[ids.index('R1-M06')+1:]:
    scenario=next((s for s in manifest['scenarios'] if s['id']==name),None)
    if scenario is None:
        assert name=='R4-M12-UPGRADE'
        scenario={'id':name,'fixture':'tools/quality_validation/schema_lifecycle.ms','assertions':[name+'-01']}
    scenarios.append(scenario)
rows=[]
for scenario in scenarios:
    start=time.monotonic()
    try:r=run(folder,scenario,timeout=180);status=r['status'];error=r.get('error','')
    except Exception as exc:status='fail';error=str(exc)
    row={'scenario':scenario['id'],'status':status,'seconds':round(time.monotonic()-start,2),'error':error};rows.append(row)
    (folder/'batch-successor02.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8');print(json.dumps(row),flush=True)
    if status!='pass':raise RuntimeError('Observe original successor request before continuing')
print('Passed',len(rows),'explicit successor scenarios',flush=True)
