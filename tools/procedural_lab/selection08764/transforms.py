"""Run after pointer.py; commands and Undo dispatched in separate host events."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    edit=r.VPNode.modifiers[0]
    rows=r.cyrusEditInspect(edit,0,500)[3]
    selected=[row for row in rows if row[7]];assert len(selected)==1
    row=selected[0];identity=str(row[4])
    matrix=lambda m:[[float(m[i][j]) for j in range(3)] for i in range(4)]
    data=dict(id=identity,delta=matrix(row[10]),input=matrix(row[11]),displayed=matrix(row[12]),revision=int(r.cyrusEditLocalRevision(edit)),pending_count=int(r.VPA.amount),shown_count=int(r.VPA.generatedCount),status='complete')
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'transform-state.json').write_text(json.dumps(data,indent=2))
