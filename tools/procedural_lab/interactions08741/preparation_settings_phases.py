"""Exercise automatic preparation and solver controls on separate Max events."""
from pathlib import Path
import hashlib,json,time,traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));case=str(r.CVProfileCase);phase=int(r.CVCaptureDirection)
path=host/('preparation-settings-'+case+'.json')
report={'case':case,'checks':[]} if phase==1 else json.loads(path.read_text(encoding='utf-8'))

def mount(root,leaf):
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    end=time.monotonic()+10
    while time.monotonic()<end and (root.mainUI==r.undefined or not bool(root.mainUI.controlsReady)):
        r.windows.processPostedMessages();time.sleep(.02)
    panel=root.mainUI;assert panel!=r.undefined and panel.controlsReady
    panel.selectLayerView(leaf);panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]

def definition(leaf):
    raw=str(leaf.interactionDefinitions[-1]);return {'hash':hashlib.sha256(raw.encode()).hexdigest(),
        'source':json.loads(raw)['source']['fingerprint'],'revision':int(leaf.interactionDefinitionRevision)}

try:
    root,leaf=r.WFRoot,r.WFGrass
    if phase==1:
        before=definition(leaf);epoch=int(root.procEpoch);mount(root,leaf)
        r.execute('WFSection.interactionsUI_stiffnessSpin.changed 0.2')
        after=definition(leaf)
        assert abs(float(leaf.interactionStiffness)-.2)<1e-6 and before==after and int(root.procEpoch)==epoch
        assert not str(root.interactionError)
        report.update(before=before,epoch=epoch,stiffness=float(leaf.interactionStiffness),status='stiffness_set')
        report['checks'].append('Solver stiffness updates without rebuilding preparation or static placements')
    elif phase==2:
        mount(root,leaf);r.CVSetting=float(r.units.decodeValue('1cm'))
        r.execute('WFSection.interactionsUI_minimumSpin.changed CVSetting')
        result=definition(leaf)
        assert abs(float(leaf.interactionMinimumM)-.01)<1e-6 and result['revision']>report['before']['revision']
        assert result['source']==report['before']['source'] and result['hash']!=report['before']['hash']
        assert not str(root.interactionError) and bool(leaf.interactionsReady(leaf.validSources()))
        report.update(minimum=result,status='minimum_set');report['checks'].append('Minimum stem automatically rebuilds the source definition')
    elif phase==3:
        mount(root,leaf);r.CVSetting=float(r.units.decodeValue('10cm'))
        r.execute('WFSection.interactionsUI_connectionSpin.changed CVSetting')
        result=definition(leaf)
        assert abs(float(leaf.interactionConnectionM)-.1)<1e-6 and result['revision']>report['minimum']['revision']
        assert result['source']==report['before']['source'] and result['hash']!=report['minimum']['hash']
        assert not str(root.interactionError) and bool(leaf.interactionsReady(leaf.validSources()))
        report.update(connection=result,status='connection_set');report['checks'].append('Branch connection automatically rebuilds the source definition')
    elif phase==4:
        source_case=json.loads((host/'cases'/(case+'.json')).read_text(encoding='utf-8'))
        target=next(x['target_scene_units'] for x in source_case['attempts'] if x['status']=='contact')
        r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages()
        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
        r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
        row=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0]
        r.CVCurrent,r.CVTarget=row.row4,r.Point3(*target)
        r.execute('undo "changed preparation contact" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
        root.interactionsEnsure();stats=json.loads(str(root.interactionsStatistics()))
        assert not str(root.interactionError) and not stats.get('error') and stats['fitted_guides']>0,stats
        audit=json.loads(str(r.cyrusInteractionValidate(root.interactionState,4000000)[2]));assert audit['passed'],audit
        report.update(contact=stats,full_mesh_audit=audit,status='pass');report['checks'].append('Changed preparation still produces a checked collider contact')
    else:raise ValueError('Use phases 1 through 4')
except Exception:
    report['status']='failed';report['error']=traceback.format_exc()
else:
    report.pop('error',None)
finally:
    path.write_text(json.dumps(report,indent=2),encoding='utf-8')
