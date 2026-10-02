global VPGestureRows=#(),VPGesturePhase="legacy",VPGestureDraw,VPGestureBefore=CVBCounts()
try(unRegisterRedrawViewsCallback VPGestureDraw)catch()
fn VPGestureDraw = (
 local held=CyrusInteractionHeld(),clock=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
 VPProductionDraw()
 clock.Stop()
 if held do append VPGestureRows #(VPGesturePhase,clock.Elapsed.TotalMilliseconds)
)
CVBRestoreCallbacks();unRegisterRedrawViewsCallback VPProductionDraw
registerRedrawViewsCallback VPGestureDraw
cyrusPreviewBatchDrawing false
max truck
CSPWriteText (CVDir+"gesture-ready.txt") "Legacy native drawing; pan tool active."
