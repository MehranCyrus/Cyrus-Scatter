global CVProfileDraw,CVProfileRows=#(),CVProfileEnabled=true
fn CVProfileDraw = (
 local whole=CVBClockClass.StartNew()
 gw.setTransform (matrix3 1)
 for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
  local c=CVBClockClass.StartNew()
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in n.baseObject.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  c.Stop();local icons=c.Elapsed.TotalMilliseconds
  c.Restart();local entries=n.baseObject.layerEntries();c.Stop()
  if CVProfileEnabled do append CVProfileRows #(0,"controller",icons,c.Elapsed.TotalMilliseconds,0,0,gw.getWinSizeX(),gw.getWinSizeY(),viewport.activeViewport)
  for entry in entries do (
   local obj=entry[2]
   c.Restart();obj.previewCache();c.Stop();local first=c.Elapsed.TotalMilliseconds
   c.Restart();obj.drawRadii();c.Stop();local radii=c.Elapsed.TotalMilliseconds
   local second=0.0d0,draw=0.0d0
   if obj.showPoints or obj.showCenters do (
    c.Restart();local cache=obj.previewCache();c.Stop();second=c.Elapsed.TotalMilliseconds
    c.Restart();if cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
    c.Stop();draw=c.Elapsed.TotalMilliseconds
   )
   if CVProfileEnabled do append CVProfileRows #(entry[1],n.layerNames[entry[1]],first,second,radii,draw,gw.getWinSizeX(),gw.getWinSizeY(),viewport.activeViewport)
  )
 )
 gw.enlargeUpdateRect #whole
 whole.Stop();CVBScatterMS+=whole.Elapsed.TotalMilliseconds;CVBScatterCalls+=1
)
try (
 makeDir (CVDir+"layer-profile")
 CVBFrameRows=#();CVBCaseRows=#()
 CVBCallbacks scatter:false
 registerRedrawViewsCallback CVProfileDraw
 CVBRunCase "layer_instrumented" frames:60 warmup:8
 unRegisterRedrawViewsCallback CVProfileDraw
 CVBWrite (CVDir+"layer-profile")
 local w=CSPWriter (CVDir+"layer-profile/stages.csv") "layer,name,cache_first_ms,cache_second_ms,radii_ms,native_draw_ms,gw_width,gw_height,active_viewport"
 for row in CVProfileRows do CSPRow w row
 w.Dispose()
 CVBRestoreCallbacks()
)catch(
 try(unRegisterRedrawViewsCallback CVProfileDraw;CVBRestoreCallbacks())catch()
 CSPWriteText (CVDir+"layer-error.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace()))
)
