"""Direction, persistence and reuse oracles; run only in a verified owned host."""
from pathlib import Path
import json,math,time,sys,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-orientation0830-')
assert json.loads((OUT/'launch.json').read_text(encoding='utf-8'))['max_year']==2027
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
RUN=str(time.time_ns());report={'status':'running','run':RUN,'checks':[],'measurements':[]}
def save():(OUT/('orientation-core-'+RUN+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
def check(ok,label):report['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def rows():return list(r.OrientationRoot.groupSnapshotRows[0])
def vector(v):return [float(v.x),float(v.y),float(v.z)]
def stable():
 return [[str(x[2]),int(x[1]),int(x[3]),vector(x[0].row4),vector(x[4]),int(x[5]),bool(x[6]),int(x[7])] for x in rows()]
def counts():
 root=r.OrientationRoot;leaf=r.OrientationLeaf
 return {'orientation':[int(x) for x in r.cyrusOrientationStats()],'receiver':[int(x) for x in leaf.receiverCacheStats()],
         'prepare':int(leaf.procPreparedBuilds),'maps':int(leaf.procDensityBakes),'epoch':int(root.procEpoch)}
def solve(label):
 before=counts();start=time.perf_counter();r.OrientationRoot.refreshAll();elapsed=(time.perf_counter()-start)*1000
 report['measurements'].append({'label':label,'milliseconds':elapsed,'before':before,'after':counts(),'rows':len(rows())});save()
def same_candidates(before,label):
 after=counts();check(after['receiver'][0]==before['receiver'][0] and after['orientation'][0]==before['orientation'][0],label)
def dot(a,b):return float(r.dot(r.normalize(a),r.normalize(b)))
def plain(v):
 if v is None or isinstance(v,(str,int,float,bool)):return v
 a=list(v)
 if len(a)==2 and str(a[0])=='recipeObject':return {str(p[0]):plain(p[1]) for p in a[1]}
 return [plain(x) for x in a]
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('meters');r.units.SystemScale=1
  r.execute('global OrientationNode,OrientationRoot,OrientationLeaf,OrientationTarget')
  r.OrientationNode=r.AminScatterObject(name='Orientation qualification');r.OrientationRoot=r.OrientationNode.baseObject;root=r.OrientationRoot
  root.updateMode=1;root.autoRender=False
  a=r.plane(name='Tilted receiver',width=100,length=100,widthsegs=2,lengthsegs=2)
  r.rotate(a,r.eulerAngles(30,0,0))
  b=r.plane(name='Flat receiver',width=100,length=100,widthsegs=2,lengthsegs=2,pos=r.Point3(130,0,0))
  model=r.pyramid(name='Asymmetric source',width=2,depth=5,height=10,pos=r.Point3(-150,0,0))
  root.newLayer();r.OrientationLeaf=root.selectedLayer();leaf=r.OrientationLeaf
  root.setLayerSurfaces(leaf,r.Array(a,b));leaf.sources=r.Array(model);leaf.ensureSourceRows();leaf.sourceForwardAxes=r.Array(1)
  leaf.amount=2000;leaf.procPopulation=1;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
  leaf.advancedAxes=True;leaf.wholeScaleMin=1;leaf.wholeScaleMax=1;leaf.rotZMin=0;leaf.rotZMax=0
  leaf.sourceRadiiWU=r.Array(0.);leaf.sourceAutoRadius=r.Array(False);leaf.alignNormal=True
  solve('cold two receivers');check(len(rows())==2000,'Two receiver populations publish complete rows')
  baseline=stable();normal=r.Point3(0,-.5,math.sqrt(.75))
  check(all(dot(x[0].row3,normal if x[0].row4.x<60 else r.Point3(0,0,1))>1-1e-6 for x in rows()),'Default frame follows each receiver normal')
  for blend in (0.,50.,100.):
   before=counts();leaf.orientationBlend=blend;solve('normal blend '+str(blend));same_candidates(before,'Blend reuses candidate and normal snapshots')
   check(stable()==baseline,'Blend preserves complete candidate identities, positions and source assignments')
   expected=math.cos(math.radians(30*blend/100))
   check(all(abs(dot(x[0].row3,r.Point3(0,0,1))-expected)<1e-6 for x in rows() if x[0].row4.x<60),'Normal blend matches angular oracle')
  before=counts();leaf.orientationMode=2;leaf.orientationX=1;leaf.orientationY=0;leaf.orientationZ=1;solve('world heading')
  same_candidates(before,'World heading reuses candidate and normal snapshots')
  check(all(dot(x[0].row2,r.Point3(1,0,1))>1-1e-6 for x in rows()),'World direction is fully three dimensional')
  check(stable()==baseline,'World heading preserves candidate provenance')
  leaf.sourceForwardAxes=r.Array(3);solve('source +X forward')
  check(all(dot(x[0].row1,r.Point3(1,0,1))>1-1e-6 for x in rows()),'Source +X points at chosen world direction')
  leaf.sourceForwardAxes=r.Array(1);r.OrientationTarget=r.Point(name='Aim target',pos=r.Point3(50,0,80));leaf.orientationTarget=r.OrientationTarget;leaf.orientationMode=3
  solve('target');check(all(dot(x[0].row2,r.OrientationTarget.pos-x[0].row4)>1-1e-6 for x in rows()),'Look at target aims at pivot from each final position')
  before=counts();r.OrientationTarget.pos=r.Point3(60,50,100);solve('moved target');same_candidates(before,'Target motion reuses candidate and normal snapshots')
  check(stable()==baseline,'Target motion preserves candidate provenance')
  document=r.CyrusRecipeCapture(root,r.Array(leaf),'Orientation and target');data=plain(document)
  check(data['formatVersion']==2 and data['layers'][0]['settings']['orientationMode']==3,'Complete recipe stores new orientation format and mode')
  role=data['layers'][0]['settings']['orientationTarget'];check(any(x['id']==role and x['kind']=='node' for x in data['roles']),'Target saved as explicit external role')
  recipe=OUT/('orientation-'+RUN+'.csrecipe.json');r.cyrusRecipeWrite(str(recipe),document);check(plain(r.cyrusRecipeRead(str(recipe)))==data,'Format 2 complete round trip')
  scene=OUT/('orientation-'+RUN+'.max');signature=fingerprint(rows());check(r.saveMaxFile(str(scene),quiet=True),'Orientation scene saves')
  check(r.loadMaxFile(str(scene),quiet=True,useFileUnits=True),'Orientation scene reopens')
  r.OrientationNode=r.getNodeByName('Orientation qualification');r.OrientationRoot=r.OrientationNode.baseObject;r.OrientationLeaf=r.OrientationRoot.layerObjects[0];r.OrientationTarget=r.getNodeByName('Aim target');root=r.OrientationRoot;leaf=r.OrientationLeaf
  solve('reopen');check(fingerprint(rows())==signature,'Save/reopen preserves every complete placement field')
  check(int(leaf.orientationMode)==3 and leaf.orientationTarget==r.OrientationTarget,'Mode and explicit target survive save/reopen')
  before=counts();signature=fingerprint(rows());leaf.orientationTarget=None
  failed=False
  try:root.refreshAll()
  except Exception:failed=True
  check((failed or 'Look at target needs' in str(leaf.cacheSnapshot()[3])) and int(root.procEpoch)==before['epoch'] and fingerprint(rows())==signature,'Missing target rejects successor and retains complete result')
  leaf.orientationMode=2;leaf.orientationX=0;leaf.orientationY=0;leaf.orientationZ=0;failed=False
  try:root.refreshAll()
  except Exception:failed=True
  check((failed or 'zero' in str(leaf.cacheSnapshot()[3])) and int(root.procEpoch)==before['epoch'] and fingerprint(rows())==signature,'Zero world direction rejects successor and retains complete result')
  leaf.orientationMode=1;leaf.alignNormal=False;solve('recover upright')
  check(all(dot(x[0].row3,r.Point3(0,0,1))>1-1e-6 for x in rows()),'Disabled normal alignment stays upright')
  r.CyrusPerfHeadless=False;r.CyrusPointSync();r.completeRedraw()
 report['status']='passed';save()
except Exception:
 report['status']='failed';report['error']=traceback.format_exc();save();raise
