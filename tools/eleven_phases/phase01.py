"""Real generated UI feedback and passive-read qualification in an owned Max host."""
from pathlib import Path
import hashlib
import json
import re
import statistics
import time
import traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification'
assert OUT.name.startswith(('foundation-roadmap-', 'foundation-viewport0817-phase01-'))
data = {'status': 'started', 'checks': [], 'cases': []}
RUN = Path(str(r.MCPFixtureLast)).stem

def save():
    payload = json.dumps(data, indent=2) + '\n'
    (OUT / ('phase01-' + RUN + '.json')).write_text(payload)
    (OUT / 'phase01.json').write_text(payload)

def stage(label):
    data['stage'] = label
    save()

def check(ok, label):
    data['checks'].append({'passed': bool(ok), 'label': label})
    save()
    if not ok:
        raise AssertionError(label)

def redraw():
    r.CyrusPointSync()
    r.completeRedraw()
    r.windows.processPostedMessages()

def fingerprint():
    return [str(r.cyrusEditFingerprint(rows, 'phase01')) for rows in root.groupSnapshotRows]

def counters():
    point = list(r.cyrusRetainedStats(r.CyrusPointOwner(node)))
    return {'epoch': int(root.procEpoch), 'groups': int(root.groupBuilds),
            'prepared': [int(l.procPreparedBuilds) for l in root.layerObjects],
            'preview': [int(l.previewBuildCount) for l in root.layerObjects],
            'fingerprints': fingerprint(), 'point_revision': int(point[2]), 'uploads': int(point[5])}

def text():
    root.statisticsUI.detailsUI_refreshButton.pressed()
    return str(root.statisticsUI.detailsUI_info.text)

def record(label):
    value = text()
    data['cases'].append({'label': label, 'text': value,
                         'dirty': [bool(l.dirty) for l in root.layerObjects],
                         'prepared_modes': [int(l.uiPreviewMode) for l in root.layerObjects]})
    save()
    return value

def select(leaf):
    root.mainUI.selectLayerView(leaf)
    root.statisticsUI.open = True
    root.mainUI.bindSection(root.statisticsUI)

try:
    stage('owned fixture setup')
    r.CyrusPerfHeadless = True
    r.resetMaxFile(r.Name('noPrompt'))
    node = r.AminScatterObject(name='P01 feedback qualification')
    root = node.baseObject
    root.updateMode = 1
    root.autoRender = False
    version = str(root.uiVersion())
    expected = re.search(r'fn uiVersion = "([^"]+)"', (ROOT / 'AminScatter/tools/ui/templates/unified-core.ms').read_text(encoding='utf-8'))[1]
    candidate = version == expected
    check(candidate or version == '0.81.7', 'Expected matched baseline or candidate')
    data['version'] = version
    data['loaded_script_fingerprint'] = str(r.CyrusLoadedScriptFingerprint)
    data['runtime'] = json.loads((OUT / ('runtime.json' if (OUT / 'runtime.json').exists() else 'launch.json')).read_text())
    receiver = r.plane(name='P01 receiver', length=1000, width=1000, lengthsegs=1, widthsegs=1)
    source = r.box(length=2, width=2, height=6, pos=r.Point3(-2000, -2000, 0))
    for count in [400, 600]:
        root.newLayer()
        leaf = root.selectedLayer()
        root.setLayerSurfaces(leaf, r.Array(receiver))
        leaf.sources = r.Array(source)
        leaf.containerMode = 1
        leaf.amount = count
        leaf.procSelfOverride = True
        leaf.procSelfEnabled = False
        leaf.distributionMode = 1
    root.layerNames = r.Array('Canopy', 'Groundcover')
    root.pointsPerPlant = 3
    stage('first publication')
    root.refreshAll()
    data['dirty_after_publication'] = [bool(l.dirty) for l in root.layerObjects]
    redraw()
    data['dirty_after_redraw'] = [bool(l.dirty) for l in root.layerObjects]
    check([int(l.generatedCount) for l in root.layerObjects] == [400, 600], 'Independent fixture counts')
    first, second = root.layerObjects[0], root.layerObjects[1]
    stage('mount actual generated editor')
    started = time.perf_counter()
    r.CyrusPerfHeadless = False
    r.select(node)
    r.execute('max modify mode')
    r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:
        root.mainUI.mountTimer.tick()
    select(first)
    data['editor_mount_ms'] = (time.perf_counter() - started) * 1000
    check(bool(root.statisticsUI.controlsReady), 'Actual Statistics rollout bound')
    if candidate:
        check(not root.statisticsUI.detailsUI_binding, 'Successful bind releases the statistics callback guard')
    value = record('Canopy completed')
    if candidate:
        check('Layer: Canopy' in value and 'Accepted placements: 400' in value, 'Statistics uses named owner and accepted count')
        check('Prepared cloud points: 1,200' in value, 'Cloud counts carry point units')
    select(second)
    value = record('Groundcover completed')
    if candidate:
        check('Layer: Groundcover' in value and 'Accepted placements: 600' in value, 'Owner switch binds the correct result')
    select(first)
    stage('warm passive UI reads')
    before = counters()
    timings = []
    for _ in range(120):
        started = time.perf_counter()
        root.mainUI.refreshStats()
        root.statisticsUI.detailsUI_refreshButton.pressed()
        timings.append((time.perf_counter() - started) * 1000)
    after = counters()
    data['passive_before'] = before
    data['passive_after'] = after
    data['warm_read_ms'] = {'median': statistics.median(timings), 'p95': sorted(timings)[113], 'max': max(timings)}
    check(before == after, '120 actual status/statistics callbacks preserve placement and preparation/upload counters')
    stage('Manual pending amount')
    first.amount = 450
    value = record('Manual pending 450, retained 400')
    if candidate:
        check('Manual: press Update scatter' in value and 'Requested: 400' in value and 'Accepted placements: 400' in value,
              'Pending settings do not relabel last-calculation quantities')
    check(counters() == before, 'Manual pending read leaves the previous complete publication')
    stage('prepared representation counts')
    for mode, label in [(4, 'centres'), (2, 'proxy instances'), (3, 'mesh instances'), (1, 'cloud points')]:
        root.setGroupDisplay(mode)
        redraw()
        value = record('Manual pending, mode ' + str(mode))
        if candidate:
            check('Prepared ' + label in value, 'Prepared representation unit: ' + label)
        check(fingerprint() == before['fingerprints'] and int(root.procEpoch) == before['epoch'],
              'Display change preserves Manual publication, mode ' + str(mode))
    stage('explicit update')
    root.mainUI.updateNow.pressed()
    redraw()
    value = record('Explicit update accepted')
    check(int(first.generatedCount) == 450 and int(second.generatedCount) == 600, 'Explicit Update applies only intended amount change')
    if candidate:
        check('Accepted placements: 450' in value and 'Manual: press Update scatter' not in value, 'Completed result replaces pending feedback')
        stage('rename and visibility feedback')
        root.layerNames = r.Array('Renamed Canopy', 'Groundcover')
        root.mainUI.refreshStats()
        check('Layer: Renamed Canopy' in str(root.statisticsUI.detailsUI_info.text), 'Status callback updates renamed owner')
        root.layerVisible = r.Array(False, True)
        check('Preview hidden' in record('hidden layer'), 'Hidden state explains preview visibility')
        root.layerVisible = r.Array(True, True)
        root.layerEnabled = r.Array(False, True)
        check('Layer disabled' in record('disabled layer'), 'Disabled layer state')
        root.layerEnabled = r.Array(True, True)
        root.cyrusEnabled = False
        check('Controller disabled' in record('disabled controller'), 'Disabled controller state')
        root.cyrusEnabled = True
        root.mainUI.updateNow.pressed()
        redraw()
        stage('failed successor retains complete publication')
        retained = fingerprint()
        retained_epoch = int(root.procEpoch)
        first.distributionMode = 3
        first.densityMap = None
        root.mainUI.updateNow.pressed()
        redraw()
        value = record('missing density map retains result')
        check('previous result retained' in value and 'Choose a density texture map' in value,
              'Failed successor shows retained-result state and actionable error')
        check(fingerprint() == retained and int(root.procEpoch) == retained_epoch,
              'Failed update preserves all complete placement rows and epoch')
        first.distributionMode = 1
        root.mainUI.updateNow.pressed()
        redraw()
        check('failed' not in record('recovered update').lower(), 'Valid successor clears the failure state')
        stage('successful zero result')
        first.amount = 0
        root.mainUI.updateNow.pressed()
        redraw()
        value = record('completed empty layer')
        check(int(first.generatedCount) == 0 and 'Last calculation accepted no placements' in value,
              'Successful zero is distinguished from no calculated result')
        stage('Live relevant amount and Point source')
        first.amount = 80
        first.makePointSource(1)
        root.mainUI.updateRadio.changed(2)
        redraw()
        value = record('Live Point row')
        check(int(first.generatedCount) == 80 and 'Accepted placements: 80' in value,
              'Live input update publishes Point row result')
        point_before = fingerprint()[0]
        second.amount = 610
        redraw()
        check(int(second.generatedCount) == 610 and fingerprint()[0] == point_before,
              'Independent Live layer edit preserves first layer placement fingerprint')
        stage('Manual pending before save and reopen')
        root.mainUI.updateRadio.changed(1)
        first.amount = 90
        check('Manual: press Update scatter' in record('Manual edit before save'), 'Manual edit is pending before Update')
        root.mainUI.updateNow.pressed()
        redraw()
        stage('current-schema save and reopen')
        scene = OUT / 'P01_roundtrip.max'
        r.saveMaxFile(str(scene), quiet=True)
        r.loadMaxFile(str(scene), quiet=True, useFileUnits=True)
        node = r.getNodeByName('P01 feedback qualification')
        root = node.baseObject
        first, second = root.layerObjects[0], root.layerObjects[1]
        redraw()
        r.select(node)
        r.execute('max modify mode')
        r.modPanel.setCurrentObject(root)
        if not root.mainUI.controlsReady:
            root.mainUI.mountTimer.tick()
        select(first)
        value = record('reopened Point layer')
        check('Layer: Renamed Canopy' in value and int(first.amount) == 90 and int(first.generatedCount) == 90,
              'Current-schema reopen restores named Point layer and reconstructs its result')
        stage('new layer failure without prior result')
        root.newLayer()
        fresh = root.selectedLayer()
        root.setLayerSurfaces(fresh, r.Array(r.getNodeByName('P01 receiver')))
        fresh.addPointSource()
        fresh.distributionMode = 3
        fresh.densityMap = None
        select(fresh)
        check('No calculated result' in record('new uncalculated layer'), 'An empty prepared cache is not a calculated result')
        root.mainUI.updateNow.pressed()
        value = record('new layer missing density map')
        check('no calculated result' in value.lower(), 'New failed layer is not described as a retained calculation')
    stage('persisted fixture for visual inspection')
    r.saveMaxFile(str(OUT / 'P01_feedback.max'), quiet=True)
    data['status'] = 'complete'
except Exception:
    data['status'] = 'failed'
    data['error'] = traceback.format_exc()
finally:
    save()
if data['status'] != 'complete':
    raise RuntimeError(data['error'])
