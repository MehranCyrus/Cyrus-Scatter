"""Max 2027 numeric/display observations; no claims of presented FPS."""
from pathlib import Path
import json,time,traceback,statistics
from pymxs import runtime as r
out=Path(str(r.GardenRun));phase=str(r.CVProfileCase);report={'phase':phase,'status':'running'}
def stats():return json.loads(str(r.WFRoot.interactionsStatistics()))
def work():return stats()['process_work']
def vec(p):return [float(p.x),float(p.y),float(p.z)]
def pump():
    for _ in range(8):r.windows.processPostedMessages();r.completeRedraw();time.sleep(.025)
def metrics():return {'epoch':int(r.WFRoot.procEpoch),'group_builds':int(r.WFRoot.groupBuilds),'work':work(),'sources':[str(x) for x in r.WFGrass.sourceRowIDs]}
try:
    if phase=='inspect':
        report.update(statistics=stats(),holding=bool(r.theHold.Holding()),layers=[{'id':str(x.layerID),'error':str(x.previewError),'mode':int(x.interactionResponse),'prepared':len(x.interactionDefinitions)} for x in r.WFRoot.layerObjects],nodes=[{'name':str(x.name),'polygons':list(r.getPolygonCount(x))} for x in r.objects if r.superClassOf(x)==r.GeometryClass],retained=list(r.cyrusRetainedMeshStats(r.CyrusPointOwner(r.WFOwner))),point_error=str(r.CyrusPointLastError))
    elif phase=='movement':
        before=metrics();start=vec(r.ADWall.pos);times=[];rows=[]
        for dx in (25,50,75,100,125,100,75,50,25,0):
            r.ADWall.pos=r.Point3(start[0]+dx,start[1],start[2]);t=time.perf_counter();assert r.cyrusInteractionSceneUpdate(r.WFRoot.interactionState);times.append((time.perf_counter()-t)*1000);rows.append(stats())
        after=metrics();assert after['epoch']==before['epoch'] and after['group_builds']==before['group_builds'],(before,after)
        for key in ('source_captures','source_preparations','layouts'):assert after['work'][key]==before['work'][key],(key,before,after)
        report.update(before=before,after=after,times_ms=times,median_ms=statistics.median(times),maximum_ms=max(times),states=rows)
        pump()
    elif phase=='scaled-boxes':
        before=metrics();original=r.ADWall.transform
        r.ADWall.scale=r.Point3(2,.04,1.2);assert r.cyrusInteractionSceneUpdate(r.WFRoot.interactionState);scaled=stats()
        r.ADWall.scale=r.Point3(-2,.04,1.2);assert r.cyrusInteractionSceneUpdate(r.WFRoot.interactionState);mirrored=stats()
        # The rejected zero-thickness successor cannot replace accepted state.
        generation=stats()['generation'];r.ADWall.scale=r.Point3(0,.04,1.2);error=''
        try:r.cyrusInteractionSceneUpdate(r.WFRoot.interactionState)
        except Exception as e:error=str(e)
        assert error and stats()['generation']==generation
        r.ADWall.transform=original;assert r.cyrusInteractionSceneUpdate(r.WFRoot.interactionState)
        report.update(before=before,after=metrics(),scaled=scaled,mirrored=mirrored,collapsed_error=error)
        pump()
    elif phase=='render-bake':
        r.WFGrass.interactionResponse=2;r.WFRoot.interactionsChanged();r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump()
        info=json.loads(str(r.cyrusInteractionRenderInfo(r.WFRoot.interactionState,1)))
        before={int(r.getHandleByAnim(n)) for n in r.objects};created=r.cyrusInteractionBake(r.WFRoot.interactionState,1)
        output=[n for n in r.objects if int(r.getHandleByAnim(n)) not in before]
        report.update(render=info,baked=int(created) if isinstance(created,int) else str(created),bake_triangles=sum(int(r.getPolygonCount(n)[0]) for n in output),statistics=stats())
    elif phase=='objects':report['nodes']=[{'name':str(n.name),'polys':list(r.getPolygonCount(n))} for n in r.objects if r.superClassOf(n)==r.GeometryClass]
    else:raise ValueError('Unknown phase '+phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc())
(out/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
if report['status']!='pass':raise RuntimeError(report['error'])
