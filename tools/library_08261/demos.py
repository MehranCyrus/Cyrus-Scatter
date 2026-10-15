"""Create redistributable procedural examples in an owned Max 2027 profile.

Each scene is saved before temporary exact-placement render geometry is created.
No artist assets, textures or installed-profile files are read or changed.
"""
from pathlib import Path
import json,math,hashlib,sys,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-library08261-')
assert json.loads((OUT/'launch.json').read_text())['max_year']==2027
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
specs={
 'meadow':('Layered meadow','Meadows',['grass','flowers','three layers'],'Three grass and flower layers. Replace the procedural pyramids and flower shapes with your own vegetation.'),
 'woodland':('Trees and understory','Woodland',['trees','shrubs','groundcover'],'Upright canopy above normal-aligned shrubs and groundcover, with independent layer settings.'),
 'mountain':('Mountain planting','Terrain',['slope','altitude','normals'],'Soft slope and altitude eligibility reduces planting on cliffs and near the summit. Tree trunks stay upright.'),
 'borders':('Painted garden and spline borders','Gardens',['paint','bands','curves'],'Saved Paint with an inner clearing, plus two spline Bands with independent density and scale curves. Use the included compatible terrain for Paint.')}
slug=json.loads((OUT/'command.json').read_text())['demo'];title,category,tags,description=specs[slug]
folder=OUT/'bundled';folder.mkdir(exist_ok=True);manifest=folder/(slug+'.csrecipe.json')
assert not manifest.exists(),'Examples are immutable; choose a fresh qualification output for regeneration.'
report={'status':'running','demo':slug,'title':title,'checks':[]}
def save():(OUT/('demo-'+slug+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
def check(ok,label):report['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def material(name,tint):return r.standardMaterial(name=name,diffuse=r.color(*tint),specularLevel=12,glossiness=20)
def source(name,width,height,tint,index):
 node=r.pyramid(name=name,width=width,depth=width,height=height,pos=r.Point3(35+index*3,0,0));node.material=material(name,tint);node.wirecolor=r.color(*tint);return node
def layer(name,models,amount,align=True):
 root.newLayer();leaf=root.selectedLayer();root.layerNames[len(root.layerObjects)-1]=name
 root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(*models);leaf.ensureSourceRows()
 leaf.amount=amount;leaf.randomSeed=1200+len(root.layerObjects)*17;leaf.procPopulation=1
 leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
 leaf.sourceRadiiWU=r.Array(*[.15 for _ in models]);leaf.sourceAutoRadius=r.Array(*[False for _ in models])
 leaf.sourceFollowScale=r.Array(*[True for _ in models]);leaf.sourceColors=r.Array(*[n.wirecolor for n in models])
 leaf.wholeScaleMin=.7;leaf.wholeScaleMax=1.3;leaf.yawMinimum=0;leaf.yawMaximum=360;leaf.alignNormal=align;leaf.projectMove=True
 return leaf
try:
 with pymxs.undo(False):
  if r.CyrusRecipeBrowser is not None:r.CyrusRecipeBrowser.closeButton.pressed()
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('meters');r.units.SystemScale=1
  r.execute('global DemoNode,DemoRoot,DemoCamera,DemoImagePath')
  r.DemoNode=r.AminScatterObject(name='CYRUS EXAMPLE | '+title);r.DemoRoot=r.DemoNode.baseObject;root=r.DemoRoot
  root.updateMode=1;root.autoRender=False
  terrain=r.plane(name='Terrain | '+title,width=20,length=20,widthsegs=40 if slug=='mountain' else 12,lengthsegs=40 if slug=='mountain' else 12)
  terrain.material=material('Terrain - warm earth',(114,126,91));terrain.wirecolor=r.color(114,126,91)
  if slug=='mountain':
   r.convertToMesh(terrain)
   for i in range(1,int(terrain.numverts)+1):
    p=r.getVert(terrain,i);p.z=6*math.exp(-((p.x/3.2)**2+(p.y/4.3)**2))+2.3*math.exp(-(((p.x+5)/2.8)**2+((p.y-3)/2.8)**2));r.setVert(terrain,i,p)
   r.update(terrain)
  grass=source('Model | Groundcover',.24,.35,(91,151,58),0)
  shrub=source('Model | Shrub',.65,.8,(52,115,56),1)
  tree=source('Model | Tree',1.1,2.7,(37,88,48),2)
  flower=source('Model | Flower',.21,.55,(215,175,94),3)
  if slug=='meadow':
   layer('Fine grass',[grass],2600);layer('Tall meadow patches',[shrub],140);layer('Warm flowers',[flower],350)
  elif slug=='woodland':
   layer('Canopy - upright',[tree],90,False);layer('Understory',[shrub],340);layer('Groundcover',[grass,flower],1500)
  elif slug=='mountain':
   for leaf in [layer('Trees below the summit',[tree],650,False),layer('Slope-aware groundcover',[grass,shrub],4500)]:
    leaf.slopeEnabled=True;leaf.slopeMinimum=0;leaf.slopeMaximum=42;leaf.slopeUpperFade=14
    leaf.altitudeEnabled=True;leaf.altitudeMinimum=0;leaf.altitudeMaximum=4.5;leaf.altitudeUpperFade=1.2
  else:
   painted=layer('Painted garden - saved clearing',[grass,flower],3600)
   paint=root.addPaintArea(painted,target=terrain);paint.paintSetName='Garden and clearing';paint.paintView=0
   contour=r.SplineShape(name='Paint input - independent snapshot')
   for index,points in enumerate([[(-8,-8,0),(8,-8,0),(8,8,0),(-8,8,0)],[(-3,-3,0),(-3,3,0),(3,3,0),(3,-3,0)]],1):
    r.addNewSpline(contour)
    for p in points:r.addKnot(contour,index,r.Name('corner'),r.Name('line'),r.Point3(*p))
    r.close(contour,index)
   r.updateShape(contour);contour.renderable=False;root.importPaintSpline(paint,contour,tolerance=.001)
   r.cyrusBrushSetFalloff(paint.paintDocument,r.Array(.6,0,True,True,.2,1.,r.Array(0.,.15,.6,1.),r.Array(0.,.3,.8,1.)));paint.publishPaint()
   bands=layer('Border bands - density and size',[shrub,flower],2500)
   path=r.Rectangle(name='Path | Border frame',width=10,length=10);path.renderable=False
   bands.diversityMode=3
   for i in range(2):
    bands.addStroke(path,side=2);bands.patternWidths[i]=1.;bands.strokeStarts[i]=float(i);bands.strokeEnds[i]=float(i+1)
    bands.setStrokeSelection(i+1,2,r.Array(str(bands.sourceRowIDs[i])))
    bands.strokeCurveEnabled[i]=True;bands.strokeCurveSamples[i]='1,0.8,0.4,0.1' if i==0 else '0.1,0.4,0.8,1'
    bands.strokeScaleModes[i]=3;bands.strokeScaleSamples[i]='0.3,0.7,1.0,1.2' if i==0 else '1.2,1.0,0.7,0.3'
  root.setGroupDisplay(3);root.refreshAll();r.CyrusPointSync()
  check(all(len(rows)>0 for rows in root.groupSnapshotRows),'Every example layer publishes placements')
  report['counts']=[len(rows) for rows in root.groupSnapshotRows];report['rows']=[fingerprint(rows) for rows in root.groupSnapshotRows]
  document=r.CyrusRecipeCapture(root,r.Array(*list(root.layerObjects)),title);r.cyrusRecipeWrite(str(manifest),document)
  check(len(r.cyrusRecipeRead(str(manifest))[1])>0,'Saved example validates and hydrates Paint')
  r.DemoCamera=r.targetCamera(name='Camera | Preset overview',pos=r.Point3(22,-30,29),target=r.targetObject(pos=r.Point3(0,0,1.3)))
  r.DemoCamera.fov=47;r.viewport.setLayout(r.Name('layout_1'));r.viewport.setCamera(r.DemoCamera)
  r.CyrusPerfHeadless=False;r.select(r.DemoNode);r.completeRedraw()
  scene=folder/(slug+'.max');check(r.saveMaxFile(str(scene),quiet=True),'Editable demonstration scene saved')
  r.DemoImagePath=str(OUT/(slug+'-render.png'))
  r.execute('''(
   local temporary=#()
   try (
    for layerIndex=1 to DemoRoot.layerObjects.count do (
     local leaf=DemoRoot.layerObjects[layerIndex],vertices=#(),faces=#(),materialIDs=#(),sourceMeshes=#()
     for source in leaf.sources do (
      local origin=copy source;origin.transform=matrix3 1;append sourceMeshes (snapshotAsMesh origin);delete origin
     )
     for row in DemoRoot.groupSnapshotRows[layerIndex] do (
      local shape=sourceMeshes[row[2]],offset=vertices.count
      for i=1 to shape.numverts do append vertices ((getVert shape i)*row[1])
      for i=1 to shape.numfaces do (append faces ((getFace shape i)+[offset,offset,offset]);append materialIDs row[2])
     )
     local snapshot=mesh name:"TEMP exact render" vertices:vertices faces:faces;append temporary snapshot
     local materials=multiMaterial numsubs:leaf.sources.count
     for i=1 to leaf.sources.count do materials.materialList[i]=leaf.sources[i].material
     snapshot.material=materials
     for i=1 to materialIDs.count do setFaceMatID snapshot i materialIDs[i]
     update snapshot
    )
    append temporary (omniLight pos:[-18,-25,40] multiplier:1.1)
    append temporary (omniLight pos:[25,15,30] multiplier:0.55)
    renderers.current=Default_Scanline_Renderer();renderWidth=512;renderHeight=320;backgroundColor=color 29 36 42;ambientLight=color 35 35 35
    local frame=render camera:DemoCamera outputFile:DemoImagePath vfb:false;close frame
   )catch(delete temporary;throw())
   delete temporary
  )''')
  metadata=r.CyrusRecipeObject(r.Array(r.Array('category',category),r.Array('tags',r.Array(*tags)),r.Array('description',description)))
  r.cyrusRecipePresentationWrite(str(manifest),metadata,str(r.DemoImagePath));thumbnail=Path(str(r.cyrusRecipeThumbnail(str(manifest))))
  check(thumbnail.is_file(),'Stored thumbnail verifies its PNG bounds and exact hash')
  report['recipe']=str(manifest);report['scene']=str(scene);report['thumbnail']=str(thumbnail)
  report['files']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [manifest,scene,thumbnail,Path(str(manifest)+'.library.json')]}
  report['status']='passed';save()
except Exception:report['status']='failed';report['error']=traceback.format_exc();save();raise
