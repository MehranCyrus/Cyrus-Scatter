"""Owned-host checks for preview reuse, append-only settings and saved scenes."""
from pathlib import Path
import hashlib,json,traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));report={}
def write():(O/'persistence.json').write_text(json.dumps(report,indent=2))
def controller():
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    return owner,owner.baseObject
def check(root):
    root.refreshAll();r.CyrusPointSync();r.completeRedraw()
    stats=json.loads(str(root.interactionsStatistics()));assert not stats['error'],stats
    assert all(not str(l.previewError) for l in root.layerObjects)
    return stats
try:
    owner,root=controller();grass=root.layerObjects[0];node=grass.validSources()[0]
    before=str(grass.interactionDefinitions[0]);report['preview_reuse']=[]
    for fraction in [.01,.25,.05]:
        grass.interactionFoliage=fraction;grass.interactionSourceCache=r.Array();grass.interactionsChanged();root.interactionsEnsure()
        value=next(x[1] for x in grass.interactionSourceCache if x[0]==node);info=json.loads(str(r.cyrusInteractionSourceInfo(value)))
        assert info['can_prepare'] and info['guide_inference_reused'];assert str(grass.interactionDefinitions[0])==before
        report['preview_reuse'].append({'fraction':fraction,'preview_triangles':info['delivered_preview_triangles'],'guides':info['guides'],'inference_reused':True})
    r.execute('undo "Test preparation limit persistence" on E873Grass.interactionMaxVertices=3000000')
    assert int(grass.interactionMaxVertices)==3000000
    r.execute('max undo');assert int(grass.interactionMaxVertices)==2000000
    r.execute('max redo');assert int(grass.interactionMaxVertices)==3000000
    report['limit_undo_redo']=True
    retained=str(root.interactionsStatistics());grass.interactionMaxVertices=3;grass.interactionsLimitsChanged()
    try:root.interactionsEnsure();raise AssertionError('Low source limit unexpectedly admitted')
    except AssertionError:raise
    except Exception as error:report['bounded_failure']=str(error)
    assert str(root.interactionsStatistics())==retained
    grass.interactionMaxVertices=3000000;grass.interactionsLimitsChanged();root.interactionsEnsure();report['failure_retained_complete_result']=True
    objects_before=len(list(r.objects));removed=grass.interactionsCleanProxies()
    assert len(list(r.objects))==objects_before;report['unused_links_removed']=int(removed);report['cleanup_keeps_meshes']=True
    grass.interactionMaxTriangles=6000000;grass.interactionMaxGuides=12000;grass.interactionMemoryMiB=4096;grass.interactionsLimitsChanged()
    report['increased_limits']=[int(x) for x in grass.interactionsLimits()];report['before_save_statistics']=check(root)
    trial=ROOT/'dist/CyrusScatter-0.87.3-20261026-interactions-r4/Trials/New_Plants_Interaction_0.87.3.max';trial.parent.mkdir(exist_ok=True)
    assert not trial.exists();r.saveMaxFile(str(trial),quiet=True);report['trial']=str(trial);report['trial_sha256']=hashlib.sha256(trial.read_bytes()).hexdigest();write()
    assert r.loadMaxFile(str(trial),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner,root=controller();grass=root.layerObjects[0]
    assert [int(x) for x in grass.interactionsLimits()]==report['increased_limits'];assert str(grass.interactionDefinitions[0])==before
    report['reopened_statistics']=check(root);report['definition_and_limits_roundtrip']=True;write()
    legacy=ROOT/'dist/CyrusScatter-0.87.2-20261026-r2/Trials/Small_Test_Interaction_0.87.2.max'
    report['legacy_original_sha256']=hashlib.sha256(legacy.read_bytes()).hexdigest()
    assert r.loadMaxFile(str(legacy),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    _,old=controller();report['legacy_statistics']=check(old)
    assert report['legacy_statistics']['plants']==3650
    assert all(int(l.interactionMaxVertices)==2000000 for l in old.layerObjects)
    trees=old.layerObjects[4];assert len(trees.interactionProxyNodes)==2 and all(r.isValidNode(n) for n in trees.interactionProxyNodes)
    large=r.cyrusInteractionSource(trees.validSources()[0],r.undefined,r.Array(.005,.05,2,trees.interactionsLimits(),.15),2)
    report['large_visual_capture']=json.loads(str(r.cyrusInteractionSourceInfo(large)))
    report['legacy_proxy_bindings_retained']=True;assert hashlib.sha256(legacy.read_bytes()).hexdigest()==report['legacy_original_sha256'];write()
    assert r.loadMaxFile(str(trial),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner,root=controller();check(root)
    r.E873Owner=owner;r.E873Root=root;r.E873Grass=root.layerObjects[0];r.E873Collider=root.layerObjects[1];r.E873Sphere=r.getNodeByName('Sphere001');r.E873Edit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    r.E873Base=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4
    root.selectLayer(2)
    r.execute('select E873Owner;max modify mode;modPanel.setCurrentObject E873Edit;subObjectLevel=1;max move;cyrusEditActiveLayers E873Edit #(E873Collider.editLayerKey);cyrusEditSelect E873Edit #(1)')
    r.execute('(local target=E873Base+[6,0,6],eye=target+[35,-50,28];local look=normalize(target-eye),right=normalize(cross look [0,0,1]),up=normalize(cross right look);viewport.setType #view_persp_user;viewport.setTM (inverse(matrix3 right up (-look) eye));viewport.setRenderLevel #smoothhighlights;completeRedraw())')
    report['status']='pass';write()
except Exception:report['failure']=traceback.format_exc();write()
