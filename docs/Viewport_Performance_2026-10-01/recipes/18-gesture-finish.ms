(
 unRegisterRedrawViewsCallback CVGestureDraw
 local w=CSPWriter (CVDir+"mouse-drags.csv") "phase,elapsed_ms,scatter_callback_ms,mouse_held,reported_fps_unverified"
 for row in CVGestureRows do CSPRow w row
 w.Dispose()
 CSPWriteText (CVDir+"mouse-drag-counts.json") (CSPObject #(#("before",CVGestureBefore),#("after",CVBCounts()),#("method","Two forward/back pan drags per condition via Windows app UI; variable input pacing, corroboration only")))
 CVBRestoreCallbacks()
 viewport.setTM CVOriginalView
 max select
 redrawViews()
)
