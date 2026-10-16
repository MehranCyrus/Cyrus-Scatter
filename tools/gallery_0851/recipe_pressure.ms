-- Pre-mutation admission with retained fixture allocations, not heap preferences.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"recipe-pressure-"+(timeStamp() as string)+".txt")
 global GalleryPressureValues;GalleryPressureValues=#()
 fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  CyrusPerfHeadless=true
  check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Owned border fixture opens" log
  local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
  local root=node.baseObject;root.updateMode=1;root.refreshAll()
  local path=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.csrecipe.json",document=cyrusRecipeRead path,bindings=CyrusRecipeSuggestBindings root document
  local needed=cyrusRecipeImportWorkingBytes document,nodes=objects as array,owners=root.layerObjects as array,epoch=root.procEpoch,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows
  -- Establish an actual retained low-headroom state; light collection itself is
  -- documented to retain Undo and does not change the configured heap size.
  gc light:true
  local initialHeap=heapSize
  for round=1 to 3 do (
   for i=1 to 2048 while heapFree>9000000 do append GalleryPressureValues (for j=1 to 2048 collect (matrix3 1))
   gc light:true
  )
  check (heapSize==initialHeap and heapFree<10000000 and heapFree<needed) "Fixture retains low headroom without heap growth" log
  format "ADMISSION required=% free=% heap=% retainedChunks=%\n" needed heapFree heapSize GalleryPressureValues.count to:log
  undo "Recipe pressure sentinel" on node.name="Recipe pressure sentinel"
  local failed=false,reason=""
  try(CyrusRecipeImport root document bindings variation:#same)catch(failed=true;reason=getCurrentException())
  format "REJECTION %\n" reason to:log
  check (failed and matchPattern reason pattern:"*working memory to preserve Undo*") "Import rejects for measured working memory before its hold" log
  check (CyrusPresetSameValues nodes (objects as array) and CyrusPresetSameValues owners (root.layerObjects as array) and root.procEpoch==epoch and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows) "Rejected import retains owners, inventory and full publication" log
  check (not theHold.Holding() and heapSize==initialHeap) "No leaked hold or heap preference/growth change" log
  max undo;check (node.name!="Recipe pressure sentinel") "Prior Undo retained" log
  max redo;check (node.name=="Recipe pressure sentinel") "Prior Redo retained" log
  GalleryPressureValues=undefined
  format "PASS: complete\n" to:log;close log
 )catch(GalleryPressureValues=undefined;format "ERROR %\n" (getCurrentException()) to:log;close log;throw())
)
