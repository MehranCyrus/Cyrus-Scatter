from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
source=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library'
catalog=json.loads((source/'model-catalog.json').read_text())
entry=next(e for e in catalog['entries'] if e['id']=='A027')
target=ROOT/'build/viewport-0867-20261020/standard-fixture/Library'
model=target/entry['scene'];model.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'build/mcp-qualification/viewport0867-content-2027/standard-leaf.max',model)
shutil.copy2(source/entry['thumbnail'],target/entry['thumbnail'])
entry['scene_bytes']=model.stat().st_size
entry['scene_sha256']=hashlib.sha256(model.read_bytes()).hexdigest()
catalog['entries']=[entry]
(target/'model-catalog.json').write_text(json.dumps(catalog,indent=2))
