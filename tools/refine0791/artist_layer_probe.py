"""Inspect an isolated copy of the artist's layering witness; do not overwrite it."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('refine0791-layer'):
    raise RuntimeError('Owned artist-copy investigation host required')
report=dict(snapshots=[],errors=[])
def write():
    (OUT/'artist-layer-probe.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
def simple(v):
    try:return [simple(x) for x in v]
    except TypeError:return str(v)
def snap(label,settle=True):
    if settle:
        r.CyrusPointSync();r.completeRedraw()
        r.execute('(local finish=timeStamp()+300;while timeStamp()<finish do (windows.processPostedMessages();sleep .01))')
    nodes=[]
    for node in list(r.objects):
        if str(r.classOf(node.baseObject))!='AminScatterObject':continue
        root=node.baseObject;owners=list(root.procPublishedOwners);layers=[]
        for j,leaf in enumerate(root.layerObjects):
            p=next((k for k,o in enumerate(owners) if o==leaf),None)
            keys=('amount','randomSeed','populationMode','diversityMode','paintEnabled','containerMode','containerActive',
                  'sourceRowIDs','sourcePoint','sourceEmpty','sourceWeights','sourceScales','sourceRadii',
                  'areaModes','areaFallConfigs','strokeModes','strokeSourceIDs','strokeColorKeys','patternWidths',
                  'viewportMode','viewportInstances','viewportFaces','showPoints','showCenters','previewBudget',
                  'dirty','previewError','generatedCount','cachedPointCount','procPopulation')
            layers.append(dict(index=j+1,id=str(leaf.layerID),name=str(root.layerNames[j]),enabled=bool(root.layerEnabled[j]),
                               visible=bool(root.layerVisible[j]),settings={k:str(getattr(leaf,k)) for k in keys},
                               sources=[str(n.name) if n is not None else None for n in leaf.sources],
                               valid_sources=list(map(str,leaf.validSources())),
                               receivers=[str(n.name) for n in leaf.surfaceNodes],
                               areas=[str(n.name) for n in leaf.areaNodes],
                               published_slot=p,count=None if p is None else len(root.groupSnapshotRows[p]),
                               fingerprint=None if p is None else str(r.cyrusEditFingerprint(root.groupSnapshotRows[p],'areas'))))
        retained=r.CyrusPointOwner(node)
        nodes.append(dict(name=str(node.name),mode=int(root.updateMode),active=int(root.activeLayer),epoch=int(root.procEpoch),
                          mesh=None if retained is None else list(map(str,r.cyrusRetainedMeshStats(retained))),
                          retained=None if retained is None else list(map(str,r.cyrusRetainedStats(retained))),layers=layers))
    report['snapshots'].append(dict(label=label,controllers=nodes,native_error=str(r.CyrusPointLastError)))
    write()
    if settle:
        r.R791CapturePath=str(OUT/(label+'.png'))
        r.execute('(local b=gw.getViewportDib();b.filename=R791CapturePath;save b;close b)')
try:
    loaded=r.loadMaxFile(str(OUT/'artist-layering-input.max'),quiet=True,useFileUnits=True)
    report['loaded']=bool(loaded);write()
    if not loaded:raise RuntimeError('Could not open the copied scene')
    report['scene_objects']=[dict(name=str(n.name),kind=str(r.classOf(n.baseObject)),position=str(n.pos)) for n in r.objects]
    snap('artist-01-loaded',False)
    snap('artist-02-realized')
    node=r.getNodeByName('Cyrus Scatter001');root=node.baseObject
    first,second=list(root.layerObjects)
    r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    for name in ('managerUI','modelsUI','surfacesUI'):
        panel=getattr(root,name);panel.open=True;root.mainUI.bindSection(panel);panel.layout()
    root.mainUI.selectLayerView(second)
    root.modelsUI.sourceUI_plantList.selection=r.execute('#{1,2}')
    root.modelsUI.sourceUI_removePlant.pressed()
    snap('artist-03-second-models-removed')
    root.modelsUI.sourceUI_addPoint.pressed()
    snap('artist-04-second-point-added')
    root.modelsUI.sourceUI_addPlant.picked(r.getNodeByName('Pyramid001'))
    snap('artist-05-add-model-after-point')
    root.modelsUI.sourceUI_addSources(r.Array(r.getNodeByName('Sphere001')))
    snap('artist-06-list-return-add-sphere')
    root.managerUI.flow_layersUI_removeButton.pressed()
    snap('artist-07-second-layer-removed')
    # Model the held/released scheduling branch without sending pointer input.
    # Store the function value in MAXScript. A pymxs callable wrapper resolves
    # its global name at invocation and cannot safely preserve a replaced fn.
    r.execute('global L791PreviousHeld=CyrusInteractionHeld')
    try:
        r.execute('fn CyrusInteractionHeld = true')
        root.managerUI.flow_layersUI_addButton.pressed()
        held_layer=root.selectedLayer()
        root.setLayerSurfaces(held_layer,r.Array(r.getNodeByName('Plane002')))
        root.modelsUI.sourceUI_addPoint.pressed()
        root.modelsUI.sourceUI_addPlant.picked(r.getNodeByName('Pyramid001'))
    finally:
        r.execute('CyrusInteractionHeld=L791PreviousHeld')
    r.CyrusReleaseTick(None,None)
    snap('artist-08-after-simulated-release')
except Exception:
    report['errors'].append(traceback.format_exc())
finally:
    write()
