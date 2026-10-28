from pathlib import Path
import json
from pymxs import runtime as r
nodes=[]
for leaf in r.WFRoot.layerObjects:
 for seq in [leaf.validSources(),leaf.validSurfaces(),leaf.interactionProxyNodes]:
  for node in seq:
   if node not in nodes:nodes.append(node)
report=[]
for node in nodes:
 report.append({'name':str(node.name),'parent':str(node.parent),'children':[str(x.name) for x in node.children],'group':bool(r.isGroupMember(node))})
 # This fixture exercises the supported independent static-geometry adapter.
 if r.isGroupMember(node):r.setGroupMember(node,False)
 r.CVStaticNode=node
 r.execute('(local frame=copy CVStaticNode.transform;with animate off (CVStaticNode.transform.controller=PRS();CVStaticNode.transform=frame;deleteKeys CVStaticNode.transform.controller #allKeys))')
 node.name=str(node.name)+"_OwnedStatic"
 node.parent=r.undefined
 for child in list(node.children):child.parent=r.undefined
r.WFRoot.refreshAll();r.CyrusPointSync()
(Path(str(r.GardenRun))/'fixture-assets.json').write_text(json.dumps(report,indent=2))
