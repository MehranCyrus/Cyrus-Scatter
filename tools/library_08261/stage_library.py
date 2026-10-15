"""Stage qualified procedural examples; never install into a Max profile."""
from pathlib import Path
import argparse,json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
host=(ROOT/'build/mcp-qualification'/a.host).resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-library08261-')
target=ROOT/'AminScatter/library';assert not target.exists(),'Do not overwrite a reviewed library; stage a deliberate successor.'
source=host/'bundled';names=set();entries=[]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
for slug in ('meadow','woodland','mountain','borders'):
 record=json.loads((host/('demo-'+slug+'.json')).read_text());assert record['status']=='passed'
 assert json.loads((host/('demo-'+slug+'-prepare.json')).read_text())['status']=='passed'
 applied=(host/('demo-'+slug+'-apply.txt')).read_text();assert 'PASS: complete' in applied and 'FAIL:' not in applied and 'ERROR:' not in applied
 for name,digest in record['files'].items():assert sha(source/name)==digest;names.add(name)
 document=json.loads((source/(slug+'.csrecipe.json')).read_text())
 def attachments(value):
  if isinstance(value,dict):
   if set(value)=={'file','sha256','bytes'}:
    file=(source/value['file']).resolve();assert file.is_relative_to(source.resolve()) and sha(file)==value['sha256'] and file.stat().st_size==value['bytes'];names.add(file.relative_to(source).as_posix())
   for child in value.values():attachments(child)
  elif isinstance(value,list):
   for child in value:attachments(child)
 attachments(document)
 entries.append({'id':slug,'name':record['title'],'recipe':slug+'.csrecipe.json','scene':slug+'.max','thumbnail':Path(record['thumbnail']).name,'counts':record['counts']})
target.mkdir()
for name in sorted(names):
 destination=target/name;destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source/name,destination)
readme='''# Cyrus planting examples

Four editable examples for Cyrus Scatter 0.82.6.1 and 3ds Max 2027. They use
procedural pyramids as groundcover, shrubs, flowers and trees. Replace these model
roles with your own assets; no third-party vegetation library is required.

| Example | Demonstrates |
| --- | --- |
| Layered meadow | Three independent grass, shrub and flower layers |
| Trees and understory | Upright canopy, shrubs and normal-aligned groundcover |
| Mountain planting | Soft slope/altitude exclusion, upright trees and aligned groundcover |
| Painted garden and spline borders | Saved Paint with a clearing, density/scale fading and two spline Bands |

Open the matching `.max` file to inspect the editable result. Select the Cyrus
controller, choose a layer, change settings and press **Update scatter**. These
examples use Manual mode. The sources are parked beside the terrain.

To reuse a recipe, open **Layers > Recipes**, choose **Bundled examples**, select
the recipe and click **Review bindings**. Explicitly bind its terrain, models and
paths. Match unique scene names can suggest bindings in the included scene. Choose
**New setup**, or leave it unchecked to **Add layers** to the selected controller.
Import is one Undo; Manual mode calculates when you press Update scatter.

Paint belongs to compatible receiver geometry, frame and saved system units.
The painted-garden example includes matching terrain. An arbitrary replacement
mountain is not automatically compatible with that Paint footprint.

Save your own versions in **My recipes** (`Documents/CyrusScatter/Library`) or
an explicit custom folder. Bundled files occupy a versioned folder and are not
overwritten by later versions. Keep each recipe, its Paint payload folder,
`.library.json` presentation sidecar and PNG together when sharing a recipe.

Thumbnails are actual renders of the saved accepted placements. These are
demonstration assets, not botanical models or renderer-specific proxy packages.
Grid/path examples will be added when their features are delivered.

## Content permission

The procedural example geometry, recipe data and thumbnails in this folder were
created for Cyrus Scatter. Permission is granted to use, modify and redistribute
this demonstration content with Cyrus Scatter and in users' scenes. This grant
does not change the plugin license or cover users' substituted third-party assets.
'''
(target/'README.md').write_text(readme,encoding='utf-8')
names.add('README.md')
inventory={'version':'0.82.6.1','max_year':2027,'source_host':a.host,'source_script_sha256':json.loads((host/'launch.json').read_text())['script_sha256'],'entries':entries,'files':{name:sha(target/name) for name in sorted(names)}}
(target/'inventory.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'files':len(names),'examples':len(entries),'directory':str(target),'bytes':sum((target/n).stat().st_size for n in names)},indent=2))
