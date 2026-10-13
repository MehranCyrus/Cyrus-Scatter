"""Initial Auto source capabilities and invalid/degenerate geometry boundaries."""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
report={'checks':[], 'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text())}
receipt=OUT/('auto-sources-'+uuid.uuid4().hex+'.json')
def check(ok,label):
    report['checks'].append({'passed':bool(ok),'label':label})
    receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    if not ok:raise AssertionError(label)
def ms(code):return r.execute('(\n'+code+'\n)')
try:
    r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest();r.fileIn(str(script))
    for label,code in (
        ('Box','box width:3 length:4 height:12'),('Sphere','sphere radius:3'),
        ('Cylinder','cylinder radius:3 height:12'),('Plane','plane width:3 length:4'),
        ('GeoSphere','geosphere radius:3'),('Cone','cone radius1:3 radius2:1 height:12'),
        ('Capsule','capsule radius:3 height:12'),
        ('Editable Mesh','convertToMesh (box width:3 length:4 height:12)'),
        ('Editable Poly','convertToPoly (box width:3 length:4 height:12)')):
        node=ms(code);info=r.cyrusSourceGeometryInfo(r.Array(node))[0]
        check(bool(r.cyrusSourceSupportsAuto(node)) and int(info[0])==1 and bool(info[5]),label+': declared Auto capability yields finite referenced bounds')
    node=ms('mesh vertices:#([0,0,0],[0,0,0],[0,0,0]) faces:#([1,2,3])')
    info=r.cyrusSourceGeometryInfo(r.Array(node))[0]
    check(int(info[0])==1 and list(info[3])==list(info[4])==[0.,0.,0.],
          'Referenced collapsed geometry is valid, distinct from an empty mesh')
    r.delete(node)
    check(ms('''local before=(cyrusSourceGeometryStats())[2]
local model=box width:4 length:5 height:20,modifier=Bend angle:0.
addModifier model modifier
local old=(cyrusSourceGeometryInfo #(model))[1]
modifier.angle=45.
local next=(cyrusSourceGeometryInfo #(model))[1]
old[3]!=next[3] and next[1]==1 and next[6] and (cyrusSourceGeometryStats())[2]==before+2'''),
          'Relevant modifier changes synchronously invalidate the evaluated source bound')
    check(ms('''local model=box(),denied=false
try(cyrusSourceGeometryInfo (for i=1 to 513 collect model))catch(denied=matchPattern (getCurrentException()) pattern:"*512*")
denied'''),'Source-count admission rejects 513 entries before mesh inspection')
    check(ms('''local node=AminScatterObject(),root=node.baseObject
root.updateMode=1;root.autoRender=false;root.newLayer()
local leaf=root.selectedLayer(),model=box width:3 length:4 height:12
root.setLayerSurfaces leaf #(plane width:500 length:500);leaf.sources=#(model);leaf.amount=40
leaf.setSourceRadius #{1} true kind:4;root.evaluateProcedural()
local epoch=root.procEpoch,cache=leaf.cachedPoints,before=root.groupSnapshotRows
delete model
local denied=false
root.procManualRevision+=1
try(root.evaluateProcedural())catch(denied=matchPattern (getCurrentException()) pattern:"*Auto Radius*")
denied and root.procEpoch==epoch and leaf.cachedPoints==cache and root.groupSnapshotRows==before'''),
          'Deleting a required Auto source cannot silently remove it from the source lottery and publish a successor')
    check(ms('''local node=AminScatterObject(),root=node.baseObject
root.updateMode=1;root.autoRender=false;root.newLayer()
local leaf=root.selectedLayer(),model=box width:3 length:4 height:12
root.setLayerSurfaces leaf #(plane width:500 length:500);leaf.sources=#(model);leaf.amount=10
leaf.setSourceRadius #{1} true kind:4;leaf.setSourceRadius #{1} true kind:3;root.evaluateProcedural()
local rows=for i=1 to 3334 collect root.groupSnapshotRows[1][1],values=for i=1 to 3334 collect root.procPublishedRadii[1][1]
local rings=leaf.radiusPreview,cache=leaf.inspectionCache,denied=false
leaf.radiusDisplayMetric=2;leaf.radiusDisplayAll=true
try(leaf.procStagePreview rows plants:root.procPublishedSources[1] placementRadiusValues:values metadata:root.procPublishedMetadata[1])catch(denied=matchPattern (getCurrentException()) pattern:"*10,000 rings*")
denied and leaf.radiusPreview==rings and leaf.inspectionCache==cache'''),
          '3D ring admission fails before point-array allocation and restores the previous radius snapshot')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
if not report['passed']:raise RuntimeError(report['error'])
