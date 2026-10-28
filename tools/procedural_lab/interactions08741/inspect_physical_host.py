"""Retain diagnostics when the private terrace pointer fixture cannot arm."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
out = {'status': 'running'}
try:
    out['owner'] = str(r.TOwner)
    out['root_error'] = str(r.TRoot.interactionError)
    out['viewport_error'] = str(r.CyrusPointLastError)
    out['epoch'] = int(r.TRoot.procEpoch)
    out['update_mode'] = int(r.TRoot.updateMode)
    out['group_builds'] = int(r.TRoot.groupBuilds)
    out['layers'] = [{'name': str(r.TRoot.layerNames[i]), 'key': int(x.editLayerKey),
                      'count': int(x.generatedCount), 'error': str(x.previewError)}
                     for i, x in enumerate(r.TRoot.layerObjects)]
    out['edit'] = str(r.TEdit)
    out['rock_key'] = int(r.TRocks.editLayerKey)
    out['handle'] = str(r.cyrusEditHandleMatrix(r.TEdit, int(r.TRocks.editLayerKey), 1))
    out['interaction'] = str(r.TRoot.interactionsStatistics()) if r.TRoot.interactionState != r.undefined else None
    out['status'] = 'complete'
except Exception:
    out['status'] = 'failed'
    out['error'] = traceback.format_exc()
(host / 'physical-inspect.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
