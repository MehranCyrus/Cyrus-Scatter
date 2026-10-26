from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));data={}
try:
    owner=r.E873Owner;root=r.E873Root;grass=r.E873Grass;collider=r.E873Collider
    r.E873Sphere.radius=3;grass.interactionCoverRoots=True
    # Each campaign starts from an unedited copy. Base placement rows do not
    # contain authored Edit overrides from an earlier campaign.
    for m in list(owner.modifiers):
        if r.classOf(m)==r.CyrusScatterEdit:r.deleteModifier(owner,m)
    edit=r.CyrusScatterEdit();r.addModifier(owner,edit)
    root.refreshAll();r.CyrusPerfHeadless=False;r.CyrusPointSuspended=False;r.CyrusPointSync();r.completeRedraw()
    r.execute('global E873Edit,E873Base,E873Current,E873Target,E873Epoch,E873Builds,E873ContactStep')
    r.E873Edit=edit;r.E873Base=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4;r.E873Current=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[1])[0][0].row4
    root.selectLayer(2);r.cyrusEditActiveLayers(edit,r.Array(int(collider.editLayerKey)));r.cyrusEditSelect(edit,r.Array(1))
    r.CyrusPointSync();r.completeRedraw();r.E873Epoch=int(root.procEpoch);r.E873Builds=int(root.groupBuilds)
    data={'status':'ready','epoch':int(root.procEpoch),'builds':int(root.groupBuilds),'poses':[]}
except Exception:data={'failure':traceback.format_exc()}
(O/'contact-events.json').write_text(json.dumps(data,indent=2))
