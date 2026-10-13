"""Current Auto Radius/paired-spacing contract in an owned, matched Max host."""
from pathlib import Path
import hashlib
import itertools
import json
import math
import traceback
import uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
report={'checks':[], 'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text())}
receipt=OUT/('auto-radius-'+uuid.uuid4().hex+'.json')

def save(): receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(ok,label):
    report['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok: raise AssertionError(label)
def ms(code): return r.execute('(\n'+code+'\n)')
def arr(items): return r.Array(*items)
def denied(action,text,label):
    try: action()
    except Exception as e: check(text.lower() in str(e).lower(),label)
    else: check(False,label)
def pairs(): return [list(map(float,p)) for p in r.AutoRoot.procPublishedRadii[0]]
def placements():
    return [[str(row[2]),int(row[1]),int(row[5]),*[list(map(float,v)) for v in (row[0].row1,row[0].row2,row[0].row3,row[0].row4)]]
            for row in r.AutoRoot.groupSnapshotRows[0]]
def update():
    r.AutoRoot.procManualRevision+=1
    return r.AutoRoot.evaluateProcedural()
def close_pair(a,b): return all(math.isclose(x,y,rel_tol=2e-6,abs_tol=2e-5) for x,y in zip(a,b))

try:
    r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest();r.fileIn(str(script))
    check(int(r.cyrusSplineBandVersion())==9 and int(r.cyrusProceduralPublicationVersion())==2,
          'Current native Band and paired-radius publication contracts are loaded')
    ms('''
global AutoBasis=matrix3 [-2,1,.5] [0,3,1] [1,0,4] [10000,-3000,200]
global AutoRows=#(#(AutoBasis,1,"c:7",1,[.2,.3,.5],0L,false,2))
global AutoSpecs=#(#(2,123.,true,[-2,-1,0],[3,4,9]))
''')
    basis=[list(map(float,v)) for v in (r.AutoBasis.row1,r.AutoBasis.row2,r.AutoBasis.row3)]
    corners=[tuple(sum(v[j]*basis[j][axis] for j in range(3)) for axis in range(3))
             for v in itertools.product((-2.,3.),(-1.,4.),(0.,9.))]
    expected=[max(math.hypot(*v[:2]) for v in corners),max(math.hypot(*v) for v in corners)]
    empty=arr([])
    native=list(map(float,r.cyrusProceduralRadii(r.AutoRows,r.AutoSpecs,empty,empty,empty)[0]))
    check(close_pair(native,expected),'Off-center, mirrored, nonuniform and sheared final bases match independent corner arithmetic')
    check(all(math.hypot(*(sum(v[j]*basis[j][axis] for j in range(3)) for axis in range(3)))<=native[1]+1e-4
              for v in itertools.product((-2.,-.5,1.,3.),(-1.,1.,4.),(0.,3.,9.))),
          'Independent interior samples lie inside the conservative 3D bound')
    ms('AutoRows[1][1].row4=[-9000,7000,-800]')
    check(close_pair(list(r.cyrusProceduralRadii(r.AutoRows,r.AutoSpecs,empty,empty,empty)[0]),expected),
          'World translation cannot contaminate either radius')
    absolute=r.cyrusProceduralRadii(r.AutoRows,r.AutoSpecs,arr(['c:7']),arr([1]),arr([2.5]))[0]
    multiplied=r.cyrusProceduralRadii(r.AutoRows,r.AutoSpecs,arr(['c:7']),arr([2]),arr([.25]))[0]
    check(close_pair(list(absolute),[2.5,2.5]) and close_pair(list(multiplied),[x*.25 for x in expected]),
          'Stable-ID absolute override sets both metrics; multiplier scales both once')
    check(ms('''local a=cyrusProceduralRadii AutoRows #(#(1,3.,false,[0,0,0],[0,0,0])) #() #() #()
local b=cyrusProceduralRadii #(#(scaleMatrix [-2,3,.1],1,"c:7",1,[.2,.3,.5],0L,false,2)) #(#(1,3.,true,[0,0,0],[0,0,0])) #() #() #()
a[1][1]==3. and a[1][2]==3. and b[1][1]==9. and b[1][2]==9.'''), 'Manual Follow Scale on/off retains scalar behavior in both metrics')
    check(ms('''local result=cyrusProceduralRadii #(#(matrix3 [0,0,0] [0,0,0] [0,0,0] [9,9,9],1,"c:7",1,[.2,.3,.5],0L,false,2)) AutoSpecs #() #() #()
result[1][1]==0. and result[1][2]==0.'''),'A finite collapsed placement basis is valid and produces zero radius')
    denied(lambda:ms('cyrusProceduralRadii #() #(#(2,0.,false,[3,0,0],[2,0,0])) #() #() #()'),
           'Invalid source bounds','Invalid admitted Auto bounds fail even with no sampled rows')
    denied(lambda:ms('cyrusProceduralRadii AutoRows #(3.) #(true) #() #() #()'),
           'argument','Retired six-argument radius transport is rejected')

    ms('''
global AutoModel=mesh vertices:#([0,0,0],[3,0,12],[0,4,0],[3,4,12],[1000,1000,1000]) faces:#([1,2,3],[2,4,3])
global AutoNode=AminScatterObject name:"Auto radius qualification"
global AutoRoot=AutoNode.baseObject
AutoRoot.updateMode=1;AutoRoot.autoRender=false;AutoRoot.newLayer()
global AutoLeaf=AutoRoot.selectedLayer()
global AutoReceiver=plane width:500 length:500 widthsegs:1 lengthsegs:1
AutoRoot.setLayerSurfaces AutoLeaf #(AutoReceiver)
AutoLeaf.sources=#(AutoModel);AutoLeaf.amount=80;AutoLeaf.scaleMinimum=1.;AutoLeaf.scaleMaximum=1.
AutoLeaf.tiltDegrees=0.;AutoLeaf.sourceScales=#(2.);AutoLeaf.sourceRadiiWU=#(7.);AutoLeaf.sourceFollowScale=#(false)
AutoLeaf.setSourceRadius #{1} true kind:4
AutoRoot.evaluateProcedural()
''')
    check(bool(r.cyrusSourceSupportsAuto(r.AutoModel)), 'Editable Mesh has an explicit Auto capability')
    info=r.cyrusSourceGeometryInfo(arr([r.AutoModel]))[0]
    check(list(info[3])==[0.,0.,0.] and list(info[4])==[3.,4.,12.], 'Source bounds exclude an extreme orphan vertex')
    check(len(pairs())==80 and all(close_pair(p,[10.,26.]) for p in pairs()),
          'Published Auto XY/3D pair includes final source scale exactly once')
    counts=list(map(int,r.cyrusSourceGeometryStats()))
    update();r.cyrusSourceGeometryInfo(arr([r.AutoModel]));r.redrawViews()
    after=list(map(int,r.cyrusSourceGeometryStats()))
    check(after[1]==counts[1] and after[2]>counts[2], 'Unchanged Update, repeated inspection and redraw reuse one source extraction')
    old_rows=placements();old_radii=pairs();epoch=int(r.AutoRoot.procEpoch)
    r.AutoLeaf.setSourceRadius(r.BitArray(1),True,kind=3)
    r.AutoRoot.radiusDisplayMetric=2;r.AutoRoot.refreshDisplay()
    check(int(r.AutoRoot.procEpoch)==epoch and placements()==old_rows and pairs()==old_radii and
          len(r.AutoLeaf.radiusPreview)==240 and int(r.AutoLeaf.radiusDisplayCount())==240,
          '3D display creates three rings per published instance without solving or changing radii')
    radius_points=r.AutoLeaf.radiusPreview[0][0];center=r.AutoRoot.groupSnapshotRows[0][0][0].row4
    check(all(math.isclose(float(r.distance(v,center)),26.,rel_tol=2e-5) for v in radius_points),
          'Displayed 3D rings agree with the published collision radius')
    r.AutoModel.objectOffsetPos=r.Point3(10,0,0)
    counts=list(map(int,r.cyrusSourceGeometryStats()))
    changed=r.cyrusSourceGeometryInfo(arr([r.AutoModel]))[0]
    check(list(changed[3])==[10.,0.,0.] and list(changed[4])==[13.,4.,12.] and int(r.cyrusSourceGeometryStats()[1])==counts[1]+1,
          'Synchronous object-offset notification invalidates pivot-local bounds once')
    r.AutoRoot.refreshDisplay()
    check(pairs()==old_radii and placements()==old_rows and int(r.AutoRoot.procEpoch)==epoch,
          'Manual pending source geometry keeps the complete published placements and radii')
    update()
    check(all(close_pair(p,[2*math.hypot(13,4),2*math.hypot(13,4,12)]) for p in pairs()),
          'Explicit Update publishes off-center source geometry and corresponding radii together')
    r.AutoLeaf.setSourceRadius(r.BitArray(1),False,kind=4);update()
    check(all(p==[7.,7.] for p in pairs()) and not r.AutoLeaf.sourceFollows(1),
          'Returning to Manual restores the saved radius and Follow Scale setting')
    r.AutoLeaf.setSourceRadius(r.BitArray(1),True,kind=4);update()
    epoch=int(r.AutoRoot.procEpoch);old_rows=placements();old_radii=pairs()
    ms('''global AutoEmptyMesh=mesh vertices:#() faces:#()
AutoLeaf.sources=#(AutoModel,AutoEmptyMesh);AutoLeaf.sourceAutoRadius=#(true,true);AutoLeaf.sourceWeights=#(1.,1e-20)''')
    builds=int(r.AutoLeaf.procPreparedBuilds)
    denied(update,'Auto Radius','An almost-never-selected invalid source fails before sampling')
    check(int(r.AutoLeaf.procPreparedBuilds)==builds and int(r.AutoRoot.procEpoch)==epoch and placements()==old_rows and pairs()==old_radii,
          'Invalid required bounds retain the preceding complete publication')
    r.AutoLeaf.sourceWeights=arr([1.,0.]);update()
    check(len(pairs())==80 and int(r.AutoRoot.procPublishedMetadata[0][3][1][0])==0,
          'A zero-weight invalid Auto source stays dormant without inspecting its contents')
    ms('''AutoLeaf.diversityMode=3;AutoLeaf.addStroke (rectangle width:300 length:300)
AutoLeaf.patternWidths=#(100.);AutoLeaf.setStrokeSelection 1 2 #(AutoModel);AutoLeaf.sourceWeights=#(1.,1.)''')
    update()
    check(len(pairs())>0,'An unassigned invalid Auto source cannot block a different Band lottery')
    ms('AutoLeaf.setStrokeSelection 1 2 #(AutoEmptyMesh);AutoLeaf.strokeStrengths[1]=0.')
    update();check(not pairs(),'Zero-contribution Bands do not require dormant Auto geometry')
    ms('AutoLeaf.strokeStrengths[1]=1.')
    denied(update,'Auto Radius','Activating the invalid source Band requires usable geometry before sampling')
    ms('AutoLeaf.setStrokeSelection 1 2 #(AutoModel);AutoLeaf.sourceWeights[2]=0.;AutoModel.scale=[0,1,1]')
    denied(update,'singular','A required singular source extraction never substitutes radius zero')
    ms('AutoModel.scale=[1,1,1];AutoLeaf.sourceAutoRadius[1]=false')
    update();check(len(pairs())>0,'Manual remains usable after Auto extraction is corrected')
    ms('''global AutoUnknown=teapot radius:2
AutoLeaf.sources=#(AutoModel,AutoUnknown);AutoLeaf.sourceAutoRadius=#(false,false)''')
    denied(lambda:r.AutoLeaf.setSourceRadius(r.BitArray(1,2),True,kind=4),'unavailable',
           'Unsupported source capability rejects a mixed selection before any radius-mode writes')
    check(not any(list(r.AutoLeaf.sourceAutoRadius)), 'Failed multi-selection Auto change is atomic')
    ms('''AutoLeaf.sources=#(AutoModel);AutoLeaf.sourceAutoRadius=#(true);AutoLeaf.sourceWeights=#(1.)
AutoLeaf.sourceRadiiWU=#(7.);AutoLeaf.setStrokeSelection 1 2 #(AutoModel)''');update()
    old_radii=pairs();old_rows=placements();node_handle=int(r.AutoNode.handle)
    scene=OUT/('auto-radius-'+uuid.uuid4().hex+'.max');r.saveMaxFile(str(scene),quiet=True)
    r.loadMaxFile(str(scene),quiet=True)
    r.AutoNode=r.maxOps.getNodeByHandle(node_handle);r.AutoRoot=r.AutoNode.baseObject;r.AutoLeaf=r.AutoRoot.layerObjects[0]
    r.AutoModel=r.AutoLeaf.sources[0];update()
    check(bool(r.AutoLeaf.sourceAutoRadius[0]) and float(r.AutoLeaf.sourceRadiiWU[0])==7. and placements()==old_rows and
          all(close_pair(a,b) for a,b in zip(pairs(),old_radii)),'Current-schema save/reopen preserves Auto, saved Manual settings, identities and full transforms')
    report['geometry_stats']=list(map(int,r.cyrusSourceGeometryStats()))
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally: save()
if not report['passed']:raise RuntimeError(report['error'])
