(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned surface host required"
 local output=createFile (MCPFixtureDir+"surface-08672.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn checksum image=(local result=[0.,0.,0.];for y=0 to image.height-1 do for c in getPixels image [0,y] image.width do result+=[c.r,c.g,c.b];result)
 try(
  resetMaxFile #noPrompt;CyrusPointSuspended=false
  viewport.setLayout #layout_1;viewport.setType #view_top;viewport.SetRenderLevel #smoothhighlights
  local targets=#(plane width:100 length:100,sphere radius:50 segs:24,box width:100 length:100 height:100)
  for i=1 to targets.count do (
   local target=targets[i];target.pos=[(i-1)*200,0,0]
   select target;max zoomext sel all;completeRedraw()
   gw.setTransform (matrix3 1)
   local center=gw.wTransPoint target.pos removeUIScaling:false
   local doc=cyrusBrushCreate target;cyrusBrushSettings doc 15 false
   undo "Hide receiver test" on cyrusSetSurfaceHidden target true
   check (cyrusSurfaceHidden target) "Surface viewport preference is set" output
   cyrusBrushBegin doc
   check ((cyrusBrushStats doc)[5]==1) ("Painter stays active for hidden surface "+(i as string)) output
   check (cyrusBrushDab doc [0,0,200] [0,0,-1] true) "Bound snapshot painting hits hidden receiver" output
   local stats=cyrusBrushStats doc
   check (stats[2]>0 and stats[5]==1) "Paint is committed and status tick keeps brush active" output
   local probe=cyrusBrushProbe doc [center.x,center.y]
   check (probe!=undefined) "Painter screen hit test works with filtered surface" output
   cyrusBrushSettings doc 5 true
   check (cyrusBrushDab doc [0,0,200] [0,0,-1] true) "Erase works while surface is hidden" output
   cyrusBrushStop();cyrusSetSurfaceHidden target false
  )
  local target=targets[1]
  delete targets[2];delete targets[3]
  target.material=standardMaterial diffuse:(color 80 160 40) selfIllumAmount:100
  select target;max zoomext sel all;clearSelection()
  renderers.current=Default_Scanline_Renderer()
  local before=render outputwidth:64 outputheight:64 vfb:false
  local beforeSum=checksum before;close before
  cyrusSetSurfaceHidden target true
  local after=render outputwidth:64 outputheight:64 vfb:false
  local afterSum=checksum after;close after
  format "RENDER before % after %\n" beforeSum afterSum to:output
  check (length(beforeSum-afterSum)<0.01 and length beforeSum>1000) "Viewport filter leaves actual Scanline render unchanged" output
  check target.isHidden "Viewport hiding is restored after rendering" output
  hide target
  local refused=false
  try(cyrusBrushBegin (cyrusBrushCreate target))catch(refused=true)
  check refused "Ordinary Max Hide still blocks painting" output
  unhide target;target.isFrozen=true;refused=false
  try(cyrusBrushBegin (cyrusBrushCreate target))catch(refused=true)
  check refused "Frozen receiver still blocks painting" output
  target.isFrozen=false
  saveMaxFile (MCPFixtureDir+"surface-visibility.max") quiet:true
  loadMaxFile (MCPFixtureDir+"surface-visibility.max") quiet:true
  check (cyrusSurfaceHidden $Plane001 and $Plane001.isHidden) "Surface visibility preference survives save/reopen" output
  format "SUCCESS\n" to:output
 )catch(try(cyrusBrushStop())catch();format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
