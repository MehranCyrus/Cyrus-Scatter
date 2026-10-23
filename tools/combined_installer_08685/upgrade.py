from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[2];W=ROOT/'build/combined-installer-08685-20261022'
sys.path.insert(0,str(ROOT/'tools/quality_validation'))
from host import bind_suite,run
from results import artifact_identity
year=int(sys.argv[1]);assert year in (2026,2027)
folder=W/f'host02-{year}';rows=json.loads((folder/'batch.json').read_text(encoding='utf-8'))
assert len(rows)==38 and all(x['status']=='pass' for x in rows)
metadata=bind_suite(folder);paths={n:Path(p) for n,p in metadata['paths'].items()};paths['driver:upgrade']=Path(__file__)
identity,hashes=artifact_identity(paths);metadata.update(artifact_id=identity,hashes=hashes,paths={n:str(p) for n,p in paths.items()})
(folder/'qualification.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
name='R4-M12-UPGRADE';r=run(folder,{'id':name,'fixture':'tools/quality_validation/schema_lifecycle.ms','assertions':[name+'-01']},timeout=180)
(folder/'upgrade.json').write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');assert r['status']=='pass';print(year,'schema58 upgrade/Undo/Redo and schema59 merge pass')
