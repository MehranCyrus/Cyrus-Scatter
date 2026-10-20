"""Reauthor disposable copies of bundled examples; run only inside an owned Max 2027 host."""
from pathlib import Path
import hashlib,json,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('density0862-reliability-')
command=json.loads((OUT/'author-library-command.json').read_text())
library=Path(command['library']).resolve();assert library.is_relative_to(ROOT/'build/reliability-0870-20261019')
inventory=json.loads((library/'inventory.json').read_text());entry=next(e for e in inventory['entries'] if e['id']==command['id'])
log={'id':entry['id'],'phase':command['phase'],'status':'running'};receipt=OUT/('author-'+entry['id']+'-'+command['phase']+'.json')
def save():receipt.write_text(json.dumps(log,indent=2)+'\n')
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.CyrusPointSuspended=True
  if command['phase']=='open':
   for name in ('CyrusRecipeBrowser','CyrusRecipeSaveEditor','CyrusRecipeLoadEditor','CyrusReadyPresetEditor'):
    dialog=getattr(r,name)
    if dialog is not None:r.destroyDialog(dialog)
   assert r.loadMaxFile(str(library/entry['scene']),quiet=True,useFileUnits=True)
  elif command['phase']=='capture':
   assert not r.theHold.Holding()
   root=next(n.baseObject for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject')
   original=library/entry['recipe'];info=r.cyrusRecipeInfo(str(original))
   metadata={'category':str(info[4]),'tags':list(info[5]),'description':str(info[6])}
   if entry['id']=='valley':
    names=['Valley moss','Rocky crests','Low valley flowers']
    for i,owner in enumerate(root.logicalLayers()):
     owner.meshMaskSource=2;owner.meshMaskEnabled=True;owner.meshMaskInvert=i!=1
     root.layerNames[int(r.findItem(root.layerObjects,owner))-1]=names[i]
    metadata.update(tags=['relative elevation','density','slope','normals'],description='Receiver-relative local height separates low-valley moss and flowers from rocky crests. Fits the selected terrain without requiring an authored mesh channel. Flat terrain receives the low-valley planting.')
   if entry['id']=='mountain':
    for owner in root.logicalLayers():
     owner.altitudeEnabled=False;owner.meshMaskSource=2;owner.meshMaskEnabled=True;owner.meshMaskInvert=False
     owner.meshMaskMinimum=0.;owner.meshMaskMaximum=1.;owner.meshMaskSamples=r.Array(1.,1.,1.,1.,.5,0.);owner.meshMaskGraph=''
    metadata.update(tags=['slope','relative elevation','normals'],description='Soft slope eligibility reduces planting on cliffs. Receiver-relative local elevation fades trees and groundcover near the summit, independent of world height and system units. Tree trunks stay upright.')
   root.refreshAll();assert all(str(x.previewError)=='' for x in root.layerObjects)
   bindings=r.Array();document=r.CyrusRecipeCapture(root,root.logicalLayers(),entry['name'],bindingResult=bindings)
   thumbnail=str(r.cyrusRecipeThumbnail(str(original)))
   if entry['id'] in ('valley','mountain'):
    cameras=[n for n in r.objects if str(r.superClassOf(n))=='camera']
    # Max's camera superclass spelling is exposed as a MAXClass, not a Python class.
    if not cameras:cameras=[n for n in r.objects if r.superClassOf(n)==r.Camera]
    assert cameras,'The maintained example needs its authored overview camera'
    r.execute('global DemoRoot,DemoCamera,DemoImagePath')
    r.DemoRoot=root;r.DemoCamera=next((n for n in cameras if str(n.name)=='Camera | Preset overview'),cameras[0])
    r.DemoImagePath=str(OUT/('thumbnail-'+entry['id']+'.png'))
    before=str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows));nodes=list(r.objects)
    r.fileIn(str(ROOT/'tools/reliability_0870/render_example.ms'))
    assert nodes==list(r.objects) and str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows))==before
    thumbnail=str(r.DemoImagePath)
   metadataValue=r.CyrusRecipeObject(r.Array(*[r.Array(k,r.Array(*v) if isinstance(v,list) else v) for k,v in metadata.items()]))
   digest=str(r.cyrusRecipeEntryWrite(str(original),document,metadataValue,thumbnail,None,str(info[10]),False))
   stage=r.CyrusAssetOwnStage()
   try:
    graph,files=r.CyrusAssetCapture(root,str(original),digest,bindings,stage[0],includeContext=True)
    assert not len(r.CyrusRecipeGet(graph,'externalRoles'))
    directory=Path(str(r.CyrusPresetPackageDirectory(str(original),digest)));directory.parent.mkdir(parents=True,exist_ok=True)
    job=r.cyrusAssetPackageStart(str(directory),str(original),digest,graph,files,'Original Cyrus procedural demonstration assets; redistribution permitted.',1)
    deadline=time.monotonic()+45
    while True:
     state=r.cyrusAssetPackagePoll(job)
     if str(state[0])!='exporting':break
     assert time.monotonic()<deadline,'Observe package worker before any retry'
     time.sleep(.05)
    assert str(state[0])=='complete',str(state)
    r.cyrusAssetPackageRead(str(directory))
   finally:r.CyrusAssetRemoveStage(stage)
   assert r.saveMaxFile(str(library/entry['scene']),quiet=True)
   log.update(package=str(directory),recipe_sha256=digest,counts=[len(x) for x in root.groupSnapshotRows],
    nodes=len(r.CyrusRecipeGet(graph,'nodes')),splines=len(r.CyrusRecipeGet(graph,'splines')),
    source_script_sha256=hashlib.sha256((OUT/'scripts/CyrusScatter.ms').read_bytes()).hexdigest())
  else:raise ValueError(command['phase'])
  log['status']='passed';save()
except Exception:log.update(status='failed',error=traceback.format_exc());save();raise
