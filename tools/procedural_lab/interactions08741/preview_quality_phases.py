"""Run preview-density UI actions and contact checks on separate Max ticks."""
from pathlib import Path
import hashlib
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
key, phase = str(r.CVProfileCase), int(r.CVCaptureDirection)
case = json.loads((host / 'cases' / (key+'.json')).read_text(encoding='utf-8'))
path = host / ('preview-quality-phased-'+key+'.json')
report = {'case': key, 'status': 'running', 'samples': [],
          'scope': 'Same source and contacts; preview quality differs. UI changes and Edit moves run in separate host events.'} if phase == 1 else json.loads(path.read_text(encoding='utf-8'))


def mount(root):
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    until = time.monotonic()+10.
    while time.monotonic()<until:
        panel = root.mainUI
        if panel != r.undefined and bool(panel.controlsReady) and len(panel.slots)>12:
            root.selectLayer(1)
            panel.slots[12].open = True
            panel.bindSection(panel.editors[12])
            r.WFSection = panel.editors[12]
            return
        r.windows.processPostedMessages()
        time.sleep(.02)
    raise RuntimeError('Interaction panel did not become ready')


def settle(root):
    until = time.monotonic()+30.
    while time.monotonic()<until:
        root.interactionsEnsure()
        r.CyrusPointSync()
        r.completeRedraw()
        r.windows.processPostedMessages()
        owner = r.CyrusPointOwner(r.WFOwner)
        stats = list(r.cyrusRetainedStats(owner)) if r.isValidNode(owner) else []
        if len(stats)>11 and int(stats[11])==1:
            return
        time.sleep(.05)
    raise RuntimeError('Retained viewport did not present the current scatter within 30 seconds')


def move(root, target):
    settle(root)
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.cyrusEditActiveLayers(r.WFEdit, r.Array(int(r.WFCollider.editLayerKey)))
    r.cyrusEditSelect(r.WFEdit, r.Array(1))
    row = r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState, 2))[0][0]
    r.CVCurrent, r.CVTarget = row.row4, r.Point3(*target)
    start = time.perf_counter()
    r.execute('undo "preview density contact" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
    root.interactionsEnsure()
    r.CyrusPointSync()
    r.completeRedraw()
    return {'command_ms': (time.perf_counter()-start)*1000., 'error': str(root.interactionError),
            'statistics': json.loads(str(root.interactionsStatistics()))}


try:
    root, leaf = r.WFRoot, r.WFGrass
    if phase == 1:
        saved = str(leaf.interactionDefinitions[-1])
        assert json.loads(saved)['source']['fingerprint'] == case['source_fingerprint']
        report['definition_sha256'] = hashlib.sha256(saved.encode('utf-8')).hexdigest()
        root.showPoints = True
        root.setGroupDisplay(3)
        root.refreshDisplay()
        settle(root)
        report['status'] = 'ready'
    elif phase in (2, 4, 6):
        percent = {2:5., 4:25., 6:100.}[phase]
        mount(root)
        r.execute('WFSection.interactionsUI_foliageSpin.changed '+str(percent))
        assert abs(float(leaf.interactionFoliage)-percent/100.) < 1e-6
        assert hashlib.sha256(str(leaf.interactionDefinitions[-1]).encode('utf-8')).hexdigest() == report['definition_sha256']
        assert not str(root.interactionError), str(root.interactionError)
        info = json.loads(str(r.cyrusInteractionSourceInfo(leaf.interactionSourceCache[0][1])))
        assert info['guide_inference_reused'], 'Preview density reran guide inference'
        report['samples'].append({'percent': percent, 'preview_triangles': info['delivered_preview_triangles'],
                                  'inference_reused': info['guide_inference_reused']})
        report['status'] = 'set_'+str(int(percent))
    elif phase in (3, 5, 7):
        percent = {3:5., 5:25., 7:100.}[phase]
        sample = report['samples'][-1]
        assert sample['percent'] == percent
        target = next(x['target_scene_units'] for x in case['attempts'] if x['status']=='contact')
        sample['movement'] = move(root, target)
        assert not sample['movement']['error'] and sample['movement']['statistics']['fitted_guides'] > 0, sample['movement']
        sample['full_mesh_audit'] = json.loads(str(r.cyrusInteractionValidate(root.interactionState, 4000000)[2]))
        assert sample['full_mesh_audit']['passed'], sample['full_mesh_audit']
        r.windows.processPostedMessages()
        owner = r.CyrusPointOwner(r.WFOwner)
        sample['retained_mesh_stats'] = [int(x) for x in r.cyrusRetainedMeshStats(owner)] if r.isValidNode(owner) else []
        if phase == 7:
            mount(root)
            r.execute('WFSection.interactionsUI_validateButton.pressed()')
            sample['ui_validation'] = str(r.WFSection.interactionsUI_info.text)
            assert '-- Runtime error' not in sample['ui_validation'], sample['ui_validation']
        sample['away'] = move(root, case['away']['target_scene_units'])
        assert not sample['away']['error'] and sample['away']['statistics']['posed'] == 0, sample['away']
        report['status'] = 'checked_'+str(int(percent))
        if phase == 7:
            assert report['samples'][0]['preview_triangles'] < report['samples'][1]['preview_triangles'] < report['samples'][2]['preview_triangles']
            report['status'] = 'pass'
    else:
        raise ValueError('Use phases 1 through 7')
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
