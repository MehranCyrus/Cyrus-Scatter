(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-*/" do throw "Owned Max 2027 profile required."
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"acceptance-phase.txt"),slug=io.ReadAllText (MCPFixtureDir+"acceptance-id.txt")
 local log=createFile (MCPFixtureDir+"acceptance-"+slug+"-"+phase+".txt")
 fn check ok message log = (format "%: %\n" (if ok then "PASS" else "FAIL") message to:log;flush log;if not ok do throw message)
 fn paintBytes root = (for owner in root.layerObjects collect #(if owner.paintDocument==undefined then undefined else (cyrusBrushRecipeExport owner.paintDocument)[1],for area in owner.paintAreas collect (if area.paintDocument==undefined then undefined else (cyrusBrushRecipeExport area.paintDocument)[1])))
 try (
  if phase=="setup" then (
   if theHold.Holding() do theHold.Accept "Owned fixture setup completion"
   for dialog in #(CyrusReadyPresetEditor,CyrusRecipeBrowser,CyrusPresetSaveEditor,CyrusRecipeSaveEditor) where dialog!=undefined do destroyDialog dialog
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.0
    global PresetTestNode=AminScatterObject name:"Owned preset target",PresetTestRoot=PresetTestNode.baseObject
    PresetTestRoot.updateMode=1;CyrusPerfHeadless=false
    select PresetTestNode;max modify mode;modPanel.setCurrentObject PresetTestNode
   )
   check (not theHold.Holding()) "Fixture starts outside any authored hold" log
   global PresetBeforeNodes=objects as array,PresetBeforeLayers=PresetTestRoot.layerObjects as array,PresetBeforeRows=cyrusRecipePublicationFingerprint PresetTestRoot.groupSnapshotRows
  ) else if phase=="load" then (
   check (not theHold.Holding()) "Load starts outside any authored hold" log
   CyrusOpenReadyPreset PresetTestRoot (io.ReadAllText (MCPFixtureDir+"preset-path.txt"))
  ) else if phase=="verify" then (
   check (CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) "Actual progress callback finishes" log
   format "STATUS: %\n" CyrusReadyPresetEditor.status.text to:log;flush log
   check (matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Actual Load + Update succeeds" log
   check (PresetTestRoot.layerObjects.count>PresetBeforeLayers.count) "Preset adds layers" log
   check (PresetTestRoot.updateMode==1) "Manual mode stays Manual" log
   check ((for rows in PresetTestRoot.groupSnapshotRows where rows.count>0 collect rows).count>0) "Preset has visible accepted placements without another Update" log
   check (not theHold.Holding()) "No stranded authored hold" log
   global PresetLoadedLayers=PresetTestRoot.layerObjects as array,PresetLoadedNodes=(for n in objects where (classof n.baseObject as string)!="Cyrus_Point_Display" collect n),PresetLoadedRows=cyrusRecipePublicationFingerprint PresetTestRoot.groupSnapshotRows,PresetLoadedPaint=paintBytes PresetTestRoot
   check ((for n in PresetLoadedNodes where findItem PresetBeforeNodes n==0 and superclassof n==GeometryClass and not n.isHidden collect n).count==1) "Prepared receiver is visible; models stay hidden" log
   format "COUNTS: %\n" (for rows in PresetTestRoot.groupSnapshotRows collect rows.count) to:log
   for owner in PresetTestRoot.layerObjects do for receiver in owner.validSurfaces() do if owner.meshMaskEnabled do cyrusMeshDensityKey receiver (owner.meshMaskPayload())
   destroyDialog CyrusReadyPresetEditor
  ) else if phase=="undo" then (
   max undo
  ) else if phase=="verifyUndo" then (
   check (CyrusPresetSameValues PresetBeforeLayers (PresetTestRoot.layerObjects as array)) "One Undo restores preceding layer ownership" log
   check ((cyrusRecipePublicationFingerprint PresetTestRoot.groupSnapshotRows)==PresetBeforeRows) "Undo restores the preceding complete publication" log
   check ((for n in objects where findItem PresetBeforeNodes n==0 and (classof n.baseObject as string)!="Cyrus_Point_Display" collect n).count==0) "Undo removes imported model/terrain/path nodes" log
  ) else if phase=="redo" then (
   max redo
  ) else if phase=="verifyRedo" then (
   check (CyrusPresetSameValues PresetLoadedLayers (PresetTestRoot.layerObjects as array)) "Redo restores exact layer identities" log
   check ((cyrusRecipePublicationFingerprint PresetTestRoot.groupSnapshotRows)==PresetLoadedRows) "Redo restores exact full placement rows without a solve" log
   check (CyrusPresetSameValues PresetLoadedPaint (paintBytes PresetTestRoot)) "Redo restores complete Paint" log
   check ((for n in PresetLoadedNodes where not isValidNode n collect n).count==0) "Redo restores captured source/context nodes" log
   check (saveMaxFile (MCPFixtureDir+slug+"-loaded.max") quiet:true) "Loaded preset scene saves" log
  ) else if phase=="reopen" then (
   check (loadMaxFile (MCPFixtureDir+slug+"-loaded.max") quiet:true useFileUnits:true) "Saved preset scene reopens" log
  ) else if phase=="verifyReopen" then (
   PresetTestNode=getNodeByName "Owned preset target";PresetTestRoot=PresetTestNode.baseObject
   PresetTestRoot.refreshAll()
   check ((cyrusRecipePublicationFingerprint PresetTestRoot.groupSnapshotRows)==PresetLoadedRows) "Reopened scene reproduces every placement field" log
   check (CyrusPresetSameValues PresetLoadedPaint (paintBytes PresetTestRoot)) "Reopened scene retains exact Paint payloads" log
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
