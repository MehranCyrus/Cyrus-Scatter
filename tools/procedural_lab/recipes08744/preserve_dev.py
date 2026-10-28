import json
from pathlib import Path
from pymxs import runtime as r
O=Path(str(r.GardenRun));r.execute('subObjectLevel=0;WFRoot.interactionsEnsure();CyrusPointSync();completeRedraw()')
def matrix(m):return [[float(m[i][j]) for j in range(3)] for i in range(4)]
rows=r.cyrusEditInspect(r.WFEdit,0,500)[3]
report={'version':str(r.WFRoot.uiVersion()),'rows':[{'key':int(x[0]),'id':str(x[3]),'output':str(x[4]),'active':bool(x[5]),'deleted':bool(x[8]),'order':int(x[9]),'delta':matrix(x[10]),'base':None if x[11]==r.undefined else matrix(x[11]),'final':None if x[12]==r.undefined else matrix(x[12])} for x in rows],'definitions':[len(str(x)) for x in r.WFGrass.interactionDefinitions],'contact':json.loads(str(r.WFRoot.interactionsStatistics()))}
(O/'source-state.json').write_text(json.dumps(report,indent=2));r.saveMaxFile(str(O/'Edited_Source_08744.max'),quiet=True)
