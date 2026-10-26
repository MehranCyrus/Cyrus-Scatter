(
    fn require ok message = (if not ok do throw message)
    fn write name value = ((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+name) value)
    local installed=(dotNetClass "System.IO.File").ReadAllText (CVLTestDir+"installed.txt")
    local doc=CVPDocument(),output=cvpNode doc 1 true,collider=getNodeByName "CVP_Test_Sphere"
    require ((getPolygonCount output)[1]==44086) "Installed preview missing."
    require (findString (cvpInfo doc 1) "Prepared"!=undefined) "Installed catalog not prepared."
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),loaded=createFile (CVLTestDir+"loaded.tsv")
    for i=0 to process.Modules.Count-1 do (local item=process.Modules.Item[i];if matchPattern item.ModuleName pattern:"CyrusVegetationStem*" do format "%\t%\t%\n" item.ModuleName item.FileName (CVPFileSHA item.FileName) to:loaded)
    close loaded
    local meter=units.decodeValue "1m"
    collider.pos=[.42*meter,.096*meter,.52*meter];redrawViews();getPolygonCount output
    write "audit.json" (cvsAudit output)
    write "moved.json" (cvsStats output)
    saveMaxFile (CVLTestDir+"Installed_Preparation_Reopened.max") quiet:true
    loadMaxFile (CVLTestDir+"Installed_Preparation_Reopened.max") quiet:true useFileUnits:true
    doc=CVPDocument();output=cvpNode doc 1 true
    require ((getPolygonCount output)[1]==44086) "Installed save reopen failed."
    cvlStage "done"
)
