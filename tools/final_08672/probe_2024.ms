(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2024/" do throw "Owned host required"
 local output=createFile (MCPFixtureDir+"probe-2024.txt")
 try(
  cyrusBrushStop()
  local target=$Sphere001
  cyrusSetSurfaceHidden target false
  select target;max zoomext sel all;completeRedraw()
  gw.setTransform (matrix3 1)
  local center=gw.wTransPoint target.pos,size=getViewSize()
  format "VIEW size % center % target % tm %\n" size center target.pos (viewport.getTM()) to:output;flush output
  local document=cyrusBrushCreate target
  for hidden in #(false,true) do (
   cyrusSetSurfaceHidden target hidden
   cyrusBrushBegin document
   for xy in #([center.x,center.y],[size.x/2,size.y/2],[center.x/2,center.y/2],[center.x*2,center.y*2]) do (
    local result=cyrusBrushProbe document xy
    format "hidden % xy % hit %\n" hidden xy result to:output;flush output
   )
   cyrusBrushStop()
  )
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
