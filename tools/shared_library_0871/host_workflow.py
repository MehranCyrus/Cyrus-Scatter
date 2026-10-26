"""Owned Max workflow: import OBJ models, save ten looks, load in fresh scenes."""
from pathlib import Path
import hashlib,json,math,os,struct,time,traceback,zlib
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.GardenRun))
DATA=Path(str(r.CyrusSharedLibraryRootOverride)).parent
checks=[]
def check(value,message):
    checks.append(message)
    if not value:raise AssertionError(message)
def settle(seconds=.05):
    until=time.monotonic()+seconds
    while time.monotonic()<until:
        r.windows.processPostedMessages();r.execute('(dotNetClass "System.Windows.Forms.Application").DoEvents()');time.sleep(.005)
def wait(predicate,timeout=120):
    until=time.monotonic()+timeout
    while time.monotonic()<until:
        if predicate():return
        settle()
    raise AssertionError('Host operation timeout')
def png(path,index):
    def chunk(tag,payload):return struct.pack('>I',len(payload))+tag+payload+struct.pack('>I',zlib.crc32(tag+payload)&0xffffffff)
    rgb=bytes((30+index*25,80+index*17,40+index*23))
    raw=b''.join(b'\0'+rgb*4 for _ in range(4))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',4,4,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
def obj(path,kind):
    # Owned external fixtures with explicit UVs. The tree exceeds the old 100k cap.
    rings,sides=(350,300) if kind==0 else ((12,8) if kind==1 else (16,12))
    with path.open('w') as f:
        f.write('o ImportedPlant\n')
        for y in range(rings):
            t=y/(rings-1);radius=(4+26*math.sin(math.pi*t)**2 if kind==0 else 2+3*math.sin(math.pi*t))
            for x in range(sides):
                angle=x/sides*math.tau;f.write(f'v {radius*math.cos(angle):.7f} {radius*math.sin(angle):.7f} {t*(320 if kind==0 else 25):.7f}\n')
        for y in range(rings):
            for x in range(sides):f.write(f'vt {x/(sides-1):.8f} {y/(rings-1):.8f}\n')
        for y in range(rings-1):
            for x in range(sides):
                a=y*sides+x+1;b=y*sides+(x+1)%sides+1;c=a+sides;d=b+sides
                f.write(f'f {a}/{a} {b}/{b} {c}/{c}\nf {b}/{b} {d}/{d} {c}/{c}\n')
def physical(path):
    stat=path.stat();return stat.st_dev,stat.st_ino
def texture_paths(root):
    result=[]
    for owner in root.layerObjects:
        for node in owner.validSources():
            material=node.material
            for name in ('diffuseMap','opacityMap'):
                bitmap=r.getProperty(material,r.Name(name))
                if bitmap is not None:result.append(str(bitmap.filename))
    return result

def render_witness(material,path):
    witness=r.box(name='Owned material witness',width=70,length=70,height=30,mapCoords=True,material=material)
    target=r.targetObject(pos=r.Point3(0,0,15));camera=r.targetCamera(pos=r.Point3(120,-160,130),target=target,fov=35)
    lights=[r.omniLight(pos=r.Point3(-80,-110,150),multiplier=1.1),r.omniLight(pos=r.Point3(100,60,120),multiplier=.6)]
    r.renderers.current=r.Default_Scanline_Renderer();r.renderWidth=192;r.renderHeight=128;r.backgroundColor=r.color(32,38,44);r.ambientLight=r.color(35,35,35)
    frame=r.render(camera=camera,outputFile=str(path),vfb=False);r.close(frame)
    for node in [witness,camera,target,*lights]:
        if r.isValidNode(node):r.delete(node)
    check(path.exists(),'scoped Standard material render exists: '+path.name)
def reset_scene():
    r.resetMaxFile(r.Name('noPrompt'))
    if bool(r.GardenSupportedOCIO):r.execute('ColorPipelineMgr.Mode=#OCIO_Default')

def main():
    (OUT/'progress.json').write_text(json.dumps({'phase':'importing external models'}))
    reset_scene();r.units.SystemType=r.Name('Centimeters');r.units.SystemScale=1
    r.CyrusSharedLibraryInstance=None;r.CyrusPFResume=False
    year=int(r.maxVersion()[0])//1000+1998
    check(str(r.CyrusLibraryVersion())=='0.87.1','matching script version')
    check(int(r.cyrusSharedLibraryVersion())==1,'matching shared native API')
    check(Path(str(r.CyrusRecipeScriptDirectory)).joinpath('CyrusGallery.dll').exists(),'gallery beside matching script')
    external=DATA/'external';external.mkdir(parents=True,exist_ok=False)
    for i in range(6):png(external/f'image{i}.png',i)
    jpeg=r.bitmap(4,4,color=r.color(80,114,86),filename=str(external/'image2.jpg'));check(bool(r.save(jpeg)),'create owned JPEG texture input');r.close(jpeg)
    sources=[]
    for i in range(3):
        path=external/f'plant{i}.obj';obj(path,i)
        before={int(r.getHandleByAnim(n)) for n in r.objects}
        r.importFile(str(path),r.Name('noPrompt'))
        added=[n for n in r.objects if int(r.getHandleByAnim(n)) not in before]
        check(len(added)==1,f'OBJ importer creates one model {i}')
        node=added[0];r.convertToMesh(node);node.name=['Imported Tree','Imported Grass','Imported Flower'][i]
        node.pos=r.Point3(1000+i*100,0,0)
        material=r.standardMaterial(name=f'Material {i}',diffuse=r.color(80,150,50))
        material.diffuseMap=r.bitmapTexture(filename=str(external/('image2.jpg' if i==1 else f'image{i*2}.png')))
        material.opacityMap=r.bitmapTexture(filename=str(external/f'image{i*2+1}.png'))
        node.material=material;node.renderable=False;r.hide(node);sources.append(node)
    check(int(sources[0].mesh.numverts)>100000,'imported tree exceeds legacy mesh limit')
    render_witness(sources[0].material,OUT/'material-original.png')
    receiver=r.plane(name='Shared library receiver',width=500,length=500,widthsegs=1,lengthsegs=1)
    scatter=r.AminScatterObject(name='Shared library author');root=scatter.baseObject;root.updateMode=1;root.viewportMode=1;root.autoRender=False
    for i,source in enumerate(sources):
        root.newLayer();owner=root.layerObjects[i];root.layerNames[i]=['Trees','Grass','Flowers'][i]
        check(bool(owner.addModelSource(source)),f'add imported source {i}')
        root.setLayerSurfaces(owner,r.Array(receiver));owner.amount=3+i;owner.autoRender=False
    root.refreshAll();r.CyrusPointSync();settle(.2)
    epoch=int(root.procEpoch);store=r.CyrusSharedStore();paths=[];durations=[];expected_amounts={};retained=0;catalog=0
    metadata=r.CyrusRecipeObject(r.Array(r.Array('category','Ten Looks'),r.Array('tags',r.Array('owned','shared')),r.Array('description','Owned cross-scene library qualification')))
    # The MCP source-consumer lease deliberately admits only 1-3 mesh nodes.
    # Use two source layers + one receiver; never weaken that consumer's bound.
    binding_fixture=r.Array();data_fixture=r.CyrusRecipeCapture(root,r.Array(*list(root.layerObjects)[:2]),'Retained source fixture',bindingResult=binding_fixture)
    fixture=r.CyrusSharedBeginSave(root,data_fixture,metadata,'',None,'','',True,binding_fixture);wait(lambda:str(r.CyrusSharedPollSave(fixture))!='working',180)
    check(str(fixture.state)=='complete','bounded retained-consumer package saves')
    prepared=r.cyrusAssetPackagePrepare(str(Path(str(fixture.result)).parent),str(store.BitmapDirectory));wait(lambda:str(r.cyrusAssetPackagePoll(prepared)[0])!='preparing')
    # Max 2024 PyMXS may round a high-bit Integer64 lease when passing it back.
    # Keep the actual lease in MAXScript, as the real scripted consumer does.
    r.execute('global GardenRetainedPackage;global GardenPreparedPackage');r.GardenPreparedPackage=prepared
    r.execute('GardenRetainedPackage=cyrusAssetPackageRetain GardenPreparedPackage');r.cyrusAssetPackageRelease(prepared)
    for look in range(10):
        (OUT/'progress.json').write_text(json.dumps({'phase':'saving looks','look':look+1}))
        for i,owner in enumerate(root.layerObjects):owner.amount=3+i+look;owner.randomSeed=100+look
        bindings=r.Array();data=r.CyrusRecipeCapture(root,r.Array(*list(root.layerObjects)),f'Look {look+1}',bindingResult=bindings)
        started=time.perf_counter();job=r.CyrusSharedBeginSave(root,data,metadata,'',None,'','',True,bindings)
        wait(lambda:str(r.CyrusSharedPollSave(job))!='working',180)
        check(str(job.state)=='complete',f'complete save {look+1}: {job.error}')
        paths.append(str(job.result));durations.append(time.perf_counter()-started)
        expected_amounts[str(job.digest)]=[3+i+look for i in range(3)]
        if look==0:
            catalog=r.cyrusRecipeCatalogOpen(str(store.Root))
            prepared=r.cyrusAssetPackagePrepare(str(Path(str(job.result)).parent),str(store.BitmapDirectory))
            wait(lambda:str(r.cyrusAssetPackagePoll(prepared)[0])!='preparing')
            check(str(r.cyrusAssetPackagePoll(prepared)[0])=='ready','prepare first look for independent retained consumer')
            rejected=False
            try:r.cyrusAssetPackageRetain(prepared)
            except RuntimeError:rejected=True
            check(rejected,'four-node planting package does not bypass retained source-consumer admission')
            r.cyrusAssetPackageRelease(prepared)
        elif look==1:
            check(str(r.execute('cyrusAssetPackagePoll GardenRetainedPackage')[0])=='ready','retained package survives another native export')
            check(r.execute('cyrusAssetPackagePrepared GardenRetainedPackage false') is not None,'retained metadata remains available')
        check(int(root.procEpoch)==epoch,f'save {look+1} retains pending Manual publication')
    models=list(store.Models());check(len(models)==3,'three reusable model definitions')
    r.execute('cyrusAssetPackageRelease GardenRetainedPackage')
    check(r.cyrusRecipeCatalogPage(catalog,'','',1) is not None,'independent MCP catalog survives gallery saves')
    r.cyrusRecipeCatalogClose(catalog)
    packages=Path(str(store.Root))/'packs/user'
    meshes={physical(p) for p in packages.glob('*/assets/*.cmesh')};images={physical(p) for p in packages.glob('*/assets/*') if p.suffix in ('.png','.jpg','.jpeg')}
    check(len(meshes)==4,'ten looks share three meshes plus one receiver mesh')
    check(len(images)==6,'ten looks share six image payloads')
    for image in Path(str(store.BitmapDirectory)).iterdir():
        check(physical(image)==physical(Path(str(store.Root))/'objects'/image.stem[:64]),'stable image path shares its immutable object')
    ids=[str(store.RecipeId(p)) for p in paths]
    operation=store.AddToCollectionFromJson('Ten looks',json.dumps(ids),'[]');wait(lambda:bool(operation.Terminal),180)
    check(str(operation.State)=='complete','collection membership complete: '+str(operation.Error))
    archive=DATA/'ten.cyruslib';operation=store.Export('Ten looks',str(archive));wait(lambda:bool(operation.Terminal),180)
    check(str(operation.State)=='complete','export complete: '+str(operation.Error))
    r.saveMaxFile(str(OUT/'author.max'),quiet=True)
    reset_scene();sources.clear();root=None;scatter=None;source=None;node=None;material=None;bindings=None;data=None;r.gc()
    r.freeSceneBitmaps();os.rename(external,DATA/'external-unavailable')
    check(not external.exists(),'original imported models/textures unavailable')
    # Recipient store is independently usable and retains no author-root dependency.
    author_root=str(store.Root);r.CyrusSharedLibraryInstance=None;r.CyrusSharedLibraryRootOverride=str(DATA/'recipient');recipient=r.CyrusSharedStore()
    operation=recipient.Import(str(archive));wait(lambda:bool(operation.Terminal),180)
    check(str(operation.State)=='complete','recipient import complete: '+str(operation.Error))
    recipient_objects=set(p.name for p in (Path(str(recipient.Root))/'objects').iterdir())
    operation=recipient.Import(str(archive));wait(lambda:bool(operation.Terminal),180)
    check(str(operation.State)=='complete','repeat recipient import complete')
    check(recipient_objects==set(p.name for p in (Path(str(recipient.Root))/'objects').iterdir()),'repeat import adds zero objects')
    archive.rename(DATA/'transport-unavailable.cyruslib')
    recipient_paths=sorted(Path(str(p)) for p in recipient.RecipePaths())
    check(len(recipient_paths)==10,'recipient has ten look roots')
    results=[]
    for index,path in enumerate(recipient_paths):
        (OUT/'progress.json').write_text(json.dumps({'phase':'loading separate recipient scenes','look':index+1}))
        reset_scene();target=r.plane(name='Fresh recipient surface',width=500,length=500,widthsegs=1,lengthsegs=1)
        r.select(target);digest=str(r.cyrusRecipeInfo(str(path))[10]);directory=str(r.CyrusPresetPackageDirectory(str(path),digest))
        r.CyrusOpenReadyPreset(None,directory,expected=digest,surface=target)
        wait(lambda:bool(r.CyrusReadyPresetEditor.finished),180)
        editor=r.CyrusReadyPresetEditor
        check(editor.result is not None,'load on fresh scene: '+str(editor.status.text))
        loaded=editor.result[0];r.destroyDialog(editor)
        check(len(list(loaded.layerObjects))==3,f'look {index} creates three ordered layers')
        check([int(layer.amount) for layer in loaded.layerObjects]==expected_amounts[digest],f'look {index} restores its own exact Count settings')
        check([str(name) for name in loaded.layerNames]==['Trees','Grass','Flowers'],f'look {index} preserves authored layer order')
        filenames=texture_paths(loaded);check(len(filenames)==6,f'look {index} restores all image map uses')
        check(all(Path(p).exists() and str(Path(p)).lower().startswith(str(recipient.Root).lower()) for p in filenames),f'look {index} uses only recipient stable textures')
        scene=OUT/f'recipient-{index}.max';r.saveMaxFile(str(scene),quiet=True)
        results.append({'path':str(path),'scene':str(scene),'layers':[str(x) for x in loaded.layerNames],'epoch':int(loaded.procEpoch),'textures':filenames})
        if index==0:
            imported_material=loaded.layerObjects[0].validSources()[0].material
            reset_scene();render_witness(imported_material,OUT/'material-imported.png');imported_material=None
            check(bool(r.compareBitmaps(str(OUT/'material-original.png'),str(OUT/'material-imported.png'),0,0,useAlpha=True)),'original/imported Standard material render pixels match exactly')
    # Exercise saved-scene reopening after both external inputs and archive disappeared.
    reset_scene();r.loadMaxFile(results[0]['scene'],quiet=True,useFileUnits=True)
    roots=[n.baseObject for n in r.objects if r.classOf(n.baseObject)==r.AminScatterObject]
    check(len(roots)==1,'saved recipient scene reopens one controller')
    check(all(Path(p).exists() for p in texture_paths(roots[0])),'reopened recipient textures remain available')
    roots[0].refreshAll();r.CyrusPointSync();settle(.2);epoch=int(roots[0].procEpoch);roots[0].layerObjects[0].amount+=17
    r.CyrusOpenRecipeLibrary(roots[0],surface=roots[0].layerObjects[0].validSurfaces()[0]);browser=r.CyrusRecipeBrowser
    browser.panel.SetNavigation(1,'',False);browser.refresh();wait(lambda:not bool(browser.scanTimer.active));browser.showSelected();settle(.2)
    check(int(roots[0].procEpoch)==epoch,'warm browsing leaves pending Manual placement unchanged');r.destroyDialog(browser)
    report={'status':'pass','host':year,'checks':checks,'author_store':author_root,'recipient_store':str(recipient.Root),'mesh_file_id_count':len(meshes),'image_file_id_count':len(images),'save_seconds':durations,'scenes':results}
    (OUT/'workflow.json').write_text(json.dumps(report,indent=2));(OUT/'completed.json').write_text(json.dumps({'status':'pass','checks':len(checks),'host':year}))
try:
    # -U MAXScript wraps Python.ExecuteFile in a startup hold. Close that owned
    # harness hold; suspending Undo would also disable the import's real hold.
    if r.theHold.Holding():r.theHold.Accept('Owned library qualification startup')
    main()
except Exception:(OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
