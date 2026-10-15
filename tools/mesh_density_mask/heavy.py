"""Bounded heavy geometry/population, receiver reuse and idle counters."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-meshmask-')
data={'status':'started','checks':[],'timings_ms':{}}
def save(): (OUT/'mesh-mask-heavy.json').write_text(json.dumps(data,indent=2)+'\n')
def check(value,label):
    data['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def solve(label):
    root.procManualRevision+=1;t=time.perf_counter();root.evaluateProcedural();data['timings_ms'][label]=(time.perf_counter()-t)*1000;save()
try:
    r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
    node=r.AminScatterObject(name='Heavy mesh mask');root=node.baseObject;root.updateMode=1;root.autoRender=False
    dense=r.Plane(name='180000 faces channel field',length=100,width=100,lengthsegs=300,widthsegs=300);r.convertToMesh(dense)
    other=r.Plane(name='Independent receiver field',length=100,width=100,lengthsegs=10,widthsegs=10,pos=r.Point3(120,0,0));r.convertToMesh(other)
    for receiver in [dense,other]:
        for i in range(1,int(r.meshop.getNumMapVerts(receiver,1))+1):
            uv=r.meshop.getMapVert(receiver,1,i);r.meshop.setMapVert(receiver,1,i,r.Point3(float(uv.x),1,0))
        r.update(receiver)
    root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(dense,other));leaf.addPointSource()
    leaf.amount=200000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False
    solve('disabled_200000');check(int(leaf.generatedCount)==200000,'Heavy baseline admits 200000 candidates across two receivers')
    leaf.meshMaskEnabled=True;leaf.meshMaskChannel=1;solve('ramp_200000')
    check(97000<int(leaf.generatedCount)<103000,'Heavy direct ramp mask interpolates 180200 geometry faces and thins 200000 candidates')
    stats=list(leaf.receiverCacheStats());count=int(leaf.generatedCount);binding=str(leaf.procBindingKey)
    for i in range(1,int(r.meshop.getNumMapVerts(other,1))+1):r.meshop.setMapVert(other,1,i,r.Point3(0,1,0))
    r.update(other);solve('one_receiver_channel_edit');after=list(leaf.receiverCacheStats())
    check(int(leaf.generatedCount)<count and 47000<int(leaf.generatedCount)<53000,'A channel edit affects only its own receiving surface')
    check(after[0]==stats[0]+1 and after[1]>=stats[1]+1,'Unchanged receiver candidate cache is reused after another receiver channel edit')
    check(str(leaf.procBindingKey)==binding,'Heavy channel-only edit preserves shared Edit geometry binding')
    data['geometry_faces']=int(dense.numfaces)+int(other.numfaces);data['candidates']=200000;data['accepted']=int(leaf.generatedCount)
    r.MeshHeavyNode=node;r.MeshHeavyRoot=root;r.MeshHeavyLeaf=leaf;r.MeshHeavyReceiver=dense
    root.updateMode=2;root.refreshAll();r.CyrusPointSync()
    r.MeshHeavyCount=leaf.generatedCount
    data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise
