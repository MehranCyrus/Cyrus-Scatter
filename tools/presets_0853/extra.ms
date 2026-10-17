(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-presets0853-*/" do throw "Owned preset host required"
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"extra-phase.txt"),log=createFile (MCPFixtureDir+"extra-"+phase+".txt")
 fn check ok text log=(format "%: %\n" (if ok then "PASS" else "FAIL") text to:log;flush log;if not ok do throw text)
 fn work root=#(root.procEpoch,root.groupBuilds,(for leaf in root.layerObjects collect #(leaf.procPreparedBuilds,leaf.procDensityBakes,(leaf.receiverCacheStats())[1])),(cyrusRetainedStreamStats())[2],(cyrusRetainedStreamStats())[3],(cyrusRetainedStreamStats())[4])
 try (
  if phase=="capacity" then (
   with undo off (while WorkflowCopyRoot.layerObjects.count<10 do WorkflowCopyRoot.newLayer())
   local before=objects as array,layers=WorkflowCopyRoot.layerObjects as array,rows=cyrusRecipePublicationFingerprint WorkflowCopyRoot.groupSnapshotRows
   global ExtraCapacityBefore=#(before,layers,rows)
   CyrusOpenReadyPreset WorkflowCopyRoot WorkflowSavedPackage
  ) else if phase=="checkCapacity" then (
   check (CyrusReadyPresetEditor.finished and findString CyrusReadyPresetEditor.status.text "exceed 10"!=undefined) "Population capacity is clearly reported" log
   check (CyrusPresetSameValues ExtraCapacityBefore[1] (objects as array) and CyrusPresetSameValues ExtraCapacityBefore[2] (WorkflowCopyRoot.layerObjects as array) and ExtraCapacityBefore[3]==(cyrusRecipePublicationFingerprint WorkflowCopyRoot.groupSnapshotRows)) "Capacity failure does not stage assets or alter publication" log
   destroyDialog CyrusReadyPresetEditor
  ) else if phase=="revise" then (
   global ExtraRevisionBefore=#(work WorkflowRoot,objects as array),ExtraOldPackage=WorkflowSavedPackage
   local previous=(cyrusRecipeInfo WorkflowSavedPath)[11]
   local metadata=CyrusRecipeObject #(#("category","Revised ready presets"),#("tags",#("mountain","paint")),#("description","Owned metadata revision without scene capture"))
   local digest=cyrusRecipeEntryWrite WorkflowSavedPath (CyrusRecipeObject #(#("name","Renamed ready mountain"))) metadata "" undefined previous true
   CyrusPresetReviseReady WorkflowSavedPath previous digest
   WorkflowSavedPackage=CyrusPresetPackageDirectory WorkflowSavedPath digest
  ) else if phase=="checkRevision" then (
   check (CyrusPresetReviseEditor.finished and findString CyrusPresetReviseEditor.status.text "ready assets saved"!=undefined) "Metadata revision preserves ready loading through actual worker" log
   local package=cyrusAssetPackageRead WorkflowSavedPackage
   check ((CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet package "manifest") "recipe") "sha256")==((cyrusRecipeInfo WorkflowSavedPath)[11])) "Revised package matches the current gallery manifest" log
   check (CyrusPresetSameValues ExtraRevisionBefore[1] (work WorkflowRoot) and CyrusPresetSameValues ExtraRevisionBefore[2] (objects as array)) "Metadata revision performs no scene or placement work" log
   check (doesFileExist (pathConfig.appendPath ExtraOldPackage "cyrus.package.json")) "Previous ready revision remains available" log
   destroyDialog CyrusPresetReviseEditor
  ) else if phase=="liveLoad" then (
   with undo off (global ExtraLiveNode=AminScatterObject name:"Owned Live preset",ExtraLiveRoot=ExtraLiveNode.baseObject;ExtraLiveRoot.updateMode=2)
   CyrusOpenReadyPreset ExtraLiveRoot WorkflowSavedPackage
  ) else if phase=="checkLive" then (
   check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Revised user preset loads in Live mode" log
   check (ExtraLiveRoot.updateMode==2 and ExtraLiveRoot.layerObjects.count==4) "Live mode and complete saved layers retained" log
   destroyDialog CyrusReadyPresetEditor
   select ExtraLiveNode;max modify mode;modPanel.setCurrentObject ExtraLiveNode
   CyrusOpenRecipeLibrary ExtraLiveRoot
   local browser=CyrusRecipeBrowser;browser.directory="F:/Cursor/_Cyrus_Apps/CyrusScatter/build/presets-0853-20261016-01/library";browser.panel.SetNavigation 3 "" false;browser.refresh()
  ) else if phase=="idleStart" then (
   check (not CyrusRecipeBrowser.scanTimer.active) "Gallery scan has settled" log
   CyrusPointSync();completeRedraw()
   global ExtraIdleBefore=work ExtraLiveRoot,ExtraIdleRows=cyrusRecipePublicationFingerprint ExtraLiveRoot.groupSnapshotRows,ExtraIdleNodes=objects as array,ExtraIdleStart=timeStamp()
   format "COUNTERS: %\n" ExtraIdleBefore to:log
  ) else if phase=="browse" then (
   local browser=CyrusRecipeBrowser
   for i=1 to 30 do (
    browser.panel.Gallery.SelectedIndex=mod i 8
    browser.panel.SetNavigation 3 "" false
    clearSelection();select ExtraLiveNode
    for slot in ExtraLiveRoot.mainUI.slots do (slot.open=false;slot.open=true)
    sliderTime=mod i 5;completeRedraw()
   )
   check (CyrusPresetSameValues ExtraIdleBefore (work ExtraLiveRoot)) "Browsing, selection, rollout toggles and unrelated time do no solve/preparation/uploads" log
  ) else if phase=="idleCheck" then (
   local elapsed=(timeStamp()-ExtraIdleStart)/1000.0
   check (elapsed>=30) "At least thirty seconds of event-loop idle elapsed" log
   check (CyrusPresetSameValues ExtraIdleBefore (work ExtraLiveRoot) and ExtraIdleRows==(cyrusRecipePublicationFingerprint ExtraLiveRoot.groupSnapshotRows) and CyrusPresetSameValues ExtraIdleNodes (objects as array)) "Live idle preserves placements, scene and zero work counters" log
   format "SECONDS: %\nCOUNTERS: %\n" elapsed (work ExtraLiveRoot) to:log
  ) else if phase=="closeAfterAddStart" then (
   with undo off (global ExtraCloseNode=AminScatterObject name:"Owned close during Update",ExtraCloseRoot=ExtraCloseNode.baseObject;ExtraCloseRoot.updateMode=1)
   global ExtraCloseBefore=for n in objects where (classof n.baseObject as string)!="Cyrus_Point_Display" collect n
   CyrusOpenReadyPreset ExtraCloseRoot WorkflowSavedPackage
   CyrusReadyPresetEditor.progress.active=false
  ) else if phase=="closeAfterAddFinish" then (
   CyrusReadyPresetEditor.loadPrepared()
   check (CyrusPointSuspended and ExtraCloseRoot.layerObjects.count==4) "Imported layers wait for the single explicit Update" log
   destroyDialog CyrusReadyPresetEditor
   check (not CyrusPointSuspended and ExtraCloseRoot.groupSnapshotRows.count==0) "Closing after Add releases display scheduling and retains the preceding Manual publication" log
   max undo
   check (ExtraCloseRoot.layerObjects.count==0 and CyrusPresetSameValues ExtraCloseBefore (for n in objects where (classof n.baseObject as string)!="Cyrus_Point_Display" collect n)) "One Undo removes the partially completed load's owned layers/assets" log
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
