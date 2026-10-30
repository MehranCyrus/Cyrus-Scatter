from pathlib import Path
from pymxs import runtime as r
import json,time,traceback,statistics
out=Path(str(r.GardenRun));data={}
def sample(nodes):return dict(streams=list(r.cyrusRetainedStreamStats()),epochs=[int(n.baseObject.procEpoch) for n in nodes])
try:
    r.CyrusSelectionTimer.Stop();nodes=[n for n in r.objects if r.classOf(n.baseObject)==r.AminScatterObject]
    picks=json.loads((out/'garden-pick.json').read_text())
    target=max((s for s in picks['samples'] if s['owners']),key=lambda s:s['ms'])
    node=r.getNodeByName(target['owners'][0],exact=True);r.cyrusViewportPickAt(node,target['x'],target['y'])
    view=r.viewport.getTM();r.viewport.setType(r.Name('view_persp_user'));r.viewport.setTM(view)
    for _ in range(8):r.redrawViews();r.windows.processPostedMessages()
    data['before']=sample(nodes);elapsed=[]
    r.cyrusRetainedInteraction(True)
    for i in range(24):
        r.viewport.setTM(r.rotateZMatrix((i-12)*.12)*view)
        t=time.perf_counter();r.redrawViews();r.windows.processPostedMessages();elapsed.append((time.perf_counter()-t)*1000)
    r.cyrusRetainedInteraction(False);r.viewport.setTM(view)
    data['after']=sample(nodes);data['redraw_ms']=elapsed;data['median_ms']=statistics.median(elapsed)
    assert data['before']==data['after']
    data['scope']='Scripted camera redraw submission with a mesh hover overlay. Not physical-input or GPU-presentation FPS.'
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'navigation.json').write_text(json.dumps(data,indent=2))
