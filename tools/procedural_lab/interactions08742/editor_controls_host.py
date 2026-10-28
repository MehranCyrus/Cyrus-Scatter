"""Recorded, separate-event checks of the reported source and editor lifecycle."""
from pathlib import Path
import hashlib,json,math,time,traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[3]
host=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
fixture=json.loads((ROOT/'build/preparation-editor-repair-20261027-01/plant-scope-fixture.json').read_text(encoding='utf-8'))
report={'phase':phase,'status':'running'}
def info():return json.loads(str(r.cyrusPreparationEditorInfo()))
def command(op,**options):r.cyrusPreparationEditorCommand(json.dumps(dict(op=op,**options)))
def settle():
    end=time.monotonic()+60
    while time.monotonic()<end:
        r.windows.processPostedMessages();value=info()
        if not value.get('busy'):return value
        time.sleep(.02)
    raise TimeoutError(info())
try:
    if phase=='selected':
        before=info();assert not before['ready'] and before['report']['unresolved_guides']==46,before
        command('select',parts=fixture['selected']);command('isolate');command('select',parts=[])
        report['isolated_without_selection']=info()
        command('prepare_selected');after=settle();assert after['ready'],after
        assert after['report']['guides']==46 and after['report']['fixed_parts']==4710,after['report']
        definition=json.loads(str(r.cyrusPreparationEditorDefinition()))
        assert definition['source']['fingerprint']==before['authoring']['fingerprint']
        assert definition['source']['metadata']['triangles']==183030
        report.update(before=before,after=after)
    elif phase=='undo':
        command('undo');after=settle();assert not after['ready'] and after['report']['unresolved_guides']==46,after
        report['after']=after
    elif phase=='redo':
        command('redo');after=settle();assert after['ready'] and after['report']['guides']==46,after
        command('isolate');report['after']=info()
    elif phase=='inspect' or phase.startswith('nav-'):report['after']=info()
    elif phase=='physical-ready':
        value=settle();assert value['ready'] and value['report']['guides']==46 and value['report']['fixed_parts']==4710,value
        assert value['report']['unresolved_guides']==0 and value['report']['unattached_parts']==0
        report['after']=value
    elif phase=='invalid-selection':
        before=settle();definition=str(r.cyrusPreparationEditorDefinition());assert before['ready']
        try:command('select',parts=[before['parts']])
        except Exception as error:report['invalid_piece_message']=str(error)
        else:raise AssertionError('Invalid piece was admitted')
        assert info()['selected']==before['selected'] and str(r.cyrusPreparationEditorDefinition())==definition
        command('select',parts=[])
        try:command('prepare_selected')
        except Exception as error:report['empty_scope_message']=str(error)
        else:raise AssertionError('Empty scope was admitted')
        assert str(r.cyrusPreparationEditorDefinition())==definition
        report['previous_complete_draft_preserved']=True
    elif phase=='sphere':
        definition=json.loads(str(r.cyrusPreparationEditorDefinition()));guide=max(definition['source']['metadata']['guides'],key=lambda g:g['nodes'][len(g['nodes'])//2][1]);p=guide['nodes'][len(guide['nodes'])//2]
        command('sphere',enabled=True,centre=[p[0]+.035,-p[2],p[1]],radius=.07,gap=0)
        report['after']=settle();assert report['after']['ready'],report['after']
    elif phase=='commit':
        command('sphere',enabled=False);after=settle();assert after['ready'],after
        root,leaf=r.WFRoot,r.WFGrass;root.updateMode=1;epoch=int(root.procEpoch);leaf.amount=2;leaf.markInputDirty()
        report['before_definitions']=[str(x) for x in leaf.interactionDefinitions]
        assert r.CyrusPreparationEditorCommit(),info()
        assert not info()['open'] and int(root.procEpoch)==epoch and int(leaf.amount)==2
        saved=json.loads(str(leaf.interactionDefinitions[-1]));assert saved['format']==2
        roles=saved['source']['authoring']['parts'];assert sum(x['role']==1 for x in roles)==46 and sum(x['role']==3 for x in roles)==4710
        report.update(epoch=epoch,manual_pending_preserved=True,saved_definition_sha256=hashlib.sha256(str(leaf.interactionDefinitions[-1]).encode()).hexdigest())
        (host/'committed-definition.json').write_text(json.dumps(saved),encoding='utf-8')
    elif phase=='failed-draft':
        before=str(r.WFGrass.interactionDefinitions[-1]);node=r.WFGrass.validSources()[0]
        r.CyrusOpenPreparationEditor(r.WFGrass,node);assert settle()['ready']
        command('select',parts=[4096]);command('role',role=1);value=settle();assert not value['ready'] and 'Piece 4097' in value['message'],value
        assert not r.CyrusPreparationEditorCommit()
        assert str(r.WFGrass.interactionDefinitions[-1])==before
        r.cyrusPreparationEditorClose();assert str(r.WFGrass.interactionDefinitions[-1])==before
        report.update(failed_draft=value,previous_complete_scene_definition_preserved=True)
    elif phase=='final-editor':
        r.CyrusOpenPreparationEditor(r.WFGrass,r.WFGrass.validSources()[0]);value=settle();assert value['ready'] and value['report']['guides']==46 and value['report']['fixed_parts']==4710,value
        report['after']=value
    elif phase in ('scene-undo-check','scene-redo-check'):
        leaf=r.WFOwner.baseObject.layerObjects[0]
        saved=json.loads((host/'editor-control-commit.json').read_text(encoding='utf-8'))
        if phase=='scene-undo-check':assert [str(x) for x in leaf.interactionDefinitions]==saved['before_definitions']
        else:assert hashlib.sha256(str(leaf.interactionDefinitions[-1]).encode()).hexdigest()==saved['saved_definition_sha256']
        report['scene_history_preserved']=True
    elif phase=='contacts':
        root=r.WFOwner.baseObject;leaf=root.layerObjects[0];collider=root.layerObjects[1]
        r.WFRoot=root;r.WFGrass=leaf;r.WFCollider=collider
        root.updateMode=1;leaf.amount=1;leaf.interactionReact=True;leaf.interactionFoliage=1.;leaf.interactionCoverRoots=False;collider.interactionCollider=False;collider.interactionReact=False
        root.refreshAll();r.CyrusPointSync();r.completeRedraw()
        saved=json.loads(str(leaf.interactionDefinitions[-1]));guide=max(saved['source']['metadata']['guides'],key=lambda g:g['length_m'])
        nodes=guide['nodes'];idx=max(1,int((len(nodes)-1)*.8));near=nodes[idx]
        def normal(v):
            length=math.sqrt(sum(x*x for x in v));return [x/length for x in v] if length>1e-12 else [1,0,0]
        tangent=normal([nodes[-1][k]-nodes[max(0,idx-1)][k] for k in range(3)]);side=normal([-tangent[2],0,tangent[0]])
        other=normal([tangent[1]*side[2]-tangent[2]*side[1],tangent[2]*side[0]-tangent[0]*side[2],tangent[0]*side[1]-tangent[1]*side[0]])
        radius=min(.2,max(.004,guide['length_m']*.08));plant=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0];scale=float(r.length(plant.row1));units=float(r.units.decodeValue('1m'))
        r.WFSphere.radius=radius*units*scale;root.refreshAll();r.CyrusPointSync();r.completeRedraw()
        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
        r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(collider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
        def move(target,audit=True):
            for _ in range(20):r.windows.processPostedMessages();time.sleep(.02);r.completeRedraw()
            rows=r.cyrusInteractionRows(root.interactionState,2) if root.interactionState!=r.undefined else root.groupSnapshotRows[1]
            r.CVCurrent=r.cyrusPlacementTransformGroups(rows)[0][0].row4;r.CVTarget=target
            r.execute('undo "selected leaf contact" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
            root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw();value=json.loads(str(root.interactionsStatistics()));error=str(root.interactionError)
            result={'statistics':value,'error':error}
            if audit and not error and value.get('fitted_guides',0):result['audit']=json.loads(str(r.cyrusInteractionValidate(root.interactionState,4000000)[2]))
            return result
        far=plant.row4+r.Point3(10000,10000,10000);move(far,False);collider.interactionColliderMode=1;collider.interactionCollider=True;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
        results=[];targets=[]
        for direction in (side,[-x for x in side],other):
            local=[near[k]+direction[k]*radius*.7 for k in range(3)]
            r.CVPoint=r.Point3(local[0]*units,-local[2]*units,local[1]*units);r.CVMatrix=plant
            target=r.execute('CVPoint * CVMatrix');targets.append(target);results.append(move(target))
        away=move(far,False);report.update(contacts=results,away=away,guide_component=guide['component'])
        assert all(not x['error'] and x['statistics'].get('fitted_guides',0)>0 and x.get('audit',{}).get('passed') for x in results),results
        assert not away['error'] and away['statistics']['posed']==0,away
        report['trial_contact']=move(targets[0]);assert report['trial_contact'].get('audit',{}).get('passed')
    elif phase=='save':
        root,leaf=r.WFRoot,r.WFGrass;root.updateMode=1;leaf.interactionFoliage=1.;leaf.interactionCoverRoots=False;root.refreshAll();r.CyrusPointSync();r.completeRedraw()
        raw=leaf.interactionsSources(root.procPublishedSources[0],2)[0];source_info=json.loads(str(r.cyrusInteractionSourceInfo(raw)))
        assert source_info['guides']==46 and source_info['delivered_preview_triangles']==183030,source_info
        report['full_preview']=source_info
        trial=ROOT/'build/preparation-editor-repair-20261027-01/Neottopteris_Selected_Leaves_08742.max';assert not trial.exists();assert r.saveMaxFile(str(trial),quiet=True)
        report['trial']=str(trial)
    elif phase=='reopen':
        trial=ROOT/'build/preparation-editor-repair-20261027-01/Neottopteris_Selected_Leaves_08742.max'
        assert r.loadMaxFile(str(trial),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
        r.WFOwner=owner;r.WFRoot=owner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0]
        saved=json.loads(str(r.WFGrass.interactionDefinitions[-1]));assert saved['source']['fingerprint']=='21c8d2f4a90e63776c27029c17c8fa551204b07ca31a598469cee950ddad5096'
        assert sum(x['role']==1 for x in saved['source']['authoring']['parts'])==46
        raw=r.cyrusInteractionSource(r.WFGrass.validSources()[0],str(r.WFGrass.interactionDefinitions[-1]),r.WFGrass.interactionsSettings(),1)
        restored=json.loads(str(r.cyrusInteractionSourceInfo(raw)));assert restored['guides']==46 and restored['fixed_parts']==4710 and restored['can_prepare'],restored
        r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
        statistics=json.loads(str(r.WFRoot.interactionsStatistics()));audit=json.loads(str(r.cyrusInteractionValidate(r.WFRoot.interactionState,4000000)[2]))
        assert not str(r.WFRoot.interactionError) and statistics['fitted_guides']>0 and audit['passed']
        report.update(saved_intent_preserved=True,restored_source=restored,restored_statistics=statistics,restored_audit=audit)
    else:raise ValueError('Unknown phase: '+phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc())
(host/('editor-control-'+phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
if report['status']!='pass':raise RuntimeError(report['error'])
