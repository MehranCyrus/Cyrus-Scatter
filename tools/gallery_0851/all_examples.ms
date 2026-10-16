(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local file=dotNetClass "System.IO.File",index=(file.ReadAllText (MCPFixtureDir+"example-index.txt")) as integer,phase=file.ReadAllText (MCPFixtureDir+"example-phase.txt")
 local log=createFile (MCPFixtureDir+"example-"+(index as string)+"-"+phase+"-"+(timeStamp() as string)+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn paints root=(for owner in root.layerObjects collect #(if owner.paintDocument==undefined then undefined else (cyrusBrushRecipeExport owner.paintDocument)[1],for area in owner.paintAreas collect (if area.paintDocument==undefined then undefined else (cyrusBrushRecipeExport area.paintDocument)[1])))
 try (
  local example=GalleryAllExamples[index]
  global GalleryRetiredExampleOwners
  if phase=="prepare" then (
   -- End only a surrounding fixture hold before replacing this owned scene.
   if theHold.Holding() do theHold.Cancel()
   if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
   GalleryRetiredExampleOwners=#()
   for n in objects where classof n.baseObject==AminScatterObject do (
    appendIfUnique GalleryRetiredExampleOwners n.baseObject
    for owner in n.baseObject.layerObjects do (
     appendIfUnique GalleryRetiredExampleOwners owner
     for area in owner.paintAreas do appendIfUnique GalleryRetiredExampleOwners area
    )
   )
   CyrusPerfHeadless=true
   check (loadMaxFile example[2] quiet:true useFileUnits:true) "Inventoried scene opens without changing its file" log
   -- Return to Max so its file-open operation finishes before any authored import.
  ) else if phase=="apply" then (
   format "EXAMPLE: %\n" example[1] to:log;flush log
   check (not theHold.Holding()) "File-open operation settled before authored import" log
   for owner in GalleryRetiredExampleOwners do check (owner.groupSnapshotRows.count==0 and owner.procPreparedRows.count==0 and owner.procPublishedOwners.count==0 and owner.procGridCache.count==0) "Departed scene owners release calculation and publication caches" log
   GalleryRetiredExampleOwners=#()
   local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
   check (node!=undefined) "Editable controller exists" log
   local root=node.baseObject;root.refreshAll()
   format "HOLD after Update: %\n" (theHold.Holding()) to:log;flush log
   local paint=paints root,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows,epoch=root.procEpoch,before=objects as array
   local counts=for placements in root.groupSnapshotRows collect placements.count
   check (CyrusPresetSameValues counts example[4]) ("Inventoried accepted counts: "+counts as string) log
   CyrusOpenRecipeLoad root example[3] (cyrusRecipeInfo example[3])[11]
   format "HOLD after opening Review: %\n" (theHold.Holding()) to:log;flush log
   local editor=CyrusRecipeLoadEditor;editor.suggestButton.pressed();editor.newSetupCheck.checked=true;editor.importVariation.selection=2
   for pair in editor.bindings do check (pair[2]!=undefined) "Explicit matching role binding" log
   format "HOLD before import: %\n" (theHold.Holding()) to:log;flush log
   editor.importButton.pressed();check (matchPattern editor.status.text pattern:"Imported*") ("Actual Load: "+editor.status.text) log
   local added=for n in objects where classof n.baseObject==AminScatterObject and findItem before n==0 collect n
   check (added.count==1) "One independent setup" log
   check (CyrusPresetSameValues paint (paints added[1].baseObject)) "Complete Paint coverage survives" log
   check (root.procEpoch==epoch and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows) "Original complete publication is retained" log
   max undo;check (not isValidNode added[1]) "One Undo removes imported setup" log
   max redo;check (isValidNode added[1] and CyrusPresetSameValues paint (paints added[1].baseObject)) "Redo restores identities and Paint" log
   added[1].baseObject.refreshAll()
   check ((cyrusRecipePublicationFingerprint added[1].baseObject.groupSnapshotRows)==rows) "Saved variation reproduces every placement row" log
   destroyDialog editor
   check (not theHold.Holding()) "No stranded authored hold" log
  ) else throw "Unknown example phase."
  format "PASS: % %\n" example[1] phase to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
