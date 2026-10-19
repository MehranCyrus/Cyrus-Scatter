(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/library-surface0861-*/" do throw "Owned profile required"
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
    CyrusOpenReadyPreset SRoot SPackage surface:STerrain
   )
   "verifyLoad":(
    check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") CyrusReadyPresetEditor.status.text log
    local owners=CyrusReadyPresetEditor.result[2]
    check (CyrusPresetSameValues SPaint (paintData owners)) "Saved/reloaded owners retain every Paint payload" log
    for owner in owners do check (CyrusPresetSameValues (owner.validSurfaces()) #(STerrain)) "Saved/reloaded preset uses selected terrain" log
    destroyDialog CyrusReadyPresetEditor
   )
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
