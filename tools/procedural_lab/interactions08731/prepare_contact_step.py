"""One completed collider edit with full-mesh validation and explicit root policy."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));path=O/'hover-contacts.json';report=json.loads(path.read_text()) if path.exists() else {'moves':[]}
step=int(r.WFContactStep);x,y,z,hide=[(0,0,23,False),(0,0,23,True),(5,0,23,False),(-5,0,23,False),(80,0,80,False)][step]
entry={'step':step,'offset_cm':[x,y,z],'hide':hide};report['moves'].append(entry)
try:
    root=r.WFRoot;grass=r.WFGrass;grass.interactionCoverRoots=hide;root.interactionsEnsure()
    r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
    r.WFCurrent=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4;r.WFTarget=r.WFBase+r.Point3(x,y,z)
    epoch=int(root.procEpoch);start=time.perf_counter()
    r.execute('undo "Hovering collider test" on cyrusEditTransform WFEdit 0 (WFTarget-WFCurrent) (matrix3 1) false')
    root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();entry['command_seconds']=time.perf_counter()-start
    entry['statistics']=json.loads(str(root.interactionsStatistics()));assert not entry['statistics']['error'],entry['statistics']['error'];assert not str(root.interactionError)
    actual=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4
    entry['target_error_cm']=float(r.distance(actual,r.WFTarget));assert entry['target_error_cm']<.001
    entry['placement_epoch_delta']=int(root.procEpoch)-epoch;assert entry['placement_epoch_delta']<=1
    entry['audit']=json.loads(str(r.cyrusInteractionValidate(root.interactionState,2000000)[2]));assert entry['audit']['passed'],entry['audit']
    assert entry['statistics']['hidden_roots']==0,'Hovering contact must not remove roots'
    if step==4:assert entry['statistics']['posed']==0,'Leaving collider must restore original plants'
    else:assert entry['statistics']['fitted_guides']>0 or entry['statistics']['posed']>0,'Hovering contact did not bend any guides'
    entry['status']='pass'
except Exception:entry['error']=traceback.format_exc()
path.write_text(json.dumps(report,indent=2),encoding='utf-8')
