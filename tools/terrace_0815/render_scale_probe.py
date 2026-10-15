"""Compare native displayed triangles with Particle Flow render geometry."""
from pathlib import Path
import json,traceback,hashlib
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.name.startswith('foundation-terrace0815-candidate')
run=1
while (OUT/('render-scale-%02d.json'%run)).exists():run+=1
data={'cases':[],'status':'started'};report=OUT/('render-scale-%02d.json'%run)
def xyz(v):return [float(v.x),float(v.y),float(v.z)]
def bounds(points):return [[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]
try:
    r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms';r.fileIn(str(script));data['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest()
    receiver=r.plane(width=100,length=100)
    source=r.box(name='Scaled source witness',width=10,length=20,height=30,pos=r.Point3(500,700,0));source.renderable=False
    node=r.AminScatterObject(name='Render scale witness');root=node.baseObject;root.updateMode=1;root.autoRender=True
    root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(receiver));leaf.sources=r.Array(source);leaf.amount=1
    leaf.scaleMinimum=1;leaf.scaleMaximum=1;leaf.yawMinimum=0;leaf.yawMaximum=0;leaf.alignNormal=False;root.setGroupDisplay(3)
    for scale in [(1,1,1),(2,3,4),(-2,3,4)]:
        source.scale=r.Point3(*scale);source.objectOffsetPos=r.Point3(4,-3,7);root.refreshAll();original=str(source.transform)
        if str(leaf.previewError):raise RuntimeError(str(leaf.previewError))
        native=[xyz(p) for face in r.cyrusPreviewTriangles(leaf.cachedPoints,100) for p in list(face)[:3]]
        r.CyrusPFBuild()
        pf=next(n for n in r.CyrusPFNodes if str(r.classOf(n))=='PF_Source')
        mesh=pf.getParticleShape(1);tm=pf.getParticleTM(1)
        actual=[xyz(r.getVert(mesh,i)*tm) for i in range(1,mesh.numverts+1)]
        a=bounds(native);b=bounds(actual);error=max(abs(x-y) for aa,bb in zip(a,b) for x,y in zip(aa,bb))
        data['cases'].append({'source_scale':scale,'native_bounds':a,'render_bounds':b,'maximum_error':error,'render_tm':str(tm),'source_unchanged':str(source.transform)==original})
        r.delete(mesh);r.CyrusPFClear()
    data['status']='complete';data['parity']=all(c['maximum_error']<.001 for c in data['cases'])
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:report.write_text(json.dumps(data,indent=2)+'\n')
if data['status']!='complete':raise RuntimeError(data['error'])
