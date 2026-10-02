global VPGrab,VPCompareCache
fn VPGrab name = (
 for i=1 to 6 do (redrawViews();windows.processPostedMessages())
 local bitmap=gw.getViewportDib();bitmap.filename=CVDir+"images/"+name+".png";save bitmap;close bitmap
)
fn VPCompareCache cache = (
 local old=cyrusPreviewTriangles cache false 100000,fast=cyrusPreviewTriangles cache true 100000
 if old.count!=fast.count do throw "Scene triangle count mismatch"
 for i=1 to old.count do (
  for j=1 to 3 do if old[i][j]!=fast[i][j] do throw "Scene triangle position mismatch"
  if old[i][4]!=fast[i][4] or old[i][5]!=fast[i][5] do throw "Scene shade/color mismatch"
 )
 old.count
)
(
 makeDir (CVDir+"images")
 CVBRestoreCallbacks();viewport.setTM CVOriginalView
 global VPSavedStyles=for n in CVControllers collect #(n,n.proxyShape,n.viewportInstances,n.pointColorMode,n.solidPointColor)
 local report=#()
 try (
  for n in CVControllers do for i=1 to n.layerObjects.count do (
   local l=n.layerObjects[i],cache=(l.cacheSnapshot())[1]
   append report #(n.layerNames[i],VPCompareCache cache,for v in cyrusPreviewDrawStats cache collect (v as integer))
  )
  CSPWriteText (CVDir+"scene-parity.json") (CSPObject #(#("layers",report),#("positions_shades_source_colors_exact",true)))
  for shape in #(3,1,2) do for colorMode in #(2,1) do (
   for n in CVControllers do (
    n.proxyShape=shape;n.viewportInstances=if shape==2 then 250 else 2000
    n.pointColorMode=colorMode
    n.refreshDisplay()
   )
   gc()
   local label="shape"+(shape as string)+"-color"+(colorMode as string)
   cyrusPreviewBatchDrawing false;VPGrab (label+"-legacy")
   cyrusPreviewBatchDrawing true;VPGrab (label+"-batch")
  )
  for state in VPSavedStyles do (
   state[1].proxyShape=state[2];state[1].viewportInstances=state[3];state[1].pointColorMode=state[4];state[1].solidPointColor=state[5]
   state[1].refreshDisplay()
  )
  gc()
  local drawStats=for n in CVControllers collect (for l in n.layerObjects collect (for v in cyrusPreviewDrawStats ((l.cacheSnapshot())[1]) collect (v as integer)))
  CSPWriteText (CVDir+"final-display.json") (CSPObject #(#("counts",CVBCounts()),#("draw_stats",drawStats),#("size",#(gw.getWinSizeX(),gw.getWinSizeY())),#("node_count",objects.count)))
  cyrusPreviewBatchDrawing true;redrawViews()
 )catch(
  for state in VPSavedStyles do (state[1].proxyShape=state[2];state[1].viewportInstances=state[3];state[1].pointColorMode=state[4];state[1].solidPointColor=state[5];state[1].refreshDisplay())
  cyrusPreviewBatchDrawing true;throw()
 )
)
