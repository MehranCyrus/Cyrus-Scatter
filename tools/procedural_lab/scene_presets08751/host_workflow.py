"""Scoped scene-preset workflow in an explicitly owned, installed Max 2027."""
from pathlib import Path
import json,time,traceback,hashlib
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running','scope':'Owned Max 2027; standard merge, no Undo claim'}
def roots():return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined]
def matrix(m):return [[float(m[i][j]) for j in range(3)] for i in range(4)]
def rows(root):return [[[matrix(m) for m in group] for group in r.cyrusPlacementTransformGroups(row)] for row in root.groupSnapshotRows]
def snapshot(root):
    lineage_slots=[str(s) for owner in root.layerObjects for s in owner.procSourceIDs]
    return {'owners':[str(x.layerID) for x in root.layerObjects],
            'sources':[[str(s) for s in x.procSourceIDs] for x in root.layerObjects],
            'layers':[str(x) for x in root.layerNames], 'rows':rows(root),
            'radii':[{'ids':list(map(str,x.procRadiusIDs)),'modes':list(x.procRadiusModes),'values':list(x.procRadiusValues),'distances':list(x.procRadiusDistances)} for x in root.layerObjects],
            'edits':[[{'key':int(x[0]),'input':str(x[3]),'output':str(x[4]),'deleted':bool(x[8]),'order':int(x[9]),'source_slot':lineage_slots.index(str(x[2])) if str(x[2]) in lineage_slots else -1,'delta':matrix(x[10]),'final':None if x[12]==r.undefined else matrix(x[12])} for x in r.cyrusEditInspect(m,0,500)[3]] for m in root.procModifiers()],
            'preparation':[list(map(str,x.interactionDefinitions)) for x in root.layerObjects]}
def compare(a,b):
    assert a['layers']==b['layers'];assert a['preparation']==b['preparation']
    for x,y in zip(a.get('radii',[]),b.get('radii',[])):
        assert len(x['ids'])==len(y['ids']);assert x['modes']==y['modes'] and x['values']==y['values'] and x['distances']==y['distances']
    assert not set(a['owners']).intersection(b['owners'])
    assert not {s for group in a['sources'] for s in group}.intersection(s for group in b['sources'] for s in group)
    # Max node/float reconstruction has the same physical coordinates.
    def flat(value):
        if isinstance(value,list):return [x for child in value for x in flat(child)]
        return [value]
    assert [list(map(len,g)) for g in a['rows']]==[list(map(len,g)) for g in b['rows']]
    error=max([abs(x-y) for x,y in zip(flat(a['rows']),flat(b['rows']))] or [0]);assert error<.002,error
    assert len(a['edits'])==len(b['edits'])
    clones=[]
    for before,after in zip(a['edits'],b['edits']):
        # Native rebinding may append inactive source history after current rows.
        # The stored order and authored visible transforms must be preserved.
        before=sorted(before,key=lambda x:(x['key'],x['order'],x.get('source_slot',0)))
        after=sorted(after,key=lambda x:(x['key'],x['order'],x.get('source_slot',0)))
        assert len(before)==len(after)
        for x,y in zip(before,after):
            assert (x['key'],x['deleted'],x['order'])==(y['key'],y['deleted'],y['order'])
            if x['input']==x['output']:assert y['input']==y['output']
            if 'delta' in x:assert max(abs(u-v) for u,v in zip(flat(x['delta']),flat(y['delta'])))<.002
            if x['final'] is not None and y['final'] is not None:
                assert max(abs(u-v) for u,v in zip(flat(x['final']),flat(y['final'])))<.002
            if x['input']!=x['output']:assert x['output']!=y['output'];clones.append(y['output'])
    return {'matrix_error_WU':error,'edit_modifiers':len(a['edits']),'clones':clones}
def pump():
    for _ in range(3):r.windows.processPostedMessages();r.completeRedraw();time.sleep(.02)
try:
    if phase in ('setup-grass','setup-fern'):
        model='Grass' if phase.endswith('grass') else 'Fern'
        scene=ROOT/f'dist/CyrusScatter-0.87.5-20261027/TestScenes/{model}_Interaction_0.87.5.max'
        assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        r.execute('global SPOwner,SPRoot,SPJob,SPEntry,SPExpected,SPOperation,SPImported,SPTexture,SPReceiver,SPOriginal;CyrusPointSuspended=true')
        r.SPOwner=roots()[0];r.SPRoot=r.SPOwner.baseObject
        r.SPRoot.updateMode=1;r.SPRoot.layerObjects[0].amount=3;r.SPRoot.viewportFaces=0;r.SPRoot.viewportNavigationFaces=0
        r.SPRoot.refreshAll();r.CyrusPointSuspended=False;r.select(r.SPOwner);pump()
        r.CyrusSharedLibraryRootOverride=str(ROOT/'build/sp51lib01');r.CyrusSharedLibraryInstance=r.undefined
        r.SPOriginal=r.SPRoot.layerObjects[0].validSources()[0]
        # A collected texture whose only original path is owned by this run.
        png=O/'owned-texture.png';png.write_bytes(bytes.fromhex('89504e470d0a1a0a0000000d4948445200000001000000010804000000b51c0c020000000b4944415478da6364f80f00010501012718e3660000000049454e44ae426082'))
        r.SPTexture=str(png);r.SPReceiver=r.SPRoot.layerObjects[0].validSurfaces()[0]
        r.execute('SPReceiver.material=standardMaterial name:"Owned receiver texture" diffuseMap:(bitmapTexture filename:SPTexture)')
        r.execute('global SPEdit=(SPRoot.procModifiers())[1];cyrusEditActiveLayers SPEdit #(SPRoot.layerObjects[1].editLayerKey);cyrusEditSelect SPEdit #(1)')
        r.execute('undo "Owned source instance move" on cyrusEditTransform SPEdit 0 [5,0,0] (matrix3 1) false')
        r.SPRoot.refreshAll();pump()
        r.execute('global SPUnrelated=box name:"Unrelated object outside preset" pos:[10000,0,0];global SPParent=dummy name:"Owned source parent";SPOriginal.parent=SPParent;with animate on (at time 10 SPParent.pos=[0,0,2]);sliderTime=0')
        r.SPRoot.refreshAll();pump()
        snap=snapshot(r.SPRoot);(O/'original-state.json').write_text(json.dumps(snap,indent=2));r.SPExpected=r.cyrusScenePresetEncode(r.CyrusRecipeObject(r.Array(r.Array('category','Scene preset qualification'),r.Array('tags',r.Array('native','test')),r.Array('description','Owned '+model+' setup'))))
        report.update(model=model,roots=len(roots()),layers=snap['layers'],edits=len(snap['edits']),version=str(r.SPRoot.uiVersion()),owned_texture=str(png))
    elif phase=='save':
        r.execute('SPJob=CyrusScenePresetSave SPRoot "Owned native preset" (CyrusRecipeObject #(#("category","Scene preset qualification"),#("tags",#("native","test")),#("description","Complete saved setup"))) ""')
        report.update(state=str(r.SPJob.state),ticket=str(r.SPJob.ticket.Directory))
    elif phase=='reference-after-development-save':
        r.SPRoot.refreshAll();pump();(O/'original-state.json').write_text(json.dumps(snapshot(r.SPRoot),indent=2))
    elif phase=='capture-authored-reference':
        png=O/'owned-texture.png';unavailable=O/'owned-texture-unavailable.png'
        if not png.exists() and unavailable.exists():unavailable.rename(png)
        pump();snap=snapshot(r.SPRoot);assert not any(str(x.previewError) for x in r.SPRoot.layerObjects);assert len(snap['edits'])==2;assert sum(x['deleted'] for group in snap['edits'] for x in group)>0
        assert sum(x['input']!=x['output'] for group in snap['edits'] for x in group)>=2;assert len(snap['radii'][0]['ids'])>0
        (O/'original-state.json').write_text(json.dumps(snap,indent=2));report.update(edits=2,radius_overrides=len(snap['radii'][0]['ids']))
    elif phase=='canonical-reference':
        before=json.loads((O/'original-state.json').read_text());node=next(n for n in roots() if [str(x.layerID) for x in n.baseObject.layerObjects]==before['owners']);snap=snapshot(node.baseObject)
        assert snap['rows']==before['rows'] and snap['radii']==before['radii'] and snap['preparation']==before['preparation'];(O/'original-state.json').write_text(json.dumps(snap,indent=2))
    elif phase=='inspect-import':
        got=snapshot(r.SPImported.baseObject);(O/'latest-import-state.json').write_text(json.dumps(got,indent=2));report.update(compare(json.loads((O/'original-state.json').read_text()),got))
        report['original_retained']=snapshot(r.SPRoot)==json.loads((O/'original-state.json').read_text());report['receiver_texture']=str(r.SPImported.baseObject.layerObjects[0].validSurfaces()[0].material.diffusemap.filename)
    elif phase=='poll-save':
        state=str(r.CyrusSharedPollSave(r.SPJob));assert state=='complete',(state,str(r.SPJob.error));r.SPEntry=str(r.SPJob.result)
        d=json.loads(Path(str(r.SPEntry)).read_text(encoding='utf-8-sig'));r.SPExpected=r.cyrusRecipeInfo(r.SPEntry)[10]
        assert d['format']=='cyrus.scene-preset' and d['version']==1 and d['maxYear']==2027
        current=snapshot(r.SPRoot);(O/'state-after-save.json').write_text(json.dumps(current,indent=2));assert current==json.loads((O/'original-state.json').read_text()),'Save changed the original setup'
        png=O/'owned-texture.png'
        if png.exists():png.rename(O/'owned-texture-unavailable.png')
        report.update(path=str(r.SPEntry),sha256=str(r.SPExpected),nodes=d['nodeCount'],assets=len(d['assets']),max_bytes=d['scene']['bytes'])
        (O/'saved-entry.json').write_text(json.dumps(report,indent=2))
    elif phase=='prepare-load':
        r.SPOperation=r.CyrusSharedStore().PrepareScene(str(r.SPEntry),str(r.SPExpected));report['state']=str(r.SPOperation.State)
    elif phase in ('merge-first','merge-repeat'):
        assert r.SPOperation.Terminal and str(r.SPOperation.State)=='complete',str(r.SPOperation.Error)
        before=snapshot(r.SPRoot);count=len(roots());r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned fixture command frame"');r.SPImported=r.CyrusScenePresetMerge(str(r.SPEntry),str(r.SPExpected),str(r.SPOperation.Result))
        r.CyrusSharedStore().DiscardSceneLoad(str(r.SPOperation.Result));pump()
        got=snapshot(r.SPImported.baseObject);(O/'latest-import-state.json').write_text(json.dumps(got,indent=2));report.update(compare(json.loads((O/'original-state.json').read_text()),got));assert len(roots())==count+1
        assert snapshot(r.SPRoot)==before,'Import changed original setup'
        receiver=r.SPImported.baseObject.layerObjects[0].validSurfaces()[0]
        report['collected_texture']=str(receiver.material.diffusemap.filename)
        assert Path(report['collected_texture']).is_file() and Path(report['collected_texture']).name!='owned-texture.png'
        assert str(r.SPReceiver.material.diffusemap.filename)==str(r.SPTexture),'Import repathed original material'
        assert r.SPImported.baseObject.layerObjects[0].validSources()[0].parent!=r.undefined
        r.execute('global SPImportedSource=(SPImported.baseObject.layerObjects[1].validSources())[1];global SPParentKeys=numKeys SPImportedSource.parent.position.controller');assert int(r.SPParentKeys)>0
        if phase=='merge-first':(O/'first-import.json').write_text(json.dumps(got,indent=2))
        else:
            first=json.loads((O/'first-import.json').read_text());assert not set(report['clones']).intersection(x['output'] for group in first['edits'] for x in group if x['input']!=x['output'])
        report.update(roots=len(roots()),contact=json.loads(str(r.SPImported.baseObject.interactionsStatistics())) if any(bool(x.interactionReact) or bool(x.interactionCollider) for x in r.SPImported.baseObject.layerObjects) else 'off')
    elif phase=='save-reopen':
        r.saveMaxFile(str(O/'native-preset-roundtrip.max'),quiet=True)
        count=len(roots());assert r.loadMaxFile(str(O/'native-preset-roundtrip.max'),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'));assert len(roots())==count
        for n in roots():n.baseObject.refreshAll();assert not str(n.baseObject.interactionError)
        report['roots']=count
    elif phase=='open-save-ui':
        r.select(r.SPOwner);r.CyrusOpenRecipeSave(r.SPRoot,r.CyrusRecipeDirectory());report['kind']=int(r.CyrusRecipeSaveEditor.saveKind.selection);assert report['kind']==1
        assert not r.CyrusRecipeSaveEditor.saveLayers.enabled
    report['status']='passed'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(O/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')


