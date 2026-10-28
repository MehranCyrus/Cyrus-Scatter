"""Arm or finish redraw observation in the private terrace fixture."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
phase = int(r.CVCaptureDirection)
result = {'phase': phase, 'status': 'running'}
try:
    if phase == 1:
        result['returned'] = bool(r.execute('PArm()'))
    elif phase == 2:
        result['returned'] = bool(r.execute('PFinish()'))
    else:
        raise ValueError('Use phase 1 to arm or phase 2 to finish')
    result['status'] = 'complete'
except Exception:
    result['status'] = 'failed'
    result['error'] = traceback.format_exc()
finally:
    (host / f'pointer-control-{phase}.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
