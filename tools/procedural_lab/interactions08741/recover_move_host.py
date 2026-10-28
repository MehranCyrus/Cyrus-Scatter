"""Move a previously failing collider to a different clear location."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case = json.loads((host / 'cases' / (str(r.CVProfileCase)+'.json')).read_text(encoding='utf-8'))
out = {'status': 'running'}
try:
    root, edit, collider = r.WFRoot, r.WFEdit, r.WFCollider
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.cyrusEditActiveLayers(edit, r.Array(int(collider.editLayerKey)))
    r.cyrusEditSelect(edit, r.Array(1))
    current = r.cyrusEditHandleMatrix(edit, int(collider.editLayerKey), 1).translation
    target = case['away']['target_scene_units']
    r.CVCurrent, r.CVTarget = current, r.Point3(target[0]+100., target[1], target[2])
    r.execute('undo "recover clear collider" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
    root.interactionsEnsure()
    r.CyrusPointSync()
    r.completeRedraw()
    r.windows.processPostedMessages()
    info = json.loads(str(root.interactionsStatistics()))
    out.update(status='complete', ui_status=str(root.interactionsStatus()), statistics=info,
               actual=[float(x) for x in [r.cyrusEditHandleMatrix(edit, int(collider.editLayerKey), 1).translation.x,
                                         r.cyrusEditHandleMatrix(edit, int(collider.editLayerKey), 1).translation.y,
                                         r.cyrusEditHandleMatrix(edit, int(collider.editLayerKey), 1).translation.z]])
except Exception:
    out.update(status='failed', error=traceback.format_exc())
(host / 'conflict-recover-other-location.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
