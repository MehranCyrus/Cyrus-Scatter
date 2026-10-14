"""Diagnose state notifications without changing the shipped script."""
from pathlib import Path
import json
from pymxs import runtime as r
ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-p01-')
node = r.getNodeByName('P01 feedback qualification')
root = node.baseObject
rows = []
def capture(label):
    current = str(root.procInputKey())
    published = str(root.groupSnapshotKey)
    rows.append({'label': label, 'dirty': [bool(l.dirty) for l in root.layerObjects],
                 'key_equal': current == published, 'current': current, 'published': published,
                 'prepared_modes': [int(l.uiPreviewMode) for l in root.layerObjects]})
capture('before')
root.refreshAll()
capture('after refreshAll')
r.CyrusPointSync(); r.completeRedraw(); r.windows.processPostedMessages()
capture('after redraw')
root.mainUI.bind()
capture('after bind')
root.statisticsUI.detailsUI_refreshStats()
capture('after direct stats')
(OUT / 'phase01-probe.json').write_text(json.dumps(rows, indent=2) + '\n')
