"""Actual Transforms open/close work with 60000 published placements."""
from pathlib import Path
import json,sys,time,statistics,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-orientation0830-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
result={'status':'running','checks':[]};target=OUT/('heavy-ui-'+str(time.time_ns())+'.json')
def save():target.write_text(json.dumps(result,indent=2),encoding='utf-8')
def snapshot():
 return {'orientation':list(r.cyrusOrientationStats())[:3],'epoch':int(root.procEpoch),
  'receiver':[list(x.receiverCacheStats()) for x in root.layerObjects],
  'prepare':[int(x.procPreparedBuilds) for x in root.layerObjects],
  'preview':[int(x.previewBuildCount) for x in root.layerObjects],
  'display':list(r.cyrusRetainedStats(r.CyrusPointOwner(node))),
  'rows':[fingerprint(x) for x in root.groupSnapshotRows]}
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
  terrain=r.plane(name='UI heavy terrain',width=1000,length=1000,widthsegs=300,lengthsegs=300)
  model=r.pyramid(name='UI heavy model',width=1,depth=1,height=5,pos=r.Point3(-600,0,0))
  node=r.AminScatterObject(name='Orientation qualification');root=node.baseObject;root.updateMode=1;root.previewBudget=3000;root.autoRender=False
  for i in range(2):
   root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(model);leaf.ensureSourceRows()
   leaf.amount=30000;leaf.procPopulation=1;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
   leaf.sourceRadiiWU=r.Array(0.);leaf.sourceAutoRadius=r.Array(False)
  root.refreshAll();assert [len(x) for x in root.groupSnapshotRows]==[30000,30000]
  r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
  if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
  root.mainUI.updateRadio.changed(2);r.CyrusPointSync();r.completeRedraw()
  before=snapshot();times=[];slot=root.mainUI.slots[8]
  for i in range(30):
   start=time.perf_counter();slot.open=True;slot.rolledUp(False);slot.open=False;slot.rolledUp(True);times.append((time.perf_counter()-start)*1000)
  after=snapshot();result.update(before=before,after=after,cycle_ms=times,median_ms=statistics.median(times),p95_ms=sorted(times)[28])
  # Cache-hit accounting may rise; build counts and all downstream work may not.
  same=all(before[k]==after[k] for k in ('orientation','epoch','prepare','preview','display','rows'))
  same=same and all(a[0]==b[0] and a[2]==b[2] for a,b in zip(before['receiver'],after['receiver']))
  result['checks'].append({'passed':same,'assertion':'Thirty actual Transforms open/close cycles leave complete 60000 rows and all calculation/preparation/upload counters unchanged'})
  assert same
  result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
