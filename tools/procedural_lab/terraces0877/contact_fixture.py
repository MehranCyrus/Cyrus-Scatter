"""Replay the artist's real model fixture in an owned Max profile."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
root=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));report={}
try:
    assert '/build/terraces0877-' in out.as_posix()
    start=time.perf_counter()
    r.loadMaxFile(str(root/'Test Scene/New Plants test 22.max'),quiet=True,useFileUnits=True)
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFEdit,DGStone; for n in objects where classof n.baseObject==AminScatterObject and n.baseObject.overlapOwner==undefined do (WFOwner=n;WFRoot=n.baseObject); WFGrass=WFRoot.layerObjects[1];WFCollider=WFRoot.layerObjects[2]')
    report['load_seconds']=time.perf_counter()-start
    report['layers']=[dict(name=str(n),amount=int(l.amount),sources=[str(x.name) if r.isValidNode(x) else 'missing' for x in l.sources],react=bool(l.interactionReact),collider=bool(l.interactionCollider)) for n,l in zip(r.WFRoot.layerNames,r.WFRoot.layerObjects)]
    r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
    report['initial_stats']=json.loads(str(r.WFRoot.interactionsStatistics()))
    report['status']='ready'
except Exception:report.update(status='failed',error=traceback.format_exc())
(out/'contact-fixture.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
