from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.MCPFixtureDir));assert out.name.startswith('foundation-roadmap-orientation0830-')
root=r.OrientationRoot;leaf=root.layerObjects[0]
record={'rows':[len(x) for x in root.groupSnapshotRows],'radii':str(root.procPublishedRadii[0][0]),'row':str(root.groupSnapshotRows[0][0]),'auto':str(leaf.sourceAutoRadius),'follow':str(leaf.sourceFollowScale),'geometry':str(leaf.procRadiusGeometry(leaf.validSources(),rows=root.groupSnapshotRows[0])),'snapshot':str(leaf.cacheSnapshot())}
(out/'heavy-inspect.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
