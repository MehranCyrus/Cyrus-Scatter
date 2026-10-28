"""Check prepared-source removal, Manual retention and physical Undo/Redo."""
from pathlib import Path
import hashlib
import json
import time
import traceback
from pymxs import runtime as r

host, phase = Path(str(r.GardenRun)), int(r.CVCaptureDirection)
path = host / 'prepared-source-removal.json'
report = {'status': 'running', 'checks': []} if phase == 1 else json.loads(path.read_text(encoding='utf-8'))


def state(root, leaf):
    return {'sources': [str(x.name) for x in leaf.validSources()], 'row_ids': [str(x) for x in leaf.sourceRowIDs],
            'definition_ids': [str(x) for x in leaf.interactionSourceIDs],
            'definition_hashes': [hashlib.sha256(str(x).encode('utf-8')).hexdigest() for x in leaf.interactionDefinitions],
            'epoch': int(root.procEpoch), 'error': str(root.interactionError),
            'interaction': json.loads(str(root.interactionsStatistics())) if root.interactionState != r.undefined else None}


try:
    root, leaf = r.WFRoot, r.WFGrass
    if phase == 1:
        assert len(leaf.validSources()) == 1 and bool(leaf.interactionReact)
        root.updateMode = 1
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
        r.WFSection = panel.editors[12]
        r.WFSection.interactionsUI_modelList.selection = 1
        report['before'] = state(root, leaf)
        report['removed_id'] = report['before']['row_ids'][0]
        assert report['removed_id'] in report['before']['definition_ids']
        assert report['before']['interaction'] is not None and not report['before']['error']
        report['status'] = 'armed'
    elif phase == 2:
        r.execute('WFSection.interactionsUI_sourceRemoveButton.pressed()')
        report['removed'] = state(root, leaf)
        assert report['removed_id'] not in report['removed']['row_ids']
        assert report['removed_id'] not in report['removed']['definition_ids'], 'Removed source left a serialized preparation in the scene'
        assert report['removed']['epoch'] == report['before']['epoch']
        assert report['removed']['interaction'] is not None and not report['removed']['error'], 'Manual removal discarded the last complete interaction publication'
        report['checks'].append('Removal prunes the definition while retaining the Manual publication')
        report['status'] = 'removed'
    elif phase == 3:
        r.execute('max undo')
        report['undo'] = state(root, leaf)
        assert report['undo']['row_ids'] == report['before']['row_ids']
        assert report['undo']['definition_ids'] == report['before']['definition_ids']
        assert report['undo']['definition_hashes'] == report['before']['definition_hashes']
        report['checks'].append('Undo restores the original source identity and exact definition')
        report['status'] = 'undone'
    elif phase == 4:
        r.execute('max redo')
        report['redo'] = state(root, leaf)
        assert report['removed_id'] not in report['redo']['row_ids'] and report['removed_id'] not in report['redo']['definition_ids']
        report['checks'].append('Redo removes the source and definition again')
        report['status'] = 'pass'
    else:
        raise ValueError('Use phases 1 through 4')
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
