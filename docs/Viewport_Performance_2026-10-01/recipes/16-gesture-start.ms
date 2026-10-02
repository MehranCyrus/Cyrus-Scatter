global CVGestureRows=#(),CVGesturePhase="scatter_on",CVGestureDraw,CVGestureClock=CVBClockClass.StartNew(),CVGestureBefore=CVBCounts()
fn CVGestureDraw = (
 local held=CyrusInteractionHeld(),begin=CVGestureClock.Elapsed.TotalMilliseconds
 local c=CVBClockClass.StartNew()
 if CVGesturePhase=="scatter_on" do CVBOriginalScatter()
 c.Stop()
 append CVGestureRows #(CVGesturePhase,begin,c.Elapsed.TotalMilliseconds,held,try(viewport.GetFPS())catch(undefined))
)
CVBCallbacks scatter:false analyzer:true
registerRedrawViewsCallback CVGestureDraw
max truck
CSPWriteText (CVDir+"gesture-ready.txt") "Pan tool active; callback timing records only normal UI navigation."
