"""Check whether a failed Prepare retains its source and prior publication."""
from pathlib import Path
import hashlib
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key = str(r.CVProfileCase)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
path = host / ('prepare-failure-' + case_key + '.json')
report = {'case': case_key, 'status': 'running', 'scope': 'Generated source-pick and Prepare UI callbacks in an owned host.'}


def definitions(leaf):
    return [hashlib.sha256(str(x).encode('utf-8')).hexdigest() for x in leaf.interactionDefinitions]


try:
    root, leaf = r.WFRoot, r.WFGrass
    node = r.getNodeByName(case['node_name'])
    assert node != r.undefined and r.isValidNode(node)
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    panel = root.mainUI
    until = time.monotonic() + 8.
    while not bool(panel.controlsReady) and time.monotonic() < until:
        r.windows.processPostedMessages()
        time.sleep(.02)
    assert panel.controlsReady
    root.selectLayer(1)
    panel.slots[12].open = True
    panel.bindSection(panel.editors[12])
    r.WFSection, r.CVModel = panel.editors[12], node
    if not any(n == node for n in leaf.validSources()):
        r.execute('WFSection.interactionsUI_sourcePickButton.picked CVModel')
    root.refreshAll()
    r.CyrusPointSync()
    r.WFSection = root.mainUI.editors[12]
    root.mainUI.bindSection(r.WFSection)
    before = {'sources': [str(x.name) for x in leaf.validSources()], 'epoch': int(root.procEpoch),
              'definitions': definitions(leaf)}
    assert str(node.name) in before['sources'], before
    r.execute('WFSection.interactionsUI_chooseRole 3')
    r.execute('WFSection.interactionsUI_prepareButton.pressed()')
    after = {'sources': [str(x.name) for x in leaf.validSources()], 'epoch': int(root.procEpoch),
             'definitions': definitions(leaf),
             'message': str(r.WFSection.interactionsUI_info.text)}
    report.update(before=before, after=after)
    assert after['sources'] == before['sources'], 'A failed preparation removed the authored model source'
    assert after['definitions'] == before['definitions'], 'A failed preparation changed persistent definitions'
    assert 'error' in after['message'].lower(), 'Expected a reported source preparation error'
    report['status'] = 'pass'
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
