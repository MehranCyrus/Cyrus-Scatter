"""Separate host events prove a preparation setting and saved definitions undo together."""
from pathlib import Path
import json,hashlib,traceback,time
from pymxs import runtime as r
O=Path(str(r.GardenRun));path=O/'prepare-undo.json';report=json.loads(path.read_text()) if path.exists() else {};phase=int(r.WFPrepareUndoPhase)
def state():
    root=r.WFRoot;root.interactionsEnsure();r.CyrusPointSync();grass=r.WFGrass
    return {'minimum':float(grass.interactionMinimumM),'definitions':hashlib.sha256(str(grass.interactionDefinitions[0]).encode()).hexdigest(),'source_ids':[str(x) for x in grass.interactionSourceIDs],'error':str(root.interactionError)}
try:
    if phase==0:
        r.execute('subObjectLevel=0;modPanel.setCurrentObject WFRoot')
        end=time.monotonic()+3
        while not bool(r.WFRoot.mainUI.controlsReady) and time.monotonic()<end:r.windows.processPostedMessages();time.sleep(.01)
        r.WFRoot.mainUI.selectLayerView(r.WFGrass);r.WFSection=r.WFRoot.mainUI.editors[12];r.WFRoot.mainUI.slots[12].open=True;r.WFRoot.mainUI.bindSection(r.WFSection)
        report['before']=state()
    elif phase==1:
        r.execute('WFSection.interactionsUI_minimumSpin.changed 0.6');report['after']=state();assert report['before']['definitions']!=report['after']['definitions'] and not report['after']['error']
    elif phase==2:
        report['undo']=state();assert report['undo']==report['before']
    elif phase==3:
        report['redo']=state();assert report['redo']==report['after'];report['status']='pass'
except Exception:report['error']=traceback.format_exc()
path.write_text(json.dumps(report,indent=2),encoding='utf-8')
