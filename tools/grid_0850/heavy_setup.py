"""Prepare a bounded heavy scene; a later request observes settled Live behavior."""
from pathlib import Path
import json,sys,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
result={'status':'running'};path=OUT/('heavy-setup-'+str(time.time_ns())+'.json')
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
  terrain=r.plane(name='Grid heavy terrain',width=1000,length=1000,widthsegs=300,lengthsegs=300)
  r.execute('(local terrain=getNodeByName "Grid heavy terrain"; convertToMesh terrain; for i=1 to terrain.numverts do (local p=getVert terrain i;p.z=60.0*sin(p.x*0.35)*cos(p.y*0.27);setVert terrain i p);update terrain)')
  model=r.pyramid(name='Grid heavy source',width=1,depth=2,height=5,pos=r.Point3(-600,0,0))
  node=r.AminScatterObject(name='Grid heavy setup');root=node.baseObject;root.updateMode=1;root.autoRender=False;root.previewBudget=3000
  for i in range(2):
   root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(model);leaf.ensureSourceRows()
   leaf.placementMode=2;leaf.gridColumnWU=6.;leaf.gridRowWU=6.;leaf.gridJitter=15.;leaf.amount=30000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
   leaf.sourceRadiiWU=r.Array(0.);leaf.sourceAutoRadius=r.Array(False)
  r.cyrusDiagnosticStart('grid-heavy-initial',4096,4*1024*1024,600000)
  start=time.perf_counter();root.refreshAll();result['initial_update_ms']=(time.perf_counter()-start)*1000
  result['diagnostic_initial']=json.loads(str(r.cyrusDiagnosticSnapshot(0,500)));r.cyrusDiagnosticStop()
  result['grid_snapshots']=[list(r.cyrusGridSnapshotInfo(x.gridSnapshot(1))) for x in root.layerObjects]
  result['grid_stats']=list(r.cyrusGridStats())
  assert [len(rows) for rows in root.groupSnapshotRows]==[27889,27889]
  result['rows']=[len(rows) for rows in root.groupSnapshotRows]
  r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
  if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
  root.mainUI.updateRadio.changed(2);r.CyrusPointSync();r.completeRedraw()
  r.saveMaxFile(str(OUT/'grid-heavy.max'),quiet=True)
  result['status']='prepared'
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:path.write_text(json.dumps(result,indent=2),encoding='utf-8')
