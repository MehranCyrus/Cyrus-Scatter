"""Compare viewport triangle budgets on a private terrace copy."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
phase = int(r.CVCaptureDirection)
path = host / 'viewport-budget.json'


def state(root):
    owner = r.CyrusPointOwner(r.TOwner)
    return {'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds),
            'idle_limit': int(root.viewportFaces), 'navigation_limit': int(root.viewportNavigationFaces),
            'retained': [str(x) for x in r.cyrusRetainedStats(owner)],
            'plan': [int(x) for x in r.cyrusRetainedViewportStats(owner)]}


try:
    root = r.TRoot
    if phase == 1:
        before = state(root)
        root.viewportFaces = 2000000
        root.viewportNavigationFaces = 500000
        root.refreshDisplay()
        r.CyrusPointSync()
        for _ in range(15):
            r.windows.processPostedMessages()
            r.completeRedraw()
            time.sleep(.02)
        after = state(root)
        assert after['epoch'] == before['epoch'] and after['builds'] == before['builds'], 'Display budget rebuilt placements'
        assert after['plan'][5] <= 2000000 and after['plan'][6] <= 500000, after
        report = {'status': 'pass', 'before': before, 'after': after,
                  'scope': 'Private scene preview draw-budget change; reducing triangle budgets may show fewer instances and does not change the render or contact solver.'}
    else:
        raise ValueError('Use phase 1 to set the temporary lower display budget')
except Exception:
    report = {'status': 'failed', 'error': traceback.format_exc()}
path.write_text(json.dumps(report, indent=2), encoding='utf-8')
