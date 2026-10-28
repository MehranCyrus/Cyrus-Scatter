"""Exercise saved-definition reuse and invalidation in an owned Max process."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key = str(r.CVProfileCase)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
path = host / ('cache-guard-' + case_key + '.json')
report = {'case': case_key, 'checks': [], 'errors': {}, 'status': 'running',
          'scope': 'Owned Max host; valid cache hits, modified saved definitions and source-geometry invalidation.'}
clone = None


def rejected(label, action):
    try:
        action()
    except Exception as exc:
        report['checks'].append(label)
        report['errors'][label] = str(exc)
        return
    raise AssertionError(label + ' unexpectedly accepted an invalid successor')


try:
    root, leaf = r.WFRoot, r.WFGrass
    node = leaf.validSources()[0]
    saved = str(leaf.interactionDefinitions[-1])
    definition = json.loads(saved)
    assert definition['source']['fingerprint'] == case['source_fingerprint']
    settings = leaf.interactionsSettings()
    before = json.loads(str(root.interactionsStatistics()))
    good = [r.cyrusInteractionSource(node, saved, settings, 1) for _ in range(3)]
    assert all(json.loads(str(r.cyrusInteractionSourceInfo(x)))['fingerprint'] == case['source_fingerprint'] for x in good)
    report['checks'].append('Unchanged saved definition and watched source are reusable')

    invalid = json.loads(saved)
    invalid['accepted'] = False
    rejected('Changed definition cannot clear acceptance', lambda: r.cyrusInteractionSource(node, json.dumps(invalid), settings, 1))
    invalid = json.loads(saved)
    invalid['source']['fingerprint'] = '0' * 64
    rejected('Changed definition cannot spoof the source fingerprint', lambda: r.cyrusInteractionSource(node, json.dumps(invalid), settings, 1))
    altered = r.Array(float(settings[0]) * 2., settings[1], settings[2], settings[3], settings[4])
    rejected('Changed preparation settings reject a stale definition', lambda: r.cyrusInteractionSource(node, saved, altered, 1))

    clone = r.copy(node)
    r.convertToMesh(clone)
    captured = r.cyrusInteractionSource(clone, saved, settings, 1)
    mesh = clone.mesh
    first = r.getVert(mesh, 1)
    r.setVert(mesh, 1, first + r.Point3(.5, 0, 0))
    r.update(clone)
    rejected('Geometry change invalidates a previously cached source', lambda: r.cyrusInteractionSource(clone, saved, settings, 1))
    assert captured != r.undefined  # Keep the older cached generation alive through the rejection.

    after = json.loads(str(root.interactionsStatistics()))
    assert after['generation'] == before['generation'] and not str(root.interactionError)
    report['checks'].append('Rejected source requests retain the prior complete interaction publication')
    report['status'] = 'pass'
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    if clone is not None and r.isValidNode(clone):
        r.delete(clone)
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
