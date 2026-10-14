"""Real Max UV transport, map sampling/cache, failure and interaction witnesses."""
from pathlib import Path
import json
import traceback
import pymxs
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-p04-')
data = {'status': 'started', 'checks': [], 'script': str(r.CyrusLoadedScriptFingerprint), 'timings': []}


def save():
    (OUT / 'phase04.json').write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')


def check(value, label):
    data['checks'].append({'passed': bool(value), 'label': label})
    save()
    if not value:
        raise AssertionError(label)


def vector(v):
    return tuple(float(v[i]) for i in range(3))


def rows():
    return {str(row[2]): ([vector(getattr(row[0], 'row' + str(i))) for i in range(1, 5)],
                          int(row[1]), int(row[3]), vector(row[4]), int(row[5]), bool(row[6]), int(row[7]))
            for row in root.groupSnapshotRows[0]}


def stats():
    return list(leaf.densityCacheStats())


def solve():
    # Same explicit revision as Update, with errors propagated directly for assertions.
    root.procManualRevision += 1
    root.evaluateProcedural()


def failed(label, expected=''):
    before = rows()
    epoch = root.procEpoch
    message = ''
    try:
        solve()
    except Exception as error:
        message = str(error)
    data.setdefault('expected_errors', []).append({'label': label, 'message': message})
    check(bool(message) and expected in message, label + ' reports expected error')
    check(rows() == before and root.procEpoch == epoch, label + ' retains complete published rows and epoch')


try:
    with pymxs.undo(False):
        r.CyrusPerfHeadless = True
        r.resetMaxFile(r.Name('noPrompt'))
        r.units.SystemType = r.Name('meters'); r.units.SystemScale = 1
        node = r.AminScatterObject(name='P04 mapping')
        root = node.baseObject; root.updateMode = 1; root.autoRender = False
        receiver = r.Plane(name='P04 two channels', length=100, width=100, lengthsegs=1, widthsegs=1)
        r.convertToMesh(receiver)
        r.meshop.setNumMaps(receiver, 3, keep=True)
        r.meshop.setMapSupport(receiver, 2, True)
        r.meshop.setNumMapVerts(receiver, 2, r.meshop.getNumMapVerts(receiver, 1))
        r.meshop.setNumMapFaces(receiver, 2, receiver.numfaces)
        for i in range(1, r.meshop.getNumMapVerts(receiver, 1) + 1):
            uv = r.meshop.getMapVert(receiver, 1, i)
            r.meshop.setMapVert(receiver, 2, i, r.Point3(1 - uv.x, uv.y, uv.z))
        for i in range(1, receiver.numfaces + 1):
            r.meshop.setMapFace(receiver, 2, i, r.meshop.getMapFace(receiver, 1, i))
        r.update(receiver)
        root.newLayer(); leaf = root.selectedLayer()
        root.setLayerSurfaces(leaf, r.Array(receiver)); leaf.addPointSource()
        leaf.amount = 10000; leaf.procSelfOverride = True; leaf.procSelfEnabled = False
        check(leaf.densityUVChannel == 1 and leaf.densityResolution == 128, 'Neutral defaults retain channel 1 and 128 square')
        check(r.cyrusDensityMapVersion() == 1, 'Matching density native capability')
        solve(); unmasked = rows()
        texture = r.Checker(color1=r.color(255, 255, 255), color2=r.color(0, 0, 0))
        leaf.densityMap = texture; leaf.distributionMode = 3
        solve(); first = rows(); initial = stats()
        check(3500 < len(first) < 6500, 'Default UV channel yields a nontrivial density pattern')
        check(all(value == unmasked[key] for key, value in first.items()), 'Map eligibility preserves full surviving IDs, bases, source and anchors')
        check(initial[0] == 1 and initial[4] == 128 * 128, 'First solve performs one bounded bake')
        # Exact old 128-square luminance expression: no color or addressing change.
        bitmap = r.renderMap(texture, size=r.Point2(128, 128))
        direct = []
        for y in range(128):
            for c in r.getPixels(bitmap, r.Point2(0, y), 128):
                direct.append(min(1., max(0., (c.r * .2126 + c.g * .7152 + c.b * .0722) / 255.)))
        r.close(bitmap)
        sampled = list(leaf.procDensityWeights())
        check(max(abs(a - b) for a, b in zip(direct, sampled)) < 1e-6, 'Default cached samples match the preceding luminance expression')
        leaf.densityUVChannel = 2
        check(rows() == first, 'Manual channel edit preserves prior placements before Update')
        solve(); second = rows()
        check(3500 < len(second) < 6500 and len(set(first).symmetric_difference(second)) > 8000, 'Selected second UV channel changes the actual spatial pattern')
        check(stats()[0] == initial[0], 'Changing UV channel reuses the map bake')
        check(all(value == unmasked[key] for key, value in second.items()), 'Channel selection preserves each surviving candidate transform')
        leaf.densityUVChannel = 1; solve()
        check(rows() == first, 'Returning to channel 1 restores the exact deterministic result')
        leaf.invertDensity = True; solve()
        check(stats()[0] == 1 and stats()[2] == 1 and stats()[4] == 2 * 128 * 128, 'Invert derives one bounded array without rebaking')
        leaf.invertDensity = False; solve()
        check(rows() == first, 'Disabling inversion restores exact results')
        for resolution in [64, 128, 256, 512]:
            leaf.densityResolution = resolution; before = stats()[0]; solve()
            snapshot = rows(); after = stats()
            check(after[0] == before + 1 and after[4] == resolution * resolution, f'{resolution} samples replace the prior cache with a bounded image')
            check(3500 < len(snapshot) < 6500 and all(value == unmasked[key] for key, value in snapshot.items()), f'{resolution} preserves deterministic candidate identity and transforms')
            before = stats(); leaf.amount = 10001; solve(); leaf.amount = 10000; solve()
            check(stats()[0] == before[0] and rows() == snapshot, f'{resolution} reuses sampled data across candidate-count changes')
            data['timings'].append({'resolution': resolution, 'bake_ms': after[3], 'retained_samples': after[4]})
        before = stats(); epoch = root.procEpoch
        for _ in range(30):
            root.cacheSnapshot(); leaf.densityCacheStats()
        check(stats() == before and root.procEpoch == epoch, 'Passive snapshot/cache reads do not bake or publish')
        leaf.densityResolution = 32; failed('Unsupported resolution', '64, 128, 256 or 512')
        leaf.densityResolution = 128; solve()
        leaf.densityUVChannel = 99; failed('Missing selected UV', 'UV channel 99')
        leaf.densityUVChannel = 2; solve()
        original_uv = [r.meshop.getMapVert(receiver, 2, i) for i in range(1, r.meshop.getNumMapVerts(receiver, 2) + 1)]
        r.meshop.setNumMapVerts(receiver, 2, 1, keep=True); r.update(receiver)
        failed('Out-of-range UV face', 'invalid vertex')
        r.meshop.setNumMapVerts(receiver, 2, len(original_uv))
        for i, uv in enumerate(original_uv, 1):
            r.meshop.setMapVert(receiver, 2, i, uv)
        r.meshop.setNumMapFaces(receiver, 2, 1, keep=True)
        failed('Partial map faces', 'incomplete mapping')
        r.meshop.setNumMapFaces(receiver, 2, receiver.numfaces)
        for i in range(1, receiver.numfaces + 1):
            r.meshop.setMapFace(receiver, 2, i, r.meshop.getMapFace(receiver, 1, i))
        r.update(receiver); solve()
        before = stats()[0]
        uv = r.meshop.getMapVert(receiver, 2, 1)
        r.meshop.setMapVert(receiver, 2, 1, r.Point3(.5, .5, 0)); r.update(receiver); solve()
        check(stats()[0] == before, 'UV vertex edit changes receiver preparation without rebaking a static map')
        r.meshop.setMapVert(receiver, 2, 1, uv); r.update(receiver)
        leaf.densityUVChannel = 1; leaf.densityMap = None
        failed('Removed density map', 'Choose a density')
        leaf.densityMap = texture; solve()
        before = stats()[0]; texture.color1 = r.color(0, 0, 0); solve()
        check(stats()[0] == before + 1 and len(rows()) == 0, 'In-place map edit invalidates bake and published eligibility')
        texture.color2 = r.color(255, 255, 255); solve()
        before = stats()[0]; texture.map1 = r.Noise(); solve()
        texture.map1.size = 7; solve()
        check(stats()[0] >= before + 2, 'Nested map assignment and parameter changes invalidate the bake')
        leaf.densityMap = r.Checker(color1=r.color(255, 255, 255), color2=r.color(255, 255, 255)); solve()
        before = stats()[0]
        receiver.pos = r.Point3(0, 0, 5); solve()
        check(stats()[0] == before and len(rows()) == 10000, 'Receiver transform changes reuse a static map bake')
        leaf.slopeEnabled = True; leaf.slopeMaximum = 10
        leaf.altitudeEnabled = True; leaf.altitudeMinimum = 4; leaf.altitudeMaximum = 6
        solve(); check(len(rows()) == 10000 and stats()[0] == before, 'Surface filters compose with cached map eligibility')
        area = root.addPaintArea(leaf, target=receiver)
        r.cyrusBrushFill(area.paintDocument, 1.0); area.paintDensity = .5; leaf.paintEnabled = True
        solve(); check(4000 < len(rows()) < 6000 and stats()[0] == before, 'Paint multiplies density while reusing map samples')
        leaf.paintEnabled = False
        path = r.Rectangle(length=60, width=60, pos=r.Point3(0, 0, 5))
        leaf.addStroke(path); leaf.diversityMode = 3; leaf.setStrokeSelection(1, 2, r.Array(leaf.sourceRowIDs[0]))
        leaf.strokeStarts[0] = 0; leaf.strokeEnds[0] = 10
        solve(); check(0 < len(rows()) < 10000 and stats()[0] == before, 'Assigned Band composes with the map without rebaking')
        leaf.diversityMode = 1; leaf.relaxEnabled = True; leaf.relaxSpacing = .3; leaf.relaxIterations = 1
        solve(); check(len(rows()) > 0 and stats()[0] == before, 'Boundary Relax uses the selected mapping without rebaking')
        leaf.relaxEnabled = False; leaf.finalRelax = True; leaf.finalIterations = 1
        solve(); check(len(rows()) > 0 and stats()[0] == before, 'Final Relax transports the selected channel through its second native call')
        leaf.finalRelax = False; leaf.distributionMode = 1; solve()
        check(stats()[4] == 0, 'Leaving Texture Density releases retained map arrays')
        data['status'] = 'passed'; save()
except Exception:
    data['status'] = 'failed'; data['error'] = traceback.format_exc(); save(); raise
