"""Capture a real failing contact as numeric input for native regression replay."""
from pathlib import Path
import hashlib
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key, direction = str(r.CVProfileCase), int(r.CVCaptureDirection)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
out = host / 'replays' / (case_key + '-direction' + str(direction))
out.mkdir(parents=True, exist_ok=False)

try:
    root, leaf = r.WFRoot, r.WFGrass
    source = json.loads(str(leaf.interactionDefinitions[-1]))['source']
    assert source['fingerprint'] == case['source_fingerprint'], 'Selected preparation is not the recorded source'
    attempt = case['attempts'][direction-1]
    assert attempt['status'] == 'contact', 'A capture needs a genuine recorded contact'
    row = r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState, 2))[0][0]
    r.CVCurrent, r.CVTarget = row.row4, r.Point3(*attempt['target_scene_units'])
    r.execute('undo "capture collider regression" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
    root.interactionsEnsure()
    assert not str(root.interactionError), str(root.interactionError)
    statistics = json.loads(str(root.interactionsStatistics()))
    assert statistics['fitted_guides'] > 0, 'Capture did not produce the intended contact'
    audit = json.loads(str(r.cyrusInteractionValidate(root.interactionState, 4000000)[2]))
    fixture = {'metres_per_unit': 1 / float(r.units.decodeValue('1m')), 'layers': [],
               'instances': [], 'audit': True, 'recorded_case': case_key, 'direction': direction,
               'max_host_statistics': statistics, 'max_host_audit': audit}
    for li, item in enumerate(root.procPublishedOwners):
        role = (1 if item.interactionCollider else 0) + (2 if item.interactionReact else 0)
        sources = []
        values = item.interactionsSources(root.procPublishedSources[li], role)
        for si, node in enumerate(root.procPublishedSources[li]):
            if not role:
                continue
            mesh = out / f'source-{li}-{si}.bin'
            r.cyrusInteractionSourceSnapshot(values[si], str(mesh))
            entry = {'kind': 'plant' if role == 2 else 'collider', 'mesh': str(mesh),
                     'sha256': hashlib.sha256(mesh.read_bytes()).hexdigest(), 'node_name': str(node.name)}
            if role == 2:
                slot = list(str(x) for x in item.interactionSourceIDs).index(str(item.sourceRowIDs[si]))
                definition = out / f'definition-{li}-{si}.json'
                definition.write_text(str(item.interactionDefinitions[slot]), encoding='utf-8')
                entry['definition'] = str(definition)
                entry['definition_sha256'] = hashlib.sha256(definition.read_bytes()).hexdigest()
            sources.append(entry)
        fixture['layers'].append({'role': role, 'cover': bool(item.interactionCoverRoots),
                                  'gap': float(item.interactionGapWU) * fixture['metres_per_unit'],
                                  'stiffness': float(item.interactionStiffness), 'sources': sources})
        if role:
            rows = root.groupSnapshotRows[li] if role == 2 else r.cyrusInteractionRows(root.interactionState, li+1)
            token, count = r.cyrusPlacementToken(rows), int(r.getProperty(rows, r.Name('count')))
            for placement in r.cyrusPlacementPage(rows, token, 0, count):
                tm = placement[0]
                fixture['instances'].append({'layer': li, 'source': int(placement[1])-1,
                                             'identity': str(placement[2]),
                                             'transform': [float(x) for v in [tm.row1, tm.row2, tm.row3, tm.row4] for x in v]})
    (out / 'fixture.json').write_text(json.dumps(fixture, indent=2), encoding='utf-8')
except Exception:
    (out / 'capture-error.txt').write_text(traceback.format_exc(), encoding='utf-8')
    raise
