(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"save-phase.txt"),log=createFile (MCPFixtureDir+"save-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn paintData owners=(for owner in owners collect #(if owner.paintDocument==undefined then undefined else (cyrusBrushRecipeExport owner.paintDocument)[1],for area in owner.paintAreas collect (if area.paintDocument==undefined then undefined else (cyrusBrushRecipeExport area.paintDocument)[1])))
 try(
  case phase of (
   "save":(
    for d in #(CyrusRecipeBrowser,CyrusReadyPresetEditor,CyrusRecipeSaveEditor,CyrusPresetSaveEditor) where d!=undefined do destroyDialog d
    loadMaxFile (io.ReadAllText (MCPFixtureDir+"save-scene.txt")) quiet:true useFileUnits:true
    global SNode=undefined,SRoot=undefined,STerrain=undefined,SPaint=#(),SDirectory=MCPFixtureDir+"saved-library",SPath="",SPackage=""
    for n in objects where classof n.baseObject==AminScatterObject do SNode=n
    SRoot=SNode.baseObject;SRoot.refreshAll();STerrain=(SRoot.layerObjects[1].validSurfaces())[1];SPaint=paintData (SRoot.layerObjects as array)

    global SMapping=undefined,SImage=undefined
    with undo off (
        SNode.transform=(rotateZMatrix 17)*(transMatrix [20,-30,0])
        CyrusSetDensityImage SRoot.layerObjects[1] (MCPFixtureDir+"scripts/Patterns/soft-patches.png") pattern:"soft-patches" revision:"QA fixture"
        local leaf=SRoot.layerObjects[1]
        leaf.densityCoordinateMode=2;leaf.densityTileXWU=350;leaf.densityTileYWU=220;leaf.densityTileLock=false
        leaf.densityHeading=23;leaf.densityOffsetXWU=17;leaf.densityOffsetYWU=-32
        leaf.densityResponseSamples=#(0.,0.05,0.35,0.85,1.)
        SMapping=leaf.densityMappingPayload();SImage=leaf.densityMap.filename
        SRoot.layerObjects[2].densityMap=Noise size:25
        SRoot.layerObjects[2].distributionMode=3;SRoot.layerObjects[2].densityCoordinateMode=1
        CyrusBakeDensityImage SRoot.layerObjects[2] directory:(MCPFixtureDir+"saved-bake")
    )
    SRoot.refreshAll()
    makeDir SDirectory all:true;select SNode;max modify mode;modPanel.setCurrentObject SNode
    CyrusOpenRecipeSave SRoot SDirectory
    CyrusRecipeSaveEditor.recipeName.text="Owned complete Paint preset"
    CyrusRecipeSaveEditor.captureThumbnail.pressed()
    check (CyrusRecipeSaveEditor.thumbnailFile!="") ("Actual Capture viewport succeeds: "+CyrusRecipeSaveEditor.status.text) log
    CyrusRecipeSaveEditor.saveRecipe.pressed()
    check (CyrusPresetSaveEditor!=undefined) ("Actual Save starts ready package worker: "+CyrusRecipeSaveEditor.status.text) log
   )
   "verifySave":(
    check (CyrusPresetSaveEditor.finished) "Ready Save finishes" log
    check (matchPattern CyrusPresetSaveEditor.status.text pattern:"Ready preset saved*") CyrusPresetSaveEditor.status.text log
    SPath=CyrusPresetSaveEditor.path;check (doesFileExist SPath) "Newly saved recipe exists" log
    local info=cyrusRecipeInfo SPath,document=cyrusRecipeRead SPath
    check ((CyrusRecipeGet document "hostYear")==((maxVersion())[1]/1000+1998)) "Recipe records actual authoring host year" log
    check info[12] "Saved recipe includes its captured thumbnail" log
    SPackage=CyrusPresetPackageDirectory SPath info[11]
    check (doesFileExist (pathConfig.appendPath SPackage "cyrus.package.json")) "Saved assets are linked to the exact recipe digest" log
    destroyDialog CyrusPresetSaveEditor;destroyDialog CyrusRecipeSaveEditor

    global SBeforeHash=cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows
    with undo off SNode.transform=(rotateZMatrix (-31))*(transMatrix [-90,55,10])
    CyrusOpenReadyPreset SRoot SPackage surface:STerrain
   )
   "verifyLoad":(
    check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") CyrusReadyPresetEditor.status.text log
    global SLoadedOwners=CyrusReadyPresetEditor.result[2],SLoadedHash=cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows;local owners=SLoadedOwners
    check (CyrusPresetSameValues SPaint (paintData owners)) "Saved/reloaded owners retain every Paint payload" log
    for owner in owners do check (CyrusPresetSameValues (owner.validSurfaces()) #(STerrain)) "Saved/reloaded preset uses selected terrain" log

    local actual=owners[1].densityMappingPayload()
    local same=true
    for i=1 to actual.count where i!=10 do if not (CyrusPresetSameValues SMapping[i] actual[i]) do same=false
    for row=1 to 4 where distance SMapping[10][row] actual[10][row]>0.0001 do same=false
    check same "Image frame, physical sizes, rotation, offsets and nonlinear response survive different-root Load" log
    check (owners[1].densityMap.filename!=SImage and doesFileExist owners[1].densityMap.filename) "Image bytes are restored from the portable package" log
    check (matchPattern owners[2].densityMapProvenance pattern:"baked 2D tile*" and classof owners[2].densityMap==Bitmaptexture) "Explicit procedural snapshot bytes and provenance survive complete Save/Load" log
    destroyDialog CyrusReadyPresetEditor
   )
   "historyWithoutPackage":(
    local unavailable=SPackage+"-unavailable",ioDirectory=dotNetClass "System.IO.Directory"
    if ioDirectory.Exists unavailable do throw "Owned unavailable destination already exists"
    ioDirectory.Move SPackage unavailable
    try (
     max undo
     check (SRoot.layerObjects.count==SPaint.count) "One Undo removes the added image/Paint recipe" log
     check ((cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows)==SBeforeHash) "Undo restores the exact previous publication" log
     max redo
     check ((cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows)==SLoadedHash) "Redo restores full output while source package is unavailable" log
     check (CyrusPresetSameValues SPaint (paintData SLoadedOwners)) "Redo retains exact Paint without package files" log
     ioDirectory.Move unavailable SPackage
    )catch(if ioDirectory.Exists unavailable do ioDirectory.Move unavailable SPackage;throw())
   )
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
