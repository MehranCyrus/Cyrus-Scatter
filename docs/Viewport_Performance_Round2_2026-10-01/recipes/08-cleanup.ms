(
 for callback in #(R2GestureDraw,R2ProfileDraw,R2FastDraw) where callback!=undefined do try(unRegisterRedrawViewsCallback callback)catch()
 CyrusInteractionHeld=R2RealInteraction
 CVBOriginalScatter=R2CandidateDraw
 CVBRestoreCallbacks()
 cyrusPreviewBatchDrawing true
 viewport.setTM CVOriginalView
 CVViewSettings.AdaptiveDegradeNeverDegradeGeometry=CVNeverDegrade
 max select
 redrawViews()
 local callbacks=createFile (CVDir+"restored-callbacks.txt")
 showRegisteredRedrawViewsCallbacks to:callbacks
 close callbacks
 CSPWriteText (CVDir+"session-final.json") (CSPObject #(#("scene",maxFilePath+maxFileName),#("max_version",maxVersion()),#("renderer",classof renderers.current as string),#("object_count",objects.count),#("counts",CVBCounts()),#("batch_drawing",cyrusPreviewBatchDrawing()),#("never_degrade_geometry",CVViewSettings.AdaptiveDegradeNeverDegradeGeometry),#("node_events",AminScatterNodeEvents.enabled),#("analyzer_events",CyrusAnalyzerEvents.enabled)))
 global CVShutdownTimer,CVShutdownTick
 fn CVShutdownTick sender args = (
  CVCommandTimer.Stop();dotNet.removeAllEventHandlers CVCommandTimer;CVCommandTimer.Dispose()
  CVShutdownTimer.Stop();dotNet.removeAllEventHandlers CVShutdownTimer;CVShutdownTimer.Dispose()
  CyrusPerfHeadless=undefined
  CSPWriteText (CVDir+"cleanup-complete.txt") "0.62 production callbacks and camera restored; adaptive degradation restored; command timers disposed. Disposable scene remains open in the isolated round-two session. No scene save or user-profile installation performed."
 )
 CVShutdownTimer=dotNetObject "System.Windows.Forms.Timer"
 CVShutdownTimer.Interval=1000
 dotNet.addEventHandler CVShutdownTimer "Tick" CVShutdownTick
 CVShutdownTimer.Start()
)
