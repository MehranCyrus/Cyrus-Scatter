"""Limited preview feedback must refer to cached sample units, preserving rows."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r
ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-p01-')
data = {'status': 'started', 'checks': []}
def check(ok, label):
    data['checks'].append({'passed': bool(ok), 'label': label})
    if not ok:
        raise AssertionError(label)
try:
    node = r.getNodeByName('P01 feedback qualification'); root = node.baseObject
    r.select(node); r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:
        root.mainUI.mountTimer.tick()
    first = root.layerObjects[0]; root.mainUI.selectLayerView(first)
    root.statisticsUI.open = True; root.mainUI.bindSection(root.statisticsUI)
    root.mainUI.updateNow.pressed(); r.CyrusPointSync()
    before = [str(r.cyrusEditFingerprint(rows, 'p01limited')) for rows in root.groupSnapshotRows]
    epoch = int(root.procEpoch)
    root.viewportInstances = 10; root.viewportNavigationInstances = 5
    root.setGroupDisplay(2); r.CyrusPointSync(); r.completeRedraw()
    root.statisticsUI.detailsUI_refreshButton.pressed()
    data['text'] = str(root.statisticsUI.detailsUI_info.text)
    check('Prepared preview is sampled' in data['text'], 'Limited state identifies the prepared subset')
    check('Accepted placements: 90' in data['text'] and 'Prepared proxy instances: 10' in data['text'],
          'Accepted count remains separate from prepared instances and shared draw limits')
    check(before == [str(r.cyrusEditFingerprint(rows, 'p01limited')) for rows in root.groupSnapshotRows] and epoch == int(root.procEpoch),
          'Display limitation preserves complete accepted rows and epoch')
    data['status'] = 'complete'
except Exception:
    data['status'] = 'failed'; data['error'] = traceback.format_exc()
finally:
    (OUT / 'phase01-limited.json').write_text(json.dumps(data, indent=2) + '\n')
if data['status'] != 'complete':
    raise RuntimeError(data['error'])
