"""Temporarily disable the Scatter controller in a disposable terrace fixture."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
try:
    root = r.TRoot
    before = {'enabled': bool(root.cyrusEnabled), 'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds)}
    root.cyrusEnabled = False
    root.refreshAll()
    r.CyrusPointSync()
    for _ in range(15):
        r.windows.processPostedMessages()
        r.completeRedraw()
        time.sleep(.02)
    result = {'status': 'pass' if not root.cyrusEnabled else 'failed', 'before': before,
              'after': {'enabled': bool(root.cyrusEnabled), 'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds)},
              'scope': 'Disposable fixture only; controller disabled to observe the remaining Max scene. This changes displayed content and is not an identical-work speed comparison.'}
except Exception:
    result = {'status': 'failed', 'error': traceback.format_exc()}
(host / 'scatter-disabled.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
