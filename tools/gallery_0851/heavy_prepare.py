"""Create H in Manual; publish only after creation notifications settle."""
from pathlib import Path
import json,pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
config=json.loads((OUT/'heavy-config.json').read_text(encoding='utf-8')) if (OUT/'heavy-config.json').exists() else {'per_layer':30000}
count=int(config['per_layer']);assert count in (10000,30000)
(OUT/'heavy-count.txt').write_text(str(count),encoding='utf-8')
with pymxs.undo(False):
 r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
 terrain=r.plane(name='Variation heavy terrain',width=1000,length=1000,widthsegs=300,lengthsegs=300)
 model=r.pyramid(name='Variation heavy source',width=1,depth=2,height=5,pos=r.Point3(-600,0,0))
 node=r.AminScatterObject(name='Variation heavy setup');root=node.baseObject;root.updateMode=1;root.autoRender=False;root.previewBudget=3000
 for _ in range(2):
  root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(model);leaf.ensureSourceRows()
  leaf.amount=count;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
  leaf.sourceRadiiWU=r.Array(0.);leaf.sourceAutoRadius=r.Array(False)
 r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
 if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
 r.CyrusPointSync();r.completeRedraw()
 r.execute('global GalleryTestRoot');r.GalleryTestRoot=root
