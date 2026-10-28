"""Separate source-pick and failed-prepare UI events across Max message ticks."""
from pathlib import Path
import hashlib
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key, phase = str(r.CVProfileCase), int(r.CVCaptureDirection)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
path = host / ('prepare-phased-' + case_key + '.json')
report = {'case': case_key, 'status': 'running'} if phase == 1 else json.loads(path.read_text(encoding='utf-8'))


def state(root, leaf):
    return {'sources': [str(x.name) for x in leaf.validSources()],
            'source_ids': [str(x) for x in leaf.sourceRowIDs],
            'definition_hashes': [hashlib.sha256(str(x).encode('utf-8')).hexdigest() for x in leaf.interactionDefinitions],
            'epoch': int(root.procEpoch)}


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
    if phase == 1:
        if not any(x == node for x in leaf.validSources()):
            r.execute('WFSection.interactionsUI_sourcePickButton.picked CVModel')
        root.refreshAll()
        leaf.interactionMaxGuides, leaf.interactionWorkMillions = 32768, 2048
        root.mainUI.bindSection(root.mainUI.editors[12])
        r.WFSection = root.mainUI.editors[12]
        r.WFSection.interactionsUI_modelList.selection = 1
        r.execute('WFSection.interactionsUI_chooseRole 3')
        report['before'] = state(root, leaf)
        assert str(node.name) in report['before']['sources']
        report['status'] = 'armed'
    elif phase == 2:
        before = report['before']
        assert state(root, leaf)['sources'] == before['sources'], 'The source changed between actions'
        r.WFSection.interactionsUI_modelList.selection = 1
        r.execute('WFSection.interactionsUI_prepareButton.pressed()')
        after = state(root, leaf)
        after['message'] = str(r.WFSection.interactionsUI_info.text)
        report['after'] = after
        assert after['sources'] == before['sources'] and after['source_ids'] == before['source_ids'], 'Failed preparation removed or replaced the source'
        assert after['definition_hashes'] == before['definition_hashes'], 'Failed preparation overwrote existing definitions'
        assert 'error' in after['message'].lower(), 'Expected a reported preparation error'
        report['status'] = 'pass'
    else:
        raise ValueError('Use two separate phases')
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
