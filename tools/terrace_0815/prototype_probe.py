from pathlib import Path
import json
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir));assert OUT.name.startswith('foundation-terrace0815-candidate')
n=r.getNodeByName('Scaled source witness');n.scale=r.Point3(2,3,4)
n.rotation=r.eulerAngles(13,22,41)
out={}
def vectors(points):return [[float(p.x),float(p.y),float(p.z)] for p in points]
def note(key,node):
    m=r.snapshotAsMesh(node)
    out[key]={'tm':str(node.transform),'object_tm':str(node.objectTransform),'box':vectors(r.nodeGetBoundingBox(node,node.transform)),
              'mesh_first':vectors([r.getVert(m,i) for i in range(1,4)]),'offset':str(node.objectOffsetPos)}
    r.delete(m)
note('source',n)
copy=r.snapshot(n);note('snapshot',copy);copy.transform=r.matrix3(1);note('normalized_snapshot',copy)
r.delete(copy)
(OUT/'prototype-probe.json').write_text(json.dumps(out,indent=2))
