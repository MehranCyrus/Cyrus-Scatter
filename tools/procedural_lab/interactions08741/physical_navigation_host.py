"""Bracket real wheel navigation in the owned terrace Max viewport."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
phase = int(r.CVCaptureDirection)
path = host / ('physical-navigation-' + str(r.CVProfileCase) + '.json')


def counters(root):
    owner = r.CyrusPointOwner(r.TOwner)
    retained = list(r.cyrusRetainedStats(owner)) if r.isValidNode(owner) else []
    return {'epoch': int(root.procEpoch), 'group_builds': int(root.groupBuilds),
            'layers': [[int(x.procPreparedBuilds), int(x.previewBuildCount)] for x in root.layerObjects],
            'retained': [str(retained[i]) for i in (0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12)] if retained else None}


try:
    root = r.TRoot
    assert int(root.updateMode) == 2
    if phase == 1:
        r.completeRedraw()
        r.windows.processPostedMessages()
        r.execute('global CVPhysicalNavTM;CVPhysicalNavTM=viewport.getTM()')
        report = {'status': 'armed', 'before': counters(root),
                  'view_before': str(r.viewport.getTM()), 'begin_qpc_ms': time.perf_counter()*1000.,
                  'qpc_minus_wall_ms': (time.perf_counter()-time.time())*1000.,
                  'scope': 'Actual wheel input on one Max viewport, with process-wide presentation capture; no input-to-photon claim.'}
    elif phase == 2:
        report = json.loads(path.read_text(encoding='utf-8'))
        report['end_qpc_ms'] = time.perf_counter()*1000.
        report['end_qpc_minus_wall_ms'] = (time.perf_counter()-time.time())*1000.
        report['after'] = counters(root)
        report['view_after'] = str(r.viewport.getTM())
        report['view_changed'] = report['view_before'] != report['view_after']
        report['status'] = 'pass' if report['before'] == report['after'] and report['view_changed'] else 'needs_review'
        restored = bool(r.execute('viewport.setTM CVPhysicalNavTM'))
        report['restore_status'] = ('restored' if restored else
                                    'setTM is unsupported for this orthographic view; reframe the fixture before another comparison')
        r.completeRedraw()
    else:
        raise ValueError('Use phase 1 to arm and phase 2 to finish')
except Exception:
    report = {'status': 'failed', 'error': traceback.format_exc()}
path.write_text(json.dumps(report, indent=2), encoding='utf-8')
