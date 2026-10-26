"""Actual generated editor entry, numeric commands, commit and scene lifecycle."""

from pathlib import Path

import json,time,traceback

from pymxs import runtime as r

O=Path(str(r.GardenRun));phase=str(r.PEPhase);report={};ROOT=Path(__file__).resolve().parents[3]

def info():return json.loads(str(r.cyrusPreparationEditorInfo()))

def command(op,**values):r.cyrusPreparationEditorCommand(json.dumps(dict(op=op,**values)))

def ready(timeout=45):

    until=time.monotonic()+timeout

    while time.monotonic()<until:

        r.windows.processPostedMessages();v=info()

        if v.get('ready'):return v

        time.sleep(.015)

    raise AssertionError(info())

def use_source(node):

    root=r.WFRoot;leaf=r.WFGrass;root.updateMode=1;r.WFCollider.interactionCollider=False;leaf.interactionReact=False

    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')

    until=time.monotonic()+5

    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.02)

    assert root.mainUI.controlsReady

    leaf.removeModelSources(r.Array(*range(1,len(leaf.sources)+1)));leaf.addModelSource(node);leaf.amount=1;leaf.interactionFoliage=1.;leaf.interactionCoverRoots=False;leaf.markInputDirty();root.refreshAll()

    root.selectLayer(1);panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]

    r.execute('WFSection.interactionsUI_chooseRole 3;WFSection.interactionsUI_prepareButton.pressed()')

    assert leaf.interactionsReady(leaf.validSources()),str(r.WFSection.interactionsUI_info.text)

    r.execute('WFSection.interactionsUI_editorButton.pressed()');return ready()

try:

    leaf=r.WFGrass

    if phase in ('fern','grass'):

        node=r.PEFern if phase=='fern' else r.PEGrass

        initial=use_source(node);assert initial['source_triangles']>1000

        report['initial']=initial

        initial_definition=json.loads(str(r.cyrusPreparationEditorDefinition()))

        parts=initial_definition['source']['metadata']['parts'];guides=initial_definition['source']['metadata']['guides']

        bending=[i for i,p in enumerate(parts) if p['stem'] and not p.get('fixed',False)]

        selected=bending[-1];command('select',parts=[selected]);before=info()['analyses'];command('role',role=3);fixed=ready()

        fixed_definition=json.loads(str(r.cyrusPreparationEditorDefinition()));assert fixed_definition['source']['metadata']['parts'][selected]['fixed']

        assert fixed['report']['guides']==initial['report']['guides']-1,'Excluding one leaf changed unrelated guide inference'

        assert fixed['source_triangles']==initial['source_triangles'];report['fixed']=fixed

        command('undo');undone=ready();command('redo');redone=ready()

        command('role',role=1);bent=ready();definition=json.loads(str(r.cyrusPreparationEditorDefinition()));assert definition['source']['metadata']['parts'][selected]['stem']

        original=definition['source']['metadata']['guides'][definition['source']['metadata']['parts'][selected]['guide']]

        command('flip');ready();command('flip');ready()

        path=[[p[0],-p[2],p[1]] for p in original['nodes']];path[len(path)//2][0]+=.0005

        command('nodes',nodes=path);manual=ready();assert manual['ready'];report['manual']=manual

        # Canonical intent survives Use, ordinary Prepare and settings refresh.

        before_use=str(leaf.interactionDefinitions[-1]);epoch=int(r.WFRoot.procEpoch);leaf.amount=2;leaf.markInputDirty()

        assert r.CyrusPreparationEditorCommit(),str(info())

        assert not info()['open']

        assert int(r.WFRoot.procEpoch)==epoch and int(leaf.amount)==2,'Commit consumed pending Manual placements'

        saved=json.loads(str(leaf.interactionDefinitions[-1]));assert saved['format']==2 and saved['source']['authoring']['parts']

        # Scene Undo is a separate host-event campaign. A fileIn command groups

        # this entire setup+commit script into its outer MAXScript hold.

        report['manual_pending_preserved']=True

        authored=saved['source']['authoring'];leaf.interactionsPrepare(r.Array(node));after=json.loads(str(leaf.interactionDefinitions[-1]));assert after['source']['authoring']==authored

        report['authored_survives_prepare']=True

        # Reopen through the actual generated control and Cancel preserves bytes.

        panel=r.WFRoot.mainUI;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12];r.execute('WFSection.interactionsUI_editorButton.pressed()');reopen=ready();assert reopen['authoring']==authored

        before_cancel=str(leaf.interactionDefinitions[-1]);command('select',parts=[selected]);command('role',role=3);ready();r.cyrusPreparationEditorClose();assert str(leaf.interactionDefinitions[-1])==before_cancel

        report['cancel_preserves_definition']=True;report['selected_part']=selected

        trial=ROOT/'Test Scene/CyrusScatter_0874_OwnedTests';trial.mkdir(exist_ok=True)

        file=trial/(('Fern' if phase=='fern' else 'Grass')+'_Preparation_0874.max');assert r.saveMaxFile(str(file),quiet=True)

        report['trial']=str(file);report['authoring']=authored;report['status']='pass'

    elif phase.startswith('contacts-'):

        kind=phase.split('-',1)[1];root=r.WFRoot;leaf=r.WFGrass;collider=r.WFCollider

        assert len(leaf.interactionDefinitions)>0

        authored=json.loads(str(leaf.interactionDefinitions[-1]))['source']['authoring'];assert authored['parts']

        r.cyrusPreparationEditorClose();root.updateMode=2;leaf.amount=1;collider.interactionCollider=False;leaf.markInputDirty();r.WFSphere.radius=13.;root.refreshAll();r.CyrusPointSync();r.completeRedraw()

        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')

        r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(collider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))

        base=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4

        r.execute('global PEContactTarget,PEContactCurrent')

        def move(offset):

            # A native Edit gesture requires the renderer to commit its current

            # feedback. Pump the owned UI between programmatic gestures.

            for _ in range(20):r.windows.processPostedMessages();time.sleep(.02);r.completeRedraw()

            current=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4

            r.PEContactCurrent=current;r.PEContactTarget=base+r.Point3(*offset)

            start=time.perf_counter();r.execute('undo "Editor source contact move" on cyrusEditTransform WFEdit 0 (PEContactTarget-PEContactCurrent) (matrix3 1) false')

            root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();stats=json.loads(str(root.interactionsStatistics()));assert not stats['error'],stats

            audit=json.loads(str(r.cyrusInteractionValidate(root.interactionState,2000000)[2]));assert audit['passed'],audit;assert stats['hidden_roots']==0

            return dict(offset=list(offset),seconds=time.perf_counter()-start,statistics=stats,audit=audit)

        root.interactionsEnsure();move((150,0,120));collider.interactionColliderMode=1;collider.interactionCollider=True;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()

        offsets=[(30,0,45),(0,30,45),(-30,0,45),(150,0,120)] if kind=='fern' else [(5,0,20),(0,5,20),(-5,0,20),(150,0,120)]

        report['moves']=[move(x) for x in offsets];assert any(m['statistics']['fitted_guides']>0 for m in report['moves'][:-1]);assert report['moves'][-1]['statistics']['posed']==0

        assert json.loads(str(leaf.interactionDefinitions[-1]))['source']['authoring']==authored

        # Leave a contacting pose, with the real collider enabled, in the trial.

        move(offsets[0]);trial=ROOT/'Test Scene/CyrusScatter_0874_OwnedTests'/(("Fern" if kind=='fern' else "Grass")+'_Preparation_0874.max');assert r.saveMaxFile(str(trial),quiet=True);report['trial']=str(trial);report['status']='pass'

    elif phase=='reopen':

        files=ROOT/'Test Scene/CyrusScatter_0874_OwnedTests'

        for name in ('Fern','Grass'):

            assert r.loadMaxFile(str(files/(name+'_Preparation_0874.max')),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))

            owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);root=owner.baseObject;leaf=root.layerObjects[0]

            saved=json.loads(str(leaf.interactionDefinitions[-1]));assert saved['source']['authoring']['parts'];leaf.interactionsPrepare(leaf.validSources(),rebuild=False);report[name]={'schema':int(root.version),'authoring':saved['source']['authoring'],'ready':bool(leaf.interactionsReady(leaf.validSources()))}

        report['status']='pass'

    elif phase=='trial-review':
        import hashlib
        for name in ('Fern','Grass'):
            file=ROOT/'Test Scene/CyrusScatter_0874_OwnedTests'/(name+'_Preparation_0874.max')
            assert r.loadMaxFile(str(file),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
            owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);root=owner.baseObject;target=root.layerObjects[0];before=str(target.interactionDefinitions[-1]);epoch=int(root.procEpoch)
            r.select(owner);r.execute('max modify mode');r.modPanel.setCurrentObject(root);until=time.monotonic()+5
            while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.02)
            assert root.mainUI.controlsReady;root.selectLayer(1);panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12])
            base=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4
            r.CyrusPointSync();r.completeRedraw();epoch=int(root.procEpoch);before=str(target.interactionDefinitions[-1])
            centre=base+r.Point3(0,0,30 if name=='Fern' else 10);camera=base+(r.Point3(130,-170,110) if name=='Fern' else r.Point3(45,-60,38));back=r.normalize(camera-centre);right=r.normalize(r.cross(r.Point3(0,0,1),back));up=r.cross(back,right)
            r.viewport.setType(r.Name('view_persp_user'));r.viewport.setTM(r.inverse(r.Matrix3(right,up,back,camera)));r.viewport.setFOV(50.);r.CyrusPointSync();r.completeRedraw()
            report[name]={'epoch_before':epoch,'epoch_after':int(root.procEpoch),'definition_unchanged':str(target.interactionDefinitions[-1])==before};assert str(target.interactionDefinitions[-1])==before and int(root.procEpoch)==epoch,report[name]
            assert r.saveMaxFile(str(file),quiet=True);audit=json.loads(str(r.cyrusInteractionValidate(root.interactionState,2000000)[2]));assert audit['passed'];report[name]={'definition_sha256':hashlib.sha256(before.encode()).hexdigest(),'audit':audit,'review_layer':str(root.layerNames[0]),'epoch_before':epoch,'epoch_after':int(root.procEpoch),'path':str(file)}
        report['status']='pass'
    elif phase=='physical':

        use_source(r.PEFern);report['status']='ready for physical input'

    elif phase=='extra':

        use_source(r.PEFern);start=ready();definition=json.loads(str(r.cyrusPreparationEditorDefinition()));meta=definition['source']['metadata'];parts=meta['parts'];guides=meta['guides']

        detail=next(i for i,p in enumerate(parts) if not p['stem'] and not p.get('fixed',False))

        parent=guides[parts[detail]['guide']]['component'];command('select',parts=[detail]);command('role',role=2);command('parent',part=parent);v=ready();assert not str(v['message']).startswith('Piece ')

        result=json.loads(str(r.cyrusPreparationEditorDefinition()));assert not result['source']['metadata']['parts'][detail]['stem'];report['follow_parent']={'piece':detail,'parent_piece':parent}

        command('select',parts=[parent]);p=guides[parts[parent]['guide']];seed=p['root_ring_vertices'][0];command('root',vertex=seed);ready();result=json.loads(str(r.cyrusPreparationEditorDefinition()));g=result['source']['metadata']['guides'][result['source']['metadata']['parts'][parent]['guide']];assert seed in g['root_ring_vertices'];report['root_patch']=True

        baseline=info()['analyses'];command('sphere',enabled=True,centre=[2,0,1],radius=.1,gap=0);far=ready();assert 'did not converge' not in far['message'];assert far['analyses']==baseline

        command('sphere',enabled=False);ready();assert info()['analyses']==baseline;report['sphere_reuses_preparation']=True

        command('role',role=3);command('role',role=1);command('role',role=3);command('role',role=1);v=ready();assert v['authoring']['parts'] and v['ready'];report['latest_draft_wins']=True

        r.cyrusPreparationEditorClose();report['status']='pass'

    elif phase in ('keyboard-undo','keyboard-redo','physical-commit'):
        report=info();report['scene_source']=str(leaf.validSources()[0].name)
        assert report['scene_source'].startswith('Outdoor_Plants_01_Neottopteris'), 'Popup shortcut changed the scene source'
        if phase=='physical-commit':
            assert not report['open'];saved=json.loads(str(leaf.interactionDefinitions[-1]));assert any(p['role']==3 for p in saved['source']['authoring']['parts']);report['persisted_authoring']=saved['source']['authoring']
        else:
            report=ready()|{'scene_source':report['scene_source']}
            if phase=='keyboard-undo':assert not report['authoring']['parts']
            else:assert any(p['role']==3 for p in report['authoring']['parts'])
        report['status']='pass'
    elif phase=='lifecycle':
        r.cyrusPreparationEditorClose()
        use_source(r.PEFern);before=str(leaf.interactionDefinitions[-1]);definition=json.loads(str(r.cyrusPreparationEditorDefinition()));selected=next(i for i,p in enumerate(definition['source']['metadata']['parts']) if p['stem']);command('select',parts=[selected]);command('role',role=3)
        for _ in range(15):r.windows.processPostedMessages();time.sleep(.02)
        r.cyrusPreparationEditorClose();assert not info()['open'];assert str(leaf.interactionDefinitions[-1])==before;report['close_during_work_preserves_scene']=True
        r.CyrusOpenPreparationEditor(leaf,r.PEFern);ready();r.delete(r.PEFern)
        for _ in range(20):r.windows.processPostedMessages();time.sleep(.02)
        v=info();assert not v['ready'] and 'changed' in v['message'];report['deleted_source_blocks_use']=True
        r.resetMaxFile(r.Name('noPrompt'));assert not info()['open'];report['reset_releases_editor']=True;report['status']='pass'
    elif phase=='physical-selection':
        report=ready();baseline=json.loads((O/'keyboard-redo.json').read_text());assert len(report['selected'])==6;assert report['analyses']==baseline['analyses'];assert report['source_triangles']==50382;assert str(leaf.validSources()[0].name).startswith('Outdoor_Plants_01_Neottopteris');report['status']='pass'
    elif phase=='physical-read':

        report=info();assert report['ready'];assert report['selected'];assert not report['authoring']['parts'];assert str(leaf.validSources()[0].name).startswith('Outdoor_Plants_01_Neottopteris');report['status']='pass'

    elif phase=='sphere-contact':

        baseline=info()['analyses'];command('sphere',enabled=True,centre=[.2666445,-.1374801,.45],radius=.13,gap=0);v=ready();assert not any(x in v['message'].lower() for x in ('failed','not converge','cannot','error'));assert v['analyses']==baseline;report['contact']=v

        command('sphere',enabled=False);v=ready();assert v['analyses']==baseline;report['restored']=v;report['status']='pass'

    elif phase=='diagnostic':

        saved=json.loads(str(leaf.interactionDefinitions[-1]));guides=saved['source']['metadata']['guides'];points=[n for g in guides for n in g['nodes']]

        report={'source_name':str(leaf.validSources()[0].name),'guide_bounds_m':[[min(p[k] for p in points),max(p[k] for p in points)] for k in range(3)],'sphere_radius_scene_units':float(r.WFSphere.radius),'unit':str(r.units.SystemType),'unit_scale':float(r.units.SystemScale),'plant_transform':str(r.cyrusPlacementTransformGroups(r.WFRoot.groupSnapshotRows[0])[0][0]),'sphere_transform':str(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0]),'status':'pass'}

    elif phase=='undo-setup':

        import hashlib

        r.WFCollider.interactionCollider=False;r.WFRoot.refreshAll();r.CyrusPointSync();r.completeRedraw()

        before=str(leaf.interactionDefinitions[-1]);r.CyrusOpenPreparationEditor(leaf,leaf.validSources()[0]);ready();definition=json.loads(str(r.cyrusPreparationEditorDefinition()));parts=definition['source']['metadata']['parts'];selected=next(i for i,p in enumerate(parts) if p['stem'])

        command('select',parts=[selected]);command('role',role=3);ready()

        report={'before_sha256':hashlib.sha256(before.encode()).hexdigest(),'source_ids':[str(x) for x in leaf.interactionSourceIDs],'amount':int(leaf.amount),'selected_piece':selected,'status':'ready'}

    elif phase in ('undo-after','undo-read','redo-read'):

        import hashlib

        before=json.loads((O/'undo-setup.json').read_text());current=hashlib.sha256(str(leaf.interactionDefinitions[-1]).encode()).hexdigest();report={'sha256':current,'source_ids':[str(x) for x in leaf.interactionSourceIDs],'amount':int(leaf.amount),'undo_names':[str(x) for x in r.theHold.GetUndoNames()],'redo_names':[str(x) for x in r.theHold.GetRedoNames()]}

        if phase=='undo-after':assert not info()['open'] and current!=before['before_sha256']

        elif phase=='undo-read':assert current==before['before_sha256'] and report['source_ids']==before['source_ids'] and report['amount']==before['amount']

        else:assert current==json.loads((O/'undo-after.json').read_text())['sha256']

        report['status']='pass'

    else:raise AssertionError('Unknown phase '+phase)

except Exception:report['error']=traceback.format_exc()

(O/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
