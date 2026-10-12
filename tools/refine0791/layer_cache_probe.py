"""Focused cache-owner and selected-layer diagnosis; owned hosts only."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('refine0791-layer'):
    raise RuntimeError('Owned investigation host required')
report=dict(cases=[],errors=[])

def write():
    (OUT/'layer-cache-probe.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

def settle():
    r.execute('(local finish=timeStamp()+250;while timeStamp()<finish do (windows.processPostedMessages();sleep .01))')
    r.CyrusPointSync();r.redrawViews()

def visible(root):
    r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(node.baseObject)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    for name in ('managerUI','modelsUI','surfacesUI'):
        panel=getattr(root,name);panel.open=True;root.mainUI.bindSection(panel);panel.layout()

def snap(label):
    settle()
    owners=list(root.procPublishedOwners)
    output=[]
    for leaf in root.layerObjects:
        i=next((i for i,o in enumerate(owners) if o==leaf),None)
        output.append(dict(id=str(leaf.layerID),amount=int(leaf.amount),sources=[str(n.name) if n else None for n in leaf.sources],
                           receivers=[str(n.name) for n in leaf.surfaceNodes],
                           shown=int(leaf.cachedPointCount),generated=int(leaf.generatedCount),
                           published_slot=i,count=None if i is None else len(root.groupSnapshotRows[i]),
                           fingerprint=None if i is None else str(r.cyrusEditFingerprint(root.groupSnapshotRows[i],'areas')),
                           error=str(leaf.previewError),dirty=bool(leaf.dirty),builds=int(leaf.previewBuildCount)))
    owner=r.CyrusPointOwner(node)
    record=dict(label=label,epoch=int(root.procEpoch),layers=output,
                model_editor=list(map(str,root.modelsUI.sourceUI_plantList.items)),
                owner=str(root.modelsUI.sourceUI_obj.layerID),
                retained=None if owner is None else list(map(str,r.cyrusRetainedStats(owner))),
                mesh=None if owner is None else list(map(str,r.cyrusRetainedMeshStats(owner))),
                native_error=str(r.CyrusPointLastError))
    case['snapshots'].append(record);write();return record

def add_model_layer(amount):
    root.managerUI.flow_layersUI_addButton.pressed()
    leaf=root.selectedLayer();leaf.amount=amount
    root.setLayerSurfaces(leaf,r.Array(ground))
    root.modelsUI.sourceUI_addPlant.picked(model)
    return leaf

try:
    if not r.cyrusLicenseAllows():raise RuntimeError('Authoring license required')
    r.resetMaxFile(r.Name('noPrompt'))
    ground=r.plane(name='Receiver',width=300,length=300)
    model=r.box(name='Probe_model',width=2,length=2,height=5,pos=r.Point3(500,0,0))
    for mode in (1,2):
        case=dict(name=('manual' if mode==1 else 'live')+'-delete-earlier-point',snapshots=[])
        report['cases'].append(case)
        node=r.AminScatterObject(name=case['name']);root=node.baseObject
        root.updateMode=1;root.autoRender=False;root.newLayer();visible(root)
        point=root.selectedLayer();point.amount=23
        root.setLayerSurfaces(point,r.Array(ground));root.modelsUI.sourceUI_addPoint.pressed()
        geometry=add_model_layer(137)
        root.setGroupDisplay(3);root.refreshAll();root.updateMode=mode
        snap('both-published')
        root.mainUI.selectLayerView(point)
        root.managerUI.flow_layersUI_removeButton.pressed()
        snap('earlier-point-removed')
        root.setGroupDisplay(4)
        snap('change-display-to-centres')
        root.setGroupDisplay(3)
        snap('change-display-to-mesh')
        root.mainUI.updateNow.pressed()
        snap('explicit-update')
        r.saveMaxFile(str(OUT/(case['name']+'.max')),quiet=True)
    case=dict(name='live-settings-and-selection',snapshots=[]);report['cases'].append(case)
    node=r.AminScatterObject(name=case['name']);root=node.baseObject
    root.updateMode=1;root.autoRender=False;root.newLayer();visible(root)
    first=root.selectedLayer();first.amount=137;root.setLayerSurfaces(first,r.Array(ground))
    root.modelsUI.sourceUI_addPlant.picked(model)
    root.modelsUI.sourceUI_sourceScaleSpin.changed(1.75)
    root.modelsUI.sourceUI_radiusSourceSpin.changed(3.25)
    root.setGroupDisplay(3);root.refreshAll();root.updateMode=2
    snap('geometry-published')
    root.managerUI.flow_layersUI_addButton.pressed()
    second=root.selectedLayer();root.modelsUI.sourceUI_addPoint.pressed()
    root.setLayerSurfaces(second,r.Array(ground))
    root.modelsUI.sourceUI_sourceScaleSpin.changed(0.6)
    root.modelsUI.sourceUI_radiusSourceSpin.changed(6.5)
    snap('point-values-edited')
    root.managerUI.flow_layersUI_removeButton.pressed()
    snap('point-removed')
    case['values']=dict(first_scale=float(first.sourceScale(1)),first_radius=float(first.sourceRadius(1)),
                       shown_scale=float(root.modelsUI.sourceUI_sourceScaleSpin.value),
                       shown_radius=float(root.modelsUI.sourceUI_radiusSourceSpin.value))
    r.clearSelection();settle();visible(root)
    snap('reselect-original')
    for i in range(3):snap('unchanged-'+str(i+1))
except Exception:
    report['errors'].append(traceback.format_exc())
finally:
    write()
