"""Scoped actual Corona adapter, complete recipe and standalone-model roundtrip."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
OUT=Path(str(r.GardenRun));DATA=Path(str(r.CyrusSharedLibraryRootOverride)).parent;checks=[]
def check(value,message):
    if not value:raise AssertionError(message)
    checks.append(message)
def wait(predicate):
    until=time.monotonic()+180
    while time.monotonic()<until:
        if predicate():return
        r.windows.processPostedMessages();r.execute('(dotNetClass "System.Windows.Forms.Application").DoEvents()');time.sleep(.01)
    raise AssertionError('operation timeout')
def operation(job):
    wait(lambda:bool(job.Terminal));check(str(job.State)=='complete','file operation: '+str(job.Error))
def save_model(node):
    r.select(node);job=r.CyrusSharedSaveModels();wait(lambda:str(r.CyrusSharedPollSave(job))!='working');check(str(job.state)=='complete','renderer model save: '+str(job.error));r.destroyDialog(r.CyrusSharedProgressEditor)
def main():
    check(bool(r.CyrusAssetCheckRenderer()),'exact registered Corona profile accepted');store=r.CyrusSharedStore();operation(store.Import(str(r.GardenLibraryArchive)))
    tree=next(m for m in store.Models() if 'Tree' in str(m.Name));r.resetMaxFile(r.Name('noPrompt'));r.CyrusSharedImportModel(tree);wait(lambda:bool(r.CyrusSharedModelImportEditor.finished));editor=r.CyrusSharedModelImportEditor;check(editor.modelResult is not None,'source tree imported');source=editor.modelResult;r.destroyDialog(editor)
    material=r.CoronaPhysicalMtl(name='Owned shared Corona',baseColor=r.color(40,130,25),baseRoughness=.71);material.baseTexmap=source.material.diffuseMap;material.baseTexmapOn=True;source.material=material
    before={p.name for p in (DATA/'author/objects').iterdir() if p.stat().st_size>1048576};save_model(source)
    check(before=={p.name for p in (DATA/'author/objects').iterdir() if p.stat().st_size>1048576},'renderer-only revision reuses existing large mesh allocations')
    corona=next(m for m in store.Models() if str(m.Id)!=str(tree.Id) and 'Tree' in str(m.Name));check(len(list(store.Models()))==4,'renderer adds exactly one model definition')
    receiver=r.plane(width=500,length=500);scatter=r.AminScatterObject();root=scatter.baseObject;root.updateMode=1;root.autoRender=False;root.newLayer();owner=root.layerObjects[0];owner.addModelSource(source);root.setLayerSurfaces(owner,r.Array(receiver));owner.amount=3
    bindings=r.Array();recipe=r.CyrusRecipeCapture(root,r.Array(owner),'Owned Corona look',bindingResult=bindings);metadata=r.CyrusRecipeObject(r.Array(r.Array('category','Corona fixture'),r.Array('tags',r.Array('owned','renderer')),r.Array('description','Owned renderer adapter qualification')))
    job=r.CyrusSharedBeginSave(root,recipe,metadata,'',None,'','',True,bindings);wait(lambda:str(r.CyrusSharedPollSave(job))!='working');check(str(job.state)=='complete','complete renderer recipe saves: '+str(job.error));path=str(job.result)
    operation(store.AddToCollectionFromJson('Corona look',json.dumps([str(store.RecipeId(path))]),'[]'));archive=DATA/'corona.cyruslib';operation(store.Export('Corona look',str(archive)))
    r.resetMaxFile(r.Name('noPrompt'));r.CyrusSharedLibraryInstance=None;r.CyrusSharedLibraryRootOverride=str(DATA/'recipient');recipient=r.CyrusSharedStore();operation(recipient.Import(str(archive)));archive.rename(DATA/'archive-unavailable.cyruslib')
    entry=str(list(recipient.RecipePaths())[0]);digest=str(r.cyrusRecipeInfo(entry)[10]);target=r.plane(width=500,length=500);r.CyrusOpenReadyPreset(None,str(r.CyrusPresetPackageDirectory(entry,digest)),expected=digest,surface=target);wait(lambda:bool(r.CyrusReadyPresetEditor.finished));editor=r.CyrusReadyPresetEditor
    check(editor.result is not None,'renderer recipe loads without transport archive: '+str(editor.status.text));loaded=editor.result[0];r.destroyDialog(editor);plant=loaded.layerObjects[0].validSources()[0]
    check(r.classOf(plant.material)==r.CoronaPhysicalMtl and abs(float(plant.material.baseRoughness)-.71)<.00001,'renderer class and authored material value restored')
    check(Path(str(plant.material.baseTexmap.filename)).is_file() and str(plant.material.baseTexmap.filename).lower().startswith(str(recipient.Root).lower()),'renderer bitmap uses recipient-owned verified image')
    r.CyrusSharedImportModel(list(recipient.Models())[0]);wait(lambda:bool(r.CyrusSharedModelImportEditor.finished));model_editor=r.CyrusSharedModelImportEditor
    check(model_editor.modelResult is not None and r.classOf(model_editor.modelResult.material)==r.CoronaPhysicalMtl,'standalone renderer model package imports through its own native reader: '+str(model_editor.status.text));standalone=model_editor.modelResult;r.destroyDialog(model_editor);save_model(standalone);check(len(list(recipient.Models()))==1,'renderer model native roundtrip reuses its canonical definition')
    witness=r.box(width=70,length=70,height=30,mapCoords=True,material=plant.material);camera=r.targetCamera(pos=r.Point3(120,-160,130),target=r.targetObject(pos=r.Point3(0,0,15)));r.omniLight(pos=r.Point3(-80,-110,150),multiplier=1.2)
    r.renderers.current=r.Corona();r.renderers.current.system_numThreads=4;r.renderers.current.progressive_passLimit=2;r.renderers.current.progressive_timeLimit=0;r.renderWidth=192;r.renderHeight=128;r.renderers.current.renderstamp_use=False
    image=r.render(camera=camera,outputFile=str(OUT/'corona-imported.png'),vfb=False);check(image is not None and (OUT/'corona-imported.png').exists(),'actual two-pass Corona render completes with imported material');r.close(image)
    scene=OUT/'corona-recipient.max';r.saveMaxFile(str(scene),quiet=True);r.resetMaxFile(r.Name('noPrompt'));r.loadMaxFile(str(scene),quiet=True,useFileUnits=True);check(any(r.classOf(m)==r.CoronaPhysicalMtl for m in r.sceneMaterials),'saved recipient scene reopens with Corona materials')
    (OUT/'renderer.json').write_text(json.dumps(dict(status='pass',checks=checks,profile=str(r.CyrusAssetAdapterProfile())),indent=2));(OUT/'completed.json').write_text(json.dumps(dict(status='pass',checks=len(checks))))
try:
    if r.theHold.Holding():r.theHold.Accept('Owned renderer startup')
    main()
except Exception:(OUT/'error.txt').write_text(traceback.format_exc())
