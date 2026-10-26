from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));path=O/'contact-events.json';data=json.loads(path.read_text());index=int(r.E873ContactStep);offset=[(6,0,6),(3,3,6),(-3,3,5),(30,0,6)][index];entry={'step':index,'offset_cm':offset};data['poses'].append(entry)
try:
    r.E873Target=r.E873Base+r.Point3(*offset);start=time.perf_counter()
    r.execute('undo "Move Cyrus interaction collider" on cyrusEditTransform E873Edit 0 (E873Target-E873Current) (matrix3 1) false')
    r.E873Root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();entry['command_seconds']=time.perf_counter()-start;entry['statistics']=json.loads(str(r.E873Root.interactionsStatistics()))
    entry['epoch']=int(r.E873Root.procEpoch);entry['builds']=int(r.E873Root.groupBuilds);entry['baseline_epoch']=int(r.E873Epoch);entry['baseline_builds']=int(r.E873Builds)
    assert not entry['statistics']['error'],entry['statistics']['error']
    # A completed authored Edit invalidates procedural spacing/filter inputs.
    # The contact kernel updates locally before that committed re-evaluation.
    assert 0<=entry['epoch']-entry['baseline_epoch']<=1
    assert 0<=entry['builds']-entry['baseline_builds']<=1
    r.E873Epoch=entry['epoch'];r.E873Builds=entry['builds']
    r.E873Current=r.E873Target
    if index<3:
        entry['audit']=json.loads(str(r.cyrusInteractionValidate(r.E873Root.interactionState,2000000)[2]));assert entry['audit']['passed'],entry['audit']
    entry['status']='pass'
except Exception:entry['failure']=traceback.format_exc();entry['display_error']=str(r.CyrusPointLastError)
path.write_text(json.dumps(data,indent=2))
