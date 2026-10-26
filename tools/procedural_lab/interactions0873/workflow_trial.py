"""Save a close-up 100% preview trial, preserving the original artist scene."""
from pathlib import Path
import hashlib,json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));report={}
def mount(root,grass,owner):
    r.select(owner);r.execute('subObjectLevel=0;max modify mode;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+3
    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
    assert bool(root.mainUI.controlsReady)
    root.mainUI.selectLayerView(grass);section=root.mainUI.editors[12];root.mainUI.slots[12].open=True;root.mainUI.bindSection(section);r.WFSection=section
    return section
try:
    root=r.WFRoot;grass=r.WFGrass;owner=r.WFOwner;collider=r.WFCollider
    grass.interactionFoliage=1.;grass.interactionSourceCache=r.Array();grass.interactionsChanged();root.interactionsEnsure()
    r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(collider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
    current=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4
    base=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4
    r.WFTarget=base+r.Point3(18,0,8);r.WFCurrent=current
    r.execute('undo "Trial collider position" on cyrusEditTransform WFEdit 0 (WFTarget-WFCurrent) (matrix3 1) false')
    root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
    report['audit']=json.loads(str(r.cyrusInteractionValidate(root.interactionState,2000000)[2]));assert report['audit']['passed']
    section=mount(root,grass,owner);assert float(section.interactionsUI_foliageSpin.value)==100.
    r.viewport.ZoomToBounds(False,base+r.Point3(-60,-60,-15),base+r.Point3(60,60,90));r.completeRedraw()
    trial=ROOT/'dist/CyrusScatter-0.87.3-20261026-workflow-r2/Trials/New_Plants_Interaction_Workflow_0.87.3.max';assert not trial.exists()
    definitions=list(grass.interactionDefinitions);r.saveMaxFile(str(trial),quiet=True)
    assert r.loadMaxFile(str(trial),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    root=owner.baseObject;grass=root.layerObjects[0];collider=root.layerObjects[1]
    r.WFOwner=owner;r.WFRoot=root;r.WFGrass=grass;r.WFCollider=collider;r.WFSphere=collider.validSources()[0]
    r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    assert list(grass.interactionDefinitions)==definitions and float(grass.interactionFoliage)==1.
    root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();mount(root,grass,owner);r.completeRedraw()
    report.update(trial=str(trial),sha256=hashlib.sha256(trial.read_bytes()).hexdigest(),statistics=json.loads(str(root.interactionsStatistics())))
    assert not str(root.interactionError);report['status']='pass'
except Exception:report['error']=traceback.format_exc()
(O/'trial.json').write_text(json.dumps(report,indent=2))
