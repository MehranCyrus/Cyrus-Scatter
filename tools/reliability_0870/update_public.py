"""Update the existing public guide's relevant chapters; does not publish a site."""
from pathlib import Path
import json,hashlib,re
ROOT=Path(__file__).resolve().parents[2];site=ROOT/'website'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
guide=ROOT/'docs/ARTIST_GUIDE.md';guide.write_text(guide.read_text().replace('Use surface field','Use surface density'))
p=site/'content/guide-chapters.json';d=read(p);sections=d['artist-guide']['sections']
for s in sections:
 if s['title']=='Mesh channel density':
  s['title']='Image, map and surface density'
  s['paragraphs']=[
   '**Image / pattern density** and **Surface density** are independent. White permits plants, black excludes them and gray thins them. Their enabled fields multiply with Paint and terrain eligibility before spacing.',
   '**Choose pattern** selects Uniform, Soft patches or Wide bands. **Image** selects a file. Both choose projected World XY. Physical tile size, rotation, offsets and Repeat/Clamp control the image footprint. Scatter local XY follows the setup frame; Receiver UV reads the explicitly selected UV channel.',
   '**Map** selects Map coordinates and evaluates supported graphs against each receiver. Vertex Color reads its own numeric channel, and Checker reads its own UV channel. Color Correction and Output chains retain those inputs. Supported classes also include Bitmap, Mix, Noise, RGB Multiply and Gradient. A surface material is not a density map; renderer/camera-dependent graphs reject with a useful explanation.',
   '**Clear** removes the map and disables image density. The independent surface field stays enabled if it was enabled. Disabling Use image alone preserves its map for later. Image or pattern selection restores projected coordinates; Map restores receiver-aware coordinates.',
   'Enable **Use surface density** and choose Mesh channel to read stored numeric values from the evaluated receiver. Channel 0 reads vertex colors; channels 1..99 select numbered map data. Choose R/X, G/Y or B/Z, then Input min/max, Invert and the response curve. Every receiver must contain the requested channel. Data Channel or VertexPaint can author it; Scatter does not invent missing data.',
   '**Relative elevation** uses evaluated local height: low is 0, high is 1 and flat terrain is 0. Node translation, rotation and scale preserve this field. It creates no mesh channel. Valley moss and Mountain planting use it so their library entries no longer depend on channel 2 or the original world altitude.',
   '**Show mask** displays Image, Surface field or Combined density and follows relevant edits. Manual plants remain at the last Update while the preview can show current inputs. Live follows relevant map/channel edits and animation. Idle and unrelated animation do not evaluate maps or solve Scatter. A failed update retains the complete previous result.',
   'Native map sampling uses unfiltered scalar values. The map graph and receiver work are bounded; unsupported requirements and oversized inputs reject cleanly. Projected maps can use an explicit portable image snapshot. Receiver-aware graphs remain editable in Max scenes but cannot be exported as arbitrary procedural packages or baked into a context-free tile.'
  ]
 if s['title']=='Complete planting recipes':s['paragraphs']=[
  'Select one terrain and open **Cyrus Library**, or open **Layers > Recipes** from the intended setup. Browse My recipes, Bundled examples or Custom library. Opening a collection, searching or selecting thumbnails does not calculate plants or modify the scene.',
  'Pressing Recipes restores a minimized Library at its normal size. X closes it; Recipes reopens it normally. Opening Recipes for another owner or terrain updates the captured destination. Later scene selection alone does not redirect loading.',
  '**Save Recipe** saves supported settings, optional preview and complete Paint. Include models, materials, terrain and paths is checked by default. Terrain is an evaluated geometry/channel snapshot. Saving pending Manual settings does not calculate plants. My recipes is Documents/CyrusScatter/Library; bundled examples are read-only.',
  '**Load onto surface** imports independent supported models/materials and adds layers to the captured setup, creating one if needed. It preserves existing layers and Manual/Live mode, then updates once. One Undo removes the imported layers and assets; Redo restores them. If several setups share a terrain, open Recipes from the intended setup.',
  'Complete presets convert physical sizes and distances into destination system units. Paint contours and static guide positions fit the saved local-XY footprint to the destination footprint. Brush radius, falloff, path widths and model dimensions remain physical. Paint requires single-valued local-XY terrain; folded, closed or stacked projections reject before import. Settings-only exact Paint restoration keeps its compatible-receiver requirement.',
  'The eight revised examples include meadow, woodland, mountain, painted borders, orchard, hexagonal hillside, garden rooms and valley. Valley and Mountain use relative local elevation. Explicit artist-authored mesh-channel requirements remain requirements; missing data is explained before adding layers.',
  '**Update selected** writes a new revision, Save Copy creates a new recipe identity, and Edit details changes presentation without touching the scene. Keep recipes, recipe-data payloads and Presets package folders together when copying a library. Settings-only recipes need supported assets saved before direct loading.',
  'The static adapter supports standalone meshes, Standard/Blinn materials and static PNG maps. XRefs, arbitrary renderer shaders/proxies, animated dependencies and authored Scatter Edit/per-instance radius codecs remain outside this adapter. Missing or corrupt assets and capacity errors retain the existing planting.'
 ]
 if s['title']=='Surfaces, models and optional containers' and not any(x.startswith('Removing the last model clears') for x in s['paragraphs']):s['paragraphs'].append('Removing the last model clears its scattered output after Update in Manual, or automatically in Live. The empty layer remains valid when Amount changes. Adding a replacement restores planting. Point and intentional Empty gap rows retain their distinct behavior.')
 if s['title']=='Copy and import variation':s['paragraphs']=[x.replace('Paint requires compatible geometry, frame and saved units.','Complete presets transfer supported Paint across units and local-XY footprints; exact settings-only Paint retains compatible geometry/frame/unit requirements.') for x in s['paragraphs']]
 if s['title']=='Final artist acceptance':s['paragraphs']=[x.replace('qualified 0.85.3 Max 2027 MZP','qualified 0.87.0 Max 2027 MZP').replace(', or the companion Windows EXE','') for x in s['paragraphs']]
write(p,d)
p=site/'content/control-explanations.json';d=read(p)
source=(ROOT/'AminScatter/tools/ui/templates/unified-core.ms').read_text()
for c in read(ROOT/'CyrusMCP/cyrus_mcp/feature-catalog.json')['controls']:
 key='.'.join(c[k] for k in ('group','section','name'))
 if key not in d:
  assert c['section']=='distributionUI' and c['help'],key
  match=re.search(r'\b'+re.escape(c['kind'])+r'\s+'+re.escape(c['name'])+r'\s+"([^"]*)"',source)
  assert match,key
  label=match[1] or ('Image preview' if c['name']=='imageThumbnail' else c['name'])
  d[key]={'label':label,'help':c['help'],'evidence':['AminScatter/tools/ui/templates/unified-core.ms:'+str(source[:match.start()].count('\n')+1)]}
d['layer.distributionUI.meshSourceList']={'label':'Field','help':'Choose an authored mesh channel or relative local elevation. Elevation uses 0 at the lowest referenced vertex and 1 at the highest; flat terrain is 0.','evidence':['AminScatter/tools/ui/templates/unified-core.ms:4878']}
for key,value in [('meshCheck',('Use surface density','Enable the independent channel or relative-elevation field.')),('coordinatesList',('Coordinates','Map coordinates uses the texture graph’s own receiver UV/data channels. Other modes project a sampled image.'))]:
 d['layer.distributionUI.'+key].update(label=value[0],help=value[1])
write(p,d)
p=site/'content/source-manifest.json';d=read(p);d['reviewed']='2026-10-19'
# Keep the concept-poster gallery's independently recorded workflow version.
for name in ('docs/ARTIST_GUIDE.md','docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md','docs/Release_Versioning.md'):
 if name in d['reviewedSourceHashes']:d['reviewedSourceHashes'][name]=hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
write(p,d)
print('Updated current public chapter/control sources. No deployment performed.')
