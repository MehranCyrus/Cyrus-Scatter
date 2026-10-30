"""Bounded held-input replay on the delivered garden, using only private Max."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
out=Path(str(r.GardenRun));drag_report={'samples':[]};drag_step=0
def drag_stats():return json.loads(str(r.RDRoot.interactionsStatistics()))
def drag_write(): (out/'garden-drag.json').write_text(json.dumps(drag_report,indent=2))
def review_drag_tick():
    global drag_step
    try:
        drag_step+=1;start=time.perf_counter()
        mode='edit' if drag_step<=12 else 'scene' if drag_step<=24 else 'orbit'
        if drag_step==13:
            r.execute('''(local rows=cyrusPlacementTransformGroups RDRoot.groupSnapshotRows[1]
            local source=(RDRoot.layerObjects[1].validSources())[1]
            local proxy=RDRoot.layerObjects[1].interactionsProxy source
            if not isValidNode proxy do throw "Garden fixture requires its closed custom proxy"
            RDStone=copy proxy;RDStone.name="Review scene stone proxy";RDStone.isHidden=false
            RDStone.transform=proxy.transform*(inverse source.transform)*rows[1][1];RDRoot.layerObjects[1].interactionCollider=false
            RDRoot.interactionSceneColliders=#(RDStone);RDRoot.interactionsEnsure();CyrusPointSync retainedOwner:RDRoot)''')
            drag_report['scene_start']=drag_stats()
        if mode=='edit':r.cyrusEditCommand(r.RDEdit,4,r.transMatrix(r.Point3(3 if drag_step<=6 else -3,0,0)))
        elif mode=='scene':
            r.RDStone.pos+=r.Point3(3 if drag_step<=18 else -3,0,0);r.CyrusSceneColliderWatch()
        else:r.viewport.setTM(r.rotateZMatrix((drag_step-24)*.15)*r.RDView)
        # Match the production redraw order: update scene transforms in the
        # existing runtime before asking for source/membership freshness.
        r.CyrusSceneColliderTick();r.RDRoot.interactionsEnsure();r.redrawViews()
        s=drag_stats();assert not s.get('error') and not str(r.RDRoot.interactionError),s
        frame=list(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.RDOwner)))
        drag_report['samples'].append(dict(step=drag_step,mode=mode,submit_ms=(time.perf_counter()-start)*1000,stats=s,frame=[str(x) for x in frame]))
        drag_write()
        if drag_step==30:
            r.RDTimer.Stop();r.execute('CyrusInteractionHeld=RDSavedHeld');r.viewport.setTM(r.RDView)
            drag_report['status']='complete';drag_report['scope']='Scripted timer with held-input predicate; presented-ticket observations, not physical mouse latency or FPS.';drag_write()
    except Exception:
        r.RDTimer.Stop();r.execute('CyrusInteractionHeld=RDSavedHeld')
        drag_report.update(status='failed',error=traceback.format_exc());drag_write()

try:
    r.execute('''global RDOwner=getNodeByName "GARDEN | Lakeside boulders" exact:true
    global RDRoot=RDOwner.baseObject,RDEdit,RDStone,RDTimer,RDView=viewport.getTM(),RDSavedHeld=CyrusInteractionHeld
    for m in RDOwner.modifiers where classof m==CyrusScatterEdit do RDEdit=m
    RDRoot.updateMode=2;RDRoot.autoRender=false
    cyrusEditActiveLayers RDEdit #(RDRoot.layerObjects[1].editLayerKey);cyrusEditSelect RDEdit #(1)
    fn CyrusInteractionHeld=true
    fn RDTimeTick sender args=(python.Execute "review_drag_tick()")
    RDTimer=dotNetObject "System.Windows.Forms.Timer";RDTimer.Interval=100
    dotNet.addEventHandler RDTimer "Tick" RDTimeTick
    ''')
    drag_report['before']=drag_stats();drag_report['status']='running';drag_write();r.RDTimer.Start()
except Exception:drag_report.update(status='failed',error=traceback.format_exc());drag_write()
