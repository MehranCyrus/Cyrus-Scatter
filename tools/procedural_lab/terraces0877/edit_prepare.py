from pathlib import Path
import json,traceback,time
from pymxs import runtime as r
root=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun))
try:
    r.execute('''(WFEdit=undefined;for m in WFOwner.modifiers where classof m==CyrusScatterEdit do WFEdit=m
    if WFEdit==undefined do (WFEdit=CyrusScatterEdit();addModifier WFOwner WFEdit)
    WFRoot.interactionSceneColliders=#();DGStone.isHidden=true
    WFCollider.removeModelSources (for i=1 to WFCollider.sources.count collect i)
    WFCollider.addModelSource (getNodeByName "Stone 1" exact:true)
    WFCollider.amount=1;WFCollider.sourceScales[1]=3.;WFCollider.interactionCollider=true
    WFRoot.layerEnabled[2]=true;WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync())''')
    until=time.monotonic()+15
    while time.monotonic()<until:
        r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
        ready=r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.WFOwner))
        if int(ready[3])==2:break
    assert int(ready[3])==2,str(ready)
    r.execute('''(cyrusEditActiveLayers WFEdit #(WFCollider.editLayerKey);cyrusEditCommand WFEdit 1 undefined
    local rows=cyrusPlacementTransformGroups (cyrusInteractionRows WFRoot.interactionState 2)
    local delta=DGStone.pos-rows[1][1].row4
    cyrusEditCommand WFEdit 4 (transMatrix delta)
    WFRoot.interactionsEnsure();CyrusPointSync();completeRedraw())''')
    until=time.monotonic()+15
    while time.monotonic()<until:
        r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
        ready=r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.WFOwner))
        if int(ready[3])==2:break
    assert int(ready[3])==2,str(ready)
    data=dict(status='complete',stats=json.loads(str(r.WFRoot.interactionsStatistics())))
    r.execute('global CVProfileCase="rapid-edit"')
    r.fileIn(str(root/'tools/procedural_lab/drag08756/drag_timer.ms'))
except Exception:data=dict(status='failed',error=traceback.format_exc())
(out/'edit-prepare.json').write_text(json.dumps(data,indent=2))
