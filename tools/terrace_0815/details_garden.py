from pathlib import Path
import json
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir));assert OUT.name.startswith('foundation-terrace0815-candidate2027-')
root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject;data={}
leaf=root.layerObjects[5];n=leaf.sources[0]
data['palm']={'info':str(r.cyrusSourceGeometryInfo(r.Array(n))),'rows':[str(row[0]) for row in root.groupSnapshotRows[5]],'autoRender':bool(leaf.autoRender),'scales':list(leaf.sourceScales),'zoffsets':list(leaf.sourceZOffsetsWU)}
data['stones']=[]
for n in r.objects:
    if str(n.name).startswith('PATH | stepping stone') and len(data['stones'])<5:data['stones'].append({'name':str(n.name),'pos':str(n.pos),'renderable':bool(n.renderable),'hidden':bool(n.isHidden),'layer_hidden':bool(n.layer.isHidden),'box':str(r.nodeGetBoundingBox(n,r.matrix3(1)))})
data['shapes']=[]
for n in r.objects:
    if n.renderable and not n.isHidden and str(r.superClassOf(n))=='shape':data['shapes'].append({'name':str(n.name),'box':str(r.nodeGetBoundingBox(n,r.matrix3(1))),'material':str(n.material)})
(OUT/'garden-details.json').write_text(json.dumps(data,indent=2)+'\n')
