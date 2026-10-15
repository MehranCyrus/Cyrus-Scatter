"""Observe real curve/preview controls and check owner-bound tooltip metadata."""
from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.MCPFixtureDir));assert out.name.startswith('foundation-roadmap-meshmask-')
root=r.MeshMaskRoot;leaf=r.MeshMaskLeaf
editor=r.CyrusFalloffGraph
data={'curve_open':editor!=r.undefined,'accepted':int(leaf.generatedCount),'curve':list(leaf.meshMaskCurve()),
      'graph':str(leaf.meshMaskGraph),'mesh_enabled':bool(leaf.meshMaskEnabled),'mesh_invert':bool(leaf.meshMaskInvert),
      'channel_reads':list(r.cyrusMeshDensityStats()),'preview_markers':len(r.CyrusMeshMaskPreviewRows)}
if editor!=r.undefined:
    data['curve_title']=str(editor.title);data['curve_owner_matches']=editor.obj==leaf
    data['curve_points']=[(float(editor.graph.curves[0].points[i].value.x),float(editor.graph.curves[0].points[i].value.y)) for i in range(int(editor.graph.curves[0].numPoints))]
path=out/'mesh-mask-ui-observations.json'
history=json.loads(path.read_text()) if path.exists() else []
history.append(data);path.write_text(json.dumps(history,indent=2)+'\n')
