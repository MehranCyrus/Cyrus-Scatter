"""Separate warm Layout toggling from layer-owner changes on the heavy scene."""
from pathlib import Path
import json,sys,time,statistics,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
node=r.getNodeByName('Grid heavy setup');root=node.baseObject
result={'status':'running'};target=OUT/('panel-costs-'+str(time.time_ns())+'.json')
def snap():return {'rows':[fingerprint(x) for x in root.groupSnapshotRows],'grid':list(r.cyrusGridStats())[:3],'epoch':int(root.procEpoch),'prepare':[int(x.procPreparedBuilds) for x in root.layerObjects],'receiver':[int(x.receiverCacheStats()[0]) for x in root.layerObjects],'uploads':int(r.cyrusRetainedStats(r.CyrusPointOwner(node))[5])}
try:
 before=snap()
 for slot in root.mainUI.slots:slot.open=False;slot.rolledUp(True)
 layout=root.mainUI.slots[4];layout.open=True;layout.rolledUp(False)
 r.cyrusDiagnosticStart('grid-warm-panels',4096,4*1024*1024,600000)
 for op in ('layout_toggle','owner_change'):
  samples=[]
  for i in range(30):
   started=time.perf_counter()
   if op=='layout_toggle':layout.open=False;layout.rolledUp(True);layout.open=True;layout.rolledUp(False)
   else:root.mainUI.selectLayerView(root.layerObjects[i%2])
   samples.append((time.perf_counter()-started)*1000)
  result[op]={'milliseconds':samples,'median_ms':statistics.median(samples),'p95_ms':sorted(samples)[28]}
 result['diagnostics']=json.loads(str(r.cyrusDiagnosticSnapshot(0,500)));r.cyrusDiagnosticStop()
 after=snap();result.update(before=before,after=after);assert before==after
 result['status']='passed'
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:target.write_text(json.dumps(result,indent=2),encoding='utf-8')
