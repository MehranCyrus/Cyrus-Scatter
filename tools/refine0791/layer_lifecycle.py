"""Observe real layer/source handlers in an owned, disposable 0.79.1 host.

Run with ``undo off (python.ExecuteFile @".../layer_lifecycle.py")`` through
runtime_driver, never in the artist process. No product overrides are installed.
"""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('refine0791-layer'):
    raise RuntimeError('Owned layer investigation profile required')
result = dict(cases=[], assertions=[], errors=[])


def write():
    (OUT / 'layer-lifecycle.json').write_text(json.dumps(result, indent=2), encoding='utf-8')


def pump():
    r.execute('(local finish=timeStamp()+250;while timeStamp()<finish do (windows.processPostedMessages();sleep .01))')
    r.CyrusPointSync()
    r.redrawViews()


def page(root, name):
    panel = getattr(root, name)
    panel.open = True
    root.mainUI.bindSection(panel)
    panel.layout()
    return panel


def ident(obj):
    return None if obj is None else str(obj.layerID)


def snapshot(root, node, label):
    started = time.perf_counter()
    pump()
    published = list(root.procPublishedOwners)
    rows = []
    for leaf in root.layerObjects:
        i = next((i for i, owner in enumerate(published) if owner == leaf), None)
        rows.append(dict(
            id=ident(leaf), name=str(root.layerCaption(leaf)),
            sources=[str(n.name) if n is not None else None for n in leaf.sources],
            source_ids=list(map(str, leaf.sourceRowIDs)),
            point_rows=[bool(leaf.isPointSource(i+1)) for i in range(len(leaf.sources))],
            surfaces=[str(n.name) if n is not None else None for n in leaf.surfaceNodes],
            amount=int(leaf.amount), dirty=bool(leaf.dirty),
            generated=int(leaf.generatedCount), shown=int(leaf.cachedPointCount),
            preview_builds=int(leaf.previewBuildCount), error=str(leaf.previewError),
            published_slot=i,
            count=None if i is None else len(root.groupSnapshotRows[i]),
            fingerprint=None if i is None else str(r.cyrusEditFingerprint(root.groupSnapshotRows[i], 'areas')),
        ))
    models=root.modelsUI
    owner=r.CyrusPointOwner(node)
    data=dict(label=label, epoch=int(root.procEpoch), active=int(root.activeLayer),
              main_owner=ident(root.mainUI.owner), models_owner=ident(models.owner),
              models_object=ident(models.sourceUI_obj), models_ready=bool(models.controlsReady),
              visible_models=list(map(str,models.sourceUI_plantList.items)),
              visible_layers=list(map(str,root.managerUI.flow_layersUI_layerList.items)),
              layers=rows, published_owners=[ident(p) for p in published],
              retained_stats=None if owner is None else list(map(str,r.cyrusRetainedStats(owner))),
              native_error=str(r.CyrusPointLastError), held=bool(r.CyrusInteractionHeld()),
              elapsed_ms=round((time.perf_counter()-started)*1000,2))
    current['snapshots'].append(data)
    write()
    return data


def check(ok, label, **details):
    result['assertions'].append(dict(case=current['name'], passed=bool(ok), label=label, **details))
    write()


try:
    result['license_allows'] = bool(r.cyrusLicenseAllows())
    if not result['license_allows']:
        raise RuntimeError('Current test authority does not authorize editing')
    for mode in (2, 1):
        for receiver in (False, True):
            current = dict(name=('live' if mode==2 else 'manual') + ('-point-receiver' if receiver else '-point-no-receiver'), snapshots=[])
            result['cases'].append(current)
            r.resetMaxFile(r.Name('noPrompt'))
            ground=r.plane(name='Geometry_receiver',width=300,length=300)
            model=r.box(name='Original_model',width=2,length=2,height=5,pos=r.Point3(500,0,0))
            node=r.AminScatterObject(name='Layer_lifecycle_probe')
            root=node.baseObject
            root.updateMode=1
            root.autoRender=False
            root.newLayer()
            first=root.selectedLayer()
            first.amount=137
            root.setLayerSurfaces(first,r.Array(ground))
            r.select(node)
            r.execute('max modify mode')
            r.modPanel.setCurrentObject(node.baseObject)
            if not root.mainUI.controlsReady:
                root.mainUI.mountTimer.tick()
            manager=page(root,'managerUI')
            models=page(root,'modelsUI')
            models.sourceUI_addPlant.picked(model)
            root.setGroupDisplay(3)
            root.refreshAll()
            root.updateMode=mode
            baseline=snapshot(root,node,'geometry-baseline')
            first_id=ident(first)
            check(baseline['layers'][0]['count']==137,'Geometry baseline has 137 placements')
            manager.flow_layersUI_addButton.pressed()
            added=snapshot(root,node,'after-add-layer')
            second=root.selectedLayer()
            check(ident(second)!=first_id and len(root.layerObjects)==2,'Add selects a distinct second layer')
            # Deliberately use the existing visible controls without force rebinding.
            root.modelsUI.sourceUI_addPoint.pressed()
            if receiver:
                root.setLayerSurfaces(second,r.Array(ground))
            pointed=snapshot(root,node,'after-add-point')
            check(first.sources[0]==model and len(first.sources)==1 and len(first.surfaceNodes)==1,
                  'Point creation preserves the first layer model and receiver')
            check(len(second.sources)==1 and second.isPointSource(1),'Point belongs to the second layer')
            if mode==1:
                root.mainUI.updateNow.pressed()
                snapshot(root,node,'manual-update-with-two-layers')
            # Max's listbox.selected property shadows the event in pymxs.
            # Invoke selectLayerView, the production operation that event calls.
            root.mainUI.selectLayerView(first)
            back=snapshot(root,node,'select-original')
            check(back['models_object']==first_id and 'Original_model' in str(back['visible_models']),
                  'Selecting the original layer restores its source editor')
            root.mainUI.selectLayerView(second)
            snapshot(root,node,'select-point-layer')
            root.managerUI.flow_layersUI_removeButton.pressed()
            removed=snapshot(root,node,'after-remove-point-layer')
            check(len(root.layerObjects)==1 and root.layerObjects[0]==first,
                  'Removing Point layer leaves the original layer identity')
            check(removed['models_object']==first_id and 'Original_model' in str(removed['visible_models']),
                  'Removal restores the original source editor')
            check(removed['layers'][0]['fingerprint']==baseline['layers'][0]['fingerprint'] and removed['layers'][0]['shown']==137,
                  'Removal retains original placements and geometry preview')
            check(not removed['layers'][0]['error'] and not removed['native_error'],'Removal has no preview/cache error')
            root.mainUI.updateNow.pressed()
            updated=snapshot(root,node,'explicit-update-after-remove')
            check(updated['layers'][0]['fingerprint']==baseline['layers'][0]['fingerprint'] and updated['layers'][0]['shown']==137,
                  'Explicit Update reproduces the original geometry exactly')
            r.saveMaxFile(str(OUT/(current['name']+'.max')),quiet=True)
except Exception:
    result['errors'].append(traceback.format_exc())
finally:
    write()
