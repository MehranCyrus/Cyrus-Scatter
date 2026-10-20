-- Run after host_acceptance.ms, in the same disposable profile.
(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-*-2027/" do throw "Owned clearance host required"
 local log=createFile (MCPFixtureDir+"clearance-lifecycle.txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn fingerprint root = cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("clearance") #()
 try (
  CyrusPointSuspended=true
  local f=openFile (MCPFixtureDir+"saved-fingerprint.txt"),expected=readLine f
  close f
  loadMaxFile (MCPFixtureDir+"clearance59.max") quiet:true
  local node=getNodeByName "Clearance acceptance",root=node.baseObject
  root.updateMode=1;root.evaluateProcedural()
  check (not root.needsClearanceUpgrade() and fingerprint root==expected) "Schema 59 save/reopen preserves complete publication" log
  local a=root.layerObjects[1],b=root.layerObjects[2],target=b.clearanceTargets[1]
  root.layerNames[1]="Renamed target";root.evaluateProcedural()
  check (b.clearanceTargets[1]==target and fingerprint root==expected) "Target rename preserves identity and output" log
  local epoch=root.procEpoch,builds=a.procPreparedBuilds
  undo "Invalid clearance fixture" on a.clearanceFactors[1]=-1
  local failed=false
  try(root.evaluateProcedural())catch(failed=true)
  check (failed and root.procEpoch==epoch and fingerprint root==expected) "Invalid successor retains the previous complete publication" log
  max undo;root.evaluateProcedural()
  check (fingerprint root==expected) "Undo recovers the valid authored policy" log
  -- Failed successors intentionally invalidate scratch preparation keys. Use
  -- a fresh ordinary load for the independent warm Live cache check.
  loadMaxFile (MCPFixtureDir+"clearance59.max") quiet:true
  root=(getNodeByName "Clearance acceptance").baseObject;a=root.layerObjects[1]
  root.updateMode=2
  CyrusPointSuspended=false
  root.evaluateProcedural()
  for pass=1 to 5 do (windows.processPostedMessages();redrawViews();sleep 0.05)
  epoch=root.procEpoch;builds=a.procPreparedBuilds
  (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"live-key-before.txt") a.procPreparedKey
  a.setSourceClearance #{1} #clearanceOthers 2
  local deadline=timeStamp()+15000
  while root.procEpoch==epoch and timeStamp()<deadline do (windows.processPostedMessages();redrawViews();sleep 0.05)
  format "Live before/after: epoch %/%, preparation %/%, error %\n" epoch root.procEpoch builds a.procPreparedBuilds a.previewError to:log
  (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"live-key-after.txt") a.procPreparedKey
  check (root.procEpoch>epoch and a.procPreparedBuilds==builds) "Live clearance edit republishes without rebuilding candidate geometry" log
  epoch=root.procEpoch;builds=a.procPreparedBuilds
  local unrelated=box name:"Unrelated animation" pos:[1000,0,0]
  animate on (at time 0 unrelated.pos=[1000,0,0];at time 10 unrelated.pos=[1100,0,0])
  for t in #(0,5,10,0) do (sliderTime=t;windows.processPostedMessages();redrawViews())
  check (root.procEpoch==epoch and a.procPreparedBuilds==builds) "Unrelated animation retains static placement publication" log
  root.updateMode=1;CyrusPointSuspended=true
  -- Existing scenes require a single explicit, Undoable upgrade.
  loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/update08671-test-clearance-baseline-2027/schema58.max" quiet:true
  local roots=for n in objects where classOf n==AminScatterObject collect n
  check (roots.count==1) "Schema 58 fixture retains its controller" log
  root=roots[1].baseObject
  check (root.needsClearanceUpgrade()) "Schema 58 requests explicit clearance upgrade" log
  failed=false;try(root.procAssertSchema())catch(failed=true)
  check failed "Pending upgrade blocks calculation" log
  local ids=for leaf in root.layerObjects collect #(leaf.layerID,leaf.sourceRowIDs as array)
  select roots[1];max modify mode
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  root.bindNativeUI()
  local mainBounds=windows.getWindowPos root.mainUI.hwnd,upgrade=root.mainUI.upgradeButton
  local upgradeBounds=windows.getWindowPos upgrade.hwnd[1]
  check (upgrade.visible and upgradeBounds.y+upgradeBounds.h<=mainBounds.y+mainBounds.h) "Upgrade button is visible and contained at the current UI scale" log
  local handle=upgrade.hwnd[1],identifier=windows.getWindowLong handle #id
  windows.sendMessage (windows.getParentHWND handle) 0x0111 identifier handle
  check (not root.needsClearanceUpgrade()) "Explicit scene upgrade enables calculation" log
  max undo
  check (root.needsClearanceUpgrade()) "Undo restores pending upgrade" log
  max redo
  check (not root.needsClearanceUpgrade()) "Redo restores upgraded scene" log
  check ((for leaf in root.layerObjects collect #(leaf.layerID,leaf.sourceRowIDs as array)) as string==ids as string) "Scene upgrade preserves layer and source identities" log
  root.evaluateProcedural()
  check (root.procEpoch>0) "Upgraded schema 58 scene calculates" log
  saveMaxFile (MCPFixtureDir+"upgraded59.max") quiet:true
  loadMaxFile (MCPFixtureDir+"upgraded59.max") quiet:true
  root=(for n in objects where classOf n==AminScatterObject collect n)[1].baseObject
  check (not root.needsClearanceUpgrade()) "Saved upgrade does not ask again on reopen" log
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)
