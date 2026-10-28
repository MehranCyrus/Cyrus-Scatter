"""Record the current Edit handle, committed collider row and failure state."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case = json.loads((host / 'cases' / (str(r.CVProfileCase)+'.json')).read_text(encoding='utf-8'))
report = {'status': 'running'}
try:
    root, edit, collider = r.WFRoot, r.WFEdit, r.WFCollider
    handle = r.cyrusEditHandleMatrix(edit, int(collider.editLayerKey), 1)
    committed = r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState, 2))[0][0]
    def xyz(v): return [float(v.x), float(v.y), float(v.z)]
    report.update(handle=xyz(handle.translation), committed=xyz(committed.row4), away=case['away']['target_scene_units'],
                  edit_revision=int(r.cyrusEditLocalRevision(edit)), update_mode=int(root.updateMode),
                  root_error=str(root.interactionError), ui_status=str(root.interactionsStatus()),
                  statistics=json.loads(str(root.interactionsStatistics())), status='complete')
except Exception:
    report.update(status='failed', error=traceback.format_exc())
(host / 'conflict-inspect.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
