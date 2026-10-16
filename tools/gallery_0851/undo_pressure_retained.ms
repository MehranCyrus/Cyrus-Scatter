-- Hold bounded fixture-only values to reproduce low headroom without changing
-- heap preferences, explicitly collecting garbage or clearing Undo.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"undo-pressure-retained-"+(timeStamp() as string)+".txt")
 fn state root label log = (format "% layers=% undo=% redo=% heapSize=% heapFree=%\n" label root.layerObjects.count (theHold.GetUndoNames()) (theHold.GetRedoNames()) heapSize heapFree to:log;flush log)
 global GalleryPressureValues;GalleryPressureValues=#()
 try (
  if theHold.Holding() do throw "Unexpected outer hold."
  loadMaxFile (MCPFixtureDir+"variation-heavy.max") quiet:true useFileUnits:true
  local node=getNodeByName "Variation heavy setup",root=node.baseObject
  root.updateMode=1;root.refreshAll();CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject root
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  state root "initial" log
  local oldHeap=heapSize
  for i=1 to 512 while heapFree>26000000 do append GalleryPressureValues (for j=1 to 2048 collect (matrix3 1))
  state root "retained fixture padding" log
  if heapSize!=oldHeap or heapFree>26000000 do throw "Fixture did not reach bounded low headroom without growth."
  local fingerprint=cyrusRecipePublicationFingerprint root.groupSnapshotRows,epoch=root.procEpoch,builds=root.groupBuilds
  undo "Pressure preceding sentinel" on node.name="Pressure preceding sentinel"
  local copied=root.copyLogicalLayer root.layerObjects[1]
  state root "copy" log
  root.mainUI.updateNow.pressed();state root "after Update" log
  format "ERRORS %\n" (for leaf in root.layerObjects collect leaf.previewError) to:log
  local admitted=not matchPattern root.layerObjects[1].previewError pattern:"*working memory to preserve Undo*"
  if not admitted do (
   if root.procEpoch!=epoch or root.groupBuilds!=builds or (cyrusRecipePublicationFingerprint root.groupSnapshotRows)!=fingerprint do throw "Admission failure changed the complete publication."
   if heapSize!=oldHeap do throw "Rejected Update grew the MAXScript heap."
   format "PASS: admission retained exact rows, counters and heap size\n" to:log
  )
  max undo;state root "after Undo" log
  local removed=root.layerObjects.count==2
  format "OBSERVED Undo removed copy: %\n" removed to:log
  max redo;state root "after Redo" log
  format "OBSERVED Redo restored a previously removed copy: %\n" (removed and root.layerObjects.count==3) to:log
  if not removed or root.layerObjects.count!=3 do throw "Copy Undo/Redo failed under pressure."
  max undo;max undo
  if node.name=="Pressure preceding sentinel" do throw "Preceding Undo entry was lost."
  format "PASS: preceding Undo survives\n" to:log
  GalleryPressureValues=undefined
  close log
 )catch(GalleryPressureValues=undefined;format "ERROR %\n" (getCurrentException()) to:log;close log;throw())
)
