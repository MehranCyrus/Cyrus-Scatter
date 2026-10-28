"""Save and reopen two explicitly labelled trial copies; never save the artist input."""
from pathlib import Path
import json,math,sys,time,traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(Path(__file__).resolve().parent))
from fixture_assets import load_owned_fixture

out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
destination=ROOT/'Test Scene/Interaction 0.87.5.3'
report={'phase':phase,'status':'running','scope':'Owned Max2027 trial copies, original materials and authored Edit rotations retained'}

def acquire():
    r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1]
    r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)

def settle():
    r.WFRoot.interactionsEnsure();r.CyrusPointSync()
    for _ in range(12):r.windows.processPostedMessages();r.completeRedraw();time.sleep(.02)

def snapshot():
    groups=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2));tm=groups[0][0]
    return {'source_ids':[list(map(str,leaf.sourceRowIDs)) for leaf in r.WFRoot.layerObjects],
            'amounts':[int(leaf.amount) for leaf in r.WFRoot.layerObjects],
            'axis':float(r.length(tm.row1)),'position':[float(x) for x in tm.row4],
            'node_scale':[float(x) for x in r.WFCollider.validSources()[0].scale],
            'model_scale':float(r.WFCollider.sourceScale(1)),
            'moving_triangles':int(r.WFRoot.viewportNavigationFaces),'idle_triangles':int(r.WFRoot.viewportFaces),
            'hide_area':int(r.WFGrass.interactionHideArea),'error':str(r.WFRoot.interactionError),
            'layer_errors':[str(leaf.previewError) for leaf in r.WFRoot.layerObjects]}

try:
    if phase in ('trial-broad-prepare','trial-original-prepare'):
        if phase=='trial-original-prepare':
            load_owned_fixture(r,ROOT/'build/interactions08753-20261028-01/fixtures/New-Plants-22-input.max',ROOT,report)
            acquire()
        r.execute('subObjectLevel=0;clearSelection()')
        r.WFRoot.updateMode=2;r.WFRoot.viewportFaces=0;r.WFRoot.viewportNavigationFaces=500000
        r.WFGrass.amount=1000;r.WFCollider.amount=1;r.WFGrass.interactionHideArea=2
        r.WFRoot.refreshAll();settle()
        report['configuration']=snapshot()
    elif phase in ('trial-save-broad','trial-save-original'):
        label='Broad_Stone_Stress_0.87.5.3.max' if phase.endswith('broad') else 'New_Plants_22_0.87.5.3.max'
        destination.mkdir(parents=True,exist_ok=True);target=destination/label
        if target.exists():
            previous=json.loads((out/(phase+'.json')).read_text(encoding='utf-8'))
            if previous.get('status')!='pass' or Path(previous.get('scene',''))!=target:
                raise RuntimeError('Refusing to overwrite a trial copy not created by this owned run: '+str(target))
            report['updated_own_trial']=True
        r.execute('subObjectLevel=0;clearSelection()');settle();before=snapshot()
        assert not before['error'] and not any(before['layer_errors'])
        assert r.saveMaxFile(str(target),quiet=True)
        load_owned_fixture(r,target,ROOT,report);acquire();settle();after=snapshot()
        assert before['source_ids']==after['source_ids'] and before['amounts']==after['amounts']
        assert before['moving_triangles']==after['moving_triangles']==500000
        assert before['idle_triangles']==after['idle_triangles']==0 and before['hide_area']==after['hide_area']==2
        assert not after['error'] and not any(after['layer_errors'])
        assert math.isclose(before['axis'],after['axis'],rel_tol=2e-5)
        assert max(abs(x-y) for x,y in zip(before['position'],after['position']))<2e-4
        report.update(scene=str(target),before=before,after=after)
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:
    (out/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
