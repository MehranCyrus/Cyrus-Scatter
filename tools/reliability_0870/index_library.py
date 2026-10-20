"""Pin the reauthored staged library and only its reachable current payloads."""
from pathlib import Path
import argparse,hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--library',type=Path,required=True);a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;library=a.library.resolve();assert library.is_relative_to(ROOT/'build/reliability-0870-20261019')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inventory=json.loads((library/'inventory.json').read_text());files={'README.md'}
baseline=library.parent/(library.name+'-baseline.json');assert baseline.is_file()
for entry in inventory['entries']:
 record=json.loads((host/('author-'+entry['id']+'-capture.json')).read_text());assert record['status']=='passed'
 recipe=library/entry['recipe'];assert sha(recipe)==record['recipe_sha256']
 doc=json.loads(recipe.read_text());assert doc['formatVersion']==7
 package=Path(record['package']).resolve();assert package.is_relative_to(library/'Presets')
 entry.update(ready_package=package.relative_to(library).as_posix(),ready_package_sha256=sha(package/'cyrus.package.json'),
  counts=record['counts'],source_host=a.host,source_script_sha256=record['source_script_sha256'])
 graph=json.loads((package/'assets.json').read_text());entry['ready_assets']={'meshes':len(graph['meshes']),'splines':len(graph['splines'])}
 entry['thumbnail']=doc['presentation']['thumbnail']['file']
 files.update((entry['recipe'],entry['scene'],entry['thumbnail']))
 sidecar=library/(entry['recipe']+'.library.json')
 if sidecar.exists():files.add(sidecar.relative_to(library).as_posix())
 def dependencies(value):
  if isinstance(value,dict):
   if set(value)=={'file','sha256','bytes'}:
    path=(library/value['file']).resolve();assert path.is_relative_to(library) and path.stat().st_size==value['bytes'] and sha(path)==value['sha256'];files.add(path.relative_to(library).as_posix())
   for x in value.values():dependencies(x)
  elif isinstance(value,list):
   for x in value:dependencies(x)
 dependencies(doc)
 files.update(path.relative_to(library).as_posix() for path in package.rglob('*') if path.is_file())
inventory.update(version='0.87.0',max_year=2027,source_host=a.host,source_script_sha256=record['source_script_sha256'],
 qualification_status='candidate: authored and package-validated; destination campaign pending',
 preserved_baseline_receipt=str(baseline),preserved_baseline_sha256=sha(baseline),
 ready_preset_contract='asset graph 2; Add Layers onto selected terrain; physical units; explicit relative elevation; local XY Paint/path transfer')
inventory['files']={name:sha(library/name) for name in sorted(files)}
(library/'inventory.json').write_text(json.dumps(inventory,indent=2)+'\n')
print('Indexed',len(inventory['entries']),'entries and',len(files),'current payloads')
