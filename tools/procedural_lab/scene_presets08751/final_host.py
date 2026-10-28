"""Fresh exact installed pair: transfer, independent restore and actual rollouts."""
from pathlib import Path
import json,traceback,importlib.util,time
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running','scope':'Fresh final installed Max 2027 pair'}
def roots():return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined]
def helpers():
    spec=importlib.util.spec_from_file_location('scene_helpers',ROOT/'tools/procedural_lab/scene_presets08751/host_workflow.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
try:
    if phase=='final-prepare':
        r.CyrusSharedLibraryRootOverride=str(ROOT/'build/sp51lib02');r.CyrusSharedLibraryInstance=r.undefined
        before=json.loads((ROOT/'build/scene-presets-08751-20261027-01/host-03/metadata-before.json').read_text());store=r.CyrusSharedStore()
        entry=next(str(p) for p in store.RecipePaths() if json.loads(Path(str(p)).read_text(encoding='utf-8-sig'))['id']==before['id'])
        d=json.loads(Path(entry).read_text(encoding='utf-8-sig'));r.SPEntry=entry;r.SPExpected=r.cyrusRecipeInfo(entry)[10]
        r.units.SystemType=r.Name('centimeters');r.units.SystemScale=d['metersPerUnit']*100
        r.SPOperation=store.PrepareScene(entry,str(r.SPExpected));report.update(entry=entry,assets=len(d['assets']))
    elif phase in ('final-merge','final-repeat','final-inspect'):
        if phase!='final-inspect':
            assert r.SPOperation.Terminal and str(r.SPOperation.State)=='complete',str(r.SPOperation.Error)
            r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned final fixture command"')
            count=len(roots());r.SPImported=r.CyrusScenePresetMerge(str(r.SPEntry),str(r.SPExpected),str(r.SPOperation.Result));r.CyrusSharedStore().DiscardSceneLoad(str(r.SPOperation.Result));assert len(roots())==count+1
        m=helpers();expected=json.loads((ROOT/'build/scene-presets-08751-20261027-01/host-03/original-state.json').read_text());got=m.snapshot(r.SPImported.baseObject);(O/'final-current-state.json').write_text(json.dumps(got));report.update(m.compare(expected,got))
        if phase in ('final-merge','final-inspect'):(O/'first-final-state.json').write_text(json.dumps(got))
        else:
            first=json.loads((O/'first-final-state.json').read_text());old={x['output'] for group in first['edits'] for x in group if x['input']!=x['output']};assert not old.intersection(report['clones'])
        report['roots']=len(roots());assert all(not str(x.previewError) for x in r.SPImported.baseObject.layerObjects)
    elif phase=='final-unit-guard':
        assert r.SPOperation.Terminal and str(r.SPOperation.State)=='complete';original=float(r.units.SystemScale);before=len(roots());r.units.SystemScale=original*2;message=''
        try:
            r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned unit fixture"')
            r.CyrusScenePresetMerge(str(r.SPEntry),str(r.SPExpected),str(r.SPOperation.Result))
        except Exception as e:message=str(e)
        finally:r.units.SystemScale=original
        assert 'system units' in message and len(roots())==before;report.update(error=message,scene_retained=True)
    elif phase=='final-prepare-repeat':r.SPOperation=r.CyrusSharedStore().PrepareScene(str(r.SPEntry),str(r.SPExpected))
    elif phase=='final-ui':
        r.CyrusOpenRecipeSave(r.SPImported.baseObject,r.CyrusRecipeDirectory());e=r.CyrusRecipeSaveEditor;assert int(e.saveKind.selection)==1 and not e.saveLayers.enabled
        assert list(map(str,e.saveKind.items))==['Scene preset','Portable preset','Settings only'];report['save_choices']=list(map(str,e.saveKind.items))
        r.CyrusOpenScenePreset(str(r.SPEntry),str(r.SPExpected));assert str(r.CyrusScenePresetLoadEditor.notice.text)=='Adds a new setup. Clears Max Undo history.';report['merge_notice']=str(r.CyrusScenePresetLoadEditor.notice.text)
    elif phase=='final-save-ui':
        r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned final rollout frame";global SPSavedUIPath=CyrusRecipeSaveEditor.saveEntry false')
        report['path']=str(r.SPSavedUIPath)
    elif phase=='final-poll-ui':
        job=r.CyrusSharedProgressData;assert str(r.CyrusSharedPollSave(job))=='complete',str(job.error);report['path']=str(job.result);assert Path(report['path']).is_file()
    report['status']='passed'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(O/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
