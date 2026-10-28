from pathlib import Path
import json
from pymxs import runtime as r
O=Path(str(r.GardenRun))
fields=['groupSnapshotKey','procStatus','interactionStatus','interactionsStatistics','procPending','procError']
report={}
for name,obj in [('root',r.WFRoot),('grass',r.WFGrass),('collider',r.WFCollider)]:
 report[name]={}
 for field in fields:
  try:report[name][field]=str(getattr(obj,field))
  except:pass
try:report['currentKey']=str(r.WFRoot.procInputKey())
except Exception as e:report['keyError']=str(e)
r.execute('CyrusPointSync();completeRedraw()')
report['edit']=str(r.cyrusEditInspect(r.WFEdit,0,5))
(O/'diagnose.json').write_text(json.dumps(report,indent=2))
