(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-perf-*-2027/" do throw "Owned performance host required"
 local log=createFile (MCPFixtureDir+"profile-r2.txt")
 fn perfWatch=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
 fn elapsed watch=watch.Elapsed.TotalMilliseconds
 fn draw root=(root.refreshDisplay();redrawViews();completeRedraw())
 try(
  resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
  units.SystemType=#centimeters;units.SystemScale=1
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  catalog.Load @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library" "0.86.7" 2027
  global PFNode=AminScatterObject name:"200-leaf performance",PFRoot=PFNode.baseObject,PFLeaf,PFModels=#()
  PFRoot.updateMode=1;PFRoot.autoRender=false;PFRoot.newLayer();PFLeaf=PFRoot.selectedLayer()
  for id in #("A006","A007") do append PFModels (CyrusModelMerge catalog (catalog.MatchingAt id "" 0) owner:PFLeaf)
  local surface=plane width:160 length:160 widthsegs:2 lengthsegs:2
  PFRoot.setLayerSurfaces PFLeaf #(surface);PFLeaf.amount=200
  PFLeaf.procSelfOverride=true;PFLeaf.procSelfEnabled=true;PFLeaf.procSelfMultiplier=1;PFLeaf.procSelfGap=0
  PFLeaf.setSourceRadius #{1,2} 3
  PFRoot.evaluateProcedural()
  viewport.setLayout #layout_1;viewport.setType #view_top
  select surface;max zoomext sel all;select PFNode;max modify mode
  if not PFRoot.mainUI.controlsReady do PFRoot.mainUI.mountTimer.tick()
  PFRoot.bindNativeUI()
  for mode in #(1,2,3,4) do (
   PFRoot.identificationMode=if mode==4 then 4 else 1
   PFRoot.setGroupDisplay (if mode==4 then 3 else mode)
   draw PFRoot
   for trial=1 to 5 do (
    cyrusDiagnosticStop();cyrusDiagnosticStart ("radius_"+mode as string+"_"+trial as string) 4096 4194304 600000
    local before=cyrusRetainedStreamStats(),clock=perfWatch()
    PFLeaf.setSourceRadius #{1} (3.+trial*.2)
    local setter=elapsed clock
    PFRoot.evaluateProcedural();local solve=elapsed clock
    draw PFRoot;local total=elapsed clock,after=cyrusRetainedStreamStats()
    cyrusDiagnosticStop()
    format "mode=% trial=% setter_ms=% solve_and_prepare_ms=% redraw_ms=% total_ms=% accepted=% prepared_hits=% geometry_bytes=% transforms_bytes=% error=%\n" mode trial setter (solve-setter) (total-solve) total PFRoot.groupSnapshotRows[1].count PFLeaf.procPreparedHits (after[2]-before[2]) (after[3]-before[3]) PFLeaf.previewError to:log;flush log
    local trace=createFile (MCPFixtureDir+"radius-"+mode as string+"-"+trial as string+".json")
    format "%\n" (cyrusDiagnosticSnapshot 0 500) to:trace;close trace
   )
  )
  saveMaxFile (MCPFixtureDir+"two-leaves.max") quiet:true
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 cyrusDiagnosticStop();close log
)
