"""Diagnose Add Model / Select From Scene after Point rows, without UI input."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('refine0791-layer'):
    raise RuntimeError('Owned investigation host required')
data=dict(snapshots=[],errors=[])
def write():
    (OUT/'point-model-probe.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
def capture(label):
    r.CyrusPointSync();r.completeRedraw()
    r.execute('(local finish=timeStamp()+250;while timeStamp()<finish do (windows.processPostedMessages();sleep .01))')
    owners=list(root.procPublishedOwners)
    layers=[]
    for leaf in root.layerObjects:
        i=next((i for i,p in enumerate(owners) if p==leaf),None)
        sources=[dict(node=str(n.name) if n is not None else None,point=bool(leaf.isPointSource(j+1)),
                      empty=bool(leaf.isEmptySource(j+1)),row_id=str(leaf.sourceRowIDs[j]),
                      label=str(leaf.sourceLabel(j+1))) for j,n in enumerate(leaf.sources)]
        counts={}
        if i is not None:
            for row in root.groupSnapshotRows[i]:
                key=str(row[1]);counts[key]=counts.get(key,0)+1
        layers.append(dict(id=str(leaf.layerID),sources=sources,receivers=[str(n.name) for n in leaf.surfaceNodes],
                           slot_counts=counts,shown=int(leaf.cachedPointCount),error=str(leaf.previewError),
                           source_points=list(map(bool,leaf.sourcePoint)),source_empty=list(map(bool,leaf.sourceEmpty))))
    owner=r.CyrusPointOwner(node)
    state=dict(label=label,layers=layers,editor=list(map(str,root.modelsUI.sourceUI_plantList.items)),
               mesh=list(map(str,r.cyrusRetainedMeshStats(owner))) if owner is not None else None,
               retained=list(map(str,r.cyrusRetainedStats(owner))) if owner is not None else None,
               native_error=str(r.CyrusPointLastError))
    data['snapshots'].append(state);write()
    r.R791CapturePath=str(OUT/(label+'.png'))
    r.execute('(local image=gw.getViewportDib();image.filename=R791CapturePath;save image;close image)')
try:
    if not r.cyrusLicenseAllows():raise RuntimeError('Authoring license required')
    r.resetMaxFile(r.Name('noPrompt'))
    ground=r.plane(name='Geometry_receiver',width=140,length=140,pos=r.Point3(-95,0,0))
    second_ground=r.plane(name='Point_receiver',width=140,length=140,pos=r.Point3(95,0,0))
    model=r.box(name='Original_box',width=8,length=8,height=16,pos=r.Point3(500,0,0))
    model.wirecolor=r.color(230,60,40)
    other=r.sphere(name='Added_sphere',radius=4,pos=r.Point3(550,0,0))
    third=r.cone(name='Listed_cone',radius1=4,radius2=0,height=12,pos=r.Point3(600,0,0))
    r.select(r.Array(ground,second_ground))
    r.execute('viewport.setLayout #layout_1;viewport.setType #view_top;max zoomext sel all;viewport.setRenderLevel #smoothhighlights')
    node=r.AminScatterObject(name='Point_model_lifecycle');root=node.baseObject
    root.updateMode=1;root.autoRender=False;root.newLayer()
    first=root.selectedLayer();first.amount=137;root.setLayerSurfaces(first,r.Array(ground))
    r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    for name in ('managerUI','modelsUI','surfacesUI'):
        panel=getattr(root,name);panel.open=True;root.mainUI.bindSection(panel);panel.layout()
    root.modelsUI.sourceUI_addPlant.picked(model)
    root.setGroupDisplay(3);root.refreshAll();root.updateMode=2
    capture('01-geometry-baseline')
    root.managerUI.flow_layersUI_addButton.pressed()
    second=root.selectedLayer();root.setLayerSurfaces(second,r.Array(second_ground))
    root.modelsUI.sourceUI_addPoint.pressed()
    capture('02-point-second-receiver')
    root.modelsUI.sourceUI_addPlant.picked(other)
    capture('03-add-model-to-point')
    # The list picker calls this same function after returning selected nodes.
    # Its modal selection UI is deliberately not opened or automated.
    root.modelsUI.sourceUI_addSources(r.Array(third))
    capture('04-list-add-to-mixed-layer')
    root.modelsUI.sourceUI_addPoint.pressed()
    capture('05-add-another-point')
    root.modelsUI.sourceUI_addSources(r.Array(other,third))
    capture('06-list-existing-models')
    root.managerUI.flow_layersUI_removeButton.pressed()
    capture('07-remove-point-model-layer')
    r.saveMaxFile(str(OUT/'Point_model_lifecycle.max'),quiet=True)
except Exception:
    data['errors'].append(traceback.format_exc())
finally:
    write()
