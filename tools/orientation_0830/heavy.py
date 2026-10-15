"""Bounded terrain/instance reuse, final radius and GC-resource measurements."""
from pathlib import Path
import json,sys,time,statistics,math,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-orientation0830-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
RUN=str(time.time_ns());result={'status':'running','checks':[],'runs':[]};target=OUT/('heavy-'+RUN+'.json')
def save():target.write_text(json.dumps(result,indent=2),encoding='utf-8')
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def counters():
 return {'orientation':[int(x) for x in r.cyrusOrientationStats()],
  'receiver':[[int(x) for x in leaf.receiverCacheStats()] for leaf in root.layerObjects],
  'prepare':[int(leaf.procPreparedBuilds) for leaf in root.layerObjects],
  'private_bytes':int(r.dotNetClass('System.Diagnostics.Process').GetCurrentProcess().PrivateMemorySize64)}
def solve(label):
 before=counters();start=time.perf_counter();root.refreshAll();elapsed=(time.perf_counter()-start)*1000
 check(all(str(leaf.cacheSnapshot()[3])=='' for leaf in root.layerObjects),'Update has no preview failure: '+label)
 result['runs'].append({'label':label,'milliseconds':elapsed,'before':before,'after':counters()});save();return elapsed
def provenance():
 # Hash all nonorientation fields, not merely accepted counts.
 import hashlib
 data=[]
 for rows in root.groupSnapshotRows:
  data.append([[str(x[2]),int(x[1]),int(x[3]),[float(x[0].row4[j]) for j in range(3)],
                [float(x[4][j]) for j in range(3)],int(x[5]),bool(x[6]),int(x[7])] for x in rows])
 return hashlib.sha256(json.dumps(data,separators=(',',':')).encode()).hexdigest()
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('meters');r.units.SystemScale=1;r.gc()
  memory_before=[int(x) for x in r.cyrusOrientationStats()];result['normal_before']=memory_before
  r.execute('''global OrientationNode,OrientationRoot,OrientationLeaf,HeavyTerrain
   HeavyTerrain=plane name:"Heavy procedural terrain" width:1000 length:1000 widthsegs:300 lengthsegs:300
   convertToMesh HeavyTerrain
   for i=1 to getNumVerts HeavyTerrain do (local p=getVert HeavyTerrain i;p.z=80*sin(p.x*0.25)*cos(p.y*0.25);setVert HeavyTerrain i p)
   update HeavyTerrain
   OrientationNode=AminScatterObject name:"Heavy orientation fixture";OrientationRoot=OrientationNode.baseObject
  ''')
  root=r.OrientationRoot;root.updateMode=1;root.autoRender=False;root.previewBudget=3000
  model=r.pyramid(name='Heavy asymmetric source',width=1,depth=2,height=8,pos=r.Point3(-600,0,0))
  r.convertToMesh(model) # Auto Radius qualifies evaluated mesh types, not Pyramid's custom class.
  for i in range(2):
   root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(r.HeavyTerrain));leaf.sources=r.Array(model);leaf.ensureSourceRows()
   leaf.amount=30000;leaf.procPopulation=1;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
   leaf.advancedAxes=True;leaf.rotZMin=0;leaf.rotZMax=0;leaf.wholeScaleMin=1;leaf.wholeScaleMax=1;leaf.sourceRadiiWU=r.Array(0.);leaf.sourceAutoRadius=r.Array(False)
  r.OrientationLeaf=root.layerObjects[0];solve('cold 60000 placements / 180000 faces / two layers')
  check([len(x) for x in root.groupSnapshotRows]==[30000,30000],'Heavy fixture publishes both full populations')
  r.gc();after=counters();expected=180000*24*2
  result['normal_after_gc']=after['orientation'];check(after['orientation'][3]-memory_before[3]==expected and after['orientation'][4]-memory_before[4]==2,'Retained normal allocation is two bounded 180000-face snapshots (8640000 bytes)')
  signature=provenance();stable=[fingerprint(x) for x in root.groupSnapshotRows];times=[]
  for i in range(8):
   before=counters();r.OrientationLeaf.orientationBlend=float(i*12);times.append(solve('blend '+str(i)))
   after=counters();check(after['orientation'][0]==before['orientation'][0] and after['receiver'][0][0]==before['receiver'][0][0] and after['receiver'][1][0]==before['receiver'][1][0],'Heavy blend edit reuses all candidates and normal snapshots')
   check(provenance()==signature and fingerprint(root.groupSnapshotRows[1])==stable[1],'Heavy blend edits preserve provenance and complete unchanged-layer rows')
  result['warm_median_ms']=statistics.median(times);result['warm_p95_ms']=max(times)
  # Small analytical spacing fixture exercises final oriented Auto Radius in-host.
  for leaf in root.layerObjects:leaf.amount=160
  first=root.layerObjects[0];first.alignNormal=False;first.orientationMode=2;first.orientationX=0;first.orientationY=1;first.orientationZ=0
  first.sourceAutoRadius=r.Array(True);first.sourceRadiiWU=r.Array(1.);first.procSelfEnabled=False
  solve('upright Auto Radius');upright=[list(x) for x in root.procPublishedRadii[0]]
  first.orientationZ=1;first.orientationY=0;solve('horizontal model up / Auto Radius');tilted=[list(x) for x in root.procPublishedRadii[0]]
  check(len(upright)==len(tilted)==160 and all(float(b[0])>float(a[0])*2 for a,b in zip(upright,tilted)),'Auto XY Radius uses the final oriented tall source bounds')
  first.procSelfEnabled=True;first.procSelfMultiplier=8;first.procSelfGap=0.;first.procSelfPlanar=True;solve('oriented planar spacing')
  rows=list(root.groupSnapshotRows[0]);radii=list(root.procPublishedRadii[0]);gap_failed=False
  for i in range(len(rows)):
   for j in range(i):
    a=rows[i][0].row4;b=rows[j][0].row4
    if math.hypot(float(a.x-b.x),float(a.y-b.y))+1e-4 < 8*(float(radii[i][0])+float(radii[j][0])):gap_failed=True
  check(not gap_failed and len(rows)<160,'Accepted rows satisfy spacing computed from final oriented XY radii')
  # Direct copied-data key guards small values that MAXScript display strings round.
  a=r.Array(2,False,0.,r.Point3(1,1,0),r.Point3(0,0,0));b=r.Array(2,False,0.,r.Point3(1.000001,1,0),r.Point3(0,0,0))
  check(str(r.cyrusOrientationKey(a,r.Array(1)))!=str(r.cyrusOrientationKey(b,r.Array(1))),'Orientation keys preserve small representable direction changes')
  r.resetMaxFile(r.Name('noPrompt'));root=None;r.OrientationNode=None;r.OrientationRoot=None;r.OrientationLeaf=None;r.gc();r.gc()
  released=[int(x) for x in r.cyrusOrientationStats()];result['normal_after_reset_gc']=released
  check(released[3]<=memory_before[3] and released[4]<=memory_before[4],'Retired scene releases all new normal snapshots after GC')
  r.CyrusPerfHeadless=False
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
