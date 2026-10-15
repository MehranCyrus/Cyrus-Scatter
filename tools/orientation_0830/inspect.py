from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.MCPFixtureDir)).resolve();assert out.name.startswith('foundation-roadmap-orientation0830-')
leaf=r.OrientationLeaf;root=r.OrientationRoot
data={'mode':int(leaf.orientationMode),'target':str(leaf.orientationTarget),'epoch':int(root.procEpoch),'cache':str(leaf.cacheSnapshot()),'status':str(root.allStatus())}
data.update(time=str(r.currentTime),payload=str(leaf.orientationPayload()),input_time=str(leaf.inputTimeStats()),time_owners=str(r.CyrusTimeOwners),last_error=str(r.CyrusPointLastError))
(out/'inspect.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
