(
 unRegisterRedrawViewsCallback R2GestureDraw
 CVBOriginalScatter=R2CandidateDraw;CVBRestoreCallbacks()
 viewport.setTM CVOriginalView;max select;redrawViews()
 local writer=CSPWriter (CVDir+"gestures.csv") "phase,scatter_callback_ms"
 for row in R2GestureRows do CSPRow writer row
 writer.Dispose()
 CSPWriteText (CVDir+"gesture-counts.json") (CSPObject #(#("before",R2GestureBefore),#("after",CVBCounts())))
)
