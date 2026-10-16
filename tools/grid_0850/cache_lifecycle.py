"""Bound retained snapshot growth through repeated replacements, without changing heap policy."""
from pathlib import Path
import json,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
result={'status':'running','snapshots':[]};target=OUT/('cache-lifecycle-'+str(time.time_ns())+'.json')
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
  terrain=r.plane(width=100,length=100,widthsegs=40,lengthsegs=40)
  node=r.AminScatterObject(name='Grid cache lifetime');root=node.baseObject;root.updateMode=1;root.autoRender=False
  root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.addPointSource()
  leaf.placementMode=2;leaf.gridColumnWU=2.;leaf.gridRowWU=2.;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
  root.refreshAll();r.gc();baseline=list(r.cyrusGridStats());result['baseline']=baseline
  for i in range(16):
   leaf.gridHeading=float(i+1);root.refreshAll();assert not str(leaf.previewError);r.gc()
   snapshot=list(r.cyrusGridStats());result['snapshots'].append(snapshot)
   assert snapshot[4]==baseline[4],'Replaced native snapshots accumulated after collection'
   # Rotated bounds can change capacity, but sixteen replacements must retain
   # one active snapshot, not sixteen meshes. Allow 1 MiB anchor-size variation.
   assert snapshot[3]<=baseline[3]+1024*1024
  leaf.placementMode=1;leaf.amount=100;root.refreshAll();r.gc();result['random_mode']=list(r.cyrusGridStats())
  assert result['random_mode'][4]==baseline[4]-1,'Switching to random must release its grid cache'
  result['status']='passed';r.CyrusPerfHeadless=False
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:target.write_text(json.dumps(result,indent=2),encoding='utf-8')
