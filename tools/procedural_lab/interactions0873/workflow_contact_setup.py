"""Present a matched owned scene before separate Cyrus Edit gesture commands."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={}
try:
    root=r.WFRoot;owner=r.WFOwner;grass=r.WFGrass;collider=r.WFCollider
    root.updateMode=2;grass.amount=50;grass.interactionCoverRoots=True;grass.interactionGapWU=0
    grass.interactionFoliage=.25;grass.interactionSourceCache=r.Array();grass.interactionsChanged()
    grass.interactionsClearGuides();collider.interactionsClearGuides()
    edit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit);r.WFEdit=edit
    root.refreshAll();assert not any(str(l.previewError) for l in root.layerObjects)
    r.execute('global WFBase,WFCurrent,WFTarget,WFContactStep,WFContactEpoch,WFContactBuilds')
    r.WFBase=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4
    r.WFCurrent=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[1])[0][0].row4
    r.execute('select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    root.selectLayer(2);r.cyrusEditActiveLayers(edit,r.Array(int(collider.editLayerKey)))
    r.CyrusPointSync();r.completeRedraw()
    report={'status':'presenting','hwnd':int(r.windows.getMAXHWND()),'base':str(r.WFBase),'current':str(r.WFCurrent),'radius_cm':float(r.WFSphere.radius),'stats':json.loads(str(root.interactionsStatistics()))}
except Exception:report={'error':traceback.format_exc()}
(O/'contacts.json').write_text(json.dumps(report,indent=2))
