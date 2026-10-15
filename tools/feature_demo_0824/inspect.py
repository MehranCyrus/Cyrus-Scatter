from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.MCPFixtureDir));assert out.name.startswith('foundation-roadmap-feature-demo0824-')
root=r.getNodeByName('CYRUS 0.82.4 | SELECT ME - five feature layers').baseObject
data={'layers':[{'name':str(root.layerNames[i]),'count':int(leaf.generatedCount),'mask':str(leaf.meshMaskPayload())}
    for i,leaf in enumerate(root.layerObjects)],'text':{},'curvature':{},'sources':[]}
for name in ['TITLE','Plane heading','Usage']:
    node=r.getNodeByName(name);bounds=r.nodeGetBoundingBox(node,r.matrix3(1))
    data['text'][name]={'properties':{str(k):str(r.getProperty(node,k)) for k in r.getPropNames(node)},
        'position':list(node.pos),'bounds':[list(v) for v in bounds]}
mesh=r.snapshotAsMesh(r.getNodeByName('02 MOUNTAIN | Data Channel Curvature to Channel 3'))
values=[float(r.meshop.getMapVert(mesh,3,i).x) for i in range(1,int(r.meshop.getNumMapVerts(mesh,3))+1)]
data['curvature']={'min':min(values),'max':max(values),'nonconstant':min(values)!=max(values)}
data['sources']=[{'name':str(n.name),'width':float(n.width),'height':float(n.height)} for n in r.objects if str(r.classOf(n))=='Pyramid']
data['cameras']=[{'name':str(n.name),'position':list(n.pos),'fov':float(n.fov),'tm':str(n.transform)} for n in r.cameras]
data['viewport']={'camera':str(r.viewport.getCamera()),'tm':str(r.viewport.getTM()),'selection':[str(n.name) for n in r.selection],
    'plane_position':list(r.getNodeByName('01 FLAT PLANE | Channel 2 = left-to-right ramp').pos)}
(out/'demo-inspection.json').write_text(json.dumps(data,indent=2)+'\n')
