"""Owned real-Max Paint/spline geometry, ownership and rejection witnesses."""
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
data = {'status': 'started', 'checks': [], 'timings_ms': {}, 'script': str(r.CyrusLoadedScriptFingerprint)}


def save():
    (OUT / 'phase05.json').write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')


def check(value, label):
    data['checks'].append({'passed': bool(value), 'label': label}); save()
    if not value:
        raise AssertionError(label)


def rows(index=0):
    return {str(row[2]): ([tuple(float(getattr(row[0], 'row' + str(i))[k]) for k in range(3)) for i in range(1, 5)],
                          int(row[1]), int(row[3]), tuple(float(row[4][k]) for k in range(3)), int(row[5]), bool(row[6]), int(row[7]))
            for row in root.groupSnapshotRows[index]}


def solve():
    root.procManualRevision += 1
    root.evaluateProcedural()


def square(radius):
    return [(-radius, -radius, 0), (radius, -radius, 0), (radius, radius, 0), (-radius, radius, 0)]


def shape(loops, closed=True):
    node = r.splineShape(name='P05 input')
    for index, loop in enumerate(loops, 1):
        r.addNewSpline(node)
        for point in loop:
            r.addKnot(node, index, r.Name('corner'), r.Name('line'), r.Point3(*point))
        if closed:
            r.close(node, index)
    r.updateShape(node)
    return node


def import_shape(node, add=False, tolerance=.002):
    return bool(root.importPaintSpline(area, node, add=add, tolerance=tolerance))


def revision():
    return int(r.cyrusBrushStats(area.paintDocument)[0])


def rejected(action, label, text=''):
    before = rows(); epoch = int(root.procEpoch); version = revision(); nodes = len(list(r.objects))
    message = ''
    try:
        action()
    except Exception as error:
        message = str(error)
    data.setdefault('expected_errors', []).append({'label': label, 'message': message})
    check(bool(message) and text in message, label + ' reports repair')
    check(rows() == before and root.procEpoch == epoch and revision() == version and len(list(r.objects)) == nodes,
          label + ' retains area, publication and scene nodes')


try:
    with pymxs.undo(False):
        r.CyrusPerfHeadless = True
        r.resetMaxFile(r.Name('noPrompt'))
        r.units.SystemType = r.Name('meters'); r.units.SystemScale = 1
        node = r.AminScatterObject(name='P05 conversion')
        root = node.baseObject; root.updateMode = 1; root.autoRender = False
        receiver = r.Plane(name='P05 receiver', length=100, width=100, lengthsegs=1, widthsegs=1)
        root.newLayer(); leaf = root.selectedLayer()
        root.setLayerSurfaces(leaf, r.Array(receiver)); leaf.addPointSource()
        leaf.amount = 10000; leaf.procSelfOverride = True; leaf.procSelfEnabled = False
        solve(); unmasked = rows()
        area = root.addPaintArea(leaf, target=receiver)
        check(r.cyrusBrushConversionVersion() == 1, 'Matching Brush conversion capability')
        solve(); check(len(rows()) == 0, 'Explicit empty Paint Area has empty coverage')
        rejected(lambda: root.exportPaintSpline(area), 'Empty export', 'empty')
        ring = shape([square(20), list(reversed(square(10))), square(3)])
        before = rows(); epoch = root.procEpoch
        started = time.perf_counter(); changed = import_shape(ring)
        data['timings_ms']['three_loop_import'] = (time.perf_counter() - started) * 1000
        check(changed and rows() == before and root.procEpoch == epoch, 'Manual import holds published plants')
        solve(); initial = rows()
        expected = {key: value for key, value in unmasked.items()
                    if (10 < max(abs(value[0][3][0]), abs(value[0][3][1])) < 20
                        or max(abs(value[0][3][0]), abs(value[0][3][1])) < 3)}
        check(initial == expected, 'Nested holes/island match independent full candidate oracle')
        version = revision(); identity = str(area.layerID); paint_doc = r.getHandleByAnim(area.paintDocument)
        epoch = root.procEpoch; nodes = len(list(r.objects))
        started = time.perf_counter(); exported = root.exportPaintSpline(area)
        data['timings_ms']['three_loop_export'] = (time.perf_counter() - started) * 1000
        check(r.numSplines(exported) == 3 and all(r.isClosed(exported, i) for i in range(1, 4)), 'Export preserves all closed outer/hole/island contours')
        check(len(list(r.objects)) == nodes + 1 and list(r.selection) == [exported], 'Export creates and selects one snapshot')
        check(revision() == version and rows() == initial and root.procEpoch == epoch, 'Export is passive for Paint and placement publication')
        check(not import_shape(exported) and revision() == version, 'Export/import is a revision-free no-op')
        shuffled = shape([list(reversed(square(3))), square(10), list(reversed(square(20)))])
        check(not import_shape(shuffled) and revision() == version, 'Winding/order changes retain exact canonical coverage')
        cfg = r.cyrusBrushFalloff(area.paintDocument)
        cfg[0] = .2; cfg[1] = .1; cfg[3] = True; cfg[4] = .25
        r.cyrusBrushSetFalloff(area.paintDocument, cfg)
        saved_cfg = str(r.cyrusBrushFalloff(area.paintDocument)); area.paintDensity = .75
        inner = shape([square(15)])
        import_shape(inner, add=True)
        check(str(r.cyrusBrushFalloff(area.paintDocument)) == saved_cfg and area.paintDensity == .75 and str(area.layerID) == identity and r.getHandleByAnim(area.paintDocument) == paint_doc,
              'Add preserves identity, document, density and falloff')
        cfg[0] = 0; cfg[1] = 0; cfg[3] = False; r.cyrusBrushSetFalloff(area.paintDocument, cfg); area.paintDensity = 1
        solve(); added = rows(); check(set(initial).issubset(added), 'Add only increases canonical eligible coverage')
        version = revision(); check(not import_shape(inner, add=True) and revision() == version, 'Contained Add is a no-op')
        import_shape(ring); solve(); check(rows() == initial, 'Replace restores exact full candidate result')
        r.move(ring, r.Point3(200, 0, 0)); solve()
        check(rows() == initial, 'Editing source spline after import has no live link')
        r.delete(ring); solve(); check(rows() == initial, 'Deleting source spline preserves imported coverage')
        open_shape = shape([square(5)], closed=False)
        rejected(lambda: import_shape(open_shape), 'Open spline', 'closed')
        line = shape([[(0, 0, 0), (10, 0, 0), (20, 0, 0)]])
        rejected(lambda: import_shape(line), 'Degenerate projection', 'region')
        mixed = shape([square(5), [(0, 0, 0), (10, 0, 0), (20, 0, 0)]])
        rejected(lambda: import_shape(mixed), 'One malformed contour among valid loops', 'region')
        rejected(lambda: import_shape(inner, tolerance=0), 'Zero tolerance', 'positive')
        rejected(lambda: import_shape(inner, tolerance=.00001), 'Below canonical precision', 'precision')
        rejected(lambda: import_shape(receiver), 'Non-shape input', 'closed spline')
        tiny = shape([square(.00001)])
        rejected(lambda: import_shape(tiny), 'Subquantum region', 'region')
        duplicate = shape([square(5), square(5)])
        rejected(lambda: import_shape(duplicate), 'Cancelling duplicate contours', 'region')
        huge = shape([[(float(i), float(i % 2), 0) for i in range(8193)]])
        rejected(lambda: import_shape(huge), 'Input knot limit', '8,192')
        bowtie = shape([[(-20, -20, 0), (20, 20, 0), (-20, 20, 0), (20, -20, 0)]])
        import_shape(bowtie); solve()
        expected = {key: value for key, value in unmasked.items()
                    if abs(value[0][3][0]) < abs(value[0][3][1]) < 20}
        check(rows() == expected, 'Self-crossing spline uses even-odd filled triangles')
        circle = r.Circle(name='P05 Bezier circle', radius=10)
        started = time.perf_counter(); import_shape(circle)
        data['timings_ms']['circle_import'] = (time.perf_counter() - started) * 1000
        solve(); circular = rows()
        # Max's four cubic arcs approximate a mathematical circle, so include its
        # own known cubic deviation plus our 2 mm projected sampling tolerance.
        for key, value in unmasked.items():
            radius = math.hypot(*value[0][3][:2])
            if abs(radius - 10) > .006:
                if (key in circular) != (radius < 10):
                    raise AssertionError('Circle coverage oracle')
        check(True, 'Adaptive Bezier import agrees with circle oracle outside declared boundary tolerance')
        snapshot = root.exportPaintSpline(area); version = revision()
        check(not import_shape(snapshot), 'Sampled Bezier snapshot round trip preserves canonical bytes')
        r.move(snapshot, r.Point3(0, 0, 200)); check(not import_shape(snapshot), 'Import projects along receiver-local Z')
        far = shape([[(x+1000, y, z) for x, y, z in square(5)]])
        import_shape(far); solve(); check(len(rows()) == 0, 'Valid outside Replace intentionally clears coverage')
        outer = shape([square(500)])
        import_shape(outer); solve(); check(rows() == unmasked, 'Oversized closed contour clips to receiver domain')
        # Scene lifecycle fixture consumes this exact converted document.
        import_shape(exported); solve(); check(rows() == initial, 'Final fixture restores nested canonical coverage')
        r.saveMaxFile(str(OUT / 'P05_conversion.max'), quiet=True)
        data['saved_area_id'] = identity
        data['final_rows'] = len(rows())
        data['status'] = 'passed'; save()
except Exception:
    data['status'] = 'failed'; data['error'] = traceback.format_exc(); save(); raise
