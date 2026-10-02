-- Diagnostic only: identical selected row indices and pyramid topology, ordinary
-- Max meshes. Layer colors/material shading differ from the plugin callback.
global CVMeshNodes=#(),CVMeshEvidence=#(),CVSourceEligibility=#()
global CVBatchedCaches=#(),CVBatchedDraw,CVBatchedPlumbingDraw
fn CVBatchedDraw = (
 local c=CVBClockClass.StartNew()
 for cache in CVBatchedCaches do aminScatterDrawPreview cache false white
 gw.enlargeUpdateRect #whole
 c.Stop();CVBScatterMS+=c.Elapsed.TotalMilliseconds;CVBScatterCalls+=1
)
fn CVBatchedPlumbingDraw = (
 local c=CVBClockClass.StartNew(),index=0
 gw.setTransform (matrix3 1)
 for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in n.baseObject.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  for entry in n.baseObject.layerEntries() do (
   local obj=entry[2]
   index+=1
   obj.previewCache();obj.drawRadii()
   if obj.showPoints or obj.showCenters do (
    local cache=obj.previewCache()
    if cache!=undefined do aminScatterDrawPreview CVBatchedCaches[index] (obj.pointColorMode==1) obj.solidPointColor
   )
  )
 )
 gw.enlargeUpdateRect #whole
 c.Stop();CVBScatterMS+=c.Elapsed.TotalMilliseconds;CVBScatterCalls+=1
)
try (
 global CVEventEnabled=AminScatterNodeEvents.enabled,CVAnalyzerEventEnabled=CyrusAnalyzerEvents.enabled
 AminScatterNodeEvents.enabled=false;CyrusAnalyzerEvents.enabled=false
 CVBCallbacks scatter:false analyzer:false
 local buildClock=CVBClockClass.StartNew()
 with undo off with redraw off (
  for n in CVControllers do for entry in n.layerEntries() do (
   local layer=entry[2],sources=layer.validSources(),rows=layer.placements (layer.validSources()) previewOnly:true
   local templates=#(),verts=#(),faces=#(),shown=0,facesUsed=0
   for src in sources do (
    local points=#()
    local eligible=classof src!=Integer
    if eligible do (
     local probe=cyrusBuildGeometryPreview #(#((matrix3 1),1)) #(src) #(white) 3 1 2000000
     eligible=(aminScatterPreviewCount probe)>0
     append CVSourceEligibility #(src.name,classof src as string,eligible)
    )
    if eligible do (
     local bounds=nodeGetBoundingBox src src.transform
     local lo=bounds[1],hi=bounds[2],center=(lo+hi)*0.5
     points=#([lo.x,lo.y,lo.z],[hi.x,lo.y,lo.z],[hi.x,hi.y,lo.z],[lo.x,hi.y,lo.z],[center.x,center.y,hi.z])
    )
    append templates points
   )
   local wanted=amin layer.viewportInstances rows.count
   for k=0 to wanted-1 do (
    local index=(floor(k*rows.count/(wanted as double))) as integer
    local row=rows[index+1],points=templates[row[2]]
    if points.count>0 and facesUsed+6<=layer.viewportFaces do (
     local offset=verts.count
     for p in points do append verts (p*row[1])
     for f in #([1,2,5],[2,3,5],[3,4,5],[4,1,5],[1,3,2],[1,4,3]) do append faces (f+[offset,offset,offset])
     shown+=1;facesUsed+=6
    )
   )
   local node=mesh name:(uniqueName ("CV_DIAGNOSTIC_"+n.layerNames[entry[1]])) vertices:verts faces:faces
   node.renderable=false;node.wirecolor=layer.solidPointColor
   node.material=standardMaterial diffuse:layer.solidPointColor twoSided:true
   update node
   append CVMeshNodes node
   local cache=layer.cacheSnapshot()
   local expectedFaces=cyrusPreviewFaces cache[1]
   if facesUsed!=expectedFaces or shown!=cache[2] do throw ("Diagnostic population mismatch: "+n.layerNames[entry[1]])
   append CVMeshEvidence #(n.layerNames[entry[1]],rows.count,shown,facesUsed,verts.count,expectedFaces,cache[2])
  )
 )
 buildClock.Stop()
 CSPWriteText (CVDir+"retained-mesh-build.json") (CSPObject #(#("build_ms",buildClock.Elapsed.TotalMilliseconds),#("layers",CVMeshEvidence),#("source_eligibility",CVSourceEligibility),#("scope","same row selection, source-local bounding pyramids and transforms; ordinary Max mesh shading, not pixel-identical production rendering")))
 local resultFolder=CVDir+"retained-mesh-v2"
 makeDir resultFolder
 CVBFrameRows=#();CVBCaseRows=#()
 for r=1 to 3 do (
  CVBCallbacks scatter:false analyzer:true
  CVBRunCase "retained_mesh_with_analyzer" frames:60 warmup:8 repeat:r
  CVBCallbacks scatter:false analyzer:false
  CVBRunCase "retained_mesh_without_analyzer" frames:60 warmup:8 repeat:r
  CVBWrite resultFolder
 )
 viewport.setTM CVOriginalView;redrawViews()
 local b=gw.getViewportDib();b.filename=CVDir+"retained-mesh.png";save b;close b
 -- Feed the same world-space triangles back through the production native draw
 -- primitive, now one begin/end triangle batch per layer instead of per proxy.
 for node in CVMeshNodes do (
  append CVBatchedCaches (cyrusBuildGeometryPreview #(#((matrix3 1),1)) #(node) #(node.wirecolor) 4 1 2000000)
  node.isHidden=true
 )
 for r=1 to 3 do (
  CVBCallbacks scatter:false analyzer:true
  registerRedrawViewsCallback CVBatchedDraw
  CVBRunCase "native_world_batched_with_analyzer" frames:60 warmup:8 repeat:r
  unRegisterRedrawViewsCallback CVBatchedDraw
  CVBCallbacks scatter:false analyzer:false
  registerRedrawViewsCallback CVBatchedDraw
  CVBRunCase "native_world_batched_without_analyzer" frames:60 warmup:8 repeat:r
  unRegisterRedrawViewsCallback CVBatchedDraw
  CVBWrite resultFolder
 )
 for r=1 to 3 do (
  CVBCallbacks scatter:false analyzer:true
  registerRedrawViewsCallback CVBatchedPlumbingDraw
  CVBRunCase "native_world_batched_original_plumbing" frames:60 warmup:8 repeat:r
  unRegisterRedrawViewsCallback CVBatchedPlumbingDraw
  CVBWrite resultFolder
 )
 CVBCallbacks scatter:false analyzer:false
 registerRedrawViewsCallback CVBatchedDraw
 viewport.setTM CVOriginalView;redrawViews()
 b=gw.getViewportDib();b.filename=CVDir+"native-world-batched.png";save b;close b
 unRegisterRedrawViewsCallback CVBatchedDraw
 CVBatchedCaches=#()
 with undo off for n in CVMeshNodes where isValidNode n do delete n
 CVMeshNodes=#()
 AminScatterNodeEvents.enabled=CVEventEnabled;CyrusAnalyzerEvents.enabled=CVAnalyzerEventEnabled
 CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
 CSPWriteText (CVDir+"retained-success-v2.txt") "All matched-population trials complete; diagnostic scene nodes removed."
)catch(
 try(unRegisterRedrawViewsCallback CVBatchedPlumbingDraw)catch()
 try(unRegisterRedrawViewsCallback CVBatchedDraw)catch()
 try(with undo off for n in CVMeshNodes where isValidNode n do delete n;CVMeshNodes=#())catch()
 try(AminScatterNodeEvents.enabled=CVEventEnabled;CyrusAnalyzerEvents.enabled=CVAnalyzerEventEnabled;CVBRestoreCallbacks())catch()
 CSPWriteText (CVDir+"retained-error-retry.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace()))
)
