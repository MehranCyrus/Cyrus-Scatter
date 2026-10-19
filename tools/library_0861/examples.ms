-- Selected-surface Add/Undo qualification on the eight saved example terrains.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/library-surface0861-*/" do throw "Owned profile required"
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"example-phase.txt"),id=io.ReadAllText (MCPFixtureDir+"example-id.txt"),log=createFile (MCPFixtureDir+"example-"+id+"-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn paintData root=(for owner in root.layerObjects collect #(if owner.paintDocument==undefined then undefined else (cyrusBrushRecipeExport owner.paintDocument)[1],for area in owner.paintAreas collect (if area.paintDocument==undefined then undefined else (cyrusBrushRecipeExport area.paintDocument)[1])))
 try(
  case phase of (
   "setup":(
    for d in #(CyrusRecipeBrowser,CyrusReadyPresetEditor) where d!=undefined do destroyDialog d
    check (loadMaxFile (io.ReadAllText (MCPFixtureDir+"example-scene.txt")) quiet:true useFileUnits:true) "Saved example copy opens" log
    global ENode=undefined,ERoot=undefined,ETerrain=undefined,ELayers=#(),EHash="",EPaint=#(),EAdded=#(),ELoadedHash=""
    for n in objects where classof n.baseObject==AminScatterObject do ENode=n
    check (ENode!=undefined) "Saved example has one Scatter controller" log
    ERoot=ENode.baseObject;ERoot.refreshAll()
    local surfaces=#();for layer in ERoot.layerObjects do for n in layer.validSurfaces() do appendIfUnique surfaces n
    check (surfaces.count==1) "Example has one explicit terrain" log
    ETerrain=surfaces[1];ELayers=ERoot.layerObjects as array;EHash=cyrusRecipePublicationFingerprint ERoot.groupSnapshotRows;EPaint=paintData ERoot
   )
   "load":(CyrusOpenReadyPreset ERoot (io.ReadAllText (MCPFixtureDir+"example-package.txt")) surface:ETerrain)
   "verify":(
    check (CyrusReadyPresetEditor.finished) "Real preparation and Update finish" log
    format "STATUS: %\n" CyrusReadyPresetEditor.status.text to:log;flush log
    check (matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Ready preset loads on its compatible selected terrain" log
    EAdded=CyrusReadyPresetEditor.result[2]
    for layer in EAdded do check (CyrusPresetSameValues (layer.validSurfaces()) #(ETerrain)) "Added layer uses explicit terrain" log
    check (ERoot.layerObjects.count==2*ELayers.count) "Add preserves preceding layers" log
    for i=1 to ELayers.count do check (ERoot.layerObjects[i]==ELayers[i]) "Prior layer identity/order retained" log
    ELoadedHash=cyrusRecipePublicationFingerprint ERoot.groupSnapshotRows
    check ((for leaf in EAdded where leaf.previewError!="" collect leaf.previewError).count==0) "No preview/calculation errors" log
    destroyDialog CyrusReadyPresetEditor
   )
   "undo":(max undo)
   "verifyUndo":(
    check (CyrusPresetSameValues ELayers (ERoot.layerObjects as array)) "One Undo restores preceding layers" log
    check ((cyrusRecipePublicationFingerprint ERoot.groupSnapshotRows)==EHash) "Undo restores exact preceding publication" log
    check (CyrusPresetSameValues EPaint (paintData ERoot)) "Undo retains complete Paint" log
   )
   "redo":(max redo)
   "verifyRedo":(
    check ((cyrusRecipePublicationFingerprint ERoot.groupSnapshotRows)==ELoadedHash) "Redo restores exact loaded publication" log
    check ((for layer in EAdded where findItem ERoot.layerObjects layer==0 collect layer).count==0) "Redo restores imported owners" log
   )
   default:throw "Unknown example phase"
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
