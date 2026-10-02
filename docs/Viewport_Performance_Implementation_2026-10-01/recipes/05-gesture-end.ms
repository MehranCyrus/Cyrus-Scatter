(
unRegisterRedrawViewsCallback VPGestureDraw
CVBRestoreCallbacks();cyrusPreviewBatchDrawing true
viewport.setTM CVOriginalView
max select
redrawViews()
local writer=CSPWriter (CVDir+"gestures.csv") "phase,scatter_callback_ms"
for row in VPGestureRows do CSPRow writer row
writer.Dispose()
CSPWriteText (CVDir+"gesture-counts.json") (CSPObject #(#("before",VPGestureBefore),#("after",CVBCounts())))
)
