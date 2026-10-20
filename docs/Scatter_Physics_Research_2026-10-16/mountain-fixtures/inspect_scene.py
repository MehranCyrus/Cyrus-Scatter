from pathlib import Path
from pymxs import runtime as r
import json
out=Path(str(r.CPLTestDir));data={'system_type':str(r.units.SystemType),'system_scale':float(r.units.SystemScale),'nodes':[]}
for node in r.objects:
    row={'name':str(node.name),'class':str(r.classOf(node)),'handle':int(r.getHandleByAnim(node)),'hidden':bool(node.isHidden),'position':list(node.pos)}
    if str(r.classOf(node))=='CyrusPhysicsLab':
        row.update(receiver=str(node.receiverNode),sources=[str(n.name) for n in node.sourceNodes],colliders=[str(n.name) for n in node.colliderNodes])
        row['stats']=json.loads(str(r.cplStats(node.physicsDocument)))
        safe='node-'+str(int(r.getHandleByAnim(node)))
        r.cplExportFile(node.physicsDocument,str(out/(safe+'.json')))
        row['export']=safe+'.json'
    else:
        try:
            b=r.nodeGetBoundingBox(node,r.matrix3(1));row['bounds']=[list(v) for v in b]
            m=r.snapshotAsMesh(node);row['vertices']=int(m.numverts);row['faces']=int(m.numfaces)
        except Exception as e:row['inspection_error']=str(e)
    data['nodes'].append(row)
(out/'scene-inventory.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
