global R2GestureRows=#(),R2GesturePhase="061",R2GestureOriginal=R2LegacyDraw,R2GestureDraw,R2GestureBefore=CVBCounts()
fn R2GestureDraw = (
 local held=CyrusInteractionHeld(),timer=CVBClockClass.StartNew()
 R2GestureOriginal()
 timer.Stop()
 if held do append R2GestureRows #(R2GesturePhase,timer.Elapsed.TotalMilliseconds)
)
CVBCallbacks scatter:false
registerRedrawViewsCallback R2GestureDraw
viewport.setTM CVOriginalView
max truck
CSPWriteText (CVDir+"gesture-ready.txt") "0.61 callback; real mouse pan enabled."
