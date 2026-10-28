"""Time repeated source capture of a current owned-host interaction binding."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
case_key = str(r.CVProfileCase)
case = json.loads((host / 'cases' / (case_key + '.json')).read_text(encoding='utf-8'))
result_path = host / ('source-profile-' + case_key + '.json')
result = {'case': case_key, 'model_name': case['name'], 'samples_ms': [], 'status': 'running',
          'scope': 'Same source, preparation definition, units and settings; synchronous host source capture, not FPS.'}
try:
    root, leaf = r.WFRoot, r.WFGrass
    saved = str(leaf.interactionDefinitions[-1])
    definition = json.loads(saved)
    assert definition['source']['fingerprint'] == case['source_fingerprint']
    result['definition_bytes_utf8'] = len(saved.encode('utf-8'))
    result['source_fingerprint'] = case['source_fingerprint']
    for _ in range(6):
        start = time.perf_counter()
        values = leaf.interactionsSources(root.procPublishedSources[0], 2)
        result['samples_ms'].append(1000. * (time.perf_counter() - start))
        assert len(values) == 1
    result['source_info'] = json.loads(str(r.cyrusInteractionSourceInfo(values[0])))
    result['status'] = 'complete'
except Exception:
    result['status'] = 'failed'
    result['error'] = traceback.format_exc()
finally:
    result_path.write_text(json.dumps(result, indent=2), encoding='utf-8')
