"""A Manual display switch may not borrow pending source geometry."""
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
receipt=OUT/('source-revision-'+uuid.uuid4().hex+'.json')


def save(): receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(ok,label):
    report['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok: raise AssertionError(label)
def ms(code): return r.execute('(\n'+code+'\n)')
def signature(node): return str(r.cyrusSourceGeometryInfo(r.Array(node))[0][2])


try:
    r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest();r.fileIn(str(script))
    ms('''
global RevisionModel=box width:10 length:20 height:30 pos:[400,0,0]
global RevisionNode=AminScatterObject name:"Published source revision"
global RevisionRoot=RevisionNode.baseObject
RevisionRoot.updateMode=1;RevisionRoot.autoRender=false;RevisionRoot.newLayer()
global RevisionLeaf=RevisionRoot.selectedLayer()
RevisionRoot.setLayerSurfaces RevisionLeaf #(plane width:200 length:200)
RevisionLeaf.sources=#(RevisionModel);RevisionLeaf.amount=100;RevisionRoot.setGroupDisplay 4
RevisionRoot.evaluateProcedural()
''')
    root,leaf,source=r.RevisionRoot,r.RevisionLeaf,r.RevisionModel
    epoch=int(root.procEpoch);rows=str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'revision'))
    before=signature(source)
    source.wirecolor=r.color(4,120,220);source.material=r.standardMaterial(diffuse=r.color(200,60,70))
    check(signature(source)==before,'Identification and render material edits preserve the geometry signature')
    source.height=60.
    check(signature(source)!=before,'Changed source dimensions produce a different content signature')
    previous=leaf.cachedPoints
    leaf.viewportMode=3
    rejected=False
    try: root.procEnsureDisplay(pending=True)
    except Exception as error: rejected='Source geometry is pending' in str(error)
    check(rejected and leaf.cachedPoints==previous and int(root.procEpoch)==epoch and
          str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'revision'))==rows,
          'Manual Mesh switch rejects pending source geometry and retains the complete published placement/preview')
    leaf.viewportMode=1;leaf.showCenters=True;root.procEnsureDisplay(pending=True)
    check(int(root.procEpoch)==epoch and int(leaf.cachedPointCount)==100,
          'Centers can still use the published placement positions without reading changed source geometry')
    leaf.showCenters=False
    rejected=False
    try: root.procEnsureDisplay(pending=True)
    except Exception as error: rejected='Source geometry is pending' in str(error)
    check(rejected,'Point Cloud also rejects an uncached pending source representation')
    source.height=30.;root.procEnsureDisplay(pending=True)
    check(int(root.procEpoch)==epoch and int(leaf.cachedPointCount)>100,
          'Restoring the exact published geometry admits Point Cloud without a placement solve')
    leaf.viewportMode=3;root.procEnsureDisplay(pending=True)
    check(int(root.procEpoch)==epoch and int(r.cyrusPreviewFaces(leaf.cachedPoints))==1200,
          'An unchanged source can prepare Mesh without consuming a pending recipe')
    # Explicitly deliver the relevant notification as well as changing geometry;
    # the display content check above did not rely on callback timing.
    source.height=60.;leaf.procExternalChanged(r.Name('geometryChanged'),r.Array(source));root.evaluateProcedural()
    check(int(root.procEpoch)==epoch+1 and str(root.procPublishedMetadata[0][3][0][2])==signature(source),
          'Explicit Update publishes the new geometry signature with the complete successor')
    check(ms('''local model=mesh vertices:#([-2,-3,-4],[5,-3,-4],[-2,7,9],[1000,1000,1000]) faces:#([1,2,3])
local info=(cyrusSourceGeometryInfo #(model))[1]
info[1]==1 and info[4]==[-2,-3,-4] and info[5]==[5,7,9]'''),
          'Face-referenced pivot-local bounds exclude orphan vertices')
    ms('with animate on (at time 0 RevisionModel.height=60.;at time 10 RevisionModel.height=90.)')
    r.sliderTime=0;animated=signature(source);r.sliderTime=10
    check(signature(source)!=animated,'Relevant source animation changes the geometry signature')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally: save()
if not report['passed']:raise RuntimeError(report['error'])
