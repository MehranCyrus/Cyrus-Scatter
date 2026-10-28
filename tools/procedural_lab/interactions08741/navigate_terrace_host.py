"""Measure a bounded viewport camera motion in the private terrace scene."""
from pathlib import Path
import json
import statistics
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case = str(r.CVProfileCase)
out = {'case': case, 'status': 'running', 'steps_ms': [],
       'scope': 'Programmatic viewport transforms with synchronous redraw; presented frames are a separate PresentMon measurement.'}
base = None


def counters(root):
    owner = r.CyrusPointOwner(r.TOwner)
    retained = list(r.cyrusRetainedStats(owner)) if r.isValidNode(owner) else []
    return {'epoch': int(root.procEpoch), 'group_builds': int(root.groupBuilds),
            'layers': [[int(x.procPreparedBuilds), int(x.previewBuildCount), int(x.containerScans),
                        int(x.containerTests), int(x.containerMembershipBuilds)] for x in root.layerObjects],
            # Draw count changes during navigation; revisions, preparation,
            # uploads, failures and payload ownership should not.
            'retained': [str(retained[i]) for i in (0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12)] if retained else None}


try:
    root = r.TRoot
    assert int(root.updateMode) == 2, 'The navigation fixture must be in Live mode'
    for _ in range(4):
        r.completeRedraw()
        r.windows.processPostedMessages()
    assert not str(root.interactionError), str(root.interactionError)
    out['before'] = counters(root)
    base = r.viewport.getTM()
    r.execute('global CVNavBase,CVNavFrame')
    r.CVNavBase = base
    out['qpc_check_ms'] = (float(r.execute('((dotNetClass "System.Diagnostics.Stopwatch").GetTimestamp() as double)/(dotNetClass "System.Diagnostics.Stopwatch").Frequency*1000.0'))
                           - time.perf_counter()*1000.)
    out['begin_qpc_ms'] = time.perf_counter()*1000.
    for i in range(1, 21):
        r.CVNavFrame = i
        start = time.perf_counter()
        changed = r.execute('viewport.setTM ((rotateZMatrix (3.0*sin(CVNavFrame*7.0)))*CVNavBase)')
        if not changed:
            raise RuntimeError('viewport.setTM does not move this viewport; this is not a navigation sample')
        r.completeRedraw()
        r.windows.processPostedMessages()
        out['steps_ms'].append((time.perf_counter()-start)*1000.)
    out['end_qpc_ms'] = time.perf_counter()*1000.
    out['after'] = counters(root)
    out['median_sync_ms'] = statistics.median(out['steps_ms'])
    out['p95_sync_ms'] = sorted(out['steps_ms'])[18]
    assert out['before'] == out['after'], 'Navigation changed placements, preparation, preview or retained buffers'
    assert abs(out['qpc_check_ms']) < 20., 'The Python and Max QPC clocks did not agree'
    assert not str(root.interactionError), str(root.interactionError)
    out['status'] = 'pass'
except Exception:
    out['status'] = 'failed'
    out['error'] = traceback.format_exc()
finally:
    if base is not None:
        r.viewport.setTM(base)
        r.completeRedraw()
    (host / ('navigation-' + case + '.json')).write_text(json.dumps(out, indent=2), encoding='utf-8')
