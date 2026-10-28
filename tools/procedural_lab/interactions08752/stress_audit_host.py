"""Record geometric correctness separately from the known deep-overlap strain limit."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));report={'scope':'Complete visible mesh in the dense owned 1000-plant stress scene'}
try:
    report['statistics']=json.loads(str(r.WFRoot.interactionsStatistics()))
    report['audit']=json.loads(str(r.cyrusInteractionValidate(r.WFRoot.interactionState,10000000)[2]))
    report['status']='recorded'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(out/'stress-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
