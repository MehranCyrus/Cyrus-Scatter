from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];site=ROOT/'website'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=site/'content/guide-chapters.json';d=read(p)
for section in d['artist-guide']['sections']:
 for i,text in enumerate(section.get('paragraphs',[])):
  text=text.replace('Vector painting supports planes and terrain single-valued in receiver-local XY, including transformed receivers. Closed, vertical, folded and overlapping projected receivers are rejected. General scattering on curved receivers is a separate supported workflow.','Vector painting supports terrain, spheres, boxes, vertical sides and manifold curved meshes. Curved strokes follow surface distance across connected edges without painting through to the opposite side or disconnected sheets. Degenerate faces and nonmanifold connections require repair.')
  text=text.replace('Paint requires single-valued local-XY terrain; folded, closed or stacked projections reject before import.','Terrain Paint presets transfer between single-valued local-XY footprints. Curved Paint presets require matching indexed topology; arbitrary remeshing does not preserve face correspondence.')
  text=text.replace('qualified 0.87.0 Max 2027 MZP','qualified 0.86.6 Max 2027 MZP or Windows EXE')
  text=text.replace("Export uses the receiver's local XY plane", "For terrain, export uses the receiver's local XY plane")
  text=text.replace('A shape is limited to 8,192 input knots and 8,192 sampled vertices.','An edited shape is limited to 8,192 input knots and 8,192 sampled vertices; unchanged guarded surface snapshots use the canonical contour budget.')
  section['paragraphs'][i]=text
 if section['title']=='Vector painting':section['paragraphs'].append('Curved Paint retains Paint/Erase, Fill/Clear, independent density and scale fade curves, Undo/Redo and saved scenes. Curved mesh distance includes nonuniform receiver scaling. Surface coverage uses vector face regions with bounded work: up to 100,000 triangles and 200,000 vertices, with separate contour and solver limits. Terrain keeps its existing projected vector behavior.')
 if section['title']=='Paint and spline snapshots':section['paragraphs'].append('Curved receivers export a 3D surface border. An unchanged exported snapshot restores exact coverage, including holes and large regions. Edited closed curves must lie on the receiver within Curve tolerance and select the smaller enclosed region on a closed component. A fully filled closed object has no border to export. The generic 8,192-knot import limit applies to edited curves; exact guarded snapshots use the native contour limit.')
write(p,d)
p=site/'content/control-explanations.json';d=read(p);tips=read(ROOT/'AminScatter/tools/ui/control-tooltips.json')
for key,entry in d.items():
 entry['help']=entry.get('help','').replace('supported single-valued local-XY terrain','supported terrain or manifold curved geometry')
 for name in ('exportSpline','importSpline'):
  if key.endswith('.'+name):entry['help']=tips['brushUI'][name]
write(p,d)
p=site/'content/changelog.json';d=read(p);d['reviewed']='2026-10-19'
for entry in d['entries']:
 if entry['version']=='0.87.0':
  entry['version']='0.86.5';entry['note']='User-corrected reliability baseline. Original build receipts labeled 0.87.0 retain their actual labels and hashes. The complete feature set is included in 0.86.6.'
d['entries'].insert(0,{'version':'0.86.6','date':'2026-10-19','title':'Surface painting restored','era':'recent','legacy':False,'note':'Max 2027 development delivery with matched MZP and shareable Windows EXE; scoped native and host qualification.','changes':[{'kind':'Fixed','text':'Paint on spheres, boxes, vertical sides and manifold curved receivers again, with surface-following strokes and opposite-side isolation.'},{'kind':'Improved','text':'Retains vector borders, Paint/Erase, Fill/Clear, fade curves, independent copies, Undo/Redo and scene persistence. Curved borders export as 3D spline snapshots.'},{'kind':'Improved','text':'Includes all corrected 0.86.5 library, Amount, receiver-map and lifecycle fixes. Installer and visible release labels consistently use 0.86.6.'}],'evidence':['docs/plans/preset-gallery-improvements/DELIVERY_0866.md']})
write(p,d)
p=site/'content/source-manifest.json';d=read(p)
for name in d.get('reviewedSourceHashes',{}):
 if name in ('docs/ARTIST_GUIDE.md','docs/Release_Versioning.md','docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md'):d['reviewedSourceHashes'][name]=hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
write(p,d)
print('Updated public sources; local import/build still required. Nothing published.')
