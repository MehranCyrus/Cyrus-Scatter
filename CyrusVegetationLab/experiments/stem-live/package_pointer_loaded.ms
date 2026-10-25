(
    local doc=CVPDocument(),output=cvpNode doc 1 true,collider=getNodeByName "CVP_Test_Sphere",meter=units.decodeValue "1m"
    collider.pos=[.5*meter,.096*meter,.78*meter]
    select #(output,collider);max zoomext sel all
    select collider;max move
    CVPDialog.showGuides.checked=false
    redrawViews();getPolygonCount output
    saveMaxFile (CVLTestDir+"CVP_FINAL_OWNED_POINTER_030.max") quiet:true
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"ready.json") (cvsStats output)
    local end=timeStamp()+180000
    while timeStamp()<end and not doesFileExist (CVLTestDir+"finish.txt") do
    (
        windows.processPostedMessages();sleep .03
        (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"progress.json") (cvsStats output)
    )
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"final.json") (cvsStats output)
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"audit.json") (cvsAudit output)
)
