"""Save/reopen a clean, owned copy with the reported fern and one edited collider."""
from pathlib import Path
import json,time,traceback,hashlib
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));phase=int(r.WFTrialPhase);path=O/'fern-roundtrip.json'
report={} if phase==0 else json.loads(path.read_text())
def digest(value):return hashlib.sha256(value.encode()).hexdigest()
def mount():
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+3
    while not bool(r.WFRoot.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
    panel=r.WFRoot.mainUI;panel.selectLayerView(r.WFGrass);panel.slots[12].open=True;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]
try:
    if phase==0:
        root=r.WFRoot;leaf=r.WFGrass;mount()
        # Keep the trial's single active definition; prior campaign fixtures are
        # not source rows in this clean copy. The artist's original is untouched.
        key=str(leaf.sourceRowIDs[0]);slot=list(str(x) for x in leaf.interactionSourceIDs).index(key);definition=str(leaf.interactionDefinitions[slot])
        leaf.interactionSourceIDs=r.Array(key);leaf.interactionDefinitions=r.Array(definition)
        for prop,value in [('interactionMaxVertices',2000000),('interactionMaxTriangles',4000000),('interactionMaxParts',100000),('interactionMaxGuides',8192),('interactionMaxPreview',500000),('interactionMemoryMiB',2048),('interactionWorkMillions',256)]:setattr(leaf,prop,value)
        leaf.interactionsRefreshPreparation(rebuild=False)
        r.execute('WFSection.interactionsUI_connectionSpin.changed 15.;WFSection.interactionsUI_minimumSpin.changed .5;WFSection.interactionsUI_stiffnessSpin.changed .5;WFSection.interactionsUI_gapSpin.changed 0.')
        for n in list(r.objects):
            if str(n.name) in ['Prepared duplicate source test','08732 source button fixture']:r.delete(n)
        root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
        r.execute('select WFOwner;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move');r.CyrusPointSync();r.completeRedraw()
        r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
        r.WFCurrent=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4;r.WFTarget=r.WFBase+r.Point3(30,0,45)
        r.execute('undo "Fern trial collider" on cyrusEditTransform WFEdit 0 (WFTarget-WFCurrent) (matrix3 1) false');root.interactionsEnsure()
        audit=json.loads(str(r.cyrusInteractionValidate(root.interactionState,2000000)[2]));assert audit['passed'],audit
        mount();r.viewport.ZoomToBounds(False,r.WFBase+r.Point3(-85,-85,-10),r.WFBase+r.Point3(85,85,85));r.completeRedraw()
        folder=ROOT/'Test Scene'/'CyrusScatter_08732_OwnedTests';folder.mkdir(exist_ok=True);trial=folder/'Neottopteris_Interaction_08732.max';assert not trial.exists()
        report={'trial':str(trial),'definition_sha256':digest(str(leaf.interactionDefinitions[0])),'source_id':str(leaf.interactionSourceIDs[0]),'audit_before_save':audit}
        r.saveMaxFile(str(trial),quiet=True);report['file_sha256']=hashlib.sha256(trial.read_bytes()).hexdigest();report['status']='saved'
    elif phase==1:
        assert r.loadMaxFile(report['trial'],quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
        r.WFOwner=owner;r.WFRoot=owner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1];r.WFSphere=r.WFCollider.validSources()[0];r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
        assert len(r.WFGrass.interactionDefinitions)==1 and digest(str(r.WFGrass.interactionDefinitions[0]))==report['definition_sha256']
        assert str(r.WFGrass.interactionSourceIDs[0])==report['source_id'] and str(r.WFRoot.uiVersion())=='0.87.3.2'
        r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();mount()
        report['audit_after_reopen']=json.loads(str(r.cyrusInteractionValidate(r.WFRoot.interactionState,2000000)[2]));assert report['audit_after_reopen']['passed'],report['audit_after_reopen']
        report['statistics']=json.loads(str(r.WFRoot.interactionsStatistics()));report['hwnd']=int(r.windows.getMAXHWND());report['status']='pass'
except Exception:report['error']=traceback.format_exc()
path.write_text(json.dumps(report,indent=2),encoding='utf-8')
