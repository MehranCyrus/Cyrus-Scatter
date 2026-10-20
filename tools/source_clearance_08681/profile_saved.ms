(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-perf-*-2027/" do throw "Owned performance host required"
 local input=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/clearance-performance-08681-20261020/input-two-leaves.max"
 loadMaxFile input quiet:true
 CyrusPerfHeadless=false;CyrusPointSuspended=true
 global PFNode=getNodeByName "200-leaf performance",PFRoot=PFNode.baseObject,PFLeaf=PFRoot.selectedLayer(),PFModels=PFLeaf.validSources(),PFThird=undefined
 local log=createFile (MCPFixtureDir+"profile-same-scene.txt")
 fn drain root=(root.refreshDisplay();for k=1 to 3 do (windows.processPostedMessages();redrawViews());completeRedraw())
 try(
  PFRoot.updateMode=1;PFRoot.autoRender=false
  select PFNode;max modify mode
  if not PFRoot.mainUI.controlsReady do PFRoot.mainUI.mountTimer.tick()
  PFRoot.bindNativeUI()
  for mode in #(1,2,3,4) do(
   PFRoot.identificationMode=if mode==4 then 4 else 1
   PFRoot.setGroupDisplay (if mode==4 then 3 else mode);drain PFRoot
   for trial=1 to 5 do(
    local streams=cyrusRetainedStreamStats(),materialStats=if cyrusMaterialPreviewStats==undefined then #(0,0,0) else cyrusMaterialPreviewStats()
    local watch=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
    PFLeaf.setSourceRadius #{1} (3.+trial*.2)
    local setter=watch.Elapsed.TotalMilliseconds
    PFRoot.evaluateProcedural();local solve=watch.Elapsed.TotalMilliseconds
    drain PFRoot;local total=watch.Elapsed.TotalMilliseconds,after=cyrusRetainedStreamStats()
    local maps=if cyrusMaterialPreviewStats==undefined then #(0,0,0) else cyrusMaterialPreviewStats()
    format "mode=% trial=% setter_ms=% solve_prepare_ms=% redraw_ms=% total_ms=% accepted=% geometry_bytes=% transform_bytes=% map_bakes=% map_reuses=% error=%\n" mode trial setter (solve-setter) (total-solve) total PFRoot.groupSnapshotRows[1].count (after[2]-streams[2]) (after[3]-streams[3]) (maps[2]-materialStats[2]) (maps[3]-materialStats[3]) PFLeaf.previewError to:log;flush log
   )
  )
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)
