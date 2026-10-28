"""Paired old/new Max 2027 movement and absence-of-work checks in owned profiles."""
from pathlib import Path
import hashlib,json,math,os,statistics,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
# Reuse the previous measured native Edit / presentation helpers verbatim.
prefix=(ROOT/'tools/procedural_lab/interactions0875/runtime_host.py').read_text(encoding='utf-8').split('\ntry:\n',1)[0]
exec(compile(prefix,'shared-pose-host-helpers','exec'),globals())
report={'phase':phase,'status':'running','scope':'Owned Max 2027, CPU wall/worker timings; not presented FPS'}
def load_scene():
    scene=ROOT/'dist/CyrusScatter-0.87.5-20261027/TestScenes/Grass_Interaction_0.87.5.max'
    r.CyrusPointSuspended=True
    try:assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    finally:r.CyrusPointSuspended=False
    r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1];r.WFSphere=r.WFCollider.validSources()[0]
    r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    r.WFRoot.viewportFaces=0;r.WFRoot.viewportNavigationFaces=0;r.WFRoot.setGroupDisplay(3);r.WFRoot.identificationMode=2
    r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();frame();require_ready()
def snapshot():return {'statistics':stats(),'counters':counters()}
def same_expensive(before,after):
    b,a=before['statistics'],after['statistics'];assert b['updates']==a['updates'] and b['generation']==a['generation'],(b,a)
    if 'process_work' in b:assert b['process_work']==a['process_work'],(b['process_work'],a['process_work'])
    if 'preview_builds' in b:assert b['preview_builds']==a['preview_builds'],(b['preview_builds'],a['preview_builds'])
    b,a=before['counters'],after['counters'];assert b['epoch']==a['epoch'] and b['group']==a['group'],(b,a)
    for i in (1,2,3,6,7):assert b['streams'][i]==a['streams'][i],(i,b,a)
try:
    if phase=='setup':load_scene();report.update(snapshot());report['version']=str(r.WFRoot.uiVersion())
    elif phase=='passive':
        pump();before=snapshot();samples=[]
        for action in ('idle','camera','selection','unrelated-animation'):
            start=snapshot()
            if action=='idle':pump(25)
            elif action=='camera':
                for k in range(20):r.viewport.setFOV(44+k*.1);r.completeRedraw();r.windows.processPostedMessages()
            elif action=='selection':
                for _ in range(8):r.clearSelection();r.select(r.WFOwner);r.windows.processPostedMessages()
            else:
                r.execute('global AuditUnrelated=point name:"Owned unrelated animation";hide AuditUnrelated;with animate on (at time 0 AuditUnrelated.pos=[0,0,0];at time 10 AuditUnrelated.pos=[10,0,0])')
                for frame_index in (1,4,8,2,0):r.sliderTime=frame_index;r.windows.processPostedMessages();r.completeRedraw()
                r.delete(r.AuditUnrelated)
            pump();after=snapshot();same_expensive(start,after);samples.append({'action':action,'before':start,'after':after})
        report.update(before=before,after=snapshot(),samples=samples)
    elif phase.startswith('bench-'):
        count=int(phase.split('-')[1]);assert count in (200,1000)
        os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None)
        root,leaf=r.WFRoot,r.WFGrass;root.updateMode=1;leaf.amount=count;root.refreshAll();root.interactionsEnsure();root.setGroupDisplay(3);root.identificationMode=2;r.CyrusPointSync();pump();p,height=frame();edit_setup()
        rows=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0];target=rows[len(rows)//2].row4+r.Point3(0,0,height*.65)
        r.WFSphere.radius=height*1.2;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();pump();edit_setup();move(target+r.Point3(height*5,0,0));pump()
        before=snapshot();samples=[];r.CyrusPointSuspended=True
        for k in range(14):
            move(target+r.Point3(height*(.5-.07*k),0,0));require_ready();samples.append({'timing':json.loads(str(r.CVMoveTiming)),'statistics':stats(),'streams':counters()['streams']})
        after=snapshot();r.CyrusPointSuspended=False;r.CyrusPointSync();pump();require_ready()
        assert before['counters']['epoch']==after['counters']['epoch']
        for i in (1,7):assert before['counters']['streams'][i]==after['counters']['streams'][i],(i,before,after)
        if 'process_work' in after['statistics']:
            for field in ('source_preparations','source_captures','collider_cooks','layouts'):
                assert before['statistics']['process_work'][field]==after['statistics']['process_work'][field],field
        report.update(count=count,before=before,after=after,samples=samples,
                      median_edit_ms=statistics.median(s['timing']['edit_ms'] for s in samples),
                      median_fit_ms=statistics.median(s['statistics']['fit_ms'] for s in samples),
                      median_redraw_ms=statistics.median(s['timing']['first_redraw_ms'] for s in samples))
    elif phase=='reset-single':load_scene();report.update(snapshot())
    elif phase=='pending':
        root=r.WFRoot;root.updateMode=1;amount=int(r.WFGrass.generatedCount);r.WFGrass.amount=amount+3;pump();before=snapshot()
        r.viewport.setFOV(47);r.clearSelection();pump();r.CyrusPointSync();pump();after=snapshot();same_expensive(before,after)
        assert int(r.WFGrass.generatedCount)==amount and int(r.WFGrass.amount)==amount+3
        report.update(before=before,after=after);r.WFGrass.amount=amount
    elif phase=='save-reload':
        before=stats();scene=out/'Grass_Interaction_0.87.5.2.max'
        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
        assert r.saveMaxFile(str(scene),quiet=True);assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
        r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1];r.WFSphere=r.WFCollider.validSources()[0];r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
        r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();frame();require_ready();report.update(before=before,after=stats(),scene=str(scene))
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc())
finally:r.CyrusPointSuspended=False
(out/'audit-history').mkdir(exist_ok=True)
(out/'audit-history'/(phase+'-'+str(time.time_ns())+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
(out/('audit-'+phase+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
if report['status']!='pass':raise RuntimeError(report['error'])
