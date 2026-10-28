"""Export the private terrace's current immutable inputs for native replay."""
from pathlib import Path
import hashlib
import json
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
out = host / ('terrace-replay-' + str(r.CVProfileCase))
out.mkdir(parents=True, exist_ok=False)
try:
    root = r.TRoot
    assert not str(root.interactionError), str(root.interactionError)
    fixture = {'metres_per_unit': 1 / float(r.units.decodeValue('1m')), 'layers': [],
               'instances': [], 'audit': False, 'scope': 'Private copy of the terrace after the real stone drag',
               'max_host_statistics': json.loads(str(root.interactionsStatistics()))}
    for li, item in enumerate(root.procPublishedOwners):
        role = (1 if item.interactionCollider else 0) + (2 if item.interactionReact else 0)
        entries = []
        if role:
            nodes = root.procPublishedSources[li]
            values = item.interactionsSources(nodes, role)
            for si, node in enumerate(nodes):
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
                entries.append(entry)
        fixture['layers'].append({'role': role, 'cover': bool(item.interactionCoverRoots),
                                  'gap': float(item.interactionGapWU) * fixture['metres_per_unit'],
                                  'stiffness': float(item.interactionStiffness), 'sources': entries})
        if role:
            rows = root.groupSnapshotRows[li] if role == 2 else r.cyrusInteractionRows(root.interactionState, li+1)
            token, count = r.cyrusPlacementToken(rows), int(r.getProperty(rows, r.Name('count')))
            for offset in range(0, count, 500):
                for placement in r.cyrusPlacementPage(rows, token, offset, min(500, count-offset)):
                    tm = placement[0]
                    fixture['instances'].append({'layer': li, 'source': int(placement[1])-1,
                                                 'identity': str(placement[2]),
                                                 'transform': [float(x) for v in [tm.row1, tm.row2, tm.row3, tm.row4] for x in v]})
    (out / 'fixture.json').write_text(json.dumps(fixture, indent=2), encoding='utf-8')
except Exception:
    (out / 'capture-error.txt').write_text(traceback.format_exc(), encoding='utf-8')
    raise
