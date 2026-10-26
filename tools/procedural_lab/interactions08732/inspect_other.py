"""Capture the non-decorative fern variant in the owned baseline host."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={}
try:
    node=next(n for n in r.objects if str(n.name)=='Outdoor_Plants_01_Neottopteris_Nidus_Bush05_001')
    value=r.cyrusInteractionSource(node,r.undefined,r.Array(.005,1.,1,r.WFGrass.interactionsLimits(),.15),1)
    report=json.loads(str(r.cyrusInteractionSourceInfo(value)));report['source_name']=str(node.name)
    r.cyrusInteractionSourceSnapshot(value,str(O/'neottopteris-plain.bin'))
    try:(O/'neottopteris-plain.json').write_text(str(r.cyrusInteractionSerialize(r.cyrusInteractionAccept(value))),encoding='utf-8')
    except Exception as e:report['accept_error']=str(e)
    report['status']='captured'
except Exception:report['error']=traceback.format_exc()
(O/'plain-inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
