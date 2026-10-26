"""One completed authored Cyrus Edit move per host event, with visible-mesh audit."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));path=O/'contacts.json';report=json.loads(path.read_text());step=int(r.WFContactStep)
offset=[(18,0,0),(18,0,8),(-18,0,0),(40,0,20)][step];entry={'step':step,'offset_cm':offset};report.setdefault('moves',[]).append(entry)
try:
    r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1));r.WFTarget=r.WFBase+r.Point3(*offset)
    r.WFCurrent=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4
    before=int(r.WFRoot.procEpoch);start=time.perf_counter()
    r.execute('undo "Test collider instance move" on cyrusEditTransform WFEdit 0 (WFTarget-WFCurrent) (matrix3 1) false')
    r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
    entry['command_seconds']=time.perf_counter()-start;entry['stats']=json.loads(str(r.WFRoot.interactionsStatistics()));entry['placement_epoch_delta']=int(r.WFRoot.procEpoch)-before
    assert not entry['stats']['error'],entry['stats']['error'];assert entry['placement_epoch_delta']<=1
    r.WFCurrent=r.WFTarget
    actual=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4
    entry['target']=str(r.WFTarget);entry['actual']=str(actual);entry['target_error_cm']=float(r.distance(actual,r.WFTarget));assert entry['target_error_cm']<.001
    entry['audit']=json.loads(str(r.cyrusInteractionValidate(r.WFRoot.interactionState,2000000)[2]));assert entry['audit']['passed'],entry['audit']
    entry['status']='pass'
except Exception:entry['error']=traceback.format_exc();entry['display_error']=str(r.CyrusPointLastError)
path.write_text(json.dumps(report,indent=2))
