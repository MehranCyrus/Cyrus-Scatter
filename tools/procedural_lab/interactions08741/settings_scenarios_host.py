"""Exercise root conflict, hiding, contact gap, and a box collider in Max."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key, phase = str(r.CVProfileCase), int(r.CVCaptureDirection)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
path = host / ('settings-scenarios-' + case_key + '.json')
report = {'case': case_key, 'status': 'running', 'checks': []} if phase == 1 else json.loads(path.read_text(encoding='utf-8'))


def stats(root):
    return json.loads(str(root.interactionsStatistics())) if root.interactionState != r.undefined else None


def section(root, layer):
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    root.selectLayer(layer)
    panel = root.mainUI
    until = time.monotonic()+8
    while not bool(panel.controlsReady) and time.monotonic() < until:
        r.windows.processPostedMessages()
        time.sleep(.02)
    assert panel.controlsReady
    panel.slots[12].open = True
    panel.bindSection(panel.editors[12])
    r.WFSection = panel.editors[12]


def move(root, target):
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.cyrusEditActiveLayers(r.WFEdit, r.Array(int(r.WFCollider.editLayerKey)))
    r.cyrusEditSelect(r.WFEdit, r.Array(1))
    # A failed successor deliberately retains the old published rows; use the
    # actual Edit handle to restore a collider that moved into a fixed root.
    handle = r.cyrusEditHandleMatrix(r.WFEdit, int(r.WFCollider.editLayerKey), 1)
    r.CVCurrent, r.CVTarget = handle.translation, r.Point3(*target)
    error = ''
    try:
        r.execute('undo "interaction settings probe" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
        root.interactionsEnsure()
    except Exception as exc:
        error = str(exc)
    result = stats(root)
    return {'error': str(root.interactionError) or error or (result or {}).get('error', ''),
            'ui_status': str(root.interactionsStatus()), 'statistics': result}


try:
    root, leaf, collider = r.WFRoot, r.WFGrass, r.WFCollider
    if phase == 1:
        assert case['status'] == 'pass' and int(root.updateMode) == 2
        before = stats(root)
        assert not before.get('error', ''), before
        definition = json.loads(str(leaf.interactionDefinitions[-1]))['source']
        guide = max((g for g in definition['metadata']['guides'] if g.get('parent', -1) < 0), key=lambda g: float(g['length_m']))
        local = guide['nodes'][0]
        r.CVPoint = r.Point3(local[0]*100., -local[2]*100., local[1]*100.)
        r.CVMatrix = r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0]
        pos = r.execute('CVPoint * CVMatrix')
        report['root_target'] = [float(pos.x), float(pos.y), float(pos.z)]
        report['before'] = before
        report['conflict'] = move(root, report['root_target'])
        assert report['conflict']['error'] and 'root' in report['conflict']['error'].lower(), report['conflict']
        assert report['conflict']['statistics']['generation'] == before['generation'], 'Failed contact replaced the previous complete result'
        report['checks'].append('Fixed-root conflict reports an error and retains the previous generation')
        report['status'] = 'conflict_checked'
    elif phase == 2:
        section(root, 1)
        r.execute('WFSection.interactionsUI_rootsCheck.changed true')
        hide_stats = stats(root)
        report['hide'] = {'error': str(root.interactionError) or hide_stats.get('error', ''), 'statistics': hide_stats}
        assert not report['hide']['error'] and report['hide']['statistics']['hidden_roots'] > 0, report['hide']
        section(root, 1)
        r.CVGap = float(r.units.decodeValue('1cm'))
        r.execute('WFSection.interactionsUI_gapSpin.changed CVGap')
        gap_stats = stats(root)
        report['gap'] = {'scene_units': float(leaf.interactionGapWU), 'error': str(root.interactionError) or gap_stats.get('error', ''), 'statistics': gap_stats}
        assert not report['gap']['error'], report['gap']
        assert report['gap']['statistics']['hidden_roots'] >= report['hide']['statistics']['hidden_roots'], 'A larger positive gap reduced rooted coverage'
        report['checks'].append('Root hiding and a larger positive contact gap update through the UI')
        report['status'] = 'coverage_checked'
    elif phase == 3:
        report['away'] = move(root, case['away']['target_scene_units'])
        assert not report['away']['error'] and report['away']['statistics']['posed'] == 0, report['away']
        section(root, 1)
        r.execute('WFSection.interactionsUI_gapSpin.changed 0.0')
        section(root, 1)
        r.execute('WFSection.interactionsUI_rootsCheck.changed false')
        section(root, 2)
        # MAXScript dropdownlist.selected is the selected text, not a
        # callable event. Exercise the same generated handler body instead.
        r.execute('WFSection.interactionsUI_chooseColliderMode 2')
        assert int(collider.interactionColliderMode) == 2 and not str(root.interactionError) and not stats(root).get('error', '')
        # A mode change schedules viewport publication. Let the host return to
        # its message loop before attempting a Cyrus Edit gesture.
        report['status'] = 'box_armed'
    elif phase == 4:
        assert int(collider.interactionColliderMode) == 2
        report['box_contact'] = move(root, case['attempts'][0]['target_scene_units'])
        assert not report['box_contact']['error'] and report['box_contact']['statistics']['fitted_guides'] > 0, report['box_contact']
        report['box_audit'] = json.loads(str(r.cyrusInteractionValidate(root.interactionState, 4000000)[2]))
        assert report['box_audit']['passed'], report['box_audit']
        report['checks'].append('Bounding-box collider produces a real, independently audited contact')
        report['status'] = 'pass'
    else:
        raise ValueError('Use phases 1 through 4')
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
else:
    report.pop('error', None)
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
