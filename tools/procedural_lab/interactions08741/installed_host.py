"""Check automatic startup of the exact package in the private install profile."""
from pathlib import Path
import json
from pymxs import runtime as r

host = Path(str(r.GardenRun))
object_ = r.AminScatterObject()
report = {'status': 'pass', 'version': str(object_.uiVersion()), 'native_capability': int(r.cyrusInteractionVersion()),
          'schema': int(object_.version), 'scope': 'Private installed automatic startup; no artist profile touched'}
assert report['version'] == '0.87.4.1' and report['native_capability'] == 9 and report['schema'] == 62, report
(host / 'installed-startup.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
(host / 'ready.json').write_text(json.dumps(report), encoding='utf-8')
