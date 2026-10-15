from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.MCPFixtureDir));assert out.name.startswith('foundation-roadmap-meshmask-')
data={'epoch':int(r.MeshMaskRoot.procEpoch),'before_epoch':int(r.MeshLiveEpoch),'accepted':int(r.MeshMaskLeaf.generatedCount),'dirty':bool(r.MeshMaskLeaf.dirty),'leaf_error':str(r.MeshMaskLeaf.previewError),'root_error':str(r.MeshMaskRoot.previewError),'point_error':str(r.CyrusPointLastError),'channel':int(r.MeshMaskLeaf.meshMaskChannel),'native':list(r.cyrusMeshDensityStats())}
(out/'mesh-mask-live-probe.json').write_text(json.dumps(data,indent=2)+'\n')
