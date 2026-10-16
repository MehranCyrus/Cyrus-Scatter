(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local log=createFile (ExampleEvidence+"/apply-"+(timeStamp() as string)+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn paints root=(for owner in root.layerObjects collect #(if owner.paintDocument==undefined then undefined else (cyrusBrushRecipeExport owner.paintDocument)[1],for area in owner.paintAreas collect (if area.paintDocument==undefined then undefined else (cyrusBrushRecipeExport area.paintDocument)[1])))
 try (
  -- End only the disposable Python preparation's enclosing hold, then reopen
  -- the immutable scene before exercising any product transaction or history.
  if theHold.Holding() do theHold.Cancel()
  check (not theHold.Holding()) "Start outside a surrounding Undo hold" log
  check (loadMaxFile ExampleScene quiet:true useFileUnits:true) "Editable example scene reopens" log
  local root=(getNodeByName ("CYRUS EXAMPLE | "+ExampleTitle)).baseObject;root.refreshAll()
  local before=objects as array,paint=paints root,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows,epoch=root.procEpoch
  CyrusOpenRecipeLoad root ExampleRecipe (cyrusRecipeInfo ExampleRecipe)[11]
  local editor=CyrusRecipeLoadEditor;editor.suggestButton.pressed();editor.newSetupCheck.checked=true;editor.importVariation.selection=2
  for pair in editor.bindings do check (pair[2]!=undefined) "Every role has an explicit matching binding" log
  editor.importButton.pressed();check (matchPattern editor.status.text pattern:"Imported*") ("Actual Load: "+editor.status.text) log
  local added=for n in objects where classof n.baseObject==AminScatterObject and findItem before n==0 collect n
  check (added.count==1) "One independent setup is created" log
  local other=added[1].baseObject
  check (CyrusPresetSameValues paint (paints other)) "All Paint areas and complete coverage payloads survive" log
  check (root.procEpoch==epoch and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows) "Original publication remains unchanged" log
  max undo;check (not isValidNode added[1]) "One Undo removes the whole imported setup" log
  max redo;check (isValidNode added[1] and CyrusPresetSameValues paint (paints added[1].baseObject)) "Redo restores identities and Paint" log
  other=added[1].baseObject;other.refreshAll()
  check ((cyrusRecipePublicationFingerprint other.groupSnapshotRows)==rows) "Saved variation reproduces every full placement row" log
  destroyDialog editor
  check (not theHold.Holding()) "No stranded authored hold" log
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
