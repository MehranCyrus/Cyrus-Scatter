"""One actual Cyrus Edit collider move; independently audit all visible triangles."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));path=O/'broadleaf-contacts.json';report=json.loads(path.read_text()) if path.exists() else {'moves':[]}
step=int(r.WFContactStep);offset=[(30,0,45),(0,30,45),(-30,0,45),(0,-30,45),(150,0,120)][step]
entry={'step':step,'offset_cm':offset};report['moves'].append(entry)
try:
    root=r.WFRoot;root.interactionsEnsure();r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
    r.WFCurrent=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4;r.WFTarget=r.WFBase+r.Point3(*offset)
    start=time.perf_counter();epoch=int(root.procEpoch)
    r.execute('undo "Fern contact move" on cyrusEditTransform WFEdit 0 (WFTarget-WFCurrent) (matrix3 1) false')
    root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();entry['command_seconds']=time.perf_counter()-start
    entry['statistics']=json.loads(str(root.interactionsStatistics()));assert not entry['statistics']['error'],entry['statistics']['error'];assert not str(root.interactionError),str(root.interactionError)
    entry['epoch_delta']=int(root.procEpoch)-epoch;assert entry['epoch_delta']<=1
    entry['audit']=json.loads(str(r.cyrusInteractionValidate(root.interactionState,2000000)[2]));assert entry['audit']['passed'],entry['audit']
    assert entry['statistics']['hidden_roots']==0
    if step<4:assert entry['statistics']['fitted_guides']>0
    else:assert entry['statistics']['posed']==0
    entry['status']='pass'
except Exception:entry['error']=traceback.format_exc()
path.write_text(json.dumps(report,indent=2),encoding='utf-8')
