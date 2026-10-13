"""Actual prepared-field generation, receiver identity and failure retention."""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / "build/mcp-qualification" or not OUT.name.startswith("foundation-spline-"):
    raise RuntimeError("Owned spline host required")
report = {"assertions": [], "errors": [], "launch": json.loads((OUT / "launch.json").read_text()),
          "fixture_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
destination = OUT / ("spline-field-" + uuid.uuid4().hex + ".json")


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


MASK = (1 << 64) - 1


def mix(value):
    value = ((value ^ (value >> 30)) * 0xbf58476d1ce4e5b9) & MASK
    value = ((value ^ (value >> 27)) * 0x94d049bb133111eb) & MASK
    return value ^ (value >> 31)


def salt(identity):
    value = 1469598103934665603
    for c in identity.encode("ascii"):
        value = ((value ^ c) * 1099511628211) & MASK
    return value


def unit(seed, ordinal, channel, receiver):
    counter = mix(ordinal) ^ mix(((seed & 0xffffffff) << 32) ^ channel) ^ mix(receiver)
    return (mix((counter + 0x9e3779b97f4a7c15) & MASK) >> 11) / 2**53


try:
    r.CyrusStopBrush()
    r.resetMaxFile(r.Name("noPrompt"))
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    report["script_sha256"] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    r.execute('''
global FieldNode=AminScatterObject name:"Prepared field fixture"
global FieldRoot=FieldNode.baseObject
FieldRoot.updateMode=1;FieldRoot.autoRender=false;FieldRoot.newLayer()
global FieldLeaf=FieldRoot.selectedLayer()
global FieldSurface=plane width:40 length:98 widthsegs:1 lengthsegs:1 pos:[120,50,0]
global FieldSurface2=plane width:40 length:98 widthsegs:1 lengthsegs:1 pos:[120,50,10]
global FieldModels=#(sphere radius:1 pos:[500,0,0],box width:1 length:1 height:2 pos:[510,0,0])
global FieldPath=rectangle width:100 length:100 pos:[50,50,0]
FieldRoot.setLayerSurfaces FieldLeaf #(FieldSurface,FieldSurface2)
FieldLeaf.sources=FieldModels;FieldLeaf.amount=30000;FieldLeaf.diversityMode=3
FieldLeaf.procSelfEnabled=false;FieldLeaf.procLayerSelfEnabled=false
for i=1 to 2 do FieldLeaf.addStroke FieldPath side:1
FieldLeaf.bandArrangement=2;FieldLeaf.strokeStarts=#(0.,0.);FieldLeaf.strokeEnds=#(10.,40.)
FieldLeaf.strokeStrengths=#(1.,0.25)
FieldLeaf.setStrokeSelection 1 2 #(FieldModels[1]);FieldLeaf.setStrokeSelection 2 2 #(FieldModels[2])
FieldRoot.evaluateProcedural()
''')
    leaf, root = r.FieldLeaf, r.FieldRoot
    before = snapshot(root.groupSnapshotRows[0])
    check(len(before) > 11000, "Actual Independent fixture emits both receiver populations")
    stats = list(leaf.splineFieldStats())
    check(int(stats[0]) == 1, "One field preparation serves both receivers")
    seed = int(leaf.effectiveSeed())
    receiver_salts = [salt(str(value)) for value in leaf.procReceiverIDs]
    owners = [int(value) for value in leaf.strokeIDs]

    def replay(rows):
        counts = [0, 0, 0]
        slots = set()
        for row in rows:
            identity = int(row[2]) - 2**32
            slot, ordinal = divmod(identity, 131072)
            if not (0 <= slot < len(receiver_salts) and ordinal < 100000):
                return False, counts, slots
            slots.add(slot)
            x = float(row[0].row4.x)
            occupancy = unit(seed, ordinal, 101, receiver_salts[slot])
            owner = unit(seed, ordinal, 102, receiver_salts[slot])
            selected = 0 if x <= 110 and owner < .8 else 1
            if x > 110 and occupancy >= .25:
                return False, counts, slots
            if int(row[5]) != owners[selected] or int(row[1]) != selected + 1:
                return False, counts, slots
            counts[0 if x <= 110 else 1] += 1
            if x <= 110 and selected == 1:
                counts[2] += 1
        return True, counts, slots

    valid, counts, slots = replay(leaf.paintBaseRows)
    check(valid and slots == {0, 1}, "Packed receiver IDs reproduce occupancy and owner decisions exactly")
    check(abs(counts[0] - 7500) < 500 and abs(counts[1] - 5625) < 500 and abs(counts[2] / counts[0] - .2) < .035,
          "Actual host achieves saturated 80/20 mixture and sparse 25% continuation")
    r.execute('FieldLeaf.amount=5000;FieldRoot.evaluateProcedural()')
    prefix = snapshot(root.groupSnapshotRows[0])
    original = {row[5]: row for row in before}
    check(all(original.get(row[5]) == row for row in prefix), "Budget reduction preserves every retained full transform and identity")
    check(int(leaf.splineFieldStats()[0]) == 1, "Changing candidate count reuses the field")
    r.execute('FieldLeaf.finalRelax=true;FieldLeaf.finalStrength=0.8;FieldLeaf.finalIterations=3;FieldLeaf.finalMaxMove=2;FieldLeaf.relaxSpacing=10;FieldRoot.evaluateProcedural()')
    valid, _, slots = replay(leaf.paintBaseRows)
    check(valid and slots == {0, 1}, "Final movement decodes and restores each receiver identity without rerolling ownership")
    retained = snapshot(root.groupSnapshotRows[0])
    rejected = False
    try:
        r.execute('FieldLeaf.procPopulation=2;FieldRoot.evaluateProcedural()')
    except Exception as error:
        rejected = "Candidate budget" in str(error)
    check(rejected and snapshot(root.groupSnapshotRows[0]) == retained,
          "Accepted target rejects Independent density and retains the previous complete publication")
    r.execute('FieldLeaf.procPopulation=1;FieldLeaf.strokeCurveEnabled[1]=true;FieldLeaf.strokeCurveSamples[1]="0,broken"')
    rejected = False
    try:
        root.evaluateProcedural()
    except Exception:
        rejected = True
    check(rejected and snapshot(root.groupSnapshotRows[0]) == retained,
          "Malformed curve retains the complete prior publication")
    r.execute('FieldLeaf.strokeCurveSamples[1]="0,1";FieldRoot.evaluateProcedural()')
    check(len(root.groupSnapshotRows[0]) > 0 and int(leaf.splineFieldStats()[0]) == 2,
          "A valid curve prepares one successor and recovers after rejection")
    report["passed"] = True
except Exception:
    report["passed"] = False
    report["errors"].append(traceback.format_exc())
finally:
    save()
if not report.get("passed"):
    raise RuntimeError(report["errors"][-1])
