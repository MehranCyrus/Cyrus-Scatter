"""Real Max surface-filter oracle, cache, failure and interaction witnesses."""
from pathlib import Path
import hashlib
import json
import math
import time
import traceback
import pymxs
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-')
RUN = Path(str(r.MCPFixtureLast)).stem
data = {'status': 'started', 'checks': [], 'script': str(r.CyrusLoadedScriptFingerprint)}


def save():
    text = json.dumps(data, indent=2) + '\n'
    (OUT / ('phase03-' + RUN + '.json')).write_text(text, encoding='utf-8')
    (OUT / 'phase03.json').write_text(text, encoding='utf-8')


def check(ok, label):
    data['checks'].append({'passed': bool(ok), 'label': label})
    save()
    if not ok:
        raise AssertionError(label)


def vector(v):
    return tuple(float(v[i]) for i in range(3))


def row_value(row):
    tm = row[0]
    return ([vector(getattr(tm, 'row' + str(i))) for i in range(1, 5)], int(row[1]), str(row[2]),
            int(row[3]), vector(row[4]), int(row[5]), bool(row[6]), int(row[7]))


def rows(index=0):
    return {str(row[2]): row_value(row) for row in root.groupSnapshotRows[index]}


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def solve():
    root.refreshAll()
    if str(first.previewError):
        raise AssertionError(str(first.previewError))


def slope_vertices():
    vertices, faces, known = [], [], []
    for i, angle in enumerate([0, 30, 45, 60, 90, 120, 180]):
        a = math.radians(angle)
        # Equal-area independent panels, with upward and downward triangles.
        tri = [(i * 30, 0, i * 20), (i * 30 + 10, 0, i * 20),
               (i * 30, 10 * math.cos(a), i * 20 + 10 * math.sin(a))]
        faces.append(r.Point3(len(vertices) + 1, len(vertices) + 2, len(vertices) + 3))
        vertices.extend(r.Point3(*p) for p in tri)
        known.append([vector(p) for p in vertices[-3:]])
    return vertices, faces, known


def height_for(row):
    tri = known[row[3] - 1]
    bary = row[4]
    return tri[0][2] + (tri[1][2] - tri[0][2]) * bary[1] + (tri[2][2] - tri[0][2]) * bary[2]


def subset(expected, label):
    actual = rows()
    check(actual == expected, label + ' (all IDs, basis, source, anchor and protection fields)')


try:
    with pymxs.undo(False):
        r.CyrusPerfHeadless = True
        r.resetMaxFile(r.Name('noPrompt'))
        r.units.SystemType = r.Name('meters'); r.units.SystemScale = 1
        node = r.AminScatterObject(name='P03 surface eligibility')
        root = node.baseObject; root.updateMode = 1; root.autoRender = False
        vertices, faces, known = slope_vertices()
        receiver = r.mesh(name='P03 analytic panels', vertices=r.Array(*vertices), faces=r.Array(*faces))
        for count in [7000, 30]:
            root.newLayer(); leaf = root.selectedLayer()
            root.setLayerSurfaces(leaf, r.Array(receiver)); leaf.addPointSource()
            leaf.amount = count; leaf.procSelfOverride = True; leaf.procSelfEnabled = False
        first, second = root.layerObjects[0], root.layerObjects[1]
        first.rotXMin = -15; first.rotXMax = 15
        first.wholeScaleMin = .7; first.wholeScaleMax = 1.3
        solve(); base = rows(); sibling = rows(1)
        check(len(base) == 7000 and int(r.cyrusSurfaceFilterVersion()) == 1, 'Matched filter capability and neutral defaults')
        receiver_builds = int(first.receiverCacheStats()[0])
        first.slopeMaximum = 40; first.slopeEnabled = True
        epoch = int(root.procEpoch)
        check(rows() == base and int(root.procEpoch) == epoch, 'Manual filter edit retains complete publication')
        solve()
        subset({k: v for k, v in base.items() if v[3] <= 2}, 'Hard slope selects 0 and 30 degree faces')
        check(rows(1) == sibling, 'Independent sibling result is unchanged')
        check(int(first.receiverCacheStats()[0]) == receiver_builds, 'Filter change reuses receiver candidates')
        stats = list(first.surfaceFilterStats())
        check(stats == [7000, 7000 - len(rows()), 0], 'Published diagnostics describe the prepared pool')
        first.slopeMinimum = 80; first.slopeMaximum = 100; solve()
        subset({k: v for k, v in base.items() if v[3] == 5}, 'Vertical faces use 90 degree slope')
        first.slopeMinimum = 170; first.slopeMaximum = 180; solve()
        subset({k: v for k, v in base.items() if v[3] == 7}, 'Undersides use 180 degrees')
        first.slopeMinimum = 0; first.slopeMaximum = 0; solve()
        subset({k: v for k, v in base.items() if v[3] == 1}, 'Equal hard slope endpoints include flat faces')
        first.slopeEnabled = False; first.altitudeEnabled = True
        first.altitudeMinimum = 25; first.altitudeMaximum = 85; solve()
        subset({k: v for k, v in base.items() if 25 <= height_for(v) <= 85}, 'World-Z interval matches an independent anchor oracle')
        first.altitudeMinimum = 120; first.altitudeMaximum = 120; solve()
        # Flat underside at z=120 is a hard endpoint, independent of barycentric rounding.
        subset({k: v for k, v in base.items() if v[3] == 7}, 'Equal hard altitude endpoints include an elevated flat face')
        first.altitudeMinimum = 0; first.altitudeMaximum = 140
        first.altitudeLowerFade = 60; first.altitudeUpperFade = 60; solve()
        faded = rows()
        check(0 < len(faded) < 6000 and all(k in base and v == base[k] for k, v in faded.items()), 'Inside fades thin without rerolling surviving candidates')
        first.altitudeEnabled = False; solve(); subset(base, 'Disabling filters restores the exact original candidates')
        first.altitudeEnabled = True; solve(); subset(faded, 'Re-enabling fades is exactly repeatable')
        before = digest(rows()); old_stats = list(first.surfaceFilterStats()); old_epoch = int(root.procEpoch)
        first.altitudeLowerFade = 100
        failed = False
        try:
            root.evaluateProcedural()
        except Exception:
            failed = True
        check(failed and digest(rows()) == before and list(first.surfaceFilterStats()) == old_stats and int(root.procEpoch) == old_epoch,
              'Overlapping fades reject atomically, preserving rows, diagnostics and epoch')
        first.altitudeLowerFade = 60; solve(); subset(faded, 'Correcting invalid fades recovers the previous result')
        # Exercise actual generated control callbacks and passive navigation.
        r.CyrusPerfHeadless = False; r.select(node); r.execute('max modify mode'); r.modPanel.setCurrentObject(root)
        if not root.mainUI.controlsReady:
            root.mainUI.mountTimer.tick()
        root.mainUI.selectLayerView(first); root.areasUI.open = True; root.mainUI.bindSection(root.areasUI)
        check(bool(root.areasUI.areaUI_altitudeMinSpin.enabled) and not bool(root.areasUI.areaUI_slopeMinSpin.enabled), 'Generated controls follow independent enable flags')
        state = (int(root.procEpoch), int(first.procPreparedBuilds), int(first.receiverCacheStats()[0]), digest(rows()))
        started = time.perf_counter()
        for _ in range(30):
            root.mainUI.selectLayerView(second); root.mainUI.selectLayerView(first); root.mainUI.bindSection(root.areasUI)
        data['owner_switch_60_ms'] = (time.perf_counter() - started) * 1000
        check(state == (int(root.procEpoch), int(first.procPreparedBuilds), int(first.receiverCacheStats()[0]), digest(rows())), 'Owner switching and control binding perform no solve/preparation')
        root.areasUI.areaUI_altitudeMaxSpin.changed(150)
        check(float(first.altitudeMaximum) == 150 and not bool(second.altitudeEnabled), 'Actual spinner edits its captured layer only')
        check(digest(rows()) == state[3], 'Actual Manual spinner callback preserves publication')
        first.altitudeMaximum = 140; first.altitudeEnabled = False; solve()
        r.CyrusPerfHeadless = True
        # Source offsets must not move the altitude sampling point.
        first.sourceZOffsetsWU = r.Array(1000.0); solve(); offset_base = rows()
        first.altitudeMinimum = 25; first.altitudeMaximum = 85; first.altitudeLowerFade = 0; first.altitudeUpperFade = 0
        first.altitudeEnabled = True; solve()
        subset({k: v for k, v in offset_base.items() if 25 <= height_for(v) <= 85}, 'Source offsets do not change receiver altitude eligibility')
        first.altitudeEnabled = False; first.sourceZOffsetsWU = r.Array(0.0); solve()
        # Both movement stages precede eligibility; compare against their unfiltered result.
        for field in ['relaxEnabled', 'finalRelax']:
            setattr(first, field, True); first.relaxSpacing = 1.0; first.finalMaxMove = .5
            solve(); relaxed = rows()
            first.altitudeEnabled = True; solve()
            subset({k: v for k, v in relaxed.items() if 25 <= height_for(v) <= 85}, field + ' completes before filtering')
            first.altitudeEnabled = False; setattr(first, field, False)
        # Persistent real Edit modifications are protected when every ordinary candidate fails.
        solve(); edit = r.CyrusScatterEdit(); r.addModifier(node, edit); solve()
        r.cyrusEditSelect(edit, r.Array(1, 2)); r.cyrusEditCommand(edit, 4, r.transMatrix(r.Point3(0, 0, 300)))
        solve(); edited = rows(); protected = {k: v for k, v in edited.items() if v[6]}
        check(len(protected) == 2, 'Real Edit transaction marks two transformed rows protected')
        binding = str(first.procBindingKey)
        first.altitudeMinimum = -100; first.altitudeMaximum = -90; first.altitudeEnabled = True; solve()
        subset(protected, 'Protected Edit plants bypass an otherwise empty filter')
        check(str(first.procBindingKey) == binding and list(first.surfaceFilterStats())[2] == 2, 'Filter changes preserve Edit binding and publish protection count')
        first.altitudeEnabled = False; solve(); subset(edited, 'Disabling filters restores ordinary and protected Edit rows')
        r.saveMaxFile(str(OUT / 'P03_filter_edit.max'), quiet=True)
        data['status'] = 'complete'
except Exception:
    data['status'] = 'failed'; data['error'] = traceback.format_exc()
finally:
    save()
if data['status'] != 'complete':
    raise RuntimeError(data['error'])
