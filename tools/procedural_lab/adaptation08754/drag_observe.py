"""Read-only telemetry during real GUI input; never drives or forces a draw."""
from pathlib import Path
import builtins,json,time
from pymxs import runtime as r
from PySide6.QtCore import QTimer
out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
def navigation_snapshot():
    return {'epoch':int(r.WFRoot.procEpoch),'group_builds':int(r.WFRoot.groupBuilds),
            'work':json.loads(str(r.WFRoot.interactionsStatistics()))['process_work'],
            'streams':list(r.cyrusRetainedStreamStats()),
            'view':[[float(row.x),float(row.y),float(row.z)] for row in r.viewport.getTM()]}
if phase=='nav-start':
    builtins.ad_nav_before=navigation_snapshot()
elif phase=='nav-stop':
    before=builtins.ad_nav_before;after=navigation_snapshot()
    report={'before':before,'after':after,'scope':'Actual viewport zoom; read-only observations, no presented FPS claim'}
    assert before['view']!=after['view'],'No actual camera movement observed'
    for key in ('epoch','group_builds','work'):assert before[key]==after[key],key
    report['upload_deltas']={str(i):after['streams'][i]-before['streams'][i] for i in (1,2,3,6,7)}
    assert not any(report['upload_deltas'].values()),report['upload_deltas']
    report['status']='pass';(out/'actual-navigation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
elif phase=='drag-start':
    if hasattr(builtins,'ad_timer'):builtins.ad_timer.stop()
    builtins.ad_samples=[]
    def observe():
        try:
            info=json.loads(str(r.WFRoot.interactionsStatistics()));p=r.ADWall.pos
            builtins.ad_samples.append({'time':time.perf_counter(),'position':[float(p.x),float(p.y),float(p.z)],'held':bool(r.CyrusInteractionHeld()),'generation':info['generation'],'updates':info['updates'],'work':info['process_work'],'error':str(r.WFRoot.interactionError),'epoch':int(r.WFRoot.procEpoch),'group_builds':int(r.WFRoot.groupBuilds)})
            if len(builtins.ad_samples)>2500:builtins.ad_timer.stop()
        except Exception as e:builtins.ad_samples.append({'error':str(e)})
    builtins.ad_timer=QTimer();builtins.ad_timer.timeout.connect(observe);builtins.ad_timer.start(40);observe()
elif phase=='drag-stop':
    builtins.ad_timer.stop();values=builtins.ad_samples
    (out/'actual-drag.json').write_text(json.dumps({'scope':'Read-only sampling during real GUI input; not presented FPS','samples':values},indent=2),encoding='utf-8')
else:raise ValueError(phase)
