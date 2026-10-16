"""Create redistributable procedural examples in an owned Max 2027 profile.

Each scene is saved before temporary exact-placement render geometry is created.
No artist assets, textures or installed-profile files are read or changed.
"""
from pathlib import Path
import json,math,hashlib,sys,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
assert json.loads((OUT/'launch.json').read_text())['max_year']==2027
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
specs={
 'orchard':('Rectangular orchard','Orchards',['grid','rectangular','trees','groundcover'],'World-aligned rectangular tree rows with independent groundcover. Change column and row pitch without moving the lattice origin. Replace the pyramids with your tree models.'),
 'hexagonal':('Hexagonal hillside planting','Gardens',['grid','hexagonal','normals','terrain'],'Even nearest-neighbor planting on a gentle hill, with low underplanting. The hexagonal row pitch is calculated from its spacing; normal blending follows the surface.')}

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
  terrain=r.plane(name='Terrain | '+title,width=20,length=20,widthsegs=40,lengthsegs=40)
  terrain.material=material('Terrain - warm earth',(114,126,91));terrain.wirecolor=r.color(114,126,91)
  if slug=='hexagonal':
   r.convertToMesh(terrain)
   for i in range(1,int(terrain.numverts)+1):
    p=r.getVert(terrain,i);p.z=1.8*math.exp(-((p.x/5.2)**2+(p.y/5.3)**2));r.setVert(terrain,i,p)
   r.update(terrain)
  grass=source('Model | Groundcover',.24,.35,(91,151,58),0)
  shrub=source('Model | Shrub',.65,.8,(52,115,56),1)
  tree=source('Model | Tree',1.1,2.7,(37,88,48),2)
  flower=source('Model | Flower',.21,.55,(215,175,94),3)
  if slug=='orchard':
   planted=layer('Orchard - regular rows',[tree],100,False)
   planted.placementMode=2;planted.gridColumnWU=3.;planted.gridRowWU=4.
   planted.gridOriginXWU=0.;planted.gridOriginYWU=0.;planted.gridHeading=0.;planted.gridJitter=0.
   planted.wholeScaleMin=.9;planted.wholeScaleMax=1.1;planted.scaleMinimum=1.;planted.scaleMaximum=1.
   layer('Low groundcover',[grass],2200)
  else:
   planted=layer('Hexagonal shrubs',[shrub,flower],100)
   planted.placementMode=4;planted.gridColumnWU=1.4;planted.gridJitter=0.;planted.orientationBlend=70.
   planted.wholeScaleMin=.9;planted.wholeScaleMax=1.1;planted.scaleMinimum=1.;planted.scaleMaximum=1.
   layer('Low groundcover',[grass],1800)
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
