"""Create two original procedural recipe examples; never overwrite the frozen six."""
from pathlib import Path
import hashlib,json,math,sys,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
command=json.loads((OUT/'command.json').read_text(encoding='utf-8'));slug=command['demo']
specs={
 'formal':('Four garden rooms','Formal gardens',['grid','paint','paths','gravel'],'Four painted beds contain regular topiary rows and soft flower edges. The gravel layer fills the intervening paths. Uses grids and Paint, not direct spline path placement.'),
 'valley':('Valley moss and rocky crests','Terrain',['mesh channel','density','slope','normals'],'A numeric R/X field in terrain channel 2 separates valley moss from rocky crests. The moss uses a density curve and slope fade. This authored numeric field illustrates mesh-channel control; it is not an automatic curvature calculation.')}
title,category,tags,description=specs[slug]
folder=OUT/'gallery-examples'/(slug+command.get('suffix',''));folder.mkdir(parents=True,exist_ok=False)
report={'status':'running','demo':slug,'title':title,'checks':[]}
def save():(folder/'receipt.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
def check(value,message):report['checks'].append({'passed':bool(value),'assertion':message});save();assert value,message
def material(name,color):return r.standardMaterial(name=name,diffuse=r.color(*color),specularLevel=8,glossiness=12)
def layer(name,models,count,normal=True):
 root.newLayer();leaf=root.selectedLayer();root.layerNames[len(root.layerObjects)-1]=name
 root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(*models);leaf.ensureSourceRows()
 leaf.amount=count;leaf.randomSeed=8510+len(root.layerObjects)*29;leaf.procPopulation=1
 leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
 leaf.sourceRadiiWU=r.Array(*[.1 for _ in models]);leaf.sourceAutoRadius=r.Array(*[False for _ in models]);leaf.sourceFollowScale=r.Array(*[True for _ in models]);leaf.sourceColors=r.Array(*[n.wirecolor for n in models])
 leaf.wholeScaleMin=.75;leaf.wholeScaleMax=1.25;leaf.yawMinimum=0;leaf.yawMaximum=360;leaf.alignNormal=normal;leaf.projectMove=True
 return leaf
def rectangle(x0,y0,x1,y1):return [(x0,y0,0),(x1,y0,0),(x1,y1,0),(x0,y1,0)]
def coverage(leaf,contours,fade):
 area=root.addPaintArea(leaf,target=terrain);area.paintSetName='Saved planting footprint';area.paintView=0
 shape=r.SplineShape(name='Paint input | '+str(root.layerNames[len(root.layerObjects)-1]))
 for i,points in enumerate(contours,1):
  r.addNewSpline(shape)
  for point in points:r.addKnot(shape,i,r.Name('corner'),r.Name('line'),r.Point3(*point))
  r.close(shape,i)
 r.updateShape(shape);shape.renderable=False;root.importPaintSpline(area,shape,tolerance=.001)
 r.cyrusBrushSetFalloff(area.paintDocument,r.Array(fade,0,fade>0,fade>0,.3,1.,r.Array(0.,.15,.65,1.),r.Array(0.,.3,.8,1.)));area.publishPaint()
 r.hide(shape)
 return area
try:
 with pymxs.undo(False):
  for name in ('CyrusRecipeBrowser','CyrusRecipeSaveEditor','CyrusRecipeLoadEditor','CyrusAssetImportEditor'):
   dialog=getattr(r,name)
   if dialog is not None:r.destroyDialog(dialog)
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('meters');r.units.SystemScale=1
  r.execute('global DemoNode,DemoRoot,DemoCamera,DemoImagePath')
  r.DemoNode=r.AminScatterObject(name='CYRUS EXAMPLE | '+title);root=r.DemoNode.baseObject;r.DemoRoot=root;root.updateMode=1;root.autoRender=False
  terrain=r.plane(name='Terrain | '+title,width=24,length=20,widthsegs=56,lengthsegs=48)
  terrain.material=material('Earth',(117,105,78));terrain.wirecolor=r.color(117,105,78)
  if slug=='valley':
   r.convertToMesh(terrain)
   for i in range(1,int(terrain.numverts)+1):
    point=r.getVert(terrain,i);point.z=3.2*math.exp(-(((point.x-3)/3.5)**2+((point.y+1)/5.5)**2))+1.8*math.exp(-(((point.x+5)/3.2)**2+((point.y-3)/3.5)**2));r.setVert(terrain,i,point)
   r.meshop.setNumMaps(terrain,3,keep=True);r.meshop.setMapSupport(terrain,2,True);r.meshop.setNumMapVerts(terrain,2,int(terrain.numverts));r.meshop.setNumMapFaces(terrain,2,int(terrain.numfaces))
   for i in range(1,int(terrain.numverts)+1):
    point=r.getVert(terrain,i);r.meshop.setMapVert(terrain,2,i,r.Point3(max(0.,min(1.,1-point.z/2.9)),0,0))
   for i in range(1,int(terrain.numfaces)+1):r.meshop.setMapFace(terrain,2,i,r.getFace(terrain,i))
   r.update(terrain)
  tree=r.geosphere(name='Model | Clipped topiary',radius=.58,segs=2,pos=r.Point3(35,0,.58));tree.material=material('Topiary green',(39,93,46));tree.wirecolor=r.color(39,93,46)
  flower=r.pyramid(name='Model | Warm flower',width=.19,depth=.19,height=.42,pos=r.Point3(38,0,0));flower.material=material('Flower',(214,169,74));flower.wirecolor=r.color(214,169,74)
  moss=r.pyramid(name='Model | Moss',width=.28,depth=.28,height=.21,pos=r.Point3(41,0,0));moss.material=material('Moss',(83,136,57));moss.wirecolor=r.color(83,136,57)
  pebble=r.geosphere(name='Model | Pebble',radius=.16,segs=1,pos=r.Point3(44,0,0));pebble.scale=r.Point3(1.3,1.,.55);pebble.material=material('Pale stone',(164,159,145));pebble.wirecolor=r.color(164,159,145)
  if slug=='formal':
   beds=[rectangle(x0,y0,x1,y1) for x0,x1 in [(-9,-2),(2,9)] for y0,y1 in [(-7,-2),(2,7)]]
   topiary=layer('Topiary lattice in four beds',[tree],100,False);topiary.placementMode=2;topiary.gridColumnWU=2.;topiary.gridRowWU=2.;topiary.gridOriginXWU=0.;topiary.gridOriginYWU=0.;topiary.gridJitter=0.;topiary.wholeScaleMin=1.;topiary.wholeScaleMax=1.;coverage(topiary,beds,0.)
   flowers=layer('Soft flower edges',[flower,moss],2600);coverage(flowers,beds,.6)
   stones=layer('Gravel paths and perimeter',[pebble],4400);coverage(stones,[rectangle(-11,-9,11,9)]+[list(reversed(points)) for points in beds],.12)
  else:
   ground=layer('Valley moss - mesh channel R',[moss],4400);ground.meshMaskEnabled=True;ground.meshMaskChannel=2;ground.meshMaskComponent=1;ground.meshMaskSamples=r.Array(0.,.1,.65,1.);ground.slopeEnabled=True;ground.slopeMinimum=0.;ground.slopeMaximum=38.;ground.slopeUpperFade=15.
   rocks=layer('Rocky crests - inverted mask',[pebble],2100);rocks.meshMaskEnabled=True;rocks.meshMaskChannel=2;rocks.meshMaskComponent=1;rocks.meshMaskInvert=True;rocks.wholeScaleMin=1.2;rocks.wholeScaleMax=2.6
   flowers=layer('Low valley flowers',[flower],550);flowers.meshMaskEnabled=True;flowers.meshMaskChannel=2;flowers.meshMaskComponent=1;flowers.meshMaskSamples=r.Array(0.,0.,.2,1.);flowers.orientationBlend=45.
  root.setGroupDisplay(3);root.refreshAll();r.CyrusPointSync()
  check(all(len(rows)>0 for rows in root.groupSnapshotRows),'All three layers publish')
  report['counts']=[len(rows) for rows in root.groupSnapshotRows];report['rows']=[fingerprint(rows) for rows in root.groupSnapshotRows]
  r.DemoCamera=r.targetCamera(name='Camera | Preset overview',pos=r.Point3(25,-32,32),target=r.targetObject(pos=r.Point3(0,0,1)))
  r.DemoCamera.fov=46;r.viewport.setLayout(r.Name('layout_1'));r.viewport.setCamera(r.DemoCamera)
  for source in [tree,flower,moss,pebble]:r.hide(source)
  r.CyrusPerfHeadless=False;r.clearSelection();r.completeRedraw()
  scene=folder/(slug+'.max');check(r.saveMaxFile(str(scene),quiet=True),'Editable scene saves before capture')
  r.CyrusOpenRecipeSave(root,str(folder));dialog=r.CyrusRecipeSaveEditor
  dialog.recipeName.text=title;dialog.recipeCategory.text=category;dialog.recipeTags.text=', '.join(tags);dialog.recipeDescription.text=description
  dialog.capturePreview(False);manifest=Path(str(dialog.saveEntry(False)));dialog.closeButton.pressed()
  thumbnail=Path(str(r.cyrusRecipeThumbnail(str(manifest))));check(thumbnail.is_file(),'Actual viewport capture is attached to format-5 recipe')
  expected=r.CyrusRecipeCapture(root,root.logicalLayers(),title)
  check(str(r.cyrusRecipeContentFingerprint(expected))==str(r.cyrusRecipeContentFingerprint(r.cyrusRecipeRead(str(manifest)))),'Complete saved settings and Paint match')
  report.update(recipe=str(manifest),scene=str(scene),thumbnail=str(thumbnail),files={str(path.relative_to(folder)):hashlib.sha256(path.read_bytes()).hexdigest() for path in folder.rglob('*') if path.is_file() and path.name!='receipt.json'},status='passed');save()
except Exception:report['status']='failed';report['error']=traceback.format_exc();save();raise
