-- Scripted qualification only: never load into an artist session.
global LRRoot,LRNode,LRLayer,LRPlane,LRSphere,LRSource,LRA,LRB,LRChecks,LRAssert,LRSetup,LRRun,LRViews,LRReopen
fn LRAssert condition message = (
    if not condition do throw ("Layer regions: "+message)
    append LRChecks message
    local log=createFile (MCPFixtureDir+"layer-regions-checks.txt")
    for item in LRChecks do format "%\n" item to:log
    close log
    true
)
fn LRSetup = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Owned qualification host required"
    LRChecks=#();CyrusStopBrush();resetMaxFile #noPrompt
    viewport.setType #view_top
    LRPlane=plane name:"LR_Plane" width:200 length:200 widthsegs:4 lengthsegs:4
    LRSphere=sphere name:"LR_Sphere" radius:60 segs:24 pos:[350,0,0]
    LRSource=box name:"LR_Model" width:1 length:1 height:4 pos:[1000,0,0];hide LRSource
    LRNode=AminScatterObject name:"LR_Controller";LRRoot=LRNode.baseObject
    LRRoot.setLayerTransfer true;LRRoot.updateMode=1;LRRoot.autoRender=false;LRRoot.newLayer()
    LRLayer=LRRoot.selectedLayer();LRLayer.sources=#(LRSource);LRLayer.sourceWeights=#(1.0);LRLayer.amount=1000
    LRRoot.setLayerTransfer false
    LRRoot.setLayerSurfaces LRLayer #(LRPlane,LRSphere)
    LRRoot.refreshAll()
    LRAssert ((LRLayer.validSurfaces()).count==2) "Layer has both receivers"
    LRAssert (LRRoot.groupSnapshotRows[1].count==1000) "Unpainted layer needs no area"
    true
)
fn LRRun = (
    local r=LRRoot,a=LRLayer
    local sources=a.sources as array
    LRA=r.addPaintArea a target:LRPlane
    LRB=r.addPaintArea a target:LRSphere
    LRAssert (r.layerObjects.count==1 and a.paintAreas.count==2) "Areas are not populations"
    LRAssert ((a.sources as array) as string==sources as string) "Selecting areas preserves layer models"
    cyrusBrushSettings LRA.paintDocument 55 1 0 false 1
    LRAssert (cyrusBrushDab LRA.paintDocument [0,0,200] [0,0,-1] true) "Paint plane"
    cyrusBrushSettings LRB.paintDocument 40 1 0 false 1
    LRAssert (cyrusBrushDab LRB.paintDocument [0,0,200] [0,0,-1] true) "Paint curved sphere"
    r.refreshAll()
    local rows=r.groupSnapshotRows[1],flat=for row in rows where row[1].row4.x<150 collect row,curved=for row in rows where row[1].row4.x>150 collect row
    LRAssert (flat.count>0 and curved.count>0) "One layer paints both targets"
    local original=cyrusEditFingerprint rows "regions",areaCount=a.paintAreas.count
    LRAssert (cyrusBrushDab LRA.paintDocument [0,0,200] [0,0,-1] true) "Second gesture accepted"
    r.refreshAll()
    LRAssert (a.paintAreas.count==areaCount) "Second gesture edits same area"
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==original) "Repeated hard paint retains output"
    local duplicate=r.addPaintArea a target:LRPlane
    cyrusBrushSettings duplicate.paintDocument 55 1 0 false 1
    cyrusBrushDab duplicate.paintDocument [0,0,200] [0,0,-1] true
    r.refreshAll()
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==original) "Overlapping areas union without duplicates"
    r.removePaintArea a duplicate;r.refreshAll()
    local history=(cyrusBrushStats LRB.paintDocument)[2]
    r.setLayerSurfaces a #(LRPlane);r.refreshAll()
    LRAssert ((for row in r.groupSnapshotRows[1] where row[1].row4.x>150 collect row).count==0) "Removed target is inactive"
    LRAssert ((cyrusBrushStats LRB.paintDocument)[2]==history and a.paintAreas.count==2) "Inactive target keeps authored paint"
    r.setLayerSurfaces a #(LRPlane,LRSphere);r.refreshAll()
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==original) "Restoring target restores paint"
    local copied=r.copyLogicalLayer a
    LRAssert (copied.paintAreas.count==2 and copied.paintAreas[1].paintDocument!=a.paintAreas[1].paintDocument) "Layer copy owns independent paint"
    LRAssert (copied.paintAreas[1].areaTarget==LRPlane and copied.paintAreas[2].areaTarget==LRSphere) "Layer copy preserves targets"
    r.removeLogicalLayer copied
    r.newLayer();local trees=r.selectedLayer();trees.sources=#(LRSource);trees.amount=75
    r.setLayerSurfaces trees #(LRPlane);r.refreshAll()
    LRAssert ((a.validSurfaces()).count==2 and (trees.validSurfaces()).count==1) "Layer receivers are independent"
    r.removeLogicalLayer trees;r.selectLayer 1;r.refreshAll()
    local before=cyrusEditFingerprint r.groupSnapshotRows[1] "regions"
    cyrusBrushSettings LRA.paintDocument 30 1 0 true 1
    cyrusBrushDab LRA.paintDocument [0,0,200] [0,0,-1] true
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==before) "Manual paint keeps last publication"
    r.refreshAll();local after=cyrusEditFingerprint r.groupSnapshotRows[1] "regions"
    LRAssert (after!=before) "Update publishes erase"
    max undo;r.refreshAll()
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==before) "Brush Undo restores coverage"
    max redo;r.refreshAll()
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==after) "Brush Redo restores coverage"
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"layer-regions-before-save.txt") after
    saveMaxFile (MCPFixtureDir+"layer-regions.max") quiet:true
    true
)
fn LRViews = (
    local r=LRRoot
    select LRNode;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    for page in r.mainUI.editors do (page.open=true;r.mainUI.bindSection page)
    LRAssert (r.mainUI.editors[1]==r.managerUI and r.mainUI.editors[2]==r.surfacesUI) "Layers precede surfaces"
    LRAssert (r.coverageUI.setsUI_setList.items.count==2) "Paint Areas listed in Painting"
    LRAssert (not isProperty r.coverageUI #brushUI_strokeList) "Per-stroke editing removed"
    local epoch=r.procEpoch,key=r.procInputKey()
    r.coverageUI.setsUI_selectSet 1
    LRAssert (r.coverageUI.brushUI_obj==LRA and r.coverageUI.brushUI_beginButton.enabled) "Plane area selected for brush"
    r.coverageUI.setsUI_selectSet 2
    LRAssert (r.coverageUI.brushUI_obj==LRB and r.coverageUI.brushUI_beginButton.enabled) "Sphere area selected for brush"
    LRAssert (r.procEpoch==epoch and r.procInputKey()==key) "Area selection does not rebuild placements"
    CyrusOpenLayerEditor r LRLayer
    CyrusLayerEditor.showTopic 3 rebind:true
    LRAssert ((CyrusLayerEditor.activeEditors()).count>0) "Popup painting view mounts"
    CyrusCloseLayerEditor()
    true
)
fn LRReopen = (
    loadMaxFile (MCPFixtureDir+"layer-regions.max") quiet:true
    LRNode=getNodeByName "LR_Controller";LRRoot=LRNode.baseObject;LRLayer=LRRoot.layerObjects[1]
    LRA=LRLayer.paintAreas[1];LRB=LRLayer.paintAreas[2]
    LRRoot.refreshAll()
    LRAssert (LRLayer.paintAreas.count==2 and isValidNode LRA.areaTarget and isValidNode LRB.areaTarget) "Saved areas retain targets"
    local before=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"layer-regions-before-save.txt")
    LRAssert ((cyrusEditFingerprint LRRoot.groupSnapshotRows[1] "regions")==before) "Save/reopen preserves placement result"
    true
)

global LRAdditional
fn LRAdditional = (
    local r=LRRoot,a=LRLayer,targets=a.validSurfaces()
    local before=cyrusEditFingerprint r.groupSnapshotRows[1] "regions"
    local rejected=false
    try(r.setPaintAreaTarget a LRA targets[2])catch(rejected=true)
    LRAssert rejected "Painted area cannot silently change target"
    r.setLayerSurfaces a #();r.refreshAll()
    LRAssert (r.groupSnapshotRows[1].count==0 and a.paintAreas.count==2) "No receivers keeps inactive areas with no placements"
    r.setLayerSurfaces a targets;r.refreshAll()
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==before) "Restoring all receivers restores coverage"
    undo "Remove receiver witness" on r.setLayerSurfaces a #(targets[1])
    max undo;r.refreshAll()
    LRAssert ((a.validSurfaces()).count==2 and (cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==before) "Receiver removal Undo restores target and result"
    a.paintEnabled=false;r.refreshAll()
    LRAssert (r.groupSnapshotRows[1].count==a.amount) "Whole surfaces retains optional areas"
    a.paintEnabled=true;r.refreshAll()
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")==before) "Re-enabling areas restores coverage"
    select LRNode;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    r.coverageUI.open=true;r.mainUI.bindSection r.coverageUI
    r.coverageUI.setsUI_selectSet 2
    r.coverageUI.brushUI_beginButton.pressed()
    LRAssert ((cyrusBrushStats LRB.paintDocument)[5]==1) "Start Brush callback uses selected sphere among multiple receivers"
    CyrusStopBrush()
    -- Live invalidation must follow the area to its owning population.
    r.updateMode=2;r.refreshAll()
    cyrusBrushFill LRA.paintDocument 1.0;LRA.publishPaint()
    r.evaluateGroups()
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "regions")!=before) "Live area edit reaches its owning layer"
    r.updateMode=1
    true
)
