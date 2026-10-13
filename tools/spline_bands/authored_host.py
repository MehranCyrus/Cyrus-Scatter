"""Current-schema authoring, explicit gaps and immutable ownership in owned Max."""
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
REPORT_PATH = OUT / ("spline-authored-" + uuid.uuid4().hex + ".json")


def write():
    REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def check(value, label):
    report["assertions"].append({"passed": bool(value), "label": label})
    write()
    if not value:
        raise AssertionError(label)


def matrix(m):
    return [list(map(float, v)) for v in (m.row1, m.row2, m.row3, m.row4)]


def snapshot(rows):
    return [[matrix(x[0]), int(x[1]), str(x[2]), int(x[3]), list(map(float, x[4])),
             int(x[5]), bool(x[6]), int(x[7])] for x in rows]


def ints(values):
    return list(map(int, values))


try:
    r.CyrusStopBrush()
    r.resetMaxFile(r.Name("noPrompt"))
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    report["script_sha256"] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    r.execute('''
global BandNode=AminScatterObject name:"Current spline fixture"
global BandRoot=BandNode.baseObject
BandRoot.updateMode=1;BandRoot.autoRender=false;BandRoot.newLayer()
global BandLeaf=BandRoot.selectedLayer()
global BandSurface=plane width:500 length:500 widthsegs:1 lengthsegs:1
global BandModels=#(box width:3 length:3 height:8 pos:[500,0,0],sphere radius:3 pos:[520,0,0])
global BandPath=rectangle width:100 length:100 name:"Authored Path"
BandRoot.setLayerSurfaces BandLeaf #(BandSurface)
BandLeaf.sources=BandModels;BandLeaf.amount=4000;BandLeaf.diversityMode=3
for i=1 to 3 do BandLeaf.addStroke BandPath side:1
BandLeaf.patternWidths=#(10.,25.,100.)
BandRoot.evaluateProcedural()
''')
    root, leaf = r.BandRoot, r.BandLeaf
    check(str(root.uiVersion()) == "0.80.0", "Matched current development script")
    ids, paths = ints(leaf.strokeIDs), ints(leaf.pathIDs)
    check(len(set(ids)) == 3 and len(paths) == 1 and ints(leaf.strokePathIDs) == paths * 3,
          "Each Band has a unique persistent ID and references one shared Path")
    check(ints(leaf.strokeModes) == [2, 2, 2] and len(leaf.strokeSourceIDs) == 0,
          "New Bands use direct empty selections")
    check(len(root.groupSnapshotRows[0]) == 0, "Empty selections produce no group fallback")
    r.execute('BandLeaf.strokeModes[1]=1;BandRoot.evaluateProcedural()')
    check(len(root.groupSnapshotRows[0]) == 0, "Switching to Groups does not select a default group")
    r.execute('BandLeaf.strokeModes[1]=2')
    r.execute('''
BandLeaf.setStrokeSelection 1 2 #(BandModels[1])
BandLeaf.setStrokeSelection 3 2 #(BandModels[2])
BandRoot.evaluateProcedural()
''')
    gap = snapshot(root.groupSnapshotRows[0])
    check(len(gap) > 300 and {x[5] for x in gap} == {ids[0], ids[2]}, "Published rows retain assigned Band owners")
    check(all(x[7] == 2 and not x[6] and x[2].startswith("c:") for x in gap),
          "Real generation-to-Edit publication uses the single eight-field contract")
    distances = [math.hypot(max(0., abs(x[0][3][0]) - 50.), max(0., abs(x[0][3][1]) - 50.)) for x in gap]
    check(all(0. < d <= 10.0001 or 34.9999 <= d <= 135.0001 for d in distances),
          "Unassigned middle Band reserves its 10-to-35 interval")
    check(all((d <= 10.0001 and x[5] == ids[0]) or (d >= 34.9999 and x[5] == ids[2]) for x, d in zip(gap, distances)),
          "Distance oracle agrees with persistent ownership")
    r.execute('BandLeaf.setStrokeSelection 2 2 #(BandModels[1]);BandRoot.evaluateProcedural()')
    full = snapshot(root.groupSnapshotRows[0])
    common = {x[2]: x for x in full}
    check(len(full) > len(gap) and all(common[x[2]] == x for x in gap),
          "Assigning the gap preserves every unaffected identity and full transform")
    r.execute('BandLeaf.setStrokeSelection 2 2 #();BandRoot.evaluateProcedural()')
    check(snapshot(root.groupSnapshotRows[0]) == gap, "Clearing membership restores the exact gap result")
    # Undo is tested by authored_undo.ms in separate native events outside pymxs.
    r.execute('BandLeaf.addStroke BandPath side:2')
    check(int(leaf.strokeIDs[3]) > max(ids), "A new Band receives a fresh monotonic ID")
    r.execute('BandLeaf.removeStroke 4')
    seed = (int(leaf.randomSeed), int(leaf.procSamplingSalt))
    r.execute('global BandCopy=BandRoot.copyLogicalLayer BandLeaf')
    copy = r.BandCopy
    check(str(copy.layerID) != str(leaf.layerID) and ints(copy.strokeIDs) == ids and ints(copy.pathIDs) == paths,
          "Layer copy has a new namespace and identical internal IDs")
    check((int(copy.randomSeed), int(copy.procSamplingSalt)) == seed, "Layer namespace does not reseed the copied recipe")
    # Both copies have independent collision scopes; compare before group spacing.
    r.execute('BandRoot.evaluateProcedural()')
    check(snapshot(leaf.procPreparedRows) == snapshot(copy.procPreparedRows), "Copied layer preserves full pre-spacing rows")
    saved = snapshot(root.groupSnapshotRows[0])
    destination = REPORT_PATH.with_suffix(".max")
    check(not destination.exists(), "Current-scene witness has a fresh destination")
    r.saveMaxFile(str(destination), quiet=True)
    r.resetMaxFile(r.Name("noPrompt"))
    r.loadMaxFile(str(destination), quiet=True)
    root = r.getNodeByName("Current spline fixture").baseObject
    leaf = root.layerObjects[0]
    root.evaluateProcedural()
    check(ints(leaf.strokeIDs) == ids and ints(leaf.pathIDs) == paths, "Save/reopen retains stable IDs")
    check(snapshot(root.groupSnapshotRows[0]) == saved, "Current-schema save/reopen preserves complete placement rows")
    r.BandRoot, r.BandLeaf = root, leaf
    r.execute('delete (getNodeByName "Authored Path")')
    check(snapshot(root.groupSnapshotRows[0]) == saved, "Manual Path deletion keeps the published result pending")
    root.evaluateProcedural()
    check(len(root.groupSnapshotRows[0]) == 0 and ints(leaf.strokeIDs) == ids and ints(leaf.pathIDs) == paths,
          "Explicit Update makes missing Paths inactive and retains authored IDs")
    r.rectangle(width=100., length=100., name="Authored Path")
    root.evaluateProcedural()
    check(len(root.groupSnapshotRows[0]) == 0, "Same-name replacement does not rebind a missing Path")
    check(not bool(r.isProperty(leaf, r.Name("sourceRadii"))) and not bool(r.isProperty(leaf, r.Name("migrateDistanceSettings55"))),
          "Retired untyped distance storage and migration methods are absent")
    report["passed"] = True
except Exception:
    report["passed"] = False
    report["errors"].append(traceback.format_exc())
finally:
    write()
if not report.get("passed"):
    raise RuntimeError(report["errors"][-1])
