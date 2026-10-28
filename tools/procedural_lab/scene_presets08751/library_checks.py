"""Owned data/store and unchanged portable workflow checks; no artist profile."""
from pathlib import Path
import json,traceback,hashlib
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running'}
def roots():return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined]
def load_entry():return Path(str(r.SPEntry)),json.loads(Path(str(r.SPEntry)).read_text(encoding='utf-8-sig'))
try:
    if phase=='metadata-start':
        entry,d=load_entry();r.execute('global SPStore=CyrusSharedStore();global SPTicket=SPStore.BeginSave SPEntry SPExpected "entry.csrecipe.json";global SPMeta=SPStore.ReviseSceneDetails SPTicket "Renamed native setup" (cyrusScenePresetEncode (CyrusRecipeObject #(#("category","Native tests"),#("tags",#("scene")),#("description","Revised details"))))')
        report['scene_hash']=d['scene']['sha256'];(O/'metadata-before.json').write_text(json.dumps(d))
    elif phase=='metadata-poll':
        assert r.SPMeta.Terminal and str(r.SPMeta.State)=='complete',str(r.SPMeta.Error);r.SPEntry=str(r.SPMeta.Result);r.SPExpected=r.cyrusRecipeInfo(str(r.SPEntry))[10]
        entry,d=load_entry();before=json.loads((O/'metadata-before.json').read_text());assert d['name']=='Renamed native setup' and d['revision']==before['revision']+1 and d['scene']==before['scene'] and d['assets']==before['assets'];report.update(path=str(entry),revision=d['revision'],same_scene_hash=True)
    elif phase=='export-start':
        r.SPLibOperation=r.CyrusSharedStore().Export('',str(O/'native-scenes.cyruslib'))
    elif phase=='export-poll':
        assert r.SPLibOperation.Terminal and str(r.SPLibOperation.State)=='complete',str(r.SPLibOperation.Error)
        report['archive_bytes']=(O/'native-scenes.cyruslib').stat().st_size
    elif phase=='import-start':
        r.SPTransferStore=r.dotNetObject('Cyrus.Content.SharedLibrary',str(ROOT/'build/sp51lib02'));r.SPImportOperation=r.SPTransferStore.Import(str(O/'native-scenes.cyruslib'))
    elif phase=='import-poll':
        assert r.SPImportOperation.Terminal and str(r.SPImportOperation.State)=='complete',str(r.SPImportOperation.Error)
        paths=list(map(str,r.SPTransferStore.RecipePaths()));report['entries']=len(paths);assert len(paths)>=2
        expected=json.loads(Path(str(r.SPEntry)).read_text(encoding='utf-8-sig'))['id']
        entry=next(p for p in paths if json.loads(Path(p).read_text(encoding='utf-8-sig'))['id']==expected)
        d=json.loads(Path(entry).read_text(encoding='utf-8-sig'));assert (Path(entry).parent/'scene.max').is_file()
        for a in d['assets']:assert (Path(entry).parent/a['payload']['file']).is_file()
        report['scene_assets']=len(d['assets'])
    elif phase=='missing-start':
        entry,d=load_entry();own=next(a['payload']['file'] for a in d['assets'] if a['payload']['sha256']=='431ced6916a2a21a156e38701afe55bbd7f88969fbbfc56d7fe099d47f265460')
        file=entry.parent/own;assert file.resolve().is_relative_to((ROOT/'build/sp51lib01').resolve());file.rename(file.with_suffix('.unavailable'));r.SPMissingFile=str(file);r.SPMissingCount=len(roots());r.SPLibOperation=r.CyrusSharedStore().PrepareScene(str(entry),str(r.SPExpected))
    elif phase=='missing-poll':
        assert r.SPLibOperation.Terminal and str(r.SPLibOperation.State)=='failed';file=Path(str(r.SPMissingFile));file.with_suffix('.unavailable').rename(file);assert len(roots())==int(r.SPMissingCount);report.update(error=str(r.SPLibOperation.Error),original_scene_retained=True)
    elif phase=='cancel-start':
        r.SPLibOperation=r.CyrusSharedStore().PrepareScene(str(r.SPEntry),str(r.SPExpected));r.CyrusSharedStore().CancelSceneLoad(r.SPLibOperation)
    elif phase=='cancel-poll':
        assert r.SPLibOperation.Terminal
        if str(r.SPLibOperation.State)=='complete':assert not Path(str(r.SPLibOperation.Result)).exists()
        else:assert str(r.SPLibOperation.State)=='cancelled',str(r.SPLibOperation.Error)
        report['state']=str(r.SPLibOperation.State)
    elif phase=='portable':
        # A static fixture fits the existing portable contract; large native
        # preparation envelopes are tested through scene presets instead.
        r.execute('global SPStaticSurface=plane width:100 length:100 name:"Portable fixture surface";global SPStaticModel=box width:1 length:1 height:2 name:"Portable fixture model";global SPStaticOwner=AminScatterObject name:"Portable fixture Scatter";global SPPortableRoot=SPStaticOwner.baseObject;SPPortableRoot.newLayer();SPPortableRoot.layerObjects[1].surfaceNodes=#(SPStaticSurface);SPPortableRoot.layerObjects[1].addModelSource SPStaticModel;SPPortableRoot.layerObjects[1].amount=3;SPPortableRoot.refreshAll();global SPPortableBindings=#();global SPPortableDoc=CyrusRecipeCapture SPPortableRoot (SPPortableRoot.logicalLayers()) "Unchanged portable workflow" bindingResult:SPPortableBindings')
        r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned portable fixture frame";global SPPortableResult=CyrusRecipeImport undefined SPPortableDoc SPPortableBindings newSetup:true calculate:true variation:#same')
        report.update(recipe_version=int(r.cyrusRecipeVersion()),layers=len(r.SPPortableResult[0].layerObjects));assert report['recipe_version']==9
    report['status']='passed'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(O/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')

