-- Same scene/workload for frozen 0.76 and 0.77. Owned host only.
global B77Compare
fn B77Compare = (
 LRSetup();local r=LRRoot,a=LRLayer
 r.setLayerSurfaces a #(LRPlane)
 local area=r.addPaintArea a target:LRPlane,d=area.paintDocument
 cyrusBrushDisplay d 2 (color 100 200 100)
 for i=1 to 1000 do (
  cyrusBrushSettings d 18 .35 .6 (mod i 4==0) 1
  cyrusBrushDab d [0,0,200] [0,0,-1] true
 )
 cyrusBrushBegin d;cyrusBrushRefreshMask d
 local times=#(),wall=#(),watch=dotNetObject "System.Diagnostics.Stopwatch"
 cyrusBrushSettings d 18 .35 .6 false 1
 for i=1 to 10 do (
  watch.Restart();cyrusBrushDab d [0,0,200] [0,0,-1] true;cyrusBrushRefreshMask d;watch.Stop()
  append times (cyrusBrushStats d)[13];append wall watch.Elapsed.TotalMilliseconds
 )
 local stats=cyrusBrushStats d,fp=cyrusEditFingerprint (cyrusBrushRows d) "feedback-comparison"
 if stats[2]!=1010 or stats[19]==0 or stats[18]!=0 do throw "Feedback comparison setup invalid"
 cyrusBrushStop()
 CSPWriteText (MCPFixtureDir+"paint-comparison.json") (CSPObject #(#("version",r.uiVersion()),#("evaluation_ms",times),#("dab_and_refresh_ms",wall),#("tint_faces",stats[19]),#("rows_fingerprint",fp)))
 true
)
