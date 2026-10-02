global R2Nodes=#(),R2Retained=false,R2RetainedDraw,R2EventEnabled,R2AnalyzerEnabled
fn R2RetainedDraw = (
 local held=CyrusInteractionHeld()
 gw.setTransform (matrix3 1)
 for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in n.baseObject.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  for entry in n.baseObject.layerEntries() do (
   local obj=entry[2],cache=obj.previewCache interactionHeld:held
   obj.drawRadii()
   if (not R2Retained) and (obj.showPoints or obj.showCenters) and cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
  )
 )
 gw.enlargeUpdateRect #whole
)
(
 R2EventEnabled=AminScatterNodeEvents.enabled;R2AnalyzerEnabled=CyrusAnalyzerEvents.enabled
 try (
  CVBCallbacks scatter:false analyzer:false
  AminScatterNodeEvents.enabled=false;CyrusAnalyzerEvents.enabled=false
  with undo off with redraw off for i=1 to R2Probes.count do (
   local n=mesh name:("R2_RETAINED_"+(i as string))
   n.mesh=cyrusProbeMesh R2Probes[i]
   n.renderable=false;n.castShadows=false;n.receiveShadows=false;n.displayByLayer=false
   n.material=standardMaterial diffuse:white selfIllumAmount:100 specularLevel:0 twoSided:true
   n.showVertexColors=true;n.shadeVertexColors=false;n.vertexColorType=#color
   n.showFrozenInGray=false;n.isFrozen=true
   update n
   append R2Nodes n
  )
  AminScatterNodeEvents.enabled=R2EventEnabled;CyrusAnalyzerEvents.enabled=R2AnalyzerEnabled
  CVBOriginalScatter=R2RetainedDraw;CVBRestoreCallbacks()
  makeDir (CVDir+"retained-pilot")
  CVBFrameRows=#();CVBCaseRows=#()
  for retained in #(false,true) do (
   R2Retained=retained
   for n in R2Nodes do n.isHidden=not retained
   local label=if retained then "retained_exact_mesh_plumbing" else "candidate_061_retained_hidden"
   CVBCallbacks();CVBRunCase label frames:20 warmup:6 repeat:1
   CVBWrite (CVDir+"retained-pilot")
   viewport.setTM CVOriginalView
   for j=1 to 5 do (redrawViews();windows.processPostedMessages())
   local bitmap=gw.getViewportDib();bitmap.filename=CVDir+"images/"+label+".png";save bitmap;close bitmap
  )
  CSPWriteText (CVDir+"retained-geometry.json") (CSPObject #(#("nodes",for n in R2Nodes collect #(n.name,n.numverts,n.numfaces,n.renderable,n.showVertexColors,n.shadeVertexColors)),#("source_counts",CVBCounts())))
  R2Retained=false;for n in R2Nodes do n.isHidden=true
  CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
 )catch(
  AminScatterNodeEvents.enabled=R2EventEnabled;CyrusAnalyzerEvents.enabled=R2AnalyzerEnabled
  R2Retained=false;for n in R2Nodes where isValidNode n do n.isHidden=true
  CVBRestoreCallbacks();throw()
 )
)
