"""Profile production-equivalent sync stages in an owned live 2027 fixture."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key = str(r.CVProfileCase)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
result_path = host / ('sync-profile-' + case_key + '.json')
result = {'case': case_key, 'model_key': case['model_key'], 'model_name': case['name'],
          'source_fingerprint': case['source_fingerprint'], 'status': 'running',
          'scope': 'Instrumented copy of loaded sync; elapsed CPU/host waits, not presented FPS.',
          'samples': []}


def save():
    result_path.write_text(json.dumps(result, indent=2), encoding='utf-8')


def array_values(value):
    return [str(x) for x in value]


def state(root):
    return {'epoch': int(root.procEpoch), 'group_builds': int(root.groupBuilds),
            'group_hits': int(root.groupHits), 'edit_key': str(root.procEditKey()),
            'layers': [{'dirty': bool(x.dirty), 'preview_builds': int(x.previewBuildCount),
                        'prepared_builds': int(x.procPreparedBuilds), 'prepared_hits': int(x.procPreparedHits)}
                       for x in root.layerObjects]}


try:
    root, leaf = r.WFRoot, r.WFGrass
    definition = json.loads(str(leaf.interactionDefinitions[-1]))
    assert definition['source']['fingerprint'] == case['source_fingerprint'], 'Current model differs from the recorded fixture'
    r.fileIn(str(host / 'profile-sync.ms'))
    target = next(a['target_scene_units'] for a in case['attempts'] if a['status'] == 'contact')
    row = r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState, 2))[0][0]
    r.CVCurrent, r.CVTarget = row.row4, r.Point3(*target)
    result['before_move'] = state(root)
    r.cyrusDiagnosticStart('interaction_sync_profile', 4096, 4*1024*1024, 120000)
    r.execute('undo "profile existing collider" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
    result['after_move'] = state(root)
    root.interactionsEnsure()
    result['after_ensure'] = state(root)
    result['contact_statistics'] = json.loads(str(root.interactionsStatistics()))
    assert not str(root.interactionError), str(root.interactionError)
    assert result['contact_statistics']['fitted_guides'] > 0, 'Profile does not have genuine fitted contact'
    for index in range(6):
        start = time.perf_counter()
        ok = bool(r.CVProfilePointSync())
        total = 1000. * (time.perf_counter() - start)
        owner = r.CyrusPointOwner(r.WFOwner)
        sample = {'index': index, 'sync_returned': ok, 'wall_ms': total,
                  'stages': [{'label': str(row[0]), 'ms': float(row[1])} for row in r.CVProfileRows],
                  'error': str(r.CyrusPointLastError),
                  'retained': array_values(r.cyrusRetainedStats(owner)),
                  'retained_mesh': array_values(r.cyrusRetainedMeshStats(owner)),
                  'presentation': array_values(r.cyrusRetainedPresentationStats(owner)),
                  'publication_state': state(root)}
        assert ok and not sample['error'], sample
        result['samples'].append(sample)
        save()
    result['diagnostics'] = json.loads(str(r.cyrusDiagnosticSnapshot(0, 500)))
    r.cyrusDiagnosticStop()
    result['status'] = 'complete'
except Exception:
    result['status'] = 'failed'
    result['error'] = traceback.format_exc()
finally:
    try:
        if r.cyrusDiagnosticActive():
            r.cyrusDiagnosticStop()
    except Exception:
        pass
    save()
