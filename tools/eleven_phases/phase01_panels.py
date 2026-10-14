"""Qualify generated page guards, owner switches and no-owner feedback."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r
ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-p01-')
data = {'status': 'started', 'checks': [], 'pages': []}
def save():
    (OUT / 'phase01-panels.json').write_text(json.dumps(data, indent=2) + '\n')
def check(ok, label):
    data['checks'].append({'passed': bool(ok), 'label': label}); save()
    if not ok:
        raise AssertionError(label)
try:
    check(bool(r.loadMaxFile(str(OUT / 'P01_roundtrip.max'), quiet=True, useFileUnits=True)), 'Owned current-schema fixture loaded')
    node = r.getNodeByName('P01 feedback qualification'); root = node.baseObject
    r.CyrusPointSync(); r.CyrusPerfHeadless = False; r.select(node); r.execute('max modify mode'); r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:
        root.mainUI.mountTimer.tick()
    manifest = json.loads((ROOT / 'AminScatter/tools/ui/approved-layout-manifest.json').read_text())
    for spec in manifest['sections']:
        page = r.getProperty(root, r.Name(spec['name']))
        page.open = True; root.mainUI.bindSection(page)
        guards = {key: bool(r.getProperty(page, r.Name(key + '_binding')))
                  for key in sorted({c['component'] for c in spec['controls']})}
        data['pages'].append({'name': spec['name'], 'guards': guards, 'width': int(page.width), 'height': int(page.height)})
        check(bool(page.controlsReady) and not any(guards.values()), 'Successful page bind releases every component guard: ' + spec['name'])
    first, second = root.layerObjects[0], root.layerObjects[1]
    root.mainUI.selectLayerView(second)
    root.statisticsUI.detailsUI_refreshButton.pressed()
    check('Layer: Groundcover' in str(root.statisticsUI.detailsUI_info.text), 'All-open editor reads second owner')
    root.mainUI.selectLayerView(first)
    root.statisticsUI.detailsUI_refreshButton.pressed()
    check('Layer: Renamed Canopy' in str(root.statisticsUI.detailsUI_info.text), 'All-open editor switches back to first owner')
    empty = r.AminScatterObject(name='P01 no layers'); empty_root = empty.baseObject
    r.select(empty); r.modPanel.setCurrentObject(empty_root)
    if not empty_root.mainUI.controlsReady:
        empty_root.mainUI.mountTimer.tick()
    empty_root.statisticsUI.open = True; empty_root.mainUI.bindSection(empty_root.statisticsUI)
    empty_root.mainUI.refreshStats()
    check('Select a layer' in str(empty_root.statisticsUI.detailsUI_info.text) or 'Add a layer' in str(empty_root.statisticsUI.detailsUI_info.text),
          'No owner has clear guidance and no stale statistics')
    r.select(node); r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:
        root.mainUI.mountTimer.tick()
    root.mainUI.selectLayerView(first)
    root.statisticsUI.open = True; root.mainUI.bindSection(root.statisticsUI)
    # Keep a meaningful owned scene ready for the separate visual check.
    r.saveMaxFile(str(OUT / 'P01_visual_ready.max'), quiet=True)
    data['status'] = 'complete'
except Exception:
    data['status'] = 'failed'; data['error'] = traceback.format_exc()
finally:
    save()
if data['status'] != 'complete':
    raise RuntimeError(data['error'])
