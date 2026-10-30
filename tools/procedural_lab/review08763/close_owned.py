from pathlib import Path
from pymxs import runtime as r
import json,os
out=Path(str(r.GardenRun)).resolve()
assert out.name=='host-01' and out.parent.name=='interaction-review-08763-20261029-01'
assert (out/'loaded-identity.json').is_file()
process=os.getpid()
assert int(process)==json.loads((out/'launch.json').read_text())['pid']
r.quitMax(r.Name('noPrompt'))
