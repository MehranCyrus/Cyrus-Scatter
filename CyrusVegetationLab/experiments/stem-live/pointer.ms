loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-plugin-20261024-02/" "CyrusVegetationStemLab.dlx"
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-plugin-20261024-02/" "CyrusVegetationStemGeometry.dlo"
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusVegetationLab/experiments/stem-live/StemLab.ms"
(
    cvlStage "load embedded stem scene"
    loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-host-20261024-03/Lavender_Stem_Live_Max2027.max" quiet:true useFileUnits:true
    global CVSOutput=getNodeByName "CVS_Stem_Lavender",CVSSphere=getNodeByName "CVS_Collider_Sphere"
    local meter=units.decodeValue "1m"
    CVSSphere.pos=[.50*meter,.096*meter,.78*meter]
    viewport.setLayout #layout_1;viewport.setType #view_front;viewport.setRenderLevel #smoothhighlights
    select #(CVSOutput,CVSSphere);max zoomext sel all
    select CVSSphere;max move
    redrawViews();local warm=getPolygonCount CVSOutput
    saveMaxFile (CVLTestDir+"CVS_OWNED_STEM_DRAG_020.max") quiet:true
    CVSOpen()
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"ready.json") (cvsStats CVSOutput)
    cvlStage "ready for physical held sphere drag"
    local deadline=timeStamp()+360000,nextLog=0
    while timeStamp()<deadline and not doesFileExist (CVLTestDir+"finish.txt") do
    (
        windows.processPostedMessages()
        if timeStamp()>nextLog do ((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"progress.json") (cvsStats CVSOutput);nextLog=timeStamp()+200)
        sleep .01
    )
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"final.json") (cvsStats CVSOutput)
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"full-audit.json") (cvsAudit CVSOutput)
    saveMaxFile (CVLTestDir+"CVS_OWNED_STEM_DRAG_RESULT_020.max") quiet:true
    cvlStage "done"
)
