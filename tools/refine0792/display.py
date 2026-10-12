"""Display correctness, pending Manual edits, owner identity and invalidation."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('refine0791-layer0792-'):
    raise RuntimeError('Owned 0.79.2 host required')
report=dict(assertions=[],errors=[])
def write():(OUT/'display0792.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(ok,label,**details):
    report['assertions'].append(dict(passed=bool(ok),label=label,**details));write()
def pump():
    r.execute('(local end=timeStamp()+450;while timeStamp()<end do (windows.processPostedMessages();sleep .01))')
    r.completeRedraw()
def sync():r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
def fp(root):return [str(r.cyrusEditFingerprint(rows,'areas')) for rows in root.groupSnapshotRows]
def fresh(count=60,layers=1,geometry=False):
    r.resetMaxFile(r.Name('noPrompt'))
    surface=r.plane(name='R792_Surface',width=300,length=300)
    model=r.box(name='R792_Model',width=2,length=2,height=5,pos=r.Point3(500,0,0))
    node=r.AminScatterObject(name='R792_Controller');root=node.baseObject;root.updateMode=1;root.autoRender=False
    for i in range(layers):
        root.newLayer();leaf=root.selectedLayer();leaf.amount=count+i*13
        root.setLayerSurfaces(leaf,r.Array(surface))
        leaf.addPointSource()
        if geometry:leaf.replacePointSource(1,model)
        leaf.setSourceRadius(r.execute('#{1}'),5.0)
        leaf.setSourceRadius(r.execute('#{1}'),True,kind=3)
    root.setGroupDisplay(3 if geometry else 4);root.refreshAll();sync();pump()
    return node,root,root.layerObjects[0],surface,model
def bind(node,root,section):
    r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(node.baseObject)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    root.mainUI.selectLayerView(root.layerObjects[0]);page=getattr(root,section)
    page.open=True;root.mainUI.bindSection(page);page.layout();return page
def count(node):return int(r.cyrusRetainedStats(r.CyrusPointOwner(node))[0])
try:
    node,root,leaf,surface,model=fresh()
    ui=bind(node,root,'previewUI');epoch=int(root.procEpoch);fingerprint=fp(root);original_radii=str(root.procPublishedRadii)
    leaf.amount=81;leaf.sourceRadii=r.Array(12.0)
    ui.flow_previewUI_radiusLimitSpin.changed(7);sync()
    check(int(root.procEpoch)==epoch and fp(root)==fingerprint and leaf.dirty,'Radius limit preserves pending Manual amount and radius edits')
    check(leaf.radiusDisplayCount()==7 and str(root.procPublishedRadii)==original_radii,'Limit shows seven circles using published radii')
    check(abs(float(r.length(leaf.radiusPreview[0][0][0]-root.groupSnapshotRows[0][0][0].row4))-5)<.001,'Pending source radius is not used in the old display')
    ui.flow_previewUI_radiusAllCheck.changed(True);sync()
    check(leaf.radiusDisplayCount()==60 and int(root.procEpoch)==epoch,'Show All restores all published circles without Update')
    models=bind(node,root,'modelsUI');models.sourceUI_plantList.selection=r.execute('#{1}')
    models.sourceUI_showRadiusCheck.changed(False);sync()
    check(leaf.radiusDisplayCount()==0 and int(root.procEpoch)==epoch,'Per-source Show Radius off changes only the display')
    models.sourceUI_showRadiusCheck.changed(True);sync()
    check(leaf.radiusDisplayCount()==60 and int(root.procEpoch)==epoch,'Per-source Show Radius on preserves pending Manual edits')
    root.refreshAll();sync()
    check(len(root.groupSnapshotRows[0])==81 and not leaf.dirty,'Explicit Update publishes pending amount')
    root.updateMode=2;pump();epoch=int(root.procEpoch);fingerprint=fp(root)
    models.sourceUI_showRadiusCheck.changed(False);sync();pump()
    check(int(root.procEpoch)==epoch and fp(root)==fingerprint,'Live Show Radius does not republish placements')
    models.sourceUI_showRadiusCheck.changed(True);sync();pump()
    epoch=int(root.procEpoch);before=leaf.cachedPoints
    r.CyrusRetainedPointDrawing(False);r.CyrusRetainedMeshDrawing(False);sync()
    check(leaf.cachedPoints==before and int(root.procEpoch)==epoch and len(r.CyrusViewportRecords[0][4])==2,'CPU fallback reuses point and radius snapshots')
    r.CyrusRetainedPointDrawing(True);r.CyrusRetainedMeshDrawing(True);sync()
    check(count(node)==81 and not str(r.CyrusPointLastError),'Retained display recovers without placement change')
    root.layerVisible[0]=False;pump()
    check(count(node)==0,'Layer visibility removes points and radii from retained publication')
    root.layerVisible[0]=True;pump();check(count(node)==81,'Layer visibility restores cached output')
    node.isHidden=True;pump();draws=int(r.cyrusRetainedStats(r.CyrusPointOwner(node))[7]);r.completeRedraw()
    check(int(r.cyrusRetainedStats(r.CyrusPointOwner(node))[7])==draws,'Hidden controller stops retained drawing immediately')
    node.isHidden=False;pump();check(count(node)==81,'Unhide restores retained output')
    epoch=int(root.procEpoch);fingerprint=fp(root);model.pos.x+=30;pump()
    check(int(root.procEpoch)==epoch and fp(root)==fingerprint,'Unrelated scene edit leaves Point placements unchanged')
    surface.width=360;pump()
    check(fp(root)!=fingerprint,'Live receiver edit invalidates cached drawable records')
    root.updateMode=1;epoch=int(root.procEpoch);fingerprint=fp(root);surface.width=400;pump()
    check(int(root.procEpoch)==epoch and fp(root)==fingerprint,'Manual receiver edit remains pending')
    root.refreshAll();sync();check(fp(root)!=fingerprint,'Explicit Update consumes Manual receiver edit')
    # Invalid successors are rejected without mutating a published snapshot.
    saved=leaf.radiusCache
    failed=False
    try:r.cyrusBuildRadiusPreview(r.Array(r.Array(r.Array(r.Point3(0,0,0),r.Point3(1,1,0)),r.color(1,2,3))))
    except Exception:failed=True
    check(failed and leaf.radiusCache==saved,'Malformed native radius input preserves published cache')
    before=leaf.cachedPoints;before_rings=leaf.radiusCache
    old_radius=root.procPublishedRadii[0][0]
    try:
        root.procPublishedRadii[0][0]='injected invalid radius'
        root.radiusDisplayAll=False;root.radiusDisplayLimit=3;root.refreshDisplay()
        check(leaf.cachedPoints==before and leaf.radiusCache==before_rings and bool(str(leaf.previewError)),'Failed display successor retains complete prior point/radius snapshot')
    finally:root.procPublishedRadii[0][0]=old_radius
    root.refreshDisplay();sync();check(leaf.radiusDisplayCount()==3 and not str(leaf.previewError),'Display failure recovers on retry')
    # Every deletion position, different amounts, mesh mode and a Manual display switch.
    for removed in (0,1,2):
        node,root,leaf,surface,model=fresh(count=31,layers=3,geometry=True)
        owners=list(root.layerObjects);original={str(o.layerID):int(o.generatedCount) for o in owners};epoch=int(root.procEpoch)
        root.activeLayer=removed+1;root.removePopulation();root.setGroupDisplay(4);root.setGroupDisplay(3);sync()
        check(all(int(o.generatedCount)==original[str(o.layerID)] and not str(o.previewError) for o in root.layerObjects),f'Manual remove index {removed+1}: surviving owners keep their geometry counts')
        check(int(root.procEpoch)==epoch,f'Manual remove index {removed+1}: display switch does not publish pending edit')
        actual=int(r.cyrusRetainedMeshStats(r.CyrusPointOwner(node))[1]);expected=sum(original[str(o.layerID)] for o in root.layerObjects)
        check(actual==expected,f'Manual remove index {removed+1}: retained mesh instances match surviving owners',actual=actual,expected=expected,held=bool(r.CyrusInteractionHeld()),error=str(r.CyrusPointLastError))
    # Native publication accepts ten point caches plus ten radius overlays.
    node,root,leaf,surface,model=fresh(count=3,layers=10)
    expected=sum(int(l.generatedCount) for l in root.layerObjects)
    check(len(r.CyrusViewportRecords[0][2])==20 and count(node)==expected and not str(r.CyrusPointLastError),'Ten populations retain all twenty point/radius caches')
    saved_fp=fp(root);r.saveMaxFile(str(OUT/'display0792-ten-layers.max'),quiet=True)
    r.loadMaxFile(str(OUT/'display0792-ten-layers.max'),quiet=True,useFileUnits=True)
    node=r.getNodeByName('R792_Controller');root=node.baseObject;root.refreshAll();sync()
    check(fp(root)==saved_fp and count(node)==expected,'Save/reopen reconstructs transient records with identical placements')
    # Analyzer data and enabled state must invalidate the cached drawables even
    # though Analyzer helper selection notifications are intentionally ignored.
    node,root,leaf,surface,model=fresh(count=300,geometry=True)
    guide=r.CyrusSurfaceAnalyzer(name='R792_Analyzer');an=guide.baseObject
    an.surface=surface;an.resolution=48;an.pointRadius=20;an.fitRadius=10;an.relaxIterations=0;an.updateMode=1;an.runAnalysis()
    leaf.diversityMode=4;leaf.analyzerNode=guide;leaf.patternLines=r.Array(guide);leaf.patternWidths=r.Array(25.0)
    leaf.strokeSides=r.Array(2);leaf.strokeModes=r.Array(2);leaf.strokeSourceRows=r.Array(1);leaf.strokeSourceNodes=r.Array(model)
    leaf.strokeMin=r.Array(1.0);leaf.strokeMax=r.Array(1.0);root.refreshAll();root.updateMode=2;sync();pump()
    check(leaf.generatedCount>0 and not str(leaf.previewError),'Analyzer border baseline is current')
    an.cyrusEnabled=False;pump()
    check(int(r.cyrusRetainedMeshStats(r.CyrusPointOwner(node))[1])==0,'Analyzer disabled state clears cached mesh display')
    an.cyrusEnabled=True;pump()
    check(int(r.cyrusRetainedMeshStats(r.CyrusPointOwner(node))[1])>0,'Analyzer re-enable restores cached mesh display')
    an.resolution=64;an.runAnalysis();pump()
    check(int(leaf.cachedAnalyzerRun)==int(an.getAnalysisRuns()) and not str(leaf.previewError),'Analyzer data revision triggers current Live display')
except Exception:report['errors'].append(traceback.format_exc())
finally:write()
