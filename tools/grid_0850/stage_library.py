"""Append two qualified grid examples without replacing the four frozen examples."""
from pathlib import Path
import argparse,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
host=(ROOT/'build/mcp-qualification'/a.host).resolve();assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-grid0850-')
library=ROOT/'AminScatter/library';source=host/'bundled'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
inventory=json.loads((library/'inventory.json').read_text(encoding='utf-8'))
assert len(inventory['entries'])==4,'Append once; never overwrite a staged successor'
for name,digest in inventory['files'].items():assert sha(library/name)==digest,name
for slug in ('orchard','hexagonal'):
 record=json.loads((host/('demo-'+slug+'.json')).read_text(encoding='utf-8'));assert record['status']=='passed'
 assert json.loads((host/('demo-'+slug+'-prepare.json')).read_text(encoding='utf-8'))['status']=='passed'
 text=(host/('demo-'+slug+'-apply.txt')).read_text(encoding='utf-8')
 assert 'PASS: complete' in text and 'FAIL:' not in text and 'ERROR:' not in text and 'Saved-variation UI import reproduces' in text
 for name,digest in record['files'].items():
  assert Path(name).name==name and sha(source/name)==digest and not (library/name).exists()
  shutil.copy2(source/name,library/name);inventory['files'][name]=digest
 inventory['entries'].append({'id':slug,'name':record['title'],'recipe':slug+'.csrecipe.json','scene':slug+'.max','thumbnail':Path(record['thumbnail']).name,'counts':record['counts'],'source_host':a.host,'source_script_sha256':json.loads((host/'launch.json').read_text(encoding='utf-8'))['script_sha256']})
text=(library/'README.md').read_text(encoding='utf-8')
a=text.index('Four editable');b=text.index('\n\n| Example',a)
text=text[:a]+"Six editable procedural examples for Cyrus Scatter 0.85.0 and 3ds Max 2027. The original four format-1 recipes, scenes and thumbnails remain unchanged; format 4 reads them with neutral defaults. The orchard and hexagonal hillside examples use format 4 and the grid generator. Replace their pyramids and simple flower shapes with your own models; no third-party vegetation library is required."+text[b:]
text=text.replace('Grid/path examples will be added when their features are delivered.','Grid presets use explicit world XY origins. Spacing determines their population; masks and collision rules thin it. Path and formal-garden examples remain planned.')
needle='| Painted garden and spline borders | Saved Paint with a clearing, density/scale fading and two spline Bands |\n'
text=text.replace(needle,needle+'| Rectangular orchard | Even tree rows with independent low groundcover |\n| Hexagonal hillside planting | Regular nearest-neighbor planting, surface projection and normal blending |\n')
(library/'README.md').write_text(text,encoding='utf-8');inventory['files']['README.md']=sha(library/'README.md')
inventory.update(version='0.85.0',qualification_host=a.host,qualification_script_sha256=json.loads((host/'launch.json').read_text(encoding='utf-8'))['script_sha256'])
(library/'inventory.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'examples':len(inventory['entries']),'files':len(inventory['files'])}))
