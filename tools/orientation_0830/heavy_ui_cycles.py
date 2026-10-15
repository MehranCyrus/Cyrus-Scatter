"""Repeat panel cycles after the initial Live activation has settled."""
from pathlib import Path
import json,sys,time,statistics
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-orientation0830-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
node=r.getNodeByName('Orientation qualification');root=node.baseObject
assert root.updateMode==2 and [len(x) for x in root.groupSnapshotRows]==[30000,30000]
def snapshot():
 return {'orientation':list(r.cyrusOrientationStats())[:3],'epoch':int(root.procEpoch),
  'receiver':[list(x.receiverCacheStats()) for x in root.layerObjects],
  'prepare':[int(x.procPreparedBuilds) for x in root.layerObjects],
  'preview':[int(x.previewBuildCount) for x in root.layerObjects],
  'display':list(r.cyrusRetainedStats(r.CyrusPointOwner(node))),
  'rows':[fingerprint(x) for x in root.groupSnapshotRows]}
before=snapshot();times=[];slot=root.mainUI.slots[8]
for i in range(30):
 start=time.perf_counter();slot.open=True;slot.rolledUp(False);slot.open=False;slot.rolledUp(True);times.append((time.perf_counter()-start)*1000)
after=snapshot();passed=before==after
result={'status':'passed' if passed else 'failed','scope':'Panel cycles after prior Live activation settled in event loop','before':before,'after':after,'cycle_ms':times,'median_ms':statistics.median(times),'p95_ms':sorted(times)[28]}
(OUT/('heavy-ui-'+str(time.time_ns())+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8');assert passed
