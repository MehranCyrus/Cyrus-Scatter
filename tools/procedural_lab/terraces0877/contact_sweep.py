"""Deterministic real-tree contact sweeps. CPU fit and scripted redraw are separate."""
from pathlib import Path
import json,time,traceback,statistics,math
from pymxs import runtime as r
out=Path(str(r.GardenRun));results=[];saved=None
def stats():return json.loads(str(r.WFRoot.interactionsStatistics()))
def pump():
    for _ in range(3):r.windows.processPostedMessages();time.sleep(.01)
def setval(key,value):r.WFRoot.layerObjects[2].interactionsResponseSetting(r.Name(key),value)
def capture(name):
    r.completeRedraw();pump();b=r.gw.getViewportDib();b.filename=str(out/(name+'.png'));r.save(b);r.close(b)
try:
    root=r.WFRoot;stone=r.DGStone;origin=r.copy(stone.pos)
    root.viewportFaces=4000000;root.viewportNavigationFaces=1000000;root.identificationMode=1;root.setGroupDisplay(3)
    r.execute('''(viewport.setLayout #layout_1;viewport.setType #view_persp_user
    local centre=DGStone.pos,size=160.0,eye=centre+[size,-size*1.4,size*.6],back=normalize(eye-centre),right=normalize(cross [0,0,1] back),up=cross back right
    viewport.setTM(inverse(matrix3 right up back eye));viewport.SetRenderLevel #smoothhighlights;completeRedraw())''')
    r.execute('global TCOriginalHeld=CyrusInteractionHeld;fn CyrusInteractionHeld=true')
    for name,strength,fixed,response,trim,cover in [('bend',1.,.3,1,0.,False),('fixed',1.,1.,1,0.,False),('zero',0.,0.,1,0.,False),('fixed-trim',1.,1.,3,1.,False),('zero-cover',0.,0.,1,0.,True)]:
        for key,value in [('interactionBendStrength',strength),('interactionFixedBase',fixed),('interactionResponse',response),('interactionPruneAmount',trim),('interactionCoverRoots',cover)]:setval(key,value)
        root.interactionsEnsure();r.CyrusPointSync();pump()
        before=stats();samples=[]
        for i in range(18):
            stone.pos=origin+r.Point3(35*math.sin(i*math.pi/8),0,0)
            r.CyrusSceneColliderWatch();start=time.perf_counter();root.interactionsEnsure();r.CyrusPointSync()
            sync_ms=(time.perf_counter()-start)*1000;start=time.perf_counter();r.redrawViews();pump()
            current=stats()
            samples.append(dict(step=i,sync_ms=sync_ms,redraw_pump_ms=(time.perf_counter()-start)*1000,stats=current,frame=str(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.WFOwner)))))
        results.append(dict(case=name,before=before,samples=samples));capture('sweep-'+name)
        (out/'contact-sweep.json').write_text(json.dumps(dict(status='running',cases=results),indent=2),encoding='utf-8')
    for key,value in [('interactionBendStrength',1.),('interactionFixedBase',.3),('interactionResponse',1),('interactionPruneAmount',0.),('interactionCoverRoots',False)]:setval(key,value)
    stone.pos=origin;root.interactionsEnsure();r.CyrusPointSync();pump();before=stats();view=r.viewport.getTM();orbit=[]
    for i in range(18):
        r.viewport.setTM(r.rotateZMatrix((i-9)*.5)*view);start=time.perf_counter();r.redrawViews();pump()
        orbit.append(dict(step=i,redraw_pump_ms=(time.perf_counter()-start)*1000,stats=stats(),frame=str(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.WFOwner)))))
    r.viewport.setTM(view)
    result=dict(status='complete',version=str(r.CyrusLibraryVersion()),cases=results,orbit=dict(before=before,samples=orbit),scope='Scripted movement plus explicit ensure/sync; CPU fit_ms is native. Redraw includes 30ms message-pump delay. Not physical mouse latency/FPS.')
except Exception:result=dict(status='failed',error=traceback.format_exc(),cases=results)
finally:
    r.execute('if TCOriginalHeld!=undefined do CyrusInteractionHeld=TCOriginalHeld')
(out/'contact-sweep.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
