"""Prepare a bounded heavy scene; a later request observes settled Live behavior."""
from pathlib import Path
import json,sys,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-variation0840-')
result={'status':'running'};path=OUT/('heavy-setup-'+str(time.time_ns())+'.json')
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
  terrain=r.plane(name='Variation heavy terrain',width=1000,length=1000,widthsegs=300,lengthsegs=300)
  model=r.pyramid(name='Variation heavy source',width=1,depth=2,height=5,pos=r.Point3(-600,0,0))
  node=r.AminScatterObject(name='Variation heavy setup');root=node.baseObject;root.updateMode=1;root.autoRender=False;root.previewBudget=3000
  for i in range(2):
   root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(model);leaf.ensureSourceRows()
   leaf.amount=30000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
   leaf.sourceRadiiWU=r.Array(0.);leaf.sourceAutoRadius=r.Array(False)
  start=time.perf_counter();root.refreshAll();result['initial_update_ms']=(time.perf_counter()-start)*1000
  assert [len(rows) for rows in root.groupSnapshotRows]==[30000,30000]
  result['rows']=[len(rows) for rows in root.groupSnapshotRows]
  r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
  if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
  root.mainUI.updateRadio.changed(2);r.CyrusPointSync();r.completeRedraw()
  r.saveMaxFile(str(OUT/'variation-heavy.max'),quiet=True)
  result['status']='prepared'
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:path.write_text(json.dumps(result,indent=2),encoding='utf-8')
