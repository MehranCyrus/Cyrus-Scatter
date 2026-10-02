-- Confirm the UI is qualified with retained Mesh, not an older native fixture.
(
    RIAssert (matchPattern RIDir pattern:"*mesh-integration-2026-10-02/ui-layer-status-*/") "Wrong fixture directory"
    local checks=#(),ui=UILayerNode.mainUI
    UILayerNode.viewportMode=3;UILayerNode.refreshDisplay()
    CyrusRetainedMeshDrawing true
    CyrusPointSync();completeRedraw();windows.processPostedMessages();completeRedraw()
    local owner=CyrusPointOwner UILayerNode
    RIAssert (isValidNode owner) "Retained display owner missing"
    local mesh=for x in cyrusRetainedMeshStats owner collect (x as integer)
    RIAssert (mesh[1]>0 and mesh[2]==5500) "Wrong retained mesh population"
    append checks "0.64 retained Mesh displays all 5,500 fixture instances"
    local nativeBefore=RIStats UILayerNode,buildsBefore=for l in UILayerNode.layerObjects collect (l.previewStats())[1]
    local rootHandles=for r in ui.roots collect r.hwnd
    for i=1 to 10 do (
        local p=ui.layerPanels[i]
        p.open=true;p.children[3].open=true;p.children[3].open=false;p.open=false
    )
    for frame=1 to 30 do (
        viewport.setTM ((rotateZMatrix (5.0*sin(frame*7.0)))*RIBaseTM)
        completeRedraw()
    )
    ui.roots[4].refreshStats()
    local nativeAfter=RIStats UILayerNode,buildsAfter=for l in UILayerNode.layerObjects collect (l.previewStats())[1]
    RIAssert ((buildsBefore as string)==(buildsAfter as string)) "UI navigation rebuilt scatter"
    append checks "Layer/category navigation and camera motion add zero preview rebuilds"
    RIAssert (nativeBefore[3]==nativeAfter[3] and nativeBefore[6]==nativeAfter[6]) "Retained Mesh changed generation or uploaded buffers"
    append checks "Camera motion and UI navigation preserve GPU generation and uploads"
    RIAssert (nativeAfter[8]>nativeBefore[8] and nativeAfter[9]==nativeBefore[9] and nativeAfter[12]==1) "Retained Mesh draw failed"
    append checks "Native retained draws advance with no new failure"
    RIAssert ((rootHandles as string)==((for r in ui.roots collect r.hwnd) as string)) "Layer navigation remounted root controls"
    append checks "Layer navigation retains root control handles"
    for i=1 to 10 do RIAssert ((ui.layerPanels[i].children[3].controls[1]).visible) "Collision control was hidden"
    append checks "Collision controls retain their intended visibility"
    RIAssert (not ui.fitWidth()) "Unchanged command-panel width requested a remount"
    append checks "Unchanged width does not request reconstruction"
    viewport.setTM RIBaseTM
    ui.roots[4].open=true;ui.layoutPanels()
    CSPWriteText (RIDir+"ui-mesh-064.json") (CSPObject #(#("passed",true),#("checks",checks),#("mesh",mesh),#("builds_before",buildsBefore),#("builds_after",buildsAfter),#("native_before",nativeBefore),#("native_after",nativeAfter),#("ui_revision",UILayerNode.uiVersion()),#("error",CyrusPointLastError)))
)
