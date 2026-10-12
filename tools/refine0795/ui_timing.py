"""Separate warm panel binding from the fixture's repeated full Modify remount."""
from pathlib import Path
import sys,traceback,statistics
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('ui-timing')
try:
    r.loadMaxFile(str(OUT/'Workflow.max'),quiet=True,useFileUnits=True)
    node=r.getNodeByName('Workflow Scatter');root=node.baseObject;root.refreshAll()
    rec.step('Initial full Modify mount',lambda:activate(node,'modelsUI'))
    fp=fingerprint(root);epoch=int(root.procEpoch)
    for repetition in range(3):
        for name in ('modelsUI','coverageUI','areasUI','layoutUI','layersUI'):
            def show(name=name):
                panel=getattr(root,name);panel.open=True;root.mainUI.bindSection(panel);panel.layout()
            rec.step('Warm bind '+name,show)
    rec.check(fp==fingerprint(root) and int(root.procEpoch)==epoch,'Warm panel binding retains publication')
    rec.data['median_warm_ms']=statistics.median(c['action_ms'] for c in rec.data['checkpoints'][1:]);rec.write()
except Exception:rec.error(traceback.format_exc())
