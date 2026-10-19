(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned density profile required"
    CyrusClearMeshMaskPreview undefined
    CyrusPerfHeadless=false;CyrusPointSuspended=true
    with undo off (
        DLayer.invertDensity=false;DLayer.amount=4000;DLayer.densityTileXWU=400
        CyrusSetDensityImage DLayer (MCPFixtureDir+"scripts/Patterns/soft-patches.png") pattern:"soft-patches" revision:"fixture"
    )
    viewport.setLayout #layout_1
    viewport.setType #view_top
    select DTerrain;max zoomext sel
    select DNode;max modify mode
    DRoot.bindNativeUI()
    CyrusPointSuspended=false;DRoot.refreshAll()
    CyrusMaskView=3;CyrusMaskOpacity=85
    CyrusShowMeshMaskPreview DLayer
    local f=createFile (MCPFixtureDir+"ui-ready.txt")
    format "owner=% hwnd=% epoch=%\n" DNode.name (windows.getMAXHWND()) DRoot.procEpoch to:f
    close f
)
