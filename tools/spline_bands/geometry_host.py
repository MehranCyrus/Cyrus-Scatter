"""Matched host geometry extraction, Sharp corners and field admission."""
from pathlib import Path
import hashlib
import json
import math
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / "build/mcp-qualification" or not OUT.name.startswith("foundation-spline-"):
    raise RuntimeError("Owned spline host required")
report = {"assertions": [], "errors": [], "launch": json.loads((OUT / "launch.json").read_text()),
          "fixture_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
destination = OUT / ("spline-geometry-" + uuid.uuid4().hex + ".json")


def save():
    destination.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def check(value, label):
    report["assertions"].append({"passed": bool(value), "label": label})
    save()
    if not value:
        raise AssertionError(label)


def snapshot(rows):
    return [[*[list(map(float, v)) for v in (x[0].row1, x[0].row2, x[0].row3, x[0].row4)],
             int(x[1]), str(x[2]), int(x[3]), list(map(float, x[4])), int(x[5]), bool(x[6]), int(x[7])] for x in rows]


try:
    r.CyrusStopBrush()
    r.resetMaxFile(r.Name("noPrompt"))
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    report["script_sha256"] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    r.execute('''
global GeometryNode=AminScatterObject name:"Geometry field fixture"
global GeometryRoot=GeometryNode.baseObject
GeometryRoot.updateMode=1;GeometryRoot.autoRender=false;GeometryRoot.newLayer()
global GeometryLeaf=GeometryRoot.selectedLayer()
global GeometrySurface=plane width:200 length:200 widthsegs:1 lengthsegs:1
global GeometryModel=box width:1 length:1 height:2 pos:[500,0,0]
global GeometryPath=rectangle width:100 length:100 cornerRadius:0
GeometryRoot.setLayerSurfaces GeometryLeaf #(GeometrySurface)
GeometryLeaf.sources=#(GeometryModel);GeometryLeaf.amount=10000;GeometryLeaf.diversityMode=3
GeometryLeaf.procSelfEnabled=false;GeometryLeaf.procLayerSelfEnabled=false
GeometryLeaf.addStroke GeometryPath side:1;GeometryLeaf.patternWidths=#(40.)
GeometryLeaf.setStrokeSelection 1 2 #(GeometryModel);GeometryLeaf.pathJoins[1]=2
GeometryRoot.evaluateProcedural()
''')
    leaf, root = r.GeometryLeaf, r.GeometryRoot
    sharp = snapshot(root.groupSnapshotRows[0])
    check(len(sharp) > 4000, "Sharp host rectangle emits its expanded region")
    check(int(leaf.splineFieldStats()[2][0]) == 4, "Linear knots are sampled once and retained as four exact corners")
    check(all(0 < max(abs(row[3][0]) - 50, abs(row[3][1]) - 50) <= 40.0001 for row in sharp),
          "Every Sharp output satisfies analytic miter support")
    check(sum(math.hypot(max(0, abs(row[3][0]) - 50), max(0, abs(row[3][1]) - 50)) > 40.01 for row in sharp) > 100,
          "Sharp actually retains corner placements beyond Rounded support")
    r.execute('GeometryLeaf.pathJoins[1]=1;GeometryRoot.evaluateProcedural()')
    rounded = snapshot(root.groupSnapshotRows[0])
    by_id = {row[5]: row for row in sharp}
    check(len(rounded) < len(sharp) and all(by_id.get(row[5]) == row for row in rounded),
          "Rounded support preserves full common transforms and identities")
    check(all(math.hypot(max(0, abs(row[3][0]) - 50), max(0, abs(row[3][1]) - 50)) <= 40.0001 for row in rounded),
          "Rounded still follows Euclidean corner distance")
    r.execute('GeometryPath.cornerRadius=2;GeometryLeaf.pathJoins[1]=2;GeometryRoot.evaluateProcedural()')
    check(int(leaf.splineFieldStats()[2][0]) > 8 and len(root.groupSnapshotRows[0]) > 0,
          "Host Bezier handles produce a bounded curved Sharp field")
    retained = snapshot(root.groupSnapshotRows[0])
    r.execute('GeometryLeaf.strokeCurveEnabled[1]=true;GeometryLeaf.strokeCurveSamples[1]="";for i=1 to 257 do GeometryLeaf.strokeCurveSamples[1]+=(if i==1 then "" else ",")+(if mod i 2==0 then "1" else "0")')
    rejected = False
    try:
        root.evaluateProcedural()
    except Exception as error:
        rejected = "budget" in str(error).lower() or "allowance" in str(error).lower()
    check(rejected and snapshot(root.groupSnapshotRows[0]) == retained,
          "Unattainable density accuracy rejects atomically with an actionable budget message")
    r.execute('GeometryLeaf.strokeCurveEnabled[1]=false;GeometryRoot.evaluateProcedural()')
    check(snapshot(root.groupSnapshotRows[0]) == retained, "Recovery after admission failure reproduces the complete previous recipe")
    report["field_stats"] = [int(value) for value in leaf.splineFieldStats()[2]]
    report["passed"] = True
except Exception:
    report["passed"] = False
    report["errors"].append(traceback.format_exc())
finally:
    save()
if not report.get("passed"):
    raise RuntimeError(report["errors"][-1])
