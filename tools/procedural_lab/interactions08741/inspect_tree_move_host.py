"""Inspect selected tree Edit rows after returning to the host message loop."""
from pathlib import Path
import json, traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));report={}
try:
    edit,root,trees=r.TSEdit,r.TSRoot,r.TSTrees
    total=int(r.cyrusEditInspect(edit,0,1)[1]);key=int(trees.editLayerKey);rows=[]
    for start in range(0,total,500):
        for row in r.cyrusEditInspect(edit,start,min(500,total-start))[3]:
            if int(row[0])==key and int(row[1]) in (1,2):
                def t(matrix):
                    return [float(matrix.row4.x),float(matrix.row4.y),float(matrix.row4.z)] if matrix!=r.undefined else None
                rows.append({'row':int(row[1]),'selected':bool(row[7]),'delta':t(row[10]),'input':t(row[11]),'presented':t(row[12]),'handle':t(r.cyrusEditHandleMatrix(edit,key,int(row[1])))})
    report={'status':'complete','rows':rows,'interaction':json.loads(str(root.interactionsStatistics())),'error':str(root.interactionError)}
except Exception:
    report={'status':'failed','error':traceback.format_exc()}
(host/'tree-move-inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
