"""Actual status-timer callbacks cannot calculate or upload unchanged results."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r
ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-')
data = {'status': 'started', 'checks': []}
def check(ok, label):
    data['checks'].append({'passed': bool(ok), 'label': label})
    if not ok:
        raise AssertionError(label)
try:
    node = r.getNodeByName('P01 feedback qualification'); root = node.baseObject
    check(bool(root.mainUI.controlsReady) and not bool(r.CyrusInteractionHeld()), 'Real editor ready without held interaction')
    def state():
        retained = list(r.cyrusRetainedStats(r.CyrusPointOwner(node)))
        return {'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds),
                'prepared': [int(l.procPreparedBuilds) for l in root.layerObjects],
                'preview': [int(l.previewBuildCount) for l in root.layerObjects],
                'rows': [str(r.cyrusEditFingerprint(rows, 'p01timer')) for rows in root.groupSnapshotRows],
                'revision': int(retained[2]), 'uploads': int(retained[5])}
    r.CyrusPointSync(); data['before'] = state()
    started = time.perf_counter()
    for _ in range(120):
        root.mainUI.statusTimer.tick()
    data['elapsed_ms'] = (time.perf_counter() - started) * 1000
    data['after'] = state()
    check(data['before'] == data['after'], '120 actual status ticks preserve placements, preparation and GPU uploads')
    data['status'] = 'complete'
except Exception:
    data['status'] = 'failed'; data['error'] = traceback.format_exc()
finally:
    (OUT / 'phase01-passive.json').write_text(json.dumps(data, indent=2) + '\n')
if data['status'] != 'complete':
    raise RuntimeError(data['error'])
