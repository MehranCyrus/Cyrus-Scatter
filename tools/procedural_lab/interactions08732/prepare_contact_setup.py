"""Place the collider safely above roots, then expose actual Cyrus Edit movement."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={}
try:
    root=r.WFRoot;owner=r.WFOwner;grass=r.WFGrass;collider=r.WFCollider
    grass.interactionFoliage=1.;grass.interactionGapWU=0.;grass.interactionCoverRoots=False;grass.interactionSourceCache=r.Array();grass.interactionsChanged()
    root.updateMode=2;root.selectLayer(2);r.WFSphere.radius=17.9853572845459
    # Disable the sphere while installing its first Edit pose, so initial saved
    # placement cannot introduce an unintended fixed-root conflict in this fixture.
    collider.interactionCollider=False;root.refreshAll();r.CyrusPointSync();r.completeRedraw()
    r.execute('global WFBase,WFCurrent,WFTarget,WFContactStep')
    r.WFBase=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4
    r.execute('select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.CyrusPointSync();r.completeRedraw()
    r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(collider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
    root.interactionsEnsure()
    r.WFCurrent=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4
    r.WFTarget=r.WFBase+r.Point3(0,0,80)
    r.execute('undo "Start collider clear of roots" on cyrusEditTransform WFEdit 0 (WFTarget-WFCurrent) (matrix3 1) false')
    collider.interactionColliderMode=1;collider.interactionCollider=True;collider.interactionReact=False;root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
    report={'status':'ready','hwnd':int(r.windows.getMAXHWND()),'base':str(r.WFBase),'radius_cm':float(r.WFSphere.radius),'statistics':json.loads(str(root.interactionsStatistics()))}
    assert not report['statistics']['error']
except Exception:report['error']=traceback.format_exc()
(O/'hover-setup.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
