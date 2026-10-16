"""Prepare a finite scene with pending Manual settings for passive UI checks."""
from pathlib import Path
import json,pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
with pymxs.undo(False):
 r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
 terrain=r.plane(name='UI terrain',width=1000,length=1000,widthsegs=24,lengthsegs=24)
 source=r.pyramid(name='UI source',width=4,depth=4,height=14,pos=r.Point3(-700,0,0))
 node=r.AminScatterObject(name='UI qualification');root=node.baseObject;root.updateMode=1;root.autoRender=False
 for i in range(2):
  root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(source);leaf.ensureSourceRows();leaf.amount=400+i*100
  leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False;leaf.sourceRadiiWU=r.Array(0.);leaf.sourceAutoRadius=r.Array(False)
 r.execute('global UI0852Root,UI0852Node');r.UI0852Root=root;r.UI0852Node=node
 r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
 r.CyrusPerfHeadless=False
(OUT/'prepare.json').write_text(json.dumps({'custom_scale':float(r.CustomControlsOptions.UIUserScaleFactor),'effective_scale':float(r.GetUIScaleFactor()),'version':str(root.uiVersion())},indent=2))
