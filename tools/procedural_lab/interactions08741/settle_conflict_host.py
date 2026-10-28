"""Allow normal Max callbacks to run before reading a retained conflict."""
from pathlib import Path
import json
import time
from pymxs import runtime as r

host = Path(str(r.GardenRun))
root = r.WFRoot
for _ in range(12):
    r.windows.processPostedMessages()
    r.CyrusPointSync()
    r.completeRedraw()
    time.sleep(.05)
try:
    root.interactionsEnsure()
    thrown = ''
except Exception as exc:
    thrown = str(exc)
report = {'thrown': thrown, 'root_error': str(root.interactionError), 'ui_status': str(root.interactionsStatus()),
          'statistics': json.loads(str(root.interactionsStatistics()))}
(host / 'conflict-settled.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
