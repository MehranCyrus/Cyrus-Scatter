(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"undo-probe-"+(timeStamp() as string)+".txt")
 fn state root label log = (format "% layers=% undo=% redo=% heapSize=% heapFree=%\n" label root.layerObjects.count (theHold.GetUndoNames()) (theHold.GetRedoNames()) heapSize heapFree to:log;flush log)
 try (
  if theHold.Holding() do theHold.Cancel()
  loadMaxFile (MCPFixtureDir+"variation-heavy.max") quiet:true useFileUnits:true
  local node=getNodeByName "Variation heavy setup",root=node.baseObject
  root.updateMode=1;root.refreshAll();CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject root
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  state root "initial" log
  local copied=root.copyLogicalLayer root.layerObjects[1] variation:#same
  state root "copy direct" log
  root.mainUI.updateNow.pressed()
  state root "after actual Update" log
  max undo;state root "after Undo" log
  max redo;state root "after Redo" log
  close log
 )catch(format "ERROR %\n" (getCurrentException()) to:log;close log;throw())
)
