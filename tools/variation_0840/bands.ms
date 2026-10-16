(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"bands-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true
  local repository=pathConfig.appendPath MCPFixtureDir "../../../"
  check (loadMaxFile (pathConfig.appendPath repository "AminScatter/library/borders.max") quiet:true useFileUnits:true) "Bundled Band/Paint scene opens" log
  local nodes=for n in objects where classof n.baseObject==AminScatterObject collect n
  check (nodes.count==1) "Unique bundled controller" log
  local root=nodes[1].baseObject;root.updateMode=1;root.refreshAll()
  local originals=for rows in root.groupSnapshotRows collect deepCopy rows,owners=root.layerObjects as array
  local doc=CyrusRecipeCapture root owners "Saved Band and Paint",bindings=CyrusRecipeSuggestBindings root doc
  local imported=CyrusRecipeImport root doc bindings newSetup:true variation:#same;imported[1].refreshAll()
  for i=1 to owners.count do check (equalRows originals[i] imported[1].groupSnapshotRows[i]) "Saved variation preserves full Band/Paint density and scale result" log
  for i=1 to owners.count do (
   local copied=root.copyLogicalLayer owners[i] variation:#same;root.refreshAll()
   check (equalRows originals[i] root.groupSnapshotRows[owners.count+1]) "Same named copy preserves remapped Band/source assignments and curves" log
   max undo;check (root.layerObjects.count==owners.count) "Band Copy remains one Undo" log
   root.refreshAll()
  )
  check (not theHold.Holding()) "No stranded Band transaction" log
  CyrusPerfHeadless=false;format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
