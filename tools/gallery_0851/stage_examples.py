"""Append the two verified examples; preserve the original six data files."""
from pathlib import Path
import argparse,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();host=a.profile.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-gallery0851-')
library=ROOT/'AminScatter/library';sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
inventory=json.loads((library/'inventory.json').read_text(encoding='utf-8'));assert len(inventory['entries'])==6
for name,digest in inventory['files'].items():assert sha(library/name)==digest,name
previous=json.loads(json.dumps(inventory))
for slug,folder_name in [('formal','formal'),('valley','valley-02')]:
 folder=host/'gallery-examples'/folder_name
 initial=json.loads((folder/'receipt.json').read_text(encoding='utf-8'));record=json.loads((folder/'preview-receipt.json').read_text(encoding='utf-8'))
 assert initial['status']==record['status']=='passed'
 logs=sorted(folder.glob('apply-*.txt'),key=lambda path:path.stat().st_mtime)
 text=logs[-1].read_text(encoding='utf-8-sig')
 assert 'PASS: complete' in text and 'FAIL:' not in text and 'Saved variation reproduces every full placement row' in text
 destination=library/slug;assert not destination.exists()
 for name,digest in record['files'].items():
  source=(folder/name).resolve();assert source.is_relative_to(folder.resolve()) and sha(source)==digest
  # The bounded catalog indexes the chosen folder, not an unbounded subtree.
  # Keep manifests and their unchanged relative payloads together at its root.
  relative=slug+'/'+name if source.suffix.lower()=='.max' else name
  target=library/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
  inventory['files'][relative]=digest
 inventory['entries'].append({'id':slug,'name':initial['title'],'recipe':Path(record['recipe']).name,
   'scene':slug+'/'+Path(record['scene']).name,'thumbnail':Path(record['thumbnail']).relative_to(folder).as_posix(),
   'counts':initial['counts'],'source_host':host.name,'qualification_scope':'Actual format-5 Save/Load, full rows, Paint, Undo/Redo; exact-placement Scanline preview',
   'source_script_sha256':sha(Path(json.loads((host/'runtime.json').read_text(encoding='utf-8'))['script']))})
readme=(library/'README.md').read_text(encoding='utf-8')
readme=readme.replace('Six editable procedural examples for Cyrus Scatter 0.85.0','Eight editable procedural examples for Cyrus Scatter 0.85.1')
readme=readme.replace('Path and formal-garden examples remain planned.','The formal garden uses grids and painted footprints. Direct spline avenue placement remains dependent on I07.')
readme+='\n## Added in 0.85.1\n\n- **Four garden rooms:** regular topiary rows, soft flower beds and gravel paths; three complete painted layers.\n- **Valley moss and rocky crests:** channel 2 R/X density, an inverted rock mask, a density curve, normal blending and slope fading. The stored numeric field is authored in the demo terrain; it does not claim automatic curvature analysis.\n\nEach entry includes an editable Max 2027 scene and a rendered preview made from its exact published placements. Models are original procedural placeholders that you can substitute with your own assets. Recipes preserve settings and Paint; bind compatible terrain/models when loading them. The six earlier scene/recipe/image sets retain their original bytes.\n'
(library/'README.md').write_text(readme,encoding='utf-8');inventory['files']['README.md']=sha(library/'README.md')
inventory.update(version='0.85.1',previous_qualification_version=previous['version'],qualification_host=host.name,
                 qualification_script_sha256=inventory['entries'][-1]['source_script_sha256'])
(library/'inventory.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
(host/'gallery-examples/staging-receipt.json').write_text(json.dumps({'previous_inventory':previous,'current_inventory_sha256':sha(library/'inventory.json'),'original_six_preserved':True},indent=2),encoding='utf-8')
print('Staged eight examples, preserving original six data hashes')
