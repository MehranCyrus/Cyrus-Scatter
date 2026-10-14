"""Execute only inside an owned matched foundation- Max host."""
from pathlib import Path
import hashlib
import json
import traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / "build/mcp-qualification" or not OUT.name.startswith("foundation-spline-"):
    raise RuntimeError("Owned spline qualification host required")
report = {"assertions": [], "errors": [], "scope": "Actual v2 transport primitives in Max; not complete spline UI qualification."}


def write():
    (OUT / "spline-transport-results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def check(condition, label):
    report["assertions"].append({"passed": bool(condition), "label": label})
    write()
    if not condition:
        raise AssertionError(label)


def denied(action, label):
    try:
        action()
    except Exception:
        check(True, label)
    else:
        check(False, label)


def arr(values):
    return r.Array(*values)


def owners(rows):
    return [int(row[5]) for row in rows]


try:
    r.CyrusStopBrush()
    r.resetMaxFile(r.Name("noPrompt"))
    report["launch"] = json.loads((OUT / "launch.json").read_text())
    report["fixture_sha256"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    r.execute('''fn SplineFixtureRows = #(
      #((transMatrix [3,4,0]),1,7L,1,[.2,.3,.5],101L,false,2),
      #((transMatrix [13,4,0]),1,8L,1,[.2,.3,.5],202L,false,2))''')
    raw = r.SplineFixtureRows()
    offset = r.cyrusReceiverOffsetRows(raw, 3)
    check(owners(offset) == [101, 202] and all(int(x[3]) == 4 for x in offset), "Receiver offsets preserve owner and change only anchor face")
    scaled = r.cyrusWholeScale(raw, 2., 2., 91)
    check(owners(scaled) == [101, 202] and all(len(x) == 8 and int(x[7]) == 2 for x in scaled), "Whole Scale retains full v2 rows")
    check(abs(float(scaled[0][0].row1.x) - 2) < 1e-6, "Whole Scale applies transform")
    shifted = r.cyrusApplySourceTransforms(scaled, arr([5.]), arr([1.]))
    check(owners(shifted) == [101, 202] and float(shifted[0][0].row4.z) == 5., "Source lift is world Z and retains provenance")
    loops = arr([arr([r.Point3(0, 0, 0), r.Point3(100, 0, 0), r.Point3(100, 100, 0), r.Point3(0, 100, 0)])])
    cfg = arr([False, 0., True, 100., arr([2., 2.]), False, 100., arr([1., 1.])])
    fall = r.cyrusBoundaryFalloff(raw, loops, cfg, 91)
    check(owners(fall) == [101, 202] and all(int(x[2]) in (7, 8) and int(x[3]) == 1 for x in fall), "Falloff Instance roundtrip retains owner and anchors")
    oriented = r.cyrusOrientRows(fall, arr([True, arr([])]), arr([1]), arr([0.]))
    check(owners(oriented) == [101, 202], "Orientation bridge roundtrip retains owner without adding spline orientation")
    analyzer_row = arr([loops, 10., arr([1]), 1., 1., 1, 0., arr([]), False,
                        arr([False, 0.]), arr([0., 0., 0., False, 45., 1, 0., 0., 0.])])
    receiver = r.plane(width=150, length=150, pos=r.Point3(50,50,0))
    def generate_analyzer(row):
        return r.cyrusScatterAdvanced(arr([receiver]), 1000, 91, 1,
            r.Point3(1,1,1), r.Point3(1,1,1), r.Point3(0,0,0), r.Point3(0,0,0),
            r.Point3(0,0,0), r.Point3(0,0,0), False, True, 0, arr([]), 128,
            arr([0]), False, 100., 1, 0., 0., 0., arr([]), arr([]),
            arr([True, arr([row])]), arr([False, 1., 1, .5]), arr([1.]), r.undefined,
            arr([True, 1., 1., 0., 0., 0., 0., 1, 0, 'analyzer-contract', 1, 1]))
    analyzer_rows = generate_analyzer(analyzer_row)
    check(len(analyzer_rows)>0 and all(int(row[5])==0 for row in analyzer_rows),
          'Current 11-field Analyzer generates unbanded placements')
    check(len(r.cyrusOrientRows(analyzer_rows, arr([True,arr([analyzer_row])]),arr([1]),arr([0.])))==len(analyzer_rows),
          'Current Analyzer orientation accepts its 11-field record')
    invalid_analyzer = arr(list(analyzer_row)); invalid_analyzer[5]=0
    denied(lambda: generate_analyzer(invalid_analyzer), 'Generation rejects the retired ordinary Analyzer mode')
    denied(lambda: r.cyrusOrientRows(raw,arr([True,arr([invalid_analyzer])]),arr([1]),arr([0.])),
           'Orientation rejects the retired ordinary Analyzer mode')
    retired_record = list(analyzer_row); retired_record.insert(5,False)
    denied(lambda: generate_analyzer(arr(retired_record)), 'Generation rejects the retired 12-field Analyzer layout')
    denied(lambda: r.cyrusOrientRows(raw,arr([True,arr([arr(retired_record)])]),arr([1]),arr([0.])),
           'Orientation rejects the retired 12-field Analyzer layout')
    node = r.box(name="Owned transport fixture")
    modifier = r.CyrusScatterEdit()
    r.addModifier(node, modifier)
    edited = r.cyrusEditStack(arr([modifier]), raw, 1, "spline-v2-fixture")
    copied = r.cyrusClonePlacementRows(raw)
    check(owners(copied)==owners(raw) and all(len(row)==8 for row in copied), 'Placement copy preserves the exact current row and Band owner')
    copied[0][0].translation=r.Point3(90,90,90)
    check(tuple(raw[0][0].translation)==(3.,4.,0.), 'Placement copy owns its transform rather than mutating the input')
    area = r.cyrusAnalyzerArea(raw, arr([]), arr([r.Point3(3,4,0)]), 0., 1., 1)
    check(owners(area)==[101], 'Analyzer Area preserves the selected current row and owner')
    check(all(len(x) == 8 and not bool(x[6]) for x in edited) and owners(edited) == [101, 202], "Edit stage retains unedited ownership and protection")
    check([str(x[2]) for x in edited] == ["c:7", "c:8"], "Edit stage translates candidate IDs explicitly")
    r.cyrusEditCommand(modifier, 1, r.Matrix3(1))
    r.cyrusEditCommand(modifier, 4, r.transMatrix(r.Point3(0, 0, 2)))
    r.cyrusEditCommand(modifier, 3, r.Matrix3(1))
    clones = r.cyrusEditStack(arr([modifier]), raw, 1, "spline-v2-fixture")
    check(len(clones) == 4 and sorted(owners(clones)) == [101, 101, 202, 202], "Clone output inherits each original Band owner")
    check(len({str(x[2]) for x in clones}) == 4 and all(bool(x[6]) for x in clones), "Clone IDs are unique and edits remain protected")
    raw_kept = r.cyrusFilterSourceRows(raw, arr([True]))
    edited_kept = r.cyrusFilterSourceRows(clones, arr([True]))
    check(len(raw_kept) == 2 and owners(raw_kept) == [101, 202], 'Source filtering accepts exact raw candidate rows')
    check(len(edited_kept) == 4 and [str(x[2]) for x in edited_kept] == [str(x[2]) for x in clones]
          and all(bool(x[6]) for x in edited_kept) and owners(edited_kept) == owners(clones),
          'Exact-output source filtering preserves edited/clone identities, protection and Band owners')
    check(len(r.cyrusFilterSourceRows(clones, arr([False]))) == 0, 'Exact-output source exclusion removes the requested source')
    denied(lambda: r.cyrusFilterSourceRows(arr([arr([r.Matrix3(1), 1])]), arr([True])),
           'Source filtering still rejects retired placement layouts')
    invalid_identity = r.SplineFixtureRows()
    invalid_identity[0][2] = ''
    denied(lambda: r.cyrusFilterSourceRows(invalid_identity, arr([True])), 'Source filtering rejects an empty output identity')
    check(all(int(x[3]) == 1 and tuple(x[4]) == tuple(raw[0][4]) for x in clones), "Clone anchors remain canonical")
    retained = r.cyrusResolveGroup(clones, 100., arr([]))
    check(len(retained[0]) == 4, "Spacing recognizes protection in eight-field rows")
    specs = arr([arr([1, 3., True, r.Point3(0,0,0), r.Point3(0,0,0)])])
    radii = r.cyrusProceduralRadii(clones, specs, arr([]), arr([]), arr([]))
    check(len(radii) == 4 and all(list(map(float,x)) == [3.,3.] for x in radii), "Manual radius resolution returns equal XY/3D values for versioned edited IDs")
    bad = r.SplineFixtureRows()
    bad[0][7] = 99
    denied(lambda: r.cyrusReceiverOffsetRows(bad, 0), "Unknown row version rejected before receiver copy")
    bad = r.SplineFixtureRows()
    bad[0][6] = True
    denied(lambda: r.cyrusWholeScale(bad, 1., 1., 91), "Raw rows reject protected edited state")
    bad = r.SplineFixtureRows()
    bad[0][5] = -1
    denied(lambda: r.cyrusEditStack(arr([modifier]), bad, 1, "spline-v2-fixture"), "Negative Band identity rejected")
    again = r.cyrusEditStack(arr([modifier]), raw, 1, "spline-v2-fixture")
    check([str(x[2]) for x in again] == [str(x[2]) for x in clones], "Denied successor preserves Edit identities")
    for length in (2, 4, 5, 7):
        retired = arr([arr(list(raw[0])[:length])])
        denied(lambda: r.cyrusReceiverOffsetRows(retired, 0), f"Retired {length}-field rows rejected")
        denied(lambda: r.cyrusEditFingerprint(retired, 'transport'), f"Fingerprint rejects retired {length}-field rows")
        denied(lambda: r.cyrusClonePlacementRows(retired), f"Placement copying rejects retired {length}-field rows")
        denied(lambda: r.cyrusAnalyzerArea(retired,arr([]),arr([]),0.,1.,1), f"Analyzer Area rejects retired {length}-field rows")
        denied(lambda: r.cyrusResolveGroup(edited,0.,arr([arr([retired,0.,True,arr([1.,1.]),arr([1.])])])),
               f"Group blocker inputs reject retired {length}-field rows")
    check(str(r.cyrusEditFingerprint(raw, 'transport'))==str(r.cyrusEditFingerprint(edited, 'transport')),
          'Current raw and edited rows retain the same position/source diagnostic fingerprint')
    check(r.execute('cyrusPreviewBatchDrawing==undefined and cyrusPreviewDrawStats==undefined'),
          'Retired expanded-batching primitives are absent')
    denied(lambda: r.cyrusEditStack(arr([modifier]), edited, 1, "spline-v2-fixture"), "Edit rejects already-edited identities at the raw boundary")
    report["passed"] = True
except Exception:
    report["passed"] = False
    report["errors"].append(traceback.format_exc())
finally:
    write()
if not report.get("passed"):
    raise RuntimeError(report["errors"][-1])
