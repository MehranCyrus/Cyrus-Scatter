-- No fixture deep copies and no version-specific variation control: A/B oracle.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"undo-stress-"+(timeStamp() as string)+".txt")
 fn state root label log = (format "% layers=% undo=% redo=% heapSize=% heapFree=%\n" label root.layerObjects.count (theHold.GetUndoNames()) (theHold.GetRedoNames()) heapSize heapFree to:log;flush log)
 try (
  if theHold.Holding() do theHold.Cancel()
  loadMaxFile (MCPFixtureDir+"variation-heavy.max") quiet:true useFileUnits:true
  local node=getNodeByName "Variation heavy setup",root=node.baseObject
  root.updateMode=1;root.refreshAll();CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject root
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  format "VERSION %\n" (root.uiVersion()) to:log
  state root "initial" log
  for i=1 to 10 do (
   local copied=root.copyLogicalLayer root.layerObjects[1]
   max undo
   if root.layerObjects.count!=2 do throw "Pending-copy Undo failed"
  )
  state root "after 10 pending copies" log
  local copied=root.copyLogicalLayer root.layerObjects[1]
  state root "copy" log
  root.mainUI.updateNow.pressed();state root "after Update" log
  max undo;state root "after Undo" log
  local removed=root.layerObjects.count==2
  format "OBSERVED Undo removed copy: %\n" removed to:log
  max redo;state root "after Redo" log
  format "OBSERVED Redo restored a previously removed copy: %\n" (removed and root.layerObjects.count==3) to:log
  close log
 )catch(format "ERROR %\n" (getCurrentException()) to:log;close log;throw())
)
