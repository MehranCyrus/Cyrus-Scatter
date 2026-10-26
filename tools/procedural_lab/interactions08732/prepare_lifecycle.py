"""Separate host commands model separate artist actions, including rejected Undo scopes."""
from pathlib import Path
import json,hashlib,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));path=O/'prepare-lifecycle.json';phase=int(r.WFPrepareLifePhase)
report={'checks':[]} if phase==0 else json.loads(path.read_text(encoding='utf-8'))
def save():path.write_text(json.dumps(report,indent=2),encoding='utf-8')
def check(name,test):assert test,name;report['checks'].append(name);save()
def definitions(grass):return [str(x) for x in grass.interactionDefinitions]
def hashes(grass):return [hashlib.sha256(x.encode()).hexdigest() for x in definitions(grass)]
def mount(root,grass):
    r.select(r.WFOwner)
    r.execute('subObjectLevel=0;modPanel.setCurrentObject WFRoot');end=time.monotonic()+3
    while not bool(root.mainUI.controlsReady) and time.monotonic()<end:r.windows.processPostedMessages();time.sleep(.01)
    assert bool(root.mainUI.controlsReady);root.mainUI.selectLayerView(grass);r.WFSection=root.mainUI.editors[12];root.mainUI.slots[12].open=True;root.mainUI.bindSection(r.WFSection)
try:
    root=r.WFRoot;grass=r.WFGrass
    if phase==0:
        mount(root,grass);report['first_id']=str(grass.interactionSourceIDs[0]);r.execute('global WFTestExtra,WFTestBadSource')
        r.WFTestExtra=r.copy(grass.validSources()[0]);r.WFTestExtra.name='Prepared duplicate source test';r.hide(r.WFTestExtra);grass.addModelSource(r.WFTestExtra);root.refreshAll();root.interactionsEnsure()
        check('Additional source waits for one-step preparation',len(grass.interactionDefinitions)==1 and not grass.interactionsReady(grass.validSources()) and not str(root.interactionError))
    elif phase==1:
        mount(root,grass);r.WFSection.interactionsUI_modelList.selection=2;r.execute('WFSection.interactionsUI_sourceState();WFSection.interactionsUI_prepareButton.pressed()')
        check('Prepare appends an ordinary array without cloning ParamBlock2',len(grass.interactionDefinitions)==2 and len(grass.interactionSourceIDs)==2 and str(grass.interactionSourceIDs[0])==report['first_id'] and grass.interactionsReady(grass.validSources()) and not str(root.interactionError))
    elif phase==2:
        before=definitions(grass);r.execute('WFSection.interactionsUI_connectionSpin.changed 11.0')
        check('Automatic setting refresh updates every prepared source',all(a!=b for a,b in zip(before,definitions(grass))) and len(grass.interactionDefinitions)==2 and not str(root.interactionError))
    elif phase==3:
        before=hashes(grass);rows=str(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,1)))
        r.execute('WFSection.interactionsUI_verticesLimitSpin.changed 3');report['rejected_limit']=str(root.interactionError)
        check('Rejected automatic preparation retains definitions and complete rows',hashes(grass)==before and str(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,1)))==rows and bool(report['rejected_limit']))
    elif phase==4:
        r.execute('WFSection.interactionsUI_verticesLimitSpin.changed 3000000')
        check('Raising admission recovers without Prepare or Accept',not str(root.interactionError) and grass.interactionsReady(grass.validSources()))
    elif phase==5:
        r.WFTestBadSource=r.sphere(radius=.00001,segs=4);r.WFTestBadSource.name='Unsupported tiny preparation test';r.hide(r.WFTestBadSource);grass.addModelSource(r.WFTestBadSource);root.refreshAll();root.interactionsEnsure();mount(root,grass)
        report['before_rejected_source']=hashes(grass)
    elif phase==6:
        r.WFSection.interactionsUI_modelList.selection=3;r.execute('WFSection.interactionsUI_sourceState();WFSection.interactionsUI_prepareButton.pressed()');report['rejected_source']=str(r.WFSection.interactionsUI_info.text)
        check('Failed new source does not overwrite existing prepared arrays',hashes(grass)==report['before_rejected_source'] and len(grass.interactionSourceIDs)==2 and not grass.interactionsReady(grass.validSources()))
    elif phase==7:
        grass.removeModelSources(r.Array(3));root.refreshAll();root.interactionsEnsure();r.delete(r.WFTestBadSource);r.WFTestBadSource=r.undefined;mount(root,grass)
        check('Removing unsupported source restores readiness',grass.interactionsReady(grass.validSources()) and not str(root.interactionError))
    elif phase==8:
        r.WFSection.interactionsUI_modelList.selection=1;r.execute('WFSection.interactionsUI_sourceState();WFSection.interactionsUI_guideReviewButton.changed true')
        check('Prepared source guides remain available after failures',len(grass.interactionGuides)>0)
        report['saved_definitions']=hashes(grass);report['saved_ids']=[str(x) for x in grass.interactionSourceIDs];trial=O/'preparation-roundtrip.max';assert not trial.exists();r.saveMaxFile(str(trial),quiet=True)
        check('Save removes transient source review',len(grass.interactionGuides)==0);report['trial']=str(trial);report['sha256']=hashlib.sha256(trial.read_bytes()).hexdigest()
    elif phase==9:
        assert r.loadMaxFile(report['trial'],quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);root=owner.baseObject;grass=root.layerObjects[0];collider=root.layerObjects[1]
        r.WFOwner=owner;r.WFRoot=root;r.WFGrass=grass;r.WFCollider=collider;r.WFSphere=collider.validSources()[0];r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
        check('Two saved definitions and their source IDs round-trip',hashes(grass)==report['saved_definitions'] and [str(x) for x in grass.interactionSourceIDs]==report['saved_ids'])
        root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();mount(root,grass);r.completeRedraw()
        check('Reopened prepared scene is complete',not str(root.interactionError) and not json.loads(str(root.interactionsStatistics()))['error']);report['status']='pass'
    save()
except Exception:report['error']=traceback.format_exc();save()
