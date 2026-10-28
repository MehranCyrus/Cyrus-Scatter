"""Retain the native preparation report for the currently selected source."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key = str(r.CVProfileCase)
path = host / ('source-failure-' + case_key + '.json')
report = {'case': case_key, 'status': 'running'}
try:
    case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
    node = r.getNodeByName(case.get('node_name', case['name']))
    assert node != r.undefined and r.isValidNode(node), 'The captured source node is no longer in this owned scene'
    data = case['settings']
    settings = r.Array(data['minimum_m'], data['preview_fraction'], 1,
                       r.Array(*data['limits']), data['branch_connection_m'])
    report['node'] = str(node.name)
    report['visible_layer_sources'] = [str(x.name) for x in r.WFGrass.validSources()]
    report['panel_source'] = str(r.execute('(local n=WFSection.interactionsUI_currentSource();if isValidNode n then n.name else "undefined")'))
    report['settings'] = data
    value = r.cyrusInteractionSource(node, r.undefined, settings, 1)
    report['analysis'] = json.loads(str(r.cyrusInteractionSourceInfo(value)))
    report['summary'] = str(r.cyrusInteractionSourceSummary(value))
    report['status'] = 'complete'
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
