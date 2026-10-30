from pathlib import Path
from pymxs import runtime as r
import json,traceback
RUN=Path(__file__).resolve().parent;OUT=Path(str(r.GardenRun));report={}
try:
 assert r.loadMaxFile(str(RUN/'Terraces-owned.max'),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
 nodes=[n for n in r.objects if 'violet' in str(n.name).lower()]
 report['nodes']=[str(n.name) for n in nodes];report['sources']=[]
 for i,node in enumerate(nodes[:5]):
  source=r.cyrusInteractionSource(node,r.undefined,r.Array(.005,.05,1),1)
  r.cyrusInteractionSourceSnapshot(source,str(OUT/f'violet-{i}.bin'))
  info=json.loads(str(r.cyrusInteractionSourceInfo(source)))
  record={'name':str(node.name),'snapshot':f'violet-{i}.bin','info':info};report['sources'].append(record)
  try:
   r.cyrusInteractionAccept(source);saved=json.loads(str(r.cyrusInteractionSerialize(source)))
   (OUT/f'violet-{i}.json').write_text(json.dumps(saved,indent=2));record['definition']=f'violet-{i}.json'
  except Exception:record['preparation_error']=traceback.format_exc()
 report['status']='complete';(OUT/'completed.json').write_text(json.dumps(report,indent=2))
except Exception:report.update(status='failed',error=traceback.format_exc());(OUT/'error.txt').write_text(report['error'])
(OUT/'violet-probe.json').write_text(json.dumps(report,indent=2))
