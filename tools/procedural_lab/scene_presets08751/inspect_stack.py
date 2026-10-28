from pathlib import Path
import json
from pymxs import runtime as r
data=[]
for m in r.SPRoot.procModifiers():
    info=r.cyrusEditInspect(m,0,50)
    data.append([{'layer':int(x[0]),'index':int(x[1]),'input':str(x[3]),'output':str(x[4]),'active':bool(x[5]),'visible':bool(x[6]),'selected':bool(x[7]),'deleted':bool(x[8]),'order':int(x[9])} for x in info[3]])
(Path(str(r.GardenRun))/'stack.json').write_text(json.dumps({'level':int(r.subObjectLevel),'enabled':[bool(m.enabled) for m in r.SPRoot.procModifiers()],'error':str(r.SPRoot.interactionError),'layer_errors':[str(x.previewError) for x in r.SPRoot.layerObjects],'data':data},indent=2))
