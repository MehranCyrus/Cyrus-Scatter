"""Qualify named presets in the real generated editor of an owned Max host."""
from pathlib import Path
import hashlib
import json
import re
import time
import traceback
import pymxs
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-')
data = {'status': 'started', 'checks': [], 'runtime': json.loads((OUT / 'runtime.json').read_text()) if (OUT / 'runtime.json').exists() else json.loads((OUT / 'launch.json').read_text())}
run = Path(str(r.MCPFixtureLast)).stem

def save():
    text = json.dumps(data, indent=2) + '\n'
    (OUT / ('phase02-' + run + '.json')).write_text(text, encoding='utf-8')
    (OUT / 'phase02.json').write_text(text, encoding='utf-8')

def check(ok, label):
    data['checks'].append({'passed': bool(ok), 'label': label})
    save()
    if not ok:
        raise AssertionError(label)

def stage(label):
    data['stage'] = label
    save()

def reject(fn, label):
    failed = False
    try:
        fn()
    except Exception:
        failed = True
    check(failed, label)

def counters():
    stats = list(r.cyrusRetainedStats(r.CyrusPointOwner(node)))
    return [int(root.procEpoch), int(root.groupBuilds), int(stats[2]), int(stats[5]),
            [int(x.procPreparedBuilds) for x in root.layerObjects],
            [str(r.cyrusEditFingerprint(x, 'p02')) for x in root.groupSnapshotRows]]

def bind(category, owner=None, **kw):
    return r.CyrusPresetMakeBinding(root, first if owner is None else owner, category, **kw)

def document(category, values, name='Test preset'):
    return r.Array(category, name, values)

def select(owner):
    root.mainUI.selectLayerView(owner)

def open_section(section, control):
    panel = getattr(root, section)
    panel.open = True
    root.mainUI.bindSection(panel)
    getattr(panel, control).pressed()
    check(r.CyrusPresetBrowser is not None, 'Generated ' + section + ' opener creates browser')
    return r.CyrusPresetBrowser

try:
    with pymxs.undo(False):
        stage('owned setup and matching native codec')
        if r.CyrusPresetBrowser is not None:
            r.destroyDialog(r.CyrusPresetBrowser)
        if r.CyrusFalloffGraph is not None:
            r.destroyDialog(r.CyrusFalloffGraph)
        r.CyrusPerfHeadless = True
        r.resetMaxFile(r.Name('noPrompt'))
        r.units.SystemType = r.Name('meters')
        r.units.SystemScale = 1.0
        node = r.AminScatterObject(name='P02 preset qualification')
        root = node.baseObject
        root.updateMode = 1
        root.autoRender = False
        check(str(root.uiVersion()) == re.search(r'fn uiVersion = "([^"]+)"', (ROOT / 'AminScatter/tools/ui/templates/unified-core.ms').read_text(encoding='utf-8'))[1] and r.cyrusPresetVersion() == 1, 'Matched development version and codec')
        receiver = r.plane(name='P02 receiver', length=30, width=30, lengthsegs=1, widthsegs=1)
        source = r.box(name='P02 source', length=.1, width=.1, height=.3, pos=r.Point3(-100, -100, 0))
        for amount in (40, 60):
            root.newLayer()
            leaf = root.selectedLayer()
            root.setLayerSurfaces(leaf, r.Array(receiver))
            leaf.sources = r.Array(source)
            leaf.containerMode = 1
            leaf.amount = amount
            leaf.procSelfOverride = True
            leaf.procSelfEnabled = False
        first, second = list(root.layerObjects)
        root.layerNames = r.Array('Canopy', 'Groundcover')
        root.refreshAll()
        r.CyrusPointSync()
        r.CyrusPerfHeadless = False
        r.select(node)
        r.execute('max modify mode')
        r.modPanel.setCurrentObject(root)
        if not root.mainUI.controlsReady:
            root.mainUI.mountTimer.tick()
        select(first)
        protected = [str(first.layerID), list(first.sources), list(first.surfaceNodes), str(second.layerID), int(second.amount)]
        initial = counters()
        library = Path(str(r.CyrusPresetDirectory())).resolve()
        check(library.is_relative_to(OUT), 'Library uses the owned private profile')
        if library.exists():
            archive = OUT / ('preset-files-before-' + run)
            library.rename(archive)

        stage('actual browser save, rename, selection and captured owner')
        browser = open_section('populationUI', 'distributionUI_presetsButton')
        browser.presetName.text = 'Ø¯Ø±Ø®ØªØ§Ù† / population'
        browser.saveNew.pressed()
        check(len(list(library.glob('*.cspreset.json'))) == 1, 'Save creates one validated local preset')
        item = next(library.glob('*.cspreset.json'))
        stored = r.CyrusPresetRead(str(item))
        check(str(stored[1]) == 'Ø¯Ø±Ø®ØªØ§Ù† / population', 'Unicode display name round trips without becoming a path')
        browser.presets.selection = 1
        browser.presetName.text = 'Renamed population'
        browser.renamePreset.pressed()
        data['rename_status'] = str(browser.status.text)
        check(str(r.CyrusPresetRead(str(item))[1]) == 'Renamed population', 'Rename atomically replaces metadata')
        for _ in range(30):
            browser.refreshList.pressed()
            browser.presets.selection = 1
        check(counters() == initial, 'Browse, save and rename preserve placements and upload counters')
        first.amount = 90
        select(second)
        data["apply_outer_hold"] = bool(r.theHold.Holding())
        browser.applyPreset.pressed()
        data["apply_status"] = str(browser.status.text)
        check(first.amount == 40 and second.amount == 60, 'Apply retains captured owner after selection changes')
        check('Applied.' in str(browser.status.text), 'Real Apply callback reports success')
        check(counters() == initial, 'Manual Apply retains previous complete publication')
        check(protected == [str(first.layerID), list(first.sources), list(first.surfaceNodes), str(second.layerID), int(second.amount)], 'Apply preserves assets, surfaces, identities and other layer')
        r.destroyDialog(browser)

        stage('strict file failures and old-file retention')
        original = item.read_bytes()
        parsed = json.loads(original)
        bad = library / 'bad.cspreset.json'
        for label, raw in [('future version', original.replace(b'"version": 1', b'"version": 99')),
                           ('invalid UTF-8', b'\xff'), ('oversized', b' ' * 65537),
                           ('duplicate key', original.replace(b'"version": 1', b'"version": 1, "version": 1'))]:
            bad.write_bytes(raw)
            reject(lambda: r.CyrusPresetRead(str(bad)), 'Rejects ' + label)
        result = r.CyrusPresetEntries(str(library), 'population')
        check(result[1] == 1 and len(result[0]) == 1, 'Corrupt files are skipped with a visible count')
        bad.unlink()
        locked = r.dotNetObject('System.IO.FileStream', str(item), r.dotNetClass('System.IO.FileMode').Open,
                               r.dotNetClass('System.IO.FileAccess').Read, r.dotNetClass('System.IO.FileShare').Read)
        try:
            changed = r.CyrusPresetRead(str(item))
            changed[1] = 'Cannot replace a locked file'
            reject(lambda: r.CyrusPresetWrite(str(item), changed, replace=True), 'Locked replacement fails explicitly')
        finally:
            locked.Close()
        check(item.read_bytes() == original and not list(library.glob('*.tmp')), 'Failed replacement preserves the previous file and cleans temporary file')

        stage('transforms and physical units')
        first.movXMinWU = 2.0
        first.movXMaxWU = 3.0
        first.wholeScaleMin = .5
        first.wholeScaleMax = 1.5
        first.rotZMin = 10.0
        first.rotZMax = 20.0
        target = bind('transforms')
        transform_doc = document('transforms', r.CyrusPresetCapture(target))
        r.units.SystemType = r.Name('centimeters')
        r.CyrusPresetApply(bind('transforms', second), transform_doc)
        check(abs(second.movXMinWU - 200) < .001 and abs(second.movXMaxWU - 300) < .001, 'Metre preset restores physical movements in centimetre scene')
        check(abs(second.wholeScaleMin - .5) < 1e-6 and second.rotZMin == 10, 'Dimensionless scale and degree values remain unchanged')
        check(all(abs(float(a)-float(b)) < 1e-4 for a,b in zip(r.CyrusPresetCapture(bind('transforms', second)), transform_doc[2])), 'Every captured transform value round trips across units')
        select(first)
        browser = open_section('transformsUI', 'randomUI_presetsButton')
        r.destroyDialog(browser)
        # Restore physical values before returning to metre scene units.
        r.units.SystemType = r.Name('meters')
        r.CyrusPresetApply(bind('transforms', second), transform_doc)

        stage('spacing scopes and fixed category validation')
        spacing = document('spacing', r.Array(True, 1.25, .2, True))
        r.CyrusPresetApply(bind('spacing'), spacing)
        check(first.procSelfOverride and first.procSelfEnabled and abs(first.procSelfGap-.2)<1e-6, 'Within-layer preset creates explicit effective rule')
        r.CyrusPresetApply(bind('spacing', peer=second), spacing)
        row = int(root.procPair(2, first, second))-1
        check(row >= 0 and abs(root.procRuleGapWU[row]-.2)<1e-6 and root.procRulePlanar[row], 'Pair preset binds two scene-selected owners')
        browser = open_section('spacingUI', 'proceduralUI_presetsButton')
        r.destroyDialog(browser)
        reject(lambda: r.CyrusPresetApply(bind('population'), spacing), 'Wrong category is rejected before writes')

        stage('curve samples, handles and incompatible data')
        editor = r.CyrusOpenFalloffGraph(first, None, True)
        editor.presetsButton.pressed()
        check(str(r.CyrusPresetBrowser.target.category) == 'density_curve', 'Actual graph opener binds density category')
        r.destroyDialog(r.CyrusPresetBrowser)
        curve_target = bind('density_curve', editor=editor)
        curve_doc = document('density_curve', r.Array(r.Array(.2, .8), r.Array(), False))
        r.CyrusPresetApply(curve_target, curve_doc)
        check(abs(first.fallDensityCurve[0]-.2)<1e-5 and abs(first.fallDensityCurve[-1]-.8)<1e-5, 'Samples-only density reconstructs an editable polyline')
        captured = r.CyrusPresetCapture(curve_target)
        check(len(captured[0]) == 257 and len(captured[1]) == 16, 'Capture keeps canonical samples and graph handles')
        r.CyrusPresetApply(curve_target, document('density_curve', captured))
        before = list(first.fallDensityCurve)
        broken = r.Array(r.Array(.8, .2), captured[1], False)
        reject(lambda: r.CyrusPresetApply(curve_target, document('density_curve', broken)), 'Mismatched sample and handle representations fail')
        data['curve_failed_before'] = before
        data['curve_failed_after'] = list(first.fallDensityCurve)
        data['transfer_after_failure'] = bool(first.getLayerTransfer())
        check(list(first.fallDensityCurve) == before and not first.getLayerTransfer(), 'Curve failure retains authored values and clears transfer guard')
        r.destroyDialog(editor)
        check(list(first.fallDensityCurve) == before, 'Closing the graph preserves the applied curve')

        stage('deleted owner cannot receive stale browser apply')
        root.newLayer()
        disposable = root.selectedLayer()
        stale = bind('population', disposable)
        root.layerObjects = r.Array(first, second)
        reject(lambda: r.CyrusPresetApply(stale, stored), 'Deleted owner fails before writes')
        # Leave a coherent two-layer scene for the native Undo and lifecycle fixture.
        root.layerNames = r.Array('Canopy', 'Groundcover')
        root.layerEnabled = r.Array(True, True)
        root.layerVisible = r.Array(True, True)
        first.procSelfEnabled = False
        second.procSelfEnabled = False
        root.procSetPair(2, first, second, False, 1.0, 0.0, False)
        root.refreshAll()
        r.CyrusPointSync()
        r.saveMaxFile(str(OUT / 'P02_presets.max'), quiet=True)
        data['status'] = 'complete'
except Exception:
    data['status'] = 'failed'
    data['error'] = traceback.format_exc()
finally:
    save()
if data['status'] != 'complete':
    raise RuntimeError(data['error'])
