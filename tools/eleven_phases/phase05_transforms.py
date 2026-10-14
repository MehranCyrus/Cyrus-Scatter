"""Owned conversion coordinate, units, terrain, source-offset and budget witnesses."""
from pathlib import Path
import json
import math
import time
import traceback
import pymxs
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-p05-')
data = {'status': 'started', 'checks': [], 'measurements': []}


def check(value, label):
    data['checks'].append({'passed': bool(value), 'label': label})
    (OUT / 'phase05-transforms.json').write_text(json.dumps(data, indent=2), encoding='utf-8')
    if not value:
        raise AssertionError(label)


def shape(points):
    node = r.splineShape(name='P05 transformed boundary'); r.addNewSpline(node)
    for p in points:
        r.addKnot(node, 1, r.Name('corner'), r.Name('line'), r.Point3(*p))
    r.close(node, 1); r.updateShape(node)
    return node


def solve():
    root.procManualRevision += 1; root.evaluateProcedural()


def ids():
    return sorted(str(row[2]) for row in root.groupSnapshotRows[0])


try:
    with pymxs.undo(False):
        r.CyrusPerfHeadless = True
        # The same physical geometry is represented in several system units.
        for system, factor in [('meters', 1.0), ('centimeters', 100.0), ('inches', 1/.0254)]:
            r.resetMaxFile(r.Name('noPrompt')); r.units.SystemType = r.Name(system); r.units.SystemScale = 1
            root = r.AminScatterObject(name='P05 transform ' + system).baseObject
            root.updateMode = 1; root.autoRender = False
            receiver = r.Plane(name='P05 terrain', length=100*factor, width=100*factor, lengthsegs=1, widthsegs=1)
            r.convertToMesh(receiver)
            for k in range(1, receiver.numverts + 1):
                p = r.getVert(receiver, k); p.z = p.x*.1; r.setVert(receiver, k, p)
            r.update(receiver)
            # Mirror, nonuniform scale, shear, tilt and translation in one affine matrix.
            tm = r.Matrix3(r.Point3(-2, .4, .2), r.Point3(.6, 3, .5), r.Point3(.1, .2, 1.5), r.Point3(40*factor, -80*factor, 5*factor))
            receiver.transform = tm
            root.newLayer(); leaf = root.selectedLayer(); root.setLayerSurfaces(leaf, r.Array(receiver)); leaf.addPointSource()
            leaf.amount = 2000; leaf.procSelfOverride = True; leaf.procSelfEnabled = False
            area = root.addPaintArea(leaf, target=receiver)
            outline = shape([(-20*factor, -20*factor, 0), (20*factor, -20*factor, 0), (20*factor, 20*factor, 0), (-20*factor, 20*factor, 0)])
            outline.transform = tm
            check(root.importPaintSpline(area, outline, tolerance=.01*factor), system + ': import under mirrored/sheared/tilted transform')
            solve(); before = ids(); check(180 < len(before) < 460, system + ': projected local rectangle has expected coverage')
            exported = root.exportPaintSpline(area)
            tm_error = max(abs(float(getattr(exported.objectTransform, 'row'+str(i))[k])-float(getattr(receiver.objectTransform, 'row'+str(i))[k])) for i in range(1, 5) for k in range(3))
            check(tm_error < .00001*factor, system + ': export retains receiver transform within Max PRS float precision')
            r.execute('fn P05LocalKnots node = (in coordsys local (for i=1 to numKnots node 1 collect getKnotPoint node 1 i))')
            local = list(r.P05LocalKnots(exported))
            check(all(abs(p.z) < 1.e-6 and abs(abs(p.x)-20*factor) < .001*factor and abs(abs(p.y)-20*factor) < .001*factor for p in local),
                  system + ': terrain snapshot uses canonical XY plane, not lifted feedback')
            root.importPaintSpline(area, exported, tolerance=.01*factor); solve()
            check(ids() == before, system + ': transformed snapshot round trip preserves eligible candidates within tolerance')
            # Different source object offset and node transform representing the
            # same world geometry must still project into the bound receiver.
            shifted = shape([(-20*factor-7*factor, -20*factor, 0), (20*factor-7*factor, -20*factor, 0),
                             (20*factor-7*factor, 20*factor, 0), (-20*factor-7*factor, 20*factor, 0)])
            shifted.objectOffsetPos = r.Point3(7*factor, 0, 0); shifted.transform = tm
            root.importPaintSpline(area, shifted, tolerance=.01*factor); solve()
            check(ids() == before, system + ': source object offset is honored')
            circle = r.Circle(radius=10*factor); circle.transform = tm
            root.importPaintSpline(area, circle, tolerance=.01*factor); solve(); coarse = ids()
            root.importPaintSpline(area, circle, tolerance=.002*factor); solve(); fine = ids()
            check(abs(len(coarse)-len(fine)) <= 3, system + ': world-unit tolerance gives stable projected curved coverage')
            snapshot = root.exportPaintSpline(area)
            vertices = sum(r.numKnots(snapshot, i) for i in range(1, r.numSplines(snapshot)+1))
            data['measurements'].append({'system_units': system, 'curve_samples': vertices, 'count': len(fine)})
        # Admission at and above the sampled-vertex limit, separate from input knots.
        r.resetMaxFile(r.Name('noPrompt')); r.units.SystemType = r.Name('meters'); r.units.SystemScale = 1
        root = r.AminScatterObject(name='P05 budget').baseObject; root.updateMode = 1; root.autoRender = False
        receiver = r.Plane(length=100, width=100, lengthsegs=1, widthsegs=1)
        root.newLayer(); leaf = root.selectedLayer(); root.setLayerSurfaces(leaf, r.Array(receiver)); leaf.addPointSource()
        leaf.amount = 100; leaf.procSelfOverride = True; leaf.procSelfEnabled = False
        area = root.addPaintArea(leaf, target=receiver)
        dense = shape([(30*math.cos(i*math.tau/8192), 30*math.sin(i*math.tau/8192), 0) for i in range(8192)])
        started = time.perf_counter(); root.importPaintSpline(area, dense, tolerance=.001)
        import_ms = (time.perf_counter()-started)*1000
        started = time.perf_counter(); dense_snapshot = root.exportPaintSpline(area)
        export_ms = (time.perf_counter()-started)*1000
        check(r.numKnots(dense_snapshot, 1) <= 8192, 'Maximum admitted linear contour produces bounded canonical snapshot')
        data['measurements'].append({'input_knots': 8192, 'output_knots': r.numKnots(dense_snapshot, 1), 'import_ms': import_ms, 'export_ms': export_ms})
        # Many individually cheap circles exceed the aggregate sampled budget.
        circles = r.Circle(radius=20)
        r.convertToSplineShape(circles)
        for i in range(79):
            item = r.Circle(radius=20-i*.1); r.convertToSplineShape(item); r.addAndWeld(circles, item, 0)
        before = int(r.cyrusBrushStats(area.paintDocument)[0]); error = ''
        try:
            root.importPaintSpline(area, circles, tolerance=.0002)
        except Exception as exc:
            error = str(exc)
        check(bool(error) and 'limit' in error.lower() or 'budget' in error.lower(), 'Aggregate adaptive sample budget rejects excessive curves')
        check(int(r.cyrusBrushStats(area.paintDocument)[0]) == before, 'Sample-budget failure retains preceding region')
        data['status'] = 'passed'
except Exception:
    data['status'] = 'failed'; data['error'] = traceback.format_exc(); raise
finally:
    (OUT / 'phase05-transforms.json').write_text(json.dumps(data, indent=2), encoding='utf-8')
