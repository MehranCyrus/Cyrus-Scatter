"""Inspect private fixture node identities after an import attempt."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
out = {'status': 'running'}
try:
    out['nodes'] = [{'name': str(n.name), 'handle': int(r.getHandleByAnim(n)), 'hidden': bool(n.isHidden)}
                    for n in r.objects if 'A085' in str(n.name) or 'A058' in str(n.name)]
    out['current_sources'] = [str(n.name) for n in r.WFGrass.validSources()]
    out['raw_sources'] = [str(n) for n in r.WFGrass.sources]
    out['current_layer_name'] = str(r.WFRoot.layerNames[0])
    out['leaf_is_current_layer'] = bool(r.WFGrass == r.WFRoot.layerObjects[0])
    out['root_layer_sources'] = [str(n) for n in r.WFRoot.layerObjects[0].sources]
    out['imported'] = str(r.CVImported)
    out['status'] = 'complete'
except Exception:
    out['status'] = 'failed'
    out['error'] = traceback.format_exc()
(host / 'inspect-import.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
