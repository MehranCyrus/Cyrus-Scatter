"""Export the real receiver footprints and planting guides for design analysis."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-candidate')
data={'receivers':[],'guides':[],'guide_notes':[],'render_geometry':[],'status':'started'}
report=OUT/'scene-layout-data.json'
if report.exists():
    run=1
    while (OUT/('scene-layout-data-previous-%02d.json'%run)).exists():run+=1
    (OUT/('scene-layout-data-previous-%02d.json'%run)).write_bytes(report.read_bytes())
def xyz(p):return [float(p.x),float(p.y),float(p.z)]
def save():(OUT/'scene-layout-data.json').write_text(json.dumps(data)+'\n',encoding='utf-8')
try:
    r.CyrusPerfHeadless=True
    r.loadMaxFile(str(ROOT/'Test Scene/Terraces_0815/Terraces_0815_Prepared.max'),quiet=True,useFileUnits=True)
    root=r.getNodeByName('Cyrus Scatter001').baseObject;root.updateMode=1;root.autoRender=False
    for node in root.layerObjects[0].validSurfaces():
        mesh=r.snapshotAsMesh(node)
        data['receivers'].append({'name':str(node.name),'area':float(r.aminScatterSurfaceArea(r.Array(node))),
            'uv':bool(r.meshop.getMapSupport(mesh,1)),
            'vertices':[xyz(r.getVert(mesh,i)) for i in range(1,mesh.numverts+1)],
            'faces':[xyz(r.getFace(mesh,i)) for i in range(1,mesh.numfaces+1)]})
        r.delete(mesh);save()
    for node in r.objects:
        if str(node.name).startswith('spl'):
            curves=[]
            try:
                for i in range(1,int(r.numSplines(node))+1):
                    curves.append({'closed':bool(r.isClosed(node,i)),
                        'knots':[xyz(r.getKnotPoint(node,i,k)) for k in range(1,int(r.numKnots(node,i))+1)]})
            except Exception as error:data['guide_notes'].append({'name':str(node.name),'reason':str(error)})
            data['guides'].append({'name':str(node.name),'curves':curves})
        if node.renderable and not node.isHidden:
            data['render_geometry'].append({'name':str(node.name),'material':str(node.material),
                'class':str(r.classOf(node.baseObject)),'mods':[str(r.classOf(m)) for m in node.modifiers]})
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])
