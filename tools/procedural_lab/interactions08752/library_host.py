"""Preserve the preceding Library delivery: save/restore an independent prepared setup."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running','scope':'Owned Max 2027 Scene preset regression, standard merge clears Undo'}
def roots():return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined]
def snapshot(root):
    return {'rows':[[[[[float(m[i][j]) for j in range(3)] for i in range(4)] for m in group] for group in r.cyrusPlacementTransformGroups(rows)] for rows in root.groupSnapshotRows],
            'preparation':[list(map(str,x.interactionDefinitions)) for x in root.layerObjects],
            'owners':[str(x.layerID) for x in root.layerObjects],
            'sources':[[str(s) for s in x.procSourceIDs] for x in root.layerObjects]}
try:
    if phase=='library-save':
        r.CyrusSharedLibraryRootOverride=str(ROOT/'build/ia52lib');r.CyrusSharedLibraryInstance=r.undefined
        asset_root=ROOT/'Test Scene/Organized Models/Plants/Outdoor/Outdoor_Plants_01'
        r.mapPaths.add(str(asset_root));r.mapPaths.add(str(asset_root/'maps'))
        # Missing renderer shaders in this stdplugs-only profile are unrelated
        # to serialization. Use supported materials on just this owned setup.
        for n in r.CyrusScenePresetNodes(r.WFRoot):n.material=r.standardMaterial()
        r.WFRoot.refreshAll();r.CyrusPointSync();r.windows.processPostedMessages()
        (out/'library-original.json').write_text(json.dumps(snapshot(r.WFRoot)))
        r.execute('global AuditPresetJob,AuditPresetEntry,AuditPresetExpected,AuditPresetLoad,AuditPresetImported;for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned audit save frame";AuditPresetJob=CyrusScenePresetSave WFRoot "Audit prepared grass" (CyrusRecipeObject #(#("category","Audit"),#("tags",#()),#("description","0.87.5.2 regression"))) ""')
    elif phase=='library-poll':
        state=str(r.CyrusSharedPollSave(r.AuditPresetJob));assert state=='complete',(state,str(r.AuditPresetJob.error))
        r.AuditPresetEntry=str(r.AuditPresetJob.result);r.AuditPresetExpected=r.cyrusRecipeInfo(r.AuditPresetEntry)[10]
        metadata=json.loads(Path(str(r.AuditPresetEntry)).read_text(encoding='utf-8-sig'));assert metadata['scatterVersion']=='0.87.5.2'
        assert snapshot(r.WFRoot)==json.loads((out/'library-original.json').read_text())
        r.AuditPresetLoad=r.CyrusSharedStore().PrepareScene(str(r.AuditPresetEntry),str(r.AuditPresetExpected));report['metadata']=metadata
    elif phase=='library-merge':
        assert r.AuditPresetLoad.Terminal and str(r.AuditPresetLoad.State)=='complete',str(r.AuditPresetLoad.Error)
        before=len(roots());original=json.loads((out/'library-original.json').read_text())
        r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned audit merge frame"')
        r.AuditPresetImported=r.CyrusScenePresetMerge(str(r.AuditPresetEntry),str(r.AuditPresetExpected),str(r.AuditPresetLoad.Result))
        r.CyrusSharedStore().DiscardSceneLoad(str(r.AuditPresetLoad.Result));r.CyrusPointSync();r.windows.processPostedMessages()
        got=snapshot(r.AuditPresetImported.baseObject);assert len(roots())==before+1
        assert got['rows']==original['rows'] and got['preparation']==original['preparation']
        assert not set(got['owners']).intersection(original['owners'])
        assert not {s for g in got['sources'] for s in g}.intersection(s for g in original['sources'] for s in g)
        assert snapshot(r.WFRoot)==original and not str(r.AuditPresetImported.baseObject.interactionError)
        report.update(independent_import=True,placements_preserved=True,preparation_preserved=True,original_retained=True)
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(out/(phase+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
