"""Source readiness, rejected authoring and persistent-scene checks in an owned host."""
from pathlib import Path
import json,hashlib,traceback,time
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));report={'checks':[]}
def save():(O/'lifecycle.json').write_text(json.dumps(report,indent=2))
def check(name,value):
    assert value,name;report['checks'].append(name);save()
try:
    root=r.WFRoot;grass=r.WFGrass;collider=r.WFCollider
    r.execute('subObjectLevel=0;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+3
    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
    assert bool(root.mainUI.controlsReady),'Modify panel did not finish mounting'
    root.mainUI.selectLayerView(grass);section=root.mainUI.editors[12];root.mainUI.slots[12].open=True;root.mainUI.bindSection(section);r.WFSection=section
    extra=r.copy(grass.validSources()[0]);extra.name='Workflow second source';r.hide(extra)
    grass.addModelSource(extra);root.refreshAll();root.interactionsEnsure()
    check('Unprepared second source remains pending without a runtime error',not grass.interactionsReady(grass.validSources()) and not str(root.interactionError) and int(json.loads(str(root.interactionsStatistics()))['plants'])==0)
    grass.interactionsAnalyze(extra);check('Hidden source receives a review copy and guides',len(grass.interactionGuides)==2 and bool(extra.isHidden))
    grass.interactionsAccept();root.interactionsEnsure()
    check('All source preparation enables reactions',grass.interactionsReady(grass.validSources()) and not str(root.interactionError) and int(json.loads(str(root.interactionsStatistics()))['plants'])==50)
    grass.removeModelSources(r.Array(2));root.refreshAll();root.interactionsEnsure();r.delete(extra);root.interactionsEnsure()
    open_mesh=r.plane(width=2,length=2,widthsegs=2,lengthsegs=2);before=int(collider.interactionColliderMode)
    try:collider.interactionsValidateProxy(r.WFSphere,open_mesh);raise AssertionError('Open mesh was accepted')
    except AssertionError:raise
    except Exception as error:report['open_mesh_rejection']=str(error)
    check('Rejected open proxy keeps working collider',int(collider.interactionColliderMode)==before and not str(root.interactionError));r.delete(open_mesh)
    retained=root.interactionState;before_stats=str(root.interactionsStatistics());old_limit=int(grass.interactionMaxVertices)
    grass.interactionMaxVertices=3;grass.interactionsLimitsChanged()
    try:root.interactionsEnsure();raise AssertionError('Undersized admission succeeded')
    except AssertionError:raise
    except Exception as error:report['limit_rejection']=str(error)
    check('Failed preparation retains the complete publication',root.interactionState==retained and str(root.interactionsStatistics())==before_stats)
    grass.interactionMaxVertices=old_limit;grass.interactionsLimitsChanged();root.interactionsEnsure()
    grass.interactionsShowGuides(grass.validSources()[0]);check('Saved source review reopens',len(grass.interactionGuides)>0)
    trial=ROOT/'dist/CyrusScatter-0.87.3-20261026-workflow-r2/Trials/New_Plants_Interaction_Workflow_Reviewed_0.87.3.max';trial.parent.mkdir(parents=True,exist_ok=True)
    assert not trial.exists();definitions=list(grass.interactionDefinitions);identities=list(grass.interactionSourceIDs)
    r.saveMaxFile(str(trial),quiet=True);report['trial']=str(trial);report['trial_sha256']=hashlib.sha256(trial.read_bytes()).hexdigest()
    check('Save removes transient review helpers',len(grass.interactionGuides)==0);save()
    assert r.loadMaxFile(str(trial),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);root=owner.baseObject;grass=root.layerObjects[0];collider=root.layerObjects[1]
    check('Accepted definitions and source identities round-trip',list(grass.interactionDefinitions)==definitions and list(grass.interactionSourceIDs)==identities)
    root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();report['reopened_statistics']=json.loads(str(root.interactionsStatistics()))
    check('Reopened contacts are complete',not str(root.interactionError) and not report['reopened_statistics']['error'])
    r.WFOwner=owner;r.WFRoot=root;r.WFGrass=grass;r.WFCollider=collider;r.WFSphere=collider.validSources()[0];r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    report['status']='pass';save()
except Exception:report['error']=traceback.format_exc();save()
