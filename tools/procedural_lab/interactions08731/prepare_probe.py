"""Reproduce the reported Prepare handler error in an owned, matched Max host."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={}
try:
    report['native_capability']=int(r.cyrusInteractionVersion())
    report['ids_type']=str(r.classOf(r.WFGrass.interactionSourceIDs))
    report['copied_ids_type']=str(r.execute('classOf(copy WFGrass.interactionSourceIDs)'))
    report['collected_ids_type']=str(r.execute('classOf(for value in WFGrass.interactionSourceIDs collect value)'))
    r.execute('WFSection.interactionsUI_prepareButton.pressed()')
    report['ui_text']=str(r.WFSection.interactionsUI_info.text)
    report['definitions']=len(r.WFGrass.interactionDefinitions)
    report['status']='reproduced' if 'findItem' in report['ui_text'] and 'ParamBlock2' in report['ui_text'] else 'different_result'
except Exception:report['error']=traceback.format_exc()
(O/'prepare-probe.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
