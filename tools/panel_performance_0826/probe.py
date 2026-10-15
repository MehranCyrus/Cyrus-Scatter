"""Owned Max 2027 UI probe; command and results stay in its disposable profile."""
from pathlib import Path
import json
import time
import statistics
import sys
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification'
assert OUT.name.startswith('foundation-roadmap-panel0826-')
assert json.loads((OUT / 'launch.json').read_text())['max_year'] == 2027
req = json.loads((OUT / 'panel-command.json').read_text())
result = {'operation': req['operation']}

def timed(fn, count=5):
    values = []
    for i in range(count):
        start = time.perf_counter()
        fn(i)
        values.append((time.perf_counter()-start)*1000)
    return {'ms': values, 'median_ms': statistics.median(values), 'max_ms': max(values)}

def counters():
    root = r.PanelRoot
    return {'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds),
            'prepared': [int(x.procPreparedBuilds) for x in root.layerObjects],
            'previews': [int(x.previewBuildCount) for x in root.layerObjects],
            'retained': [str(x) for x in r.cyrusRetainedStats(r.CyrusPointOwner(r.PanelNode))]}

def mount():
    r.select(r.PanelNode)
    r.execute('max modify mode')
    if r.modPanel.getCurrentObject() != r.PanelRoot:
        r.modPanel.setCurrentObject(r.PanelRoot)
    if not r.PanelRoot.mainUI.controlsReady:
        r.PanelRoot.mainUI.mountTimer.tick()

try:
    if req['operation'] == 'setup':
        r.execute('global PanelNode, PanelRoot, PanelReceiver, PanelOther')
        r.resetMaxFile(r.Name('noPrompt'))
        r.CyrusPerfHeadless = True
        r.disableSceneRedraw()
        r.PanelNode = r.AminScatterObject(name='Panel performance owned fixture')
        r.PanelRoot = r.PanelNode.baseObject
        root = r.PanelRoot
        root.updateMode = 1
        r.PanelReceiver = r.plane(length=1000, width=1000, lengthsegs=20, widthsegs=20)
        source = r.pyramid(width=2, depth=2, height=6, pos=r.Point3(-2000, 0, 0))
        for i in range(8):
            root.newLayer()
            leaf = root.selectedLayer()
            root.setLayerSurfaces(leaf, r.Array(r.PanelReceiver))
            leaf.sources = r.Array(source)
            leaf.containerMode = 1
            leaf.amount = 5000
            leaf.procSelfOverride = True
            leaf.procSelfEnabled = False
        r.PanelOther = r.box(pos=r.Point3(9000, 0, 0))
        root.autoRender = False
        root.pointsPerPlant = 1
        root.setGroupDisplay(1)
        root.refreshAll()
        root.updateMode = 2
        r.enableSceneRedraw()
        r.CyrusPointSync()
        r.completeRedraw()
        r.CyrusPerfHeadless = False
        result['placements'] = [int(x.generatedCount) for x in root.layerObjects]
        result['mount'] = timed(lambda i: mount(), 1)
        result['counters'] = counters()
    elif req['operation'] == 'measure':
        mount()
        result['before'] = counters()
        result['bind'] = timed(lambda i: r.PanelRoot.mainUI.bind(), 10)
        result['pages'] = {}
        for index, page in enumerate(r.PanelRoot.mainUI.editors):
            slot = r.PanelRoot.mainUI.slots[index] if r.isProperty(r.PanelRoot.mainUI, r.Name('slots')) else page
            result['checkpoint'] = str(page.name)
            (OUT / 'panel-progress.json').write_text(json.dumps(result, indent=2))
            slot.open = True
            r.PanelRoot.mainUI.bindSection(page)
            result['pages'][str(page.name)] = timed(lambda i: r.PanelRoot.mainUI.bindSection(page), 5)
            slot.open = False
        if r.isProperty(r.PanelRoot.mainUI, r.Name('slots')):
            r.PanelRoot.mainUI.slots[0].open = True
        else:
            r.PanelRoot.managerUI.open = True
        r.PanelRoot.mainUI.rememberViews()
        def select_again(i):
            r.select(r.PanelOther)
            mount()
        result['selection'] = timed(select_again, req.get('count', 10))
        result['after'] = counters()
    elif req['operation'] == 'lazy_probe':
        result['probe'] = str(r.execute('''
            plugin simpleObject CyrusLazyProbe name:"Cyrus lazy probe" classID:#(0x516b626,0x7a260026) noncreatable:true (
                local bodyUI=undefined
                tool create (on mousePoint click do #stop)
                fn makeBody = (
                    rollout body "" width:190 (
                        local pluginOwner
                        spinner amount "Amount" range:[0,100,1]
                    )
                    body
                )
                rollout shell "Lazy panel" width:#cmdPanel (
                    subRollout host "" pos:[0,0] width:200 height:100
                )
                on buildMesh do setMesh mesh vertices:#([0,0,0],[1,0,0],[0,1,0]) faces:#([1,2,3])
            )
            global LazyProbeNode=CyrusLazyProbe()
            select LazyProbeNode
            max modify mode
            global LazyProbeBefore=LazyProbeNode.bodyUI
            LazyProbeNode.shell.open=true
            LazyProbeNode.bodyUI=LazyProbeNode.makeBody()
            addSubRollout LazyProbeNode.shell.host LazyProbeNode.bodyUI rolledUp:false border:false
            LazyProbeNode.bodyUI.pluginOwner=LazyProbeNode.baseObject
            #(LazyProbeBefore,LazyProbeNode.bodyUI,LazyProbeNode.bodyUI.pluginOwner==LazyProbeNode.baseObject,LazyProbeNode.bodyUI.hwnd)
        '''))
    elif req['operation'] == 'save_fixture':
        sys.path.insert(0, str(ROOT / 'tools/recipes_0825'))
        from recipe_rows import fingerprint
        r.clearSelection()
        r.execute('max create mode')
        if r.isValidNode(r.LazyProbeNode):
            r.delete(r.LazyProbeNode)
        r.PanelRoot.refreshAll()
        r.CyrusPointSync()
        result['rows'] = [fingerprint(rows) for rows in r.PanelRoot.groupSnapshotRows]
        result['counters'] = counters()
        path = OUT / 'panel-baseline.max'
        assert r.saveMaxFile(str(path), quiet=True)
        result['scene'] = str(path)
    elif req['operation'] == 'inspect':
        result['state'] = str(r.execute('''with printAllElements on (
            #(PanelRoot.mainUI.controlsReady,PanelRoot.mainUI.binding,PanelRoot.mainUI.layerBinding,
              PanelRoot.mainUI.root==PanelRoot,PanelRoot.managerUISlot.view,
              PanelRoot.managerUISlot.open,PanelRoot.managerUI.isDisplayed,
              PanelRoot.managerUI.root,PanelRoot.managerUI.controlsReady,
              PanelRoot.managerUI.panel,PanelRoot.managerUI.owner,
              PanelRoot.mainUI.bindSection PanelRoot.managerUI,
              PanelRoot.managerUI.controlsReady,PanelRoot.managerUI.root==PanelRoot) as string
        )'''))
    else:
        raise ValueError(req['operation'])
    result['status'] = 'ok'
except Exception as exc:
    result['status'] = 'error'
    result['error'] = str(exc)
    raise
finally:
    (OUT / ('panel-' + req.get('label', req['operation']) + '.json')).write_text(json.dumps(result, indent=2))
