global R2ProductionDraw=AminScatterObjectDraw,R2Draw,R2Mode=0,R2Probes=#(),R2LayerObjects=#()
global R2NativeStats=#()
fn R2Draw = (
 local held=CyrusInteractionHeld(),i=0
 gw.setTransform (matrix3 1)
 for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in n.baseObject.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  for entry in n.baseObject.layerEntries() do (
   local obj=entry[2],cache=obj.previewCache interactionHeld:held
   obj.drawRadii();i+=1
   if obj.showPoints or obj.showCenters do (
    if cache!=undefined do (
     if R2Mode==0 then aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
     else cyrusProbeDraw R2Probes[i] R2Mode
    )
   )
  )
 )
 gw.enlargeUpdateRect #whole
)
(
 makeDir (CVDir+"pilot");makeDir (CVDir+"images")
 unRegisterRedrawViewsCallback R2ProductionDraw
 CVBOriginalScatter=R2Draw;CVBRestoreCallbacks()
 try (
  for n in CVControllers do for entry in n.layerEntries() do (
   local layer=entry[2],cache=layer.previewCache interactionHeld:false
   append R2LayerObjects layer
   append R2Probes (cyrusProbeBuild (cyrusPreviewTriangles cache true 100000))
  )
  CVBFrameRows=#();CVBCaseRows=#()
  for mode in #(0,3,1,2) do (
   R2Mode=mode;CVBCallbacks()
   local label=(#("mesh_render","hardware_buffer","flat_triangles","candidate_061"))[if mode==0 then 4 else mode]
   CSPWriteText (CVDir+"progress.txt") ("Pilot "+label)
   CVBRunCase label frames:12 warmup:4 repeat:1
   CVBWrite (CVDir+"pilot")
   viewport.setTM CVOriginalView
   for j=1 to 4 do (redrawViews();windows.processPostedMessages())
   local bitmap=gw.getViewportDib();bitmap.filename=CVDir+"images/"+label+".png";save bitmap;close bitmap
   append R2NativeStats #(label,for p in R2Probes collect cyrusProbeStats p)
   CSPWriteText (CVDir+"probe-stats.json") (CSPObject #(#("modes",R2NativeStats)))
  )
  R2Mode=0;CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
  CSPWriteText (CVDir+"pilot-complete.txt") "All pilot modes completed; 0.61 drawing restored."
 )catch(
  R2Mode=0;CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
  throw()
 )
)
