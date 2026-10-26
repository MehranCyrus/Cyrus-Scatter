"""Contact commands dispatched after startup so native Undo ownership is meaningful."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));result={'poses':[]}
def save():(O/'contact.json').write_text(json.dumps(result,indent=2),encoding='utf8')
def vec(p):return [float(p.x),float(p.y),float(p.z)]
try:
    root=r.E873Root;owner=r.E873Owner;grass=r.E873Grass;collider=r.E873Collider;sphere=r.E873Sphere
    grass.interactionCoverRoots=True;sphere.radius=3.0
    edits=[m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit]
    if not edits:r.addModifier(owner,r.CyrusScatterEdit())
    edit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    root.refreshAll();assert not any(str(l.previewError) for l in root.layerObjects)
    r.CyrusPerfHeadless=False;r.CyrusPointSuspended=False;r.CyrusPointSync();r.completeRedraw()
    end=time.monotonic()+1
    while time.monotonic()<end:r.windows.processPostedMessages();time.sleep(.01)
    base=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4
    start=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[1])[0][0].row4
    r.execute('global E873Edit,E873Base,E873Original,E873Epoch,E873Builds');r.E873Edit=edit;r.E873Base=base;r.E873Original=start;r.E873Epoch=int(root.procEpoch);r.E873Builds=int(root.groupBuilds)
    root.selectLayer(2);r.cyrusEditActiveLayers(edit,r.Array(int(collider.editLayerKey)));r.cyrusEditSelect(edit,r.Array(1))
    current=start
    for index,offset in enumerate([(6,0,6),(3,3,6),(-3,3,5),(30,0,6)]):
        target=base+r.Point3(*offset);entry={'offset_cm':offset};result['poses'].append(entry);save();t=time.perf_counter()
        try:
            r.cyrusEditTransform(edit,0,target-current,r.Matrix3(1),False)
            root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages();entry['statistics']=json.loads(str(root.interactionsStatistics()));entry['command_seconds']=time.perf_counter()-t
            entry['epoch']=int(root.procEpoch);entry['builds']=int(root.groupBuilds)
            assert entry['epoch']==int(r.E873Epoch) and entry['builds']==int(r.E873Builds),'Static placements rebuilt during contact edit'
            if index<3:
                audit=r.cyrusInteractionValidate(root.interactionState,2000000);entry['audit']=json.loads(str(audit[2]))
            current=target
        except Exception as e:entry['error']=str(e);break
        save()
    result['status']='complete';save()
except Exception:result['failure']=traceback.format_exc();save()
