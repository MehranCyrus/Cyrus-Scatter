"""Private Max 2027 scheduling/performance witness; never run in an artist host."""
from pathlib import Path
import hashlib
import json
import math
import shutil
import statistics
import time
import traceback

from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification'
assert OUT.name.startswith(('foundation-roadmap-idle-', 'foundation-roadmap-p05-idle-'))
assert json.loads((OUT / 'launch.json').read_text())['max_year'] == 2027
request = json.loads((OUT / 'idle-request.json').read_text())
operation = request['operation']
result = {'operation': operation, 'status': 'started'}
destination = OUT / ('idle-' + request.get('label', operation) + '.json')


def save():
    destination.write_text(json.dumps(result, indent=2) + '\n')


def counters():
    root = r.IdleRoot
    owner = r.CyrusPointOwner(r.IdleNode)
    return {
        'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds),
        'hits': int(root.groupHits),
        'prepared': [int(x.procPreparedBuilds) for x in root.layerObjects],
        'preview_builds': [int(x.previewBuildCount) for x in root.layerObjects],
        'time_queries': [int(x.inputTimeQueries) for x in root.layerObjects],
        'dirty': [bool(x.dirty) for x in root.layerObjects],
        'syncs': int(r.IdleSyncs), 'redraw_requests': int(r.IdleRedraws),
        'input_events': int(r.CyrusLiveChangeCalls),
        'pending': bool(r.CyrusPointPending), 'records_dirty': bool(r.CyrusViewportRecordsDirty),
        'presentation_pending': bool(r.CyrusPointPresentationPending),
        'release_timer': bool(r.CyrusReleaseTimer.Enabled),
        'ui_timer': bool(root.mainUI.statusTimer.active),
        'retained': [str(x) for x in r.cyrusRetainedStats(owner)] if r.isValidNode(owner) else [],
        'errors': [str(x.previewError) for x in root.layerObjects],
        'display_error': str(r.CyrusPointLastError),
    }


def fingerprints():
    return [str(r.cyrusEditFingerprint(rows, 'idle-audit')) for rows in r.IdleRoot.groupSnapshotRows]


def timed(action, count):
    values = []
    for i in range(count):
        start = time.perf_counter()
        action(i)
        values.append(1000 * (time.perf_counter() - start))
    return {'samples_ms': values, 'median_ms': statistics.median(values),
            'p95_ms': sorted(values)[math.ceil(.95 * len(values)) - 1]}


def mount():
    r.CyrusPerfHeadless = False
    r.select(r.IdleNode)
    r.execute('max modify mode')
    # Selection already mounts the object in Modify. Setting it again destroys
    # and recreates its UI, artificially doubling a normal selection's latency.
    if r.modPanel.getCurrentObject() != r.IdleRoot:
        r.modPanel.setCurrentObject(r.IdleRoot)
    if not r.IdleRoot.mainUI.controlsReady:
        r.IdleRoot.mainUI.mountTimer.tick()


try:
    save()
    if operation == 'setup':
        r.execute('global IdleNode,IdleRoot,IdleReceiver,IdleUnrelated,IdleSyncs=0,IdleRedraws=0,IdleOriginalSync,IdleOriginalRedraw,IdleTimer,IdleTicks,IdleNativeMatches')
        r.resetMaxFile(r.Name('noPrompt'))
        r.CyrusPerfHeadless = True
        r.disableSceneRedraw()
        if request.get('terrace'):
            original = ROOT / 'Test Scene/Terraces_0815/Terraces_0815_Final.max'
            result['scene_sha256'] = hashlib.sha256(original.read_bytes()).hexdigest()
            copied = OUT / 'Terrace_input.max'
            shutil.copy2(original, copied)
            assert r.loadMaxFile(str(copied), quiet=True, useFileUnits=True)
            r.IdleNode = r.getNodeByName('CYRUS | Terrace planting 0.81.5')
            camera = r.getNodeByName('PhysCamera002')
            r.viewport.setLayout(r.Name('layout_1'))
            r.viewport.setType(r.Name('view_persp_user'))
            r.viewport.setTM(r.inverse(camera.transform))
            r.viewport.setFOV(camera.fov)
            r.IdleRoot = r.IdleNode.baseObject
            r.IdleReceiver = r.IdleRoot.layerObjects[0].validSurfaces()[0]
        else:
            r.IdleNode = r.AminScatterObject(name='Idle audit controller')
            r.IdleRoot = r.IdleNode.baseObject
            r.IdleRoot.updateMode = 1
            r.IdleReceiver = r.plane(length=1000, width=1000, lengthsegs=8, widthsegs=8)
            source = r.box(length=1, width=1, height=4, pos=r.Point3(-2000, 0, 0))
            for i in range(8):
                r.IdleRoot.newLayer()
                leaf = r.IdleRoot.selectedLayer()
                r.IdleRoot.setLayerSurfaces(leaf, r.Array(r.IdleReceiver))
                leaf.sources = r.Array(source)
                leaf.containerMode = 1
                leaf.amount = 5000
                leaf.procSelfOverride = True
                leaf.procSelfEnabled = False
            for i in range(1000):
                r.box(length=1, width=1, height=1, pos=r.Point3(5000 + i * 3, 0, 0), name='Unrelated audit model')
            r.viewport.setLayout(r.Name('layout_1'))
            r.viewport.setType(r.Name('view_persp_user'))
        r.IdleUnrelated = r.box(length=3, width=3, height=3, pos=r.Point3(9000, 9000, 0), name='Unrelated audit event')
        r.IdleRoot.autoRender = False
        r.IdleRoot.updateMode = 1
        r.IdleRoot.pointsPerPlant = 1
        r.IdleRoot.setGroupDisplay(1)
        r.IdleRoot.refreshAll()
        r.IdleRoot.updateMode = 2
        r.enableSceneRedraw()
        r.CyrusPointSync()
        r.completeRedraw()
        r.execute('''
            IdleOriginalSync=CyrusPointSync;IdleOriginalRedraw=CyrusViewportRedraw
            fn CyrusPointSync = (IdleSyncs+=1;IdleOriginalSync())
            fn CyrusViewportRedraw = (IdleRedraws+=1;IdleOriginalRedraw())
        ''')
        result['placements'] = [int(x.generatedCount) for x in r.IdleRoot.layerObjects]
        result['fingerprints'] = fingerprints()
        result['after'] = counters()
    elif operation == 'arm_idle':
        result['before'] = counters()
        result['fingerprints'] = fingerprints()
        r.execute('''
            try(IdleTimer.Stop();IdleTimer.Dispose())catch()
            deleteFile (MCPFixtureDir+"idle-ready.txt")
            IdleTicks=0
            fn IdleTick sender args = (
                IdleTicks+=1
                if IdleTicks>=50 do (
                    IdleTimer.Stop()
                    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"idle-ready.txt") "ready"
                )
            )
            IdleTimer=dotNetObject "System.Windows.Forms.Timer";IdleTimer.Interval=100
            dotNet.addEventHandler IdleTimer "Tick" IdleTick;IdleTimer.Start()
        ''')
    elif operation == 'observe':
        result['after'] = counters()
        result['fingerprints'] = fingerprints()
    elif operation == 'trace':
        r.execute('''
            global IdleInputLog=#()
            fn CyrusPerfTraceInput origin event handles = (
                if IdleInputLog.count<180 do append IdleInputLog #(timeStamp(),event,
                    for h in handles collect (local n=getAnimByHandle h;#(h,if isValidNode n then n.name else "deleted")),
                    for leaf in IdleRoot.layerObjects collect #(leaf.dirty,leaf.procGeometryRevision,leaf.containerUIChanged))
            )
        ''')
        result['after'] = counters()
    elif operation == 'trace_result':
        result['events'] = str(r.execute('with printAllElements on (IdleInputLog as string)'))
        result['after'] = counters()
    elif operation == 'navigation':
        result['before'] = counters()
        result['before_fingerprints'] = fingerprints()
        base = r.viewport.getTM()
        def frame(i):
            r.viewport.setTM(r.rotateZMatrix(1.5 * math.sin((i + 1) * .15)) * base)
            r.completeRedraw()
            r.windows.processPostedMessages()
        result['timing'] = timed(frame, 80)
        r.viewport.setTM(base)
        result['after'] = counters()
        result['fingerprints'] = fingerprints()
    elif operation == 'panels':
        result['before'] = counters()
        result['before_fingerprints'] = fingerprints()
        result['mount'] = timed(lambda i: mount(), 1)
        result['panels'] = {}
        for name in ['populationUI', 'modelsUI', 'areasUI', 'transformsUI', 'displayUI', 'statisticsUI']:
            section = r.getProperty(r.IdleRoot, r.Name(name))
            def toggle(i):
                section.open = False
                section.open = True
                # Include actual binding: a programmatic .open assignment alone
                # does not establish that Max delivered a physical rolledUp.
                r.IdleRoot.mainUI.bindSection(section)
            result['panels'][name] = timed(toggle, 5)
            save()
        def select_again(i):
            r.select(r.IdleUnrelated)
            r.modPanel.setCurrentObject(r.IdleUnrelated.baseObject)
            mount()
        result['selection'] = timed(select_again, 3)
        result['after'] = counters()
        result['fingerprints'] = fingerprints()
    elif operation == 'unrelated':
        result['before'] = counters()
        result['before_fingerprints'] = fingerprints()
        handle = r.getHandleByAnim(r.IdleUnrelated)
        result['dispatch'] = timed(lambda i: r.AminScatterLiveChanged(r.Name('geometryChanged'), r.Array(handle)), 100)
        r.IdleUnrelated.pos = r.Point3(9001, 9000, 0)
        result['after'] = counters()
        result['fingerprints'] = fingerprints()
    elif operation == 'panel_profile':
        r.clearSelection()
        r.execute('max create mode')
        r.CyrusPerfHeadless = False
        result['select'] = timed(lambda i: r.select(r.IdleNode), 1)
        result['modify'] = timed(lambda i: r.execute('max modify mode'), 1)
        result['set_current'] = timed(lambda i: r.modPanel.setCurrentObject(r.IdleRoot), 1)
        result['mount_tick'] = timed(lambda i: r.IdleRoot.mainUI.mountTimer.tick(), 1)
        result['bind'] = timed(lambda i: r.IdleRoot.mainUI.bind(), 5)
        result['native_layout'] = timed(lambda i: r.cyrusSetRolloutVisible(r.IdleRoot.mainUI.hwnd, True, 0), 10)
        result['layouts'] = {}
        for name in ['managerUI', 'modelsUI', 'areasUI', 'transformsUI', 'displayUI']:
            section = r.getProperty(r.IdleRoot, r.Name(name))
            section.open = True
            r.IdleRoot.mainUI.bindSection(section)
            result['layouts'][name] = timed(lambda i: section.layout(), 5)
        result['after'] = counters()
    elif operation == 'panel_detail':
        mount()
        result['before'] = counters()
        result['components'] = {}
        for name, functions in {
            'modelsUI': ['sourceUI_bind', 'layout'],
            'areasUI': ['areaUI_bind', 'areaUI_syncAnalyzerArea', 'areaUI_syncFalloff', 'areaUI_syncSurfaceFilters', 'areaUI_updateAreas', 'areaUI_arrangeDetails', 'layout'],
            'coverageUI': ['brushUI_bind', 'layout'],
            'transformsUI': ['randomUI_bind', 'layout'],
        }.items():
            section = r.getProperty(r.IdleRoot, r.Name(name))
            section.open = True
            r.IdleRoot.mainUI.bindSection(section)
            for function in functions:
                action = r.getProperty(section, r.Name(function))
                owner = r.IdleRoot.selectedLayer()
                if function == 'brushUI_bind':
                    owner = r.IdleRoot.selectedPaintArea(owner)
                result['components'][name + '.' + function] = timed(
                    lambda i: action(owner) if function.endswith('_bind') else action(), 5)
                save()
        result['after'] = counters()
    elif operation == 'parameter':
        mount()
        section = r.IdleRoot.populationUI
        section.open = True
        r.IdleRoot.mainUI.bindSection(section)
        result['before'] = counters()
        result['before_fingerprints'] = fingerprints()
        control = section.distributionUI_countSpin
        value = int(r.IdleRoot.selectedLayer().amount) + 1
        result['timing'] = timed(lambda i: control.changed(value), 1)
        result['after'] = counters()
        result['fingerprints'] = fingerprints()
    elif operation == 'mesh':
        result['before'] = counters()
        result['before_fingerprints'] = fingerprints()
        r.IdleRoot.setGroupDisplay(3)
        r.CyrusPointSync()
        r.completeRedraw()
        result['after'] = counters()
        result['fingerprints'] = fingerprints()
    elif operation == 'not_ready':
        result['before'] = counters()
        # A hidden native helper cannot submit its new render items. The visible
        # controller still has a complete CPU fallback. Exercise real readiness.
        owner = r.CyrusPointOwner(r.IdleNode)
        r.hide(owner)
        r.cyrusRetainedPublish(owner, r.IdleNode, r.Array(), r.Array())
        r.CyrusPointSync()
        r.completeRedraw()
        result['after'] = counters()
    elif operation == 'recover':
        r.unhide(r.CyrusPointOwner(r.IdleNode))
        r.IdleRoot.refreshDisplay()
        r.completeRedraw()
        result['after'] = counters()
    else:
        raise ValueError(operation)
    result['status'] = 'complete'
except Exception:
    result['status'] = 'failed'
    result['error'] = traceback.format_exc()
finally:
    save()
if result['status'] != 'complete':
    raise RuntimeError(result['error'])
