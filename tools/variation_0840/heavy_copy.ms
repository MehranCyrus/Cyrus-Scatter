(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned variation host required."
 local log=createFile (MCPFixtureDir+"heavy-copy-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 fn manager root = (
  root.activeLayer=1;root.bindNativeUI()
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  root.mainUI.slots[1].open=true;root.mainUI.slots[1].rolledUp false
  root.mainUI.editors[1]
 )
 try (
  if theHold.Holding() do theHold.Cancel()
  loadMaxFile (MCPFixtureDir+"variation-heavy.max") quiet:true useFileUnits:true
  local node=getNodeByName "Variation heavy setup",root=node.baseObject
  root.updateMode=1;root.refreshAll();select node;max modify mode;modPanel.setCurrentObject root
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  root.mainUI.updateRadio.changed 1
  -- Published rows are immutable. Avoid duplicating 60000 nested MAXScript
  -- records solely for the oracle; the Python witness also compares hashes.
  local leaf=root.layerObjects[1],baseline=root.groupSnapshotRows[1],other=root.groupSnapshotRows[2],epoch=root.procEpoch,prep=leaf.procPreparedBuilds,builds=(leaf.receiverCacheStats())[1]
  local times=#()
  for i=1 to 10 do (
   local page=manager root;page.flow_layersUI_copyVariation.selection=1
   local started=timeStamp();page.flow_layersUI_copyButton.pressed();append times (timeStamp()-started)
   check (root.layerObjects.count==3) "Actual Copy handler creates one layer" log
   max undo;check (root.layerObjects.count==2) "One Undo removes actual UI copy" log
  )
  format "COPY HANDLER MS: %\n" times to:log
  check (root.procEpoch==epoch and leaf.procPreparedBuilds==prep and (leaf.receiverCacheStats())[1]==builds and equalRows baseline root.groupSnapshotRows[1] and equalRows other root.groupSnapshotRows[2]) "Ten pending copies and Undo preserve complete 60000 rows without calculations" log
  for choice=1 to 2 do (
   local page=manager root;page.flow_layersUI_copyVariation.selection=choice
   page.flow_layersUI_copyButton.pressed()
   format "BEFORE UPDATE undo=% heapFree=% heapSize=%\n" (theHold.GetUndoNames()) heapFree heapSize to:log
   local started=timeStamp();root.mainUI.updateNow.pressed()
   format "AFTER UPDATE undo=% heapFree=% heapSize=%\n" (theHold.GetUndoNames()) heapFree heapSize to:log
   format "EXPLICIT UPDATE CHOICE % MS %\n" choice (timeStamp()-started) to:log
   check (root.groupSnapshotRows.count==3 and root.groupSnapshotRows[3].count==30000) "Actual Update publishes 90000 complete rows" log
   check ((equalRows baseline root.groupSnapshotRows[3])==(choice==1)) "Actual variation dropdown controls Same versus New output" log
   check (equalRows baseline root.groupSnapshotRows[1] and equalRows other root.groupSnapshotRows[2]) "Explicit copy update preserves both original layers" log
   max undo;root.refreshAll();check (root.layerObjects.count==2) "Heavy copy Undo restores original layer set" log
  )
  check (not theHold.Holding()) "No stranded UI transaction" log
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
