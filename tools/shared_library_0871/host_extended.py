"""Owned Max shared-model, revision, browser, Undo and relocation checks."""
from pathlib import Path
import hashlib,json,time,traceback,struct,zlib,shutil,zipfile
import pymxs
from pymxs import runtime as r
OUT=Path(str(r.GardenRun));DATA=Path(str(r.CyrusSharedLibraryRootOverride)).parent
ROOT=Path(__file__).resolve().parents[2];checks=[]
def check(v,message):
    checks.append(message)
    if not v:raise AssertionError(message)
def wait(predicate,timeout=180):
    end=time.monotonic()+timeout
    while time.monotonic()<end:
        if predicate():return
        r.windows.processPostedMessages();r.execute('(dotNetClass "System.Windows.Forms.Application").DoEvents()');time.sleep(.01)
    raise AssertionError('operation timeout')
def operation(op):
    wait(lambda:bool(op.Terminal));check(str(op.State)=='complete','file operation: '+str(op.Error));return str(op.Result)
def all_images():
    return list(r.getClassInstances(r.Bitmaptexture,target=r.rootNode))
def pngs():
    return {p.stem[:64] for p in (DATA/'author'/'resolved').glob('*.png')}
def meshes():
    return {p.stem for base in (DATA/'author'/'packs'/'user',DATA/'author'/'models') for p in base.glob('*/assets/*.cmesh')}
def save_models(node):
    r.select(node);job=r.CyrusSharedSaveModels();wait(lambda:str(r.CyrusSharedPollSave(job))!='working')
    check(str(job.state)=='complete','model-only save: '+str(job.error))
    if r.CyrusSharedProgressEditor is not None:r.destroyDialog(r.CyrusSharedProgressEditor)
    return job
def import_model(model,owner=None,root=None):
    r.CyrusSharedImportModel(model,owner=owner,root=root);wait(lambda:bool(r.CyrusSharedModelImportEditor.finished));return r.CyrusSharedModelImportEditor

def reset_scene():
    r.resetMaxFile(r.Name('noPrompt'))
    if bool(r.GardenSupportedOCIO):r.execute('ColorPipelineMgr.Mode=#OCIO_Default')

def main():
    store=r.CyrusSharedStore();archive=Path(str(r.GardenLibraryArchive))
    operation(store.Import(str(archive)));check(len(list(store.Models()))==3,'three imported personal models')
    tree=next(m for m in store.Models() if 'Tree' in str(m.Name));tree_revision=str(tree.Revision)
    reset_scene()
    r.execute('undo "Owned prior box" on (global SharedPriorBox=box name:"Owned prior box")')
    check(not r.theHold.Holding(),'normal UI transaction state before model import')
    editor=import_model(tree);check(editor.modelResult is not None,'personal model native import: '+str(editor.status.text))
    model=editor.modelResult;model_name=str(model.name);r.destroyDialog(editor)
    check(int(model.mesh.numverts)>100000,'native model import restores the large tree')
    check(len(list(r.objects))==2,'model import creates exactly one scene node')
    r.execute('max undo');check(r.getNodeByName(model_name) is None and r.getNodeByName('Owned prior box') is not None,'Undo removes import and preserves earlier history')
    r.execute('max redo');model=r.getNodeByName(model_name);check(model is not None,'Redo restores imported model')
    r.execute('max undo');r.execute('max undo');check(r.getNodeByName('Owned prior box') is None,'earlier meaningful Undo remains reachable')
    r.execute('max redo');r.execute('max redo');model=r.getNodeByName(model_name)
    # Fault after native node staging must cancel only this authored transaction.
    before=len(list(r.objects));r.execute('global SharedOriginalStage=CyrusAssetStage;fn CyrusAssetStage package bindings createdNodes:undefined=(local result=SharedOriginalStage package bindings createdNodes:createdNodes;throw "Owned injected post-stage failure")')
    try:
        editor=import_model(tree);check(editor.modelResult is None,'post-stage failure is rejected');check(len(list(r.objects))==before,'post-stage failure removes owned nodes');r.destroyDialog(editor)
    finally:r.execute('CyrusAssetStage=SharedOriginalStage')
    original_meshes=meshes();original_images=pngs();recipe_count=len(list(store.RecipePaths()))
    save_models(model)
    check(len(list(store.RecipePaths()))==recipe_count,'Save Model creates no recipe card')
    check(len(list(store.Models()))==3,'import/re-save reuses canonical model definitions')
    check(str(next(m for m in store.Models() if str(m.Id)==str(tree.Id)).Revision)==tree_revision,'canonical tree identity survives native roundtrip')
    check(not any((DATA/'author'/'objects'/sha).stat().st_size>1048576 for sha in meshes()-original_meshes),'model-only roundtrip creates no new large geometry allocation')
    check(pngs()==original_images,'model-only roundtrip adds no image bytes')
    baseline_meshes=meshes();baseline_images=pngs();model.material.diffuse=r.color(12,90,180);save_models(model)
    check(len(list(store.Models()))==4,'tint creates a distinct model/material definition')
    check(meshes()==baseline_meshes and pngs()==baseline_images,'tint reuses geometry and image payloads')
    image=model.material.diffuseMap.bitmap;gamma_input=DATA/'authored-gamma.png';shutil.copyfile(str(model.material.diffuseMap.filename),gamma_input)
    model.material.diffuseMap.bitmap=r.cyrusAssetOpenStaticImage(str(gamma_input),str(image.colorSpace),1.0)
    save_models(model);check(len(list(store.Models()))==5,'explicit gamma creates a separate faithful definition')
    check(meshes()==baseline_meshes and pngs()==baseline_images,'gamma interpretation shares the same raw image and mesh')
    def chunk(tag,payload):return struct.pack('>I',len(payload))+tag+payload+struct.pack('>I',zlib.crc32(tag+payload)&0xffffffff)
    changed=DATA/'changed.png';raw=b''.join(b'\0'+bytes((200,35,160))*4 for _ in range(4));changed.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',4,4,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
    model.material.diffuseMap.filename=str(changed);save_models(model)
    check(len(pngs()-baseline_images)==1,'changing one image creates exactly one new encoded image object')
    check(meshes()==baseline_meshes,'image revision reuses all geometry payloads')
    # A copied scene material stays independent from immutable library definitions.
    model.pos=r.Point3(0,0,0);save_models(model)
    check(len(list(store.Models()))==6,'world translation does not create a new model definition')
    model_ids={str(m.Id) for m in store.Models()}
    old_vertex=r.getVert(model,1);r.setVert(model,1,old_vertex+r.Point3(.15,0,0));r.update(model);save_models(model)
    latest=next(m for m in store.Models() if str(m.Id) not in model_ids)
    check(len(meshes()-baseline_meshes)==1,'geometry edit creates exactly one new mesh object')
    check(len(list(store.Models()))==7,'geometry edit creates a successor model definition')
    check(all(Path(str(p)).exists() for p in store.RecipePaths()),'older recipes retain their pinned packages after model edits')
    # Browse the same model with every supported layout scale. No scene solve.
    target=r.plane(name='Browser receiver',width=500,length=500)
    r.CyrusOpenRecipeLibrary(None,surface=target);browser=r.CyrusRecipeBrowser
    browser.panel.SetNavigation(4,'',False);browser.refresh();wait(lambda:not bool(browser.scanTimer.active))
    check(int(browser.panel.Gallery.ItemCount)==7,'personal models provider displays current cards')
    for scale in (1.0,1.5,2.0):
        browser.panel.UserScale=scale;browser.panel.SetNavigation(4,'',False);browser.refresh();wait(lambda:not bool(browser.scanTimer.active));check(int(browser.panel.Gallery.ItemCount)==7,f'model cards remain usable at {scale} scale')
        bitmap=r.dotNetObject('System.Drawing.Bitmap',int(browser.panel.Width),int(browser.panel.Height));rectangle=r.dotNetObject('System.Drawing.Rectangle',0,0,int(browser.panel.Width),int(browser.panel.Height))
        browser.panel.DrawToBitmap(bitmap,rectangle);bitmap.Save(str(OUT/f'models-{int(scale*100)}.png'));bitmap.Dispose()
    browser.panel.SetNavigation(1,'@:Ten looks',False);browser.refresh()
    wait(lambda:str(r.cyrusRecipeLibraryPage(browser.scan,'','',1)[0])!='scanning')
    browser.showPage();check(int(browser.panel.Gallery.ItemCount)==10,'shared collection displays all ten saved looks')
    r.destroyDialog(browser)
    # Relocation retains old paths; an explicit scene-copy relink changes only filenames.
    reset_scene();editor=import_model(latest);check(editor.modelResult is not None,'reimport edited model through stable library paths');model=editor.modelResult;r.destroyDialog(editor)
    check(abs(float(model.material.diffuseMap.bitmap.gamma)-1.0)<.001,'model import restores the authored numeric gamma')
    old_paths=[str(m.filename) for m in all_images()];old_gamma=[float(m.bitmap.gamma) for m in all_images()]
    destination=DATA/'moved';operation(store.Relocate(str(destination)))
    check(all(Path(p).exists() for p in old_paths),'relocation retains old scene paths')
    r.CyrusSharedLibraryInstance=None;r.CyrusSharedLibraryRootOverride=str(destination);moved=r.CyrusSharedStore()
    check(len(list(moved.Models()))==7,'relocated catalog retains all model revisions')
    scene=OUT/'relinked.max';r.CyrusSharedRelinkScene(path=str(scene));wait(lambda:bool(r.CyrusSharedRelinkEditor.finished))
    editor=r.CyrusSharedRelinkEditor;check(bool(editor.applied),'explicit scene-copy relink: '+str(editor.status.text));check(scene.exists(),'relinked scene copy saved');r.destroyDialog(editor)
    check(all(str(m.filename).lower().startswith(str(destination).lower()) for m in all_images()),'relink uses the new shared root')
    check([float(m.bitmap.gamma) for m in all_images()]==old_gamma,'relink preserves image gamma interpretation')
    r.execute('max undo');check([str(m.filename) for m in all_images()]==old_paths,'relink Undo restores exact original paths')
    r.execute('max redo');check(all(str(m.filename).lower().startswith(str(destination).lower()) for m in all_images()),'relink Redo restores new paths')
    reset_scene();r.loadMaxFile(str(scene),quiet=True,useFileUnits=True)
    check(all(Path(str(m.filename)).exists() and str(m.filename).lower().startswith(str(destination).lower()) for m in all_images()),'relinked scene copy reopens with complete images')
    # Source-route ownership and Undo must be exercised through the real UI helper.
    reset_scene();controller=r.AminScatterObject(name='Owned model target');root=controller.baseObject;root.updateMode=1;root.autoRender=False
    receiver=r.plane(width=500,length=500);root.newLayer();owner=root.layerObjects[0];root.setLayerSurfaces(owner,r.Array(receiver));owner.amount=3
    epoch=int(root.procEpoch);editor=import_model(tree,owner,root)
    check(editor.modelResult is not None,'add personal model to an existing layer: '+str(editor.status.text));added=editor.modelResult;added_name=str(added.name);r.destroyDialog(editor)
    check(len(list(owner.validSources()))==1 and bool(added.isHidden),'added source is hidden and bound to the captured layer')
    check(int(root.procEpoch)==epoch,'adding a source leaves Manual placement pending')
    r.execute('max undo');check(r.getNodeByName(added_name) is None and len(list(owner.validSources()))==0,'layer import Undo removes its source and binding')
    r.execute('max redo');check(r.getNodeByName(added_name) is not None and len(list(owner.validSources()))==1,'layer import Redo restores the same source binding')
    before=len(list(r.objects));r.CyrusSharedImportModel(tree,owner=owner,root=root);r.delete(controller)
    wait(lambda:bool(r.CyrusSharedModelImportEditor.finished));editor=r.CyrusSharedModelImportEditor
    check(editor.modelResult is None and len(list(r.objects))==before-1,'deleted captured owner rejects pending model import without a stray node');r.destroyDialog(editor)
    # A tree-only transport must not include its former recipe's grass/flowers.
    operation(moved.AddToCollectionFromJson('Only tree','[]',json.dumps([str(tree.Id)])))
    only=DATA/'only-tree.cyruslib';operation(moved.Export('Only tree',str(only)))
    with zipfile.ZipFile(only) as archive_file:
        manifest=json.loads(archive_file.read('library.json'))
        check(len(manifest['packages'])==0 and len(manifest['modelPackages'])==1,'model-only archive contains one standalone package and no recipe')
    r.CyrusSharedLibraryInstance=None;r.CyrusSharedLibraryRootOverride=str(DATA/'model-recipient');recipient=r.CyrusSharedStore();operation(recipient.Import(str(only)))
    check(len(list(recipient.Models()))==1 and len(list(recipient.RecipePaths()))==0,'clean recipient imports exactly one model card')
    reset_scene();editor=import_model(list(recipient.Models())[0]);check(editor.modelResult is not None,'standalone archive imports its model in a fresh scene');model=editor.modelResult;r.destroyDialog(editor)
    # Equal shader definitions preserve scene reference topology, separately from bytes.
    model.material.opacityMap=r.copy(model.material.diffuseMap);save_models(model)
    variants=list(recipient.Models());distinct=next(m for m in variants if str(m.Id)!=str(tree.Id))
    editor=import_model(distinct);pair=editor.modelResult;check(pair is not None,'distinct map fixture imports');r.destroyDialog(editor)
    r.execute('global SharedAliasPair');r.SharedAliasPair=pair
    check(bool(r.execute('SharedAliasPair.material.diffuseMap != SharedAliasPair.material.opacityMap')),'equal distinct maps remain separate scene shader objects')
    pair.material.opacityMap=pair.material.diffuseMap;known={str(m.Id) for m in recipient.Models()};save_models(pair)
    instanced=next(m for m in recipient.Models() if str(m.Id) not in known)
    editor=import_model(instanced);check(editor.modelResult is not None,'instanced map fixture imports');r.SharedAliasPair=editor.modelResult;r.destroyDialog(editor)
    check(bool(r.execute('SharedAliasPair.material.diffuseMap == SharedAliasPair.material.opacityMap')),'instanced maps retain one shared scene shader object')
    (OUT/'extended.json').write_text(json.dumps({'status':'pass','checks':checks,'host':int(r.maxVersion()[0])//1000+1998},indent=2))
    (OUT/'completed.json').write_text(json.dumps({'status':'pass','checks':len(checks)}))
try:
    if r.theHold.Holding():r.theHold.Accept('Owned extended qualification startup')
    main()
except Exception:(OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
