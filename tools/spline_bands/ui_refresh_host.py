"""Pointer/layout regression in a disposable, matched Max 2026/2027 host.

Invoke real .NET MouseMove and native radio handlers. Instrument only the owned
copy to count layouts; finally reload the pristine matched script for UI checks.
"""
from pathlib import Path
import hashlib
import json
import time
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-ui-refresh-'):
    raise RuntimeError('Owned UI refresh host required')
source = OUT / 'scripts/CyrusScatter.ms'
receipt = OUT / ('ui-refresh-' + uuid.uuid4().hex + '.json')
report = {'checks': [], 'samples': [], 'launch': json.loads((OUT / 'launch.json').read_text()),
          'fixture_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}


def save():
    receipt.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


def check(value, label):
    report['checks'].append({'passed': bool(value), 'label': label}); save()
    if not value:
        raise AssertionError(label)


def ms(code):
    return r.execute('(\n' + code + '\n)')


def counters():
    return {'epoch': int(r.UIRoot.procEpoch), 'prepared': int(r.UILeaf.procPreparedBuilds),
            'streams': list(map(int, r.cyrusRetainedStreamStats())),
            'geometry': list(map(int, r.cyrusSourceGeometryStats()))}


def rows():
    return [[[[float(v) for v in xyz] for xyz in (row[0].row1, row[0].row2, row[0].row3, row[0].row4)],
             int(row[1]), str(row[2]), int(row[3]), list(map(float, row[4])), int(row[5]), bool(row[6]), int(row[7])]
            for row in r.UIRoot.groupSnapshotRows[0]]


def sample(label, code):
    r.UIRefreshCounts = r.Array(0, 0, 0, 0)
    before = counters(); start = time.perf_counter(); ms(code)
    result = {'action': label, 'ms': (time.perf_counter() - start) * 1000,
              'calls': list(map(int, r.UIRefreshCounts)), 'before': before, 'after': counters()}
    report['samples'].append(result); save()
    return result


SETUP = '''
global UINode=AminScatterObject name:"UI refresh regression"
global UIRoot=UINode.baseObject
UIRoot.updateMode=1;UIRoot.autoRender=false;UIRoot.newLayer()
global UILeaf=UIRoot.selectedLayer()
global UIReceiver=plane width:500 length:500 widthsegs:1 lengthsegs:1
global UISources=#(box width:3 length:3 height:8 pos:[500,0,0],sphere radius:3 pos:[520,0,0])
UIRoot.setLayerSurfaces UILeaf #(UIReceiver)
UILeaf.sources=UISources;UILeaf.addPointSource();UILeaf.amount=2000
UIRoot.evaluateProcedural()
UILeaf.addStroke (rectangle width:100 length:100)
UILeaf.setStrokeSelection 1 2 #(UISources[1]);UILeaf.diversityMode=3
select UINode;max modify mode
if not UIRoot.mainUI.controlsReady do UIRoot.mainUI.mountTimer.tick()
UIRoot.mainUI.selectLayerView UILeaf
UIRoot.modelsUI.open=true;UIRoot.mainUI.bindSection UIRoot.modelsUI
UIRoot.layoutUI.open=true;UIRoot.mainUI.bindSection UIRoot.layoutUI
global UIModels=UIRoot.modelsUI,UILayout=UIRoot.layoutUI
'''


def bind_mouse():
    ms('''
global UIList=UIModels.sourceUI_plantList_colored
global UIMoveMethod=(UIList.GetType()).GetMethod "OnMouseMove" (dotNet.combineEnums (dotNetClass "System.Reflection.BindingFlags").Instance (dotNetClass "System.Reflection.BindingFlags").NonPublic)
global UIMoveArgs=dotNetObject "System.Windows.Forms.MouseEventArgs" (dotNetClass "System.Windows.Forms.MouseButtons").None 0 30 8 0
''')


try:
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    check(digest == report['launch']['script_sha256'] == hashlib.sha256((ROOT / 'AminScatter/scripts/AminScatterObject.ms').read_bytes()).hexdigest(), 'Owned startup and current generated script match')
    r.resetMaxFile(r.Name('noPrompt'))
    text = source.read_text(encoding='utf-8-sig')
    for signature, slot in [('fn layout = (', 1), ('fn syncColorLists = (', 2),
                            ('fn layoutPanels = (', 3), ('fn CyrusLicenseCanEdit = (', 4)]:
        assert signature in text
        text = text.replace(signature, signature + f'UIRefreshCounts[{slot}]+=1;')
    instrument = OUT / ('instrumented-' + uuid.uuid4().hex + '.ms')
    instrument.write_text('global UIRefreshCounts=#(0,0,0,0)\n' + text, encoding='utf-8')
    r.fileIn(str(instrument)); ms(SETUP)
    r.CyrusPerfHeadless = False
    ms('completeRedraw();windows.processPostedMessages()')
    retained = rows(); check(len(retained) > 0, 'Fixture retains a nonempty completed Manual result')
    baseline = counters()
    for view in ['inline', 'container']:
        if view == 'container':
            ms('global UIContainer=UILeaf.containerCreate();UILeaf.containerMode=1;select UIContainer;max modify mode;if not UIContainer.mainUI.controlsReady do UIContainer.mainUI.mountTimer.tick();UIContainer.modelsUI.open=true;UIContainer.layoutUI.open=true;UIContainer.mainUI.bind();UIModels=UIContainer.modelsUI;UILayout=UIContainer.layoutUI')
        bind_mouse()
        for label, code in [
            ('100 same-row moves', 'for i=1 to 100 do UIMoveMethod.Invoke UIList #(UIMoveArgs)'),
            ('20 model/Point row moves', 'for i=1 to 20 do (local ev=dotNetObject "System.Windows.Forms.MouseEventArgs" (dotNetClass "System.Windows.Forms.MouseButtons").None 0 30 (8+16*(mod i 3)) 0;UIMoveMethod.Invoke UIList #(ev))')]:
            result = sample(view + ': ' + label, code)
            check(result['calls'] == [0, 0, 0, 0], view + ': pointer inspection performs no layout, list sync or edit-gate calls')
            check(result['before'] == result['after'] and rows() == retained, view + ': hover preserves complete placements, preparation and GPU/source counters')
        ms('UIMoveMethod.Invoke UIList #(UIMoveArgs)')
        check(ms('(UIModels.sourceUI_plantList_colored_tip.GetToolTip UIList)==(UILeaf.sourceBandDetails 1)'), view + ': membership tooltip remains accurate')
        sample(view + ': change selection', 'UIList.ClearSelected();UIList.SetSelected 1 true')
        check(ms('UIModels.sourceUI_plantList.selection==#{2} and UIModels.sourceUI_sourceName.text==(UILeaf.sourceLabel 2)'), view + ': visible selection updates source controls')
        for mode in [1, 2, 3, 4, 1, 2, 3, 4]:
            result = sample(view + ': mode ' + str(mode), f'UILayout.diversityUI_diversityRadio.state={mode};UILayout.diversityUI_diversityRadio.changed {mode}')
            check(int(r.UILeaf.diversityMode) == mode and result['calls'][:3] == [1, 1, 0], view + ': mode changes lay out only their own page once')
            check(ms(f'UILayout.diversityUI_sizeSpin.visible==({mode}==2) and UILayout.diversityUI_pathsList.visible==({mode}==3) and UILayout.diversityUI_analyzerStatus.visible==({mode}==4)'), view + ': correct mode-specific controls are visible')
        check(rows() == retained and int(r.UIRoot.procEpoch) == baseline['epoch'] and int(r.UILeaf.procPreparedBuilds) == baseline['prepared'], view + ': selection and pending mode edits retain Manual publication')
        ms('UIMoveMethod.Invoke UIList #(UIMoveArgs);UIModels.controlsReady=false;UIModels.root=undefined;UIList.Dispose()')
        check(ms('UIModels.sourceUI_plantList_colored_tip==undefined and UIModels.sourceUI_plantList_colored_tipRow== -1'), view + ': handle destruction disposes tooltip after owner lifetime ends')
    r.resetMaxFile(r.Name('noPrompt')); r.fileIn(str(source)); ms(SETUP)
    ms('completeRedraw();windows.processPostedMessages()')
    check(ms('UIRoot.modelsUI.sourceUI_plantList_colored.Items.Count==3 and UIRoot.layoutUI.diversityUI_pathsList.visible'), 'Pristine generated script remounts Models/Points and Spline bands')
    scene = OUT / ('UI-refresh-Max' + str(report['launch']['max_year']) + '.max')
    r.saveMaxFile(str(scene), quiet=True)
    report['source_sha256'] = digest
    report['instrumentation'] = 'Counters at four function entries in an owned copy; pristine source restored for final mount.'
    report['passed'] = True
except Exception:
    report['passed'] = False; report['error'] = traceback.format_exc()
finally:
    save()
if not report['passed']:
    raise RuntimeError(report['error'])
