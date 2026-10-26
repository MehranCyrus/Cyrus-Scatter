(
    loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-preparation-host-20261024-04/Vegetation_Preparation_Max2027.max" quiet:true useFileUnits:true
    global CVPPointerOutput=getNodeByName "CVP_Prepared_Plant",CVPPointerSphere=getNodeByName "CVP_Test_Sphere"
    local meter=units.decodeValue "1m"
    CVPPointerSphere.pos=[.5*meter,.096*meter,.78*meter]
    viewport.setLayout #layout_1;viewport.setType #view_front;viewport.setRenderLevel #smoothhighlights
    select #(CVPPointerOutput,CVPPointerSphere);max zoomext sel all
    select CVPPointerSphere;max move
    CVPOpen();CVPDialog.showGuides.checked=false
    redrawViews();getPolygonCount CVPPointerOutput
    saveMaxFile (CVLTestDir+"CVP_OWNED_POINTER_030.max") quiet:true
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"ready.json") (cvsStats CVPPointerOutput)
    local deadline=timeStamp()+240000
    while timeStamp()<deadline and not doesFileExist (CVLTestDir+"finish.txt") do
    (
        windows.processPostedMessages();sleep .03
        (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"progress.json") (cvsStats CVPPointerOutput)
    )
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"final.json") (cvsStats CVPPointerOutput)
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"audit.json") (cvsAudit CVPPointerOutput)
)
