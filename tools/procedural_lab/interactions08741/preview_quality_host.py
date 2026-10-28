"""Compare user-visible foliage percentages on the same real contact path."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key = str(r.CVProfileCase)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
path = host / ('preview-quality-' + case_key + '.json')
report = {'case': case_key, 'model_name': case['name'], 'samples': [], 'status': 'running',
          'scope': 'Same plant and sphere contact. Preview settings deliberately differ; timings are not FPS or an equal-quality speedup.'}


def save():
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')


def mount(root):
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    until = time.monotonic()+10.
    while time.monotonic()<until:
        panel = root.mainUI
        if panel != r.undefined and bool(panel.controlsReady) and len(panel.slots) > 12:
            root.selectLayer(1)
            panel.slots[12].open = True
            panel.bindSection(panel.editors[12])
            r.WFSection = panel.editors[12]
            return
        r.windows.processPostedMessages()
        time.sleep(.02)
    raise RuntimeError('Interaction panel did not become ready')


def edit_move(target):
    row = r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState, 2))[0][0]
    r.CVCurrent, r.CVTarget = row.row4, r.Point3(*target)
    start = time.perf_counter()
    r.execute('undo "preview quality contact" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
    moved = time.perf_counter()
    r.WFRoot.interactionsEnsure()
    r.CyrusPointSync()
    sync = time.perf_counter()
    r.completeRedraw()
    return {'move_ms': (moved-start)*1000, 'sync_and_ensure_ms': (sync-moved)*1000,
            'command_ms': (time.perf_counter()-start)*1000,
            'statistics': json.loads(str(r.WFRoot.interactionsStatistics())),
            'error': str(r.WFRoot.interactionError)}


try:
    root, leaf = r.WFRoot, r.WFGrass
    root.showPoints = True
    root.setGroupDisplay(3)  # Mesh display exercises the lightweight mesh path.
    root.refreshDisplay()
    r.CyrusPointSync()
    r.completeRedraw()
    saved = str(leaf.interactionDefinitions[-1])
    assert json.loads(saved)['source']['fingerprint'] == case['source_fingerprint']
    contact = next(x['target_scene_units'] for x in case['attempts'] if x['status'] == 'contact')
    far = case['away']['target_scene_units']
    for percent in (5., 25., 100.):
        mount(root)
        started = time.perf_counter()
        r.execute('WFSection.interactionsUI_foliageSpin.changed ' + str(percent))
        change_ms = 1000. * (time.perf_counter()-started)
        assert abs(float(leaf.interactionFoliage) - percent/100.) < 1e-6
        assert str(leaf.interactionDefinitions[-1]) == saved, 'Preview changes must not replace authored guides'
        assert not str(root.interactionError), str(root.interactionError)
        info = json.loads(str(r.cyrusInteractionSourceInfo(leaf.interactionSourceCache[0][1])))
        assert info['guide_inference_reused'], 'Preview change unexpectedly reran guide inference'
        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
        r.cyrusEditActiveLayers(r.WFEdit, r.Array(int(r.WFCollider.editLayerKey)))
        r.cyrusEditSelect(r.WFEdit, r.Array(1))
        movement = edit_move(contact)
        assert not movement['error'] and movement['statistics']['fitted_guides'] > 0, movement
        audit = json.loads(str(r.cyrusInteractionValidate(root.interactionState, 4000000)[2]))
        assert audit['passed'], audit
        ui_validation = None
        if percent == 100.:
            mount(root)
            r.execute('WFSection.interactionsUI_validateButton.pressed()')
            ui_validation = str(r.WFSection.interactionsUI_info.text)
            assert '-- Runtime error' not in ui_validation, ui_validation
            r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
            r.cyrusEditActiveLayers(r.WFEdit, r.Array(int(r.WFCollider.editLayerKey)))
            r.cyrusEditSelect(r.WFEdit, r.Array(1))
        r.windows.processPostedMessages()
        owner = r.CyrusPointOwner(r.WFOwner)
        mesh_stats = [int(x) for x in r.cyrusRetainedMeshStats(owner)] if r.isValidNode(owner) else []
        away = edit_move(far)
        assert not away['error'] and away['statistics']['posed'] == 0, away
        report['samples'].append({'percent': percent, 'change_ms': change_ms,
                                  'preview_triangles': info['delivered_preview_triangles'],
                                  'inference_reused': info['guide_inference_reused'],
                                  'movement': movement, 'full_mesh_audit': audit, 'ui_validation': ui_validation,
                                  'retained_mesh_stats': mesh_stats, 'away': away})
        save()
    assert report['samples'][0]['preview_triangles'] < report['samples'][1]['preview_triangles'] < report['samples'][2]['preview_triangles']
    report['status'] = 'complete'
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    save()
