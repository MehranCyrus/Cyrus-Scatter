"""Capture an untouched schema-56 migration oracle in an owned Max host."""
from pathlib import Path
import hashlib
import json
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / "build/mcp-qualification" or not OUT.name.startswith("foundation-spline-"):
    raise RuntimeError("Owned spline host required")
destination = OUT / "schema56-scene.max"
if destination.exists():
    raise RuntimeError("Preserve the existing schema-56 witness")
r.CyrusStopBrush()
r.resetMaxFile(r.Name("noPrompt"))
r.fileIn(str(OUT / "scripts/CyrusScatter.ms"))
r.execute('''
global SplineOldNode=AminScatterObject name:"Schema56 spline witness"
global SplineOldRoot=SplineOldNode.baseObject
SplineOldRoot.updateMode=1;SplineOldRoot.autoRender=false
SplineOldRoot.newLayer()
global SplineOldLeaf=SplineOldRoot.selectedLayer()
global SplineOldSurface=plane width:500 length:500 widthsegs:1 lengthsegs:1
global SplineOldModels=#(box width:3 length:3 height:8 pos:[500,0,0],sphere radius:3 pos:[520,0,0])
global SplineOldPath=rectangle width:100 length:100
SplineOldRoot.setLayerSurfaces SplineOldLeaf #(SplineOldSurface)
SplineOldLeaf.sources=SplineOldModels;SplineOldLeaf.amount=2000;SplineOldLeaf.diversityMode=3
for i=1 to 3 do SplineOldLeaf.addStroke SplineOldPath side:1
SplineOldLeaf.patternWidths=#(10.,25.,100.)
for i=1 to 3 do (SplineOldLeaf.strokeModes[i]=2;SplineOldLeaf.setStrokeSelection i 2 #(SplineOldModels[(mod (i-1) 2)+1]))
SplineOldLeaf.sourceRadiiWU=#(3.,5.);SplineOldLeaf.sourceZOffsetsWU=#(1.,2.)
SplineOldRoot.evaluateProcedural()
''')
root = r.SplineOldRoot
leaf = r.SplineOldLeaf


def matrix(m):
    return [list(map(float, v)) for v in (m.row1, m.row2, m.row3, m.row4)]


expected = {
    "schema": 56,
    "launch": json.loads((OUT / "launch.json").read_text()),
    "rows": [[matrix(row[0]), int(row[1]), str(row[2]), bool(row[3])] for row in root.groupSnapshotRows[0]],
    "widths": list(map(float, leaf.patternWidths)),
    "source_row_ids": list(map(str, leaf.sourceRowIDs)),
    "source_selections": list(map(str, leaf.strokeSourceIDs)),
    "source_radii": list(map(float, leaf.sourceRadiiWU)),
    "source_z_offsets": list(map(float, leaf.sourceZOffsetsWU)),
    "seed": int(leaf.randomSeed),
    "sampling_salt": int(leaf.procSamplingSalt),
}
if not expected["rows"]:
    raise RuntimeError("Migration fixture produced no placements")
r.saveMaxFile(str(destination), quiet=True)
expected["scene_sha256"] = hashlib.sha256(destination.read_bytes()).hexdigest()
(OUT / "schema56-expected.json").write_text(json.dumps(expected, indent=2) + "\n", encoding="utf-8")
