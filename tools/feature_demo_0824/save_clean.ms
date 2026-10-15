(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-feature-demo0824-*/" do throw "Owned feature-demo host required."
    local path=MCPFixtureDir+"CyrusScatter 0.82.4 Feature Demo.max"
    loadMaxFile path quiet:true useFileUnits:true
    (LayerManager.getLayerFromName "DEMO | Cameras").isHidden=false
    for cam in cameras do unhide cam
    hideByCategory.cameras=true
    local node=getNodeByName "CYRUS 0.82.4 | SELECT ME - five feature layers",root=node.baseObject,cam=getNodeByName "CAM 01 | Overview"
    root.updateMode=1;root.refreshAll();CyrusPointSync()
    select node;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.selectLayer 1;root.populationUI.open=true;root.mainUI.bindSection root.populationUI
    viewport.setCamera cam
    if viewport.getCamera()!=cam do throw "Overview camera was not selected."
    saveMaxFile path quiet:true
    loadMaxFile path quiet:true useFileUnits:true
    if viewport.getCamera()!=(getNodeByName "CAM 01 | Overview") do throw "Saved scene did not reopen in Overview camera."
    local log=createFile (MCPFixtureDir+"demo-saved-camera.txt")
    format "PASS: Saved scene reopens in %\nCOMPLETE\n" (viewport.getCamera()).name to:log;close log
)
