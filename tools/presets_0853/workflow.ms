(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-presets0853-*/" do throw "Owned host required."
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"workflow-phase.txt"),log=createFile (MCPFixtureDir+"workflow-"+(timeStamp() as string)+"-"+phase+".txt")
 fn check ok message log=(format "%: %\n" (if ok then "PASS" else "FAIL") message to:log;flush log;if not ok do throw message)
 fn rowsHash root=(cyrusRecipePublicationFingerprint root.groupSnapshotRows)
 fn sceneNodes=(for n in objects where (classof n.baseObject as string)!="Cyrus_Point_Display" collect n)
 try (
  if phase=="setup" then (
   if theHold.Holding() do theHold.Accept "Owned fixture setup completion"
   for dialog in #(CyrusRecipeBrowser,CyrusReadyPresetEditor,CyrusRecipeSaveEditor,CyrusPresetSaveEditor) where dialog!=undefined do destroyDialog dialog
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.0
    global WorkflowNode=AminScatterObject name:"Owned existing planting",WorkflowRoot=WorkflowNode.baseObject
    global WorkflowGround=plane name:"Owned mountain" width:2400 length:2000 widthsegs:16 lengthsegs:16
    local terrainNoise=noiseModifier strength:[0,0,65] scale:300;addModifier WorkflowGround terrainNoise
    global WorkflowSource=pyramid name:"Repeated model name" width:20 depth:20 height:75 pos:[3500,0,0]
    WorkflowSource.material=standardMaterial name:"Protected artist material" diffuse:(color 38 122 61)
    local duplicate=box name:"Repeated model name" width:450 length:450 height:900 pos:[5000,0,0];duplicate.name=WorkflowSource.name
    WorkflowRoot.updateMode=1;WorkflowRoot.newLayer();global WorkflowLayer=WorkflowRoot.selectedLayer()
    WorkflowRoot.setLayerSurfaces WorkflowLayer #(WorkflowGround);WorkflowLayer.sources=#(WorkflowSource);WorkflowLayer.ensureSourceRows()
    WorkflowLayer.amount=120;WorkflowLayer.randomSeed=1337;WorkflowLayer.procSelfOverride=true;WorkflowLayer.procSelfEnabled=false;WorkflowLayer.procLayerSelfEnabled=false
    local area=WorkflowRoot.addPaintArea WorkflowLayer target:WorkflowGround
    cyrusBrushFill area.paintDocument 1.0;cyrusBrushSetFalloff area.paintDocument #(25.0,0.0,true,true,0.4,1.0,#(0.0,1.0),#(0.0,1.0));area.publishPaint()
    WorkflowRoot.refreshAll();select WorkflowNode;max modify mode;modPanel.setCurrentObject WorkflowNode
   )
   global WorkflowBeforeLayers=WorkflowRoot.layerObjects as array,WorkflowBeforeSettings=CyrusStyleSnapshot WorkflowLayer,WorkflowBeforeRows=rowsHash WorkflowRoot,WorkflowBeforePaint=(cyrusBrushRecipeExport WorkflowLayer.paintAreas[1].paintDocument)[1],WorkflowBeforeNodes=sceneNodes()
   check (WorkflowRoot.groupSnapshotRows[1].count>0) "Existing painted mountain planting publishes" log
   check (not theHold.Holding()) "Fixture is settled" log
   CyrusOpenRecipeLibrary WorkflowRoot
   local browser=CyrusRecipeBrowser;browser.directory="F:/Cursor/_Cyrus_Apps/CyrusScatter/build/presets-0853-20261016-01/library";browser.panel.SetNavigation 3 "" false;browser.refresh()
  ) else if phase=="galleryLoad" then (
   local browser=CyrusRecipeBrowser
   check (not browser.scanTimer.active and browser.entries.count==8) "Actual gallery indexes eight entries" log
   local index=0;for i=1 to browser.entries.count where browser.entries[i][2][1]=="Layered meadow" do index=i
   check (index>0) "Ready meadow tile is present" log
   browser.panel.Gallery.SelectedIndex=index-1;browser.action "load"
  ) else if phase=="preserved" then (
   check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Actual gallery Load + Update completes" log
   check (findString CyrusReadyPresetEditor.status.text "Current terrain: Owned mountain"!=undefined) "Preset automatically uses the existing mountain" log
   check (WorkflowRoot.layerObjects.count==4 and WorkflowRoot.layerObjects[1]==WorkflowLayer) "Adds three layers and preserves the preceding layer" log
   local after=CyrusStyleSnapshot WorkflowLayer,fields=CyrusRecipeFields()
   for i=1 to fields.count where fields[i][1]!="previewBudget" do check (CyrusPresetSameValues WorkflowBeforeSettings[i] after[i]) ("Existing setting preserved: "+fields[i][1]) log
   check (WorkflowRoot.previewBudget==20000) "Controller viewport budget is retained; per-layer share redistributes" log
   check ((cyrusRecipePublicationFingerprint #(WorkflowRoot.groupSnapshotRows[1]))==WorkflowBeforeRows) "Existing full placement rows remain identical" log
   check ((cyrusBrushRecipeExport WorkflowLayer.paintAreas[1].paintDocument)[1]==WorkflowBeforePaint) "Existing Paint remains byte-identical" log
   global WorkflowLoadedRows=rowsHash WorkflowRoot,WorkflowLoadedLayers=WorkflowRoot.layerObjects as array,WorkflowLoadedNodes=sceneNodes(),WorkflowLoadedBuilds=WorkflowRoot.groupBuilds
   destroyDialog CyrusReadyPresetEditor;destroyDialog CyrusRecipeBrowser
  ) else if phase=="undo" then (max undo)
  else if phase=="checkUndo" then (
   check (CyrusPresetSameValues WorkflowBeforeLayers (WorkflowRoot.layerObjects as array)) "One Undo restores the preceding artist layer" log
   check ((rowsHash WorkflowRoot)==WorkflowBeforeRows) "Undo restores the previous complete mountain publication" log
   check (CyrusPresetSameValues WorkflowBeforeNodes (sceneNodes())) "Undo removes only the imported assets" log
  ) else if phase=="redo" then (max redo)
  else if phase=="checkRedo" then (
   check (CyrusPresetSameValues WorkflowLoadedLayers (WorkflowRoot.layerObjects as array)) "Redo restores exact ownership" log
   check ((rowsHash WorkflowRoot)==WorkflowLoadedRows and WorkflowRoot.groupBuilds==WorkflowLoadedBuilds) "Redo restores full rows without recalculating" log
   check (CyrusPresetSameValues WorkflowLoadedNodes (sceneNodes())) "Redo restores the same sources without library files" log
  ) else if phase=="save" then (
   (dotNetClass "System.IO.Directory").CreateDirectory (MCPFixtureDir+"saved-library")
   global WorkflowSaveNodes=sceneNodes(),WorkflowSaveBuilds=WorkflowRoot.groupBuilds,WorkflowSaveUndo=theHold.GetUndoNames()
   CyrusOpenRecipeSave WorkflowRoot (MCPFixtureDir+"saved-library")
   local editor=CyrusRecipeSaveEditor;editor.recipeName.text="My ready mountain preset";editor.recipeCategory.text="Owned test"
   check editor.readyPreset.checked "Ready assets are enabled by default" log
   global WorkflowSavedPath=editor.saveEntry false
  ) else if phase=="checkSave" then (
   check (CyrusPresetSaveEditor!=undefined and CyrusPresetSaveEditor.finished) "Actual ready-save worker finishes" log
   format "STATUS: %\n" CyrusPresetSaveEditor.status.text to:log;flush log
   check (matchPattern CyrusPresetSaveEditor.status.text pattern:"Ready preset saved*") "Ready Save completes without model-name binding" log
   check (CyrusPresetSameValues WorkflowSaveNodes (sceneNodes()) and WorkflowRoot.groupBuilds==WorkflowSaveBuilds) "Save does not change objects or calculate placements" log
   check (CyrusPresetSameValues WorkflowSaveUndo (theHold.GetUndoNames())) "Save preserves prior Undo history" log
   local digest=(cyrusRecipeInfo WorkflowSavedPath)[11];global WorkflowSavedPackage=CyrusPresetPackageDirectory WorkflowSavedPath digest
   local package=cyrusAssetPackageRead WorkflowSavedPackage,graph=CyrusRecipeGet package "graph"
   check ((CyrusRecipeGet graph "externalRoles").count==0) "Saved preset includes all terrain/model/Paint dependencies" log
   check ((CyrusRecipeGet graph "nodes").count==5) "Exact captured references exclude the same-name unrelated box" log
   destroyDialog CyrusPresetSaveEditor;destroyDialog CyrusRecipeSaveEditor
  ) else if phase=="loadSaved" then (
   with undo off (global WorkflowCopyNode=AminScatterObject name:"Owned ready copy",WorkflowCopyRoot=WorkflowCopyNode.baseObject;WorkflowCopyRoot.updateMode=1)
   CyrusOpenReadyPreset WorkflowCopyRoot WorkflowSavedPackage
  ) else if phase=="checkSaved" then (
   check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "User-saved ready preset loads in one action" log
   check (WorkflowCopyRoot.layerObjects.count==4) "All four saved layers load" log
   check ((cyrusBrushRecipeExport WorkflowCopyRoot.layerObjects[1].paintAreas[1].paintDocument)[1]==WorkflowBeforePaint) "Saved Paint survives its included evaluated Noise terrain" log
   check ((rowsHash WorkflowRoot)==WorkflowLoadedRows) "Loading another setup preserves the original publication" log
   destroyDialog CyrusReadyPresetEditor
  ) else if phase=="cancel" then (
   local before=sceneNodes(),layers=WorkflowRoot.layerObjects as array,rows=rowsHash WorkflowRoot
   CyrusOpenReadyPreset WorkflowRoot WorkflowSavedPackage;destroyDialog CyrusReadyPresetEditor
   check (CyrusPresetSameValues before (sceneNodes()) and CyrusPresetSameValues layers (WorkflowRoot.layerObjects as array) and rows==(rowsHash WorkflowRoot)) "Cancelling before the apply tick preserves the whole scene" log
  ) else if phase=="fault" then (
   global WorkflowOriginalStage=CyrusAssetStage
   fn CyrusAssetStage package bindings=(local result=WorkflowOriginalStage package bindings;throw "Owned failure after source/context staging")
   global WorkflowFaultNodes=sceneNodes(),WorkflowFaultLayers=WorkflowCopyRoot.layerObjects as array,WorkflowFaultRows=rowsHash WorkflowCopyRoot
   CyrusOpenReadyPreset WorkflowCopyRoot WorkflowSavedPackage
  ) else if phase=="checkFault" then (
   CyrusAssetStage=WorkflowOriginalStage
   check (CyrusReadyPresetEditor.finished and findString CyrusReadyPresetEditor.status.text "Owned failure after"!=undefined) "Late staged failure is reported" log
   check (CyrusPresetSameValues WorkflowFaultNodes (sceneNodes()) and CyrusPresetSameValues WorkflowFaultLayers (WorkflowCopyRoot.layerObjects as array)) "Failure removes staged assets and preserves authored layers" log
   check ((rowsHash WorkflowCopyRoot)==WorkflowFaultRows and not theHold.Holding()) "Failure retains the previous complete publication and releases its hold" log
   destroyDialog CyrusReadyPresetEditor
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
