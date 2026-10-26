"""Export source-local plant preparation evidence from an owned Max 2027 host."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={}
try:
    nodes=[n for n in r.objects if 'neottopteris' in str(n.name).lower()];report['matching_nodes']=[str(n.name) for n in nodes]
    node=next(n for n in nodes if 'Decorative05' in str(n.name));r.execute('global BroadleafSource');r.BroadleafSource=node
    report['source']={'name':str(node.name),'class':str(r.classOf(node.baseObject)),'transform':str(node.transform),'hidden':bool(node.isHidden),'metres_per_unit':1/float(r.units.decodeValue('1m'))}
    for minimum in [.005,.01]:
        value=r.cyrusInteractionSource(node,r.undefined,r.Array(minimum,1.,1,r.WFGrass.interactionsLimits(),.15),1)
        info=json.loads(str(r.cyrusInteractionSourceInfo(value)));report[str(minimum)]=info
        r.cyrusInteractionSourceSnapshot(value,str(O/f'neottopteris-{minimum}.bin'))
        try:
            accepted=r.cyrusInteractionAccept(value);definition=str(r.cyrusInteractionSerialize(accepted));(O/f'neottopteris-{minimum}.json').write_text(definition,encoding='utf-8')
        except Exception as error:report[str(minimum)]['accept_error']=str(error)
    report['status']='captured'
except Exception:report['error']=traceback.format_exc()
(O/'model-inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
