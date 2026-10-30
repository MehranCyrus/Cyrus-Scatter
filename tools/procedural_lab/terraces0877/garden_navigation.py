"""Separate retained drawing cost from contact work on the actual landscape."""
from pathlib import Path
import json,time,traceback,statistics
from pymxs import runtime as r
out=Path(str(r.GardenRun));cases=[]
def sample():
    return dict(stream=list(r.cyrusRetainedStreamStats()),epochs=[int(n.baseObject.procEpoch) for n in r.GardenNodes],
      work=json.loads(str(r.TCGardenColliderRoot.interactionsStatistics()))['process_work'],
      viewport=[dict(name=str(n.name),values=list(r.cyrusRetainedViewportStats(r.CyrusPointOwner(n)))) for n in r.GardenNodes],memory=list(r.cyrusViewportMemoryStats()))
try:
    r.execute('clearSelection();viewport.setCamera TCOverview')
    for name,faces,nav in [('light',2000000,300000),('balanced',6000000,1000000),('detail',10000000,2000000)]:
        for n in r.GardenNodes:
            root=n.baseObject;root.viewportFaces=faces;root.viewportNavigationFaces=nav;root.refreshDisplay()
        r.CyrusPointSync()
        for _ in range(20):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.025)
        before=sample();view=r.viewport.getTM();timings=[]
        r.viewport.setType(r.Name('view_persp_user'));r.viewport.setTM(view)
        r.cyrusRetainedInteraction(True)
        for i in range(24):
            r.viewport.setTM(r.rotateZMatrix((i-12)*.12)*view)
            t=time.perf_counter();r.redrawViews();r.windows.processPostedMessages()
            timings.append((time.perf_counter()-t)*1000)
        after=sample();r.viewport.setTM(view);r.cyrusRetainedInteraction(False)
        for _ in range(10):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.025)
        b=r.gw.getViewportDib();b.filename=str(out/('navigation-'+name+'.png'));r.save(b);r.close(b)
        cases.append(dict(case=name,per_controller_idle=faces,per_controller_navigation=nav,redraw_ms=timings,before=before,after=after))
        (out/'garden-navigation.json').write_text(json.dumps(dict(status='running',cases=cases),indent=2),encoding='utf-8')
    # Comfortable saved defaults; full render continues to use every accepted plant.
    for n in r.GardenNodes:
        n.baseObject.viewportFaces=6000000;n.baseObject.viewportNavigationFaces=1000000;n.baseObject.refreshDisplay()
    r.CyrusPointSync();r.viewport.setCamera(r.TCBoulderCamera)
    result=dict(status='complete',cases=cases,scope='24 scripted camera redraw calls per budget; no sleep in timed region. Explicit native navigation state. CPU host submission timing, not GPU/frame-presentation FPS.')
except Exception:result=dict(status='failed',error=traceback.format_exc(),cases=cases)
(out/'garden-navigation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
