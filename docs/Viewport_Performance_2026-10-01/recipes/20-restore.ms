(
 try(CSPStop "investigation_finished")catch()
 for callback in #(CVProfileDraw,CVBatchedDraw,CVBatchedPlumbingDraw,CVGestureDraw,CVAnalyzerNoFlush) where callback!=undefined do try(unRegisterRedrawViewsCallback callback)catch()
 CVBRestoreCallbacks()
 CVViewSettings.AdaptiveDegradeNeverDegradeGeometry=CVNeverDegrade
 for n in CVControllers do CSPWriteText (CVDir+"settings-restored-"+(n.handle as string)+".json") (CSPSettings n)
 CSPWriteText (CVDir+"pre-reload-state.json") (CSPObject #(#("object_count",objects.count),#("temporary_nodes",for n in objects where matchPattern n.name pattern:"CV_DIAGNOSTIC_*" collect n.name),#("preview_counts",CVBCounts()),#("node_events",AminScatterNodeEvents.enabled),#("analyzer_events",CyrusAnalyzerEvents.enabled)))
 if not (loadMaxFile "F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/SaveSelect 2.max" quiet:true useFileUnits:true) do throw "Could not reopen original scene"
 local f=createFile (CVDir+"restored-callbacks.txt")
 showRegisteredRedrawViewsCallbacks to:f
 close f
 CSPWriteText (CVDir+"restored-scene.json") (CSPObject #(#("scene",maxFilePath+maxFileName),#("dirty",getSaveRequired()),#("object_count",objects.count),#("viewport_type",viewport.getType() as string),#("viewport_tm",viewport.getTM() as string),#("never_degrade_geometry",(NitrousGraphicsManager.GetActiveViewportSetting()).AdaptiveDegradeNeverDegradeGeometry)))
 global CVShutdownTimer,CVShutdownTick
 fn CVShutdownTick sender args = (
  CVCommandTimer.Stop();dotNet.removeAllEventHandlers CVCommandTimer;CVCommandTimer.Dispose()
  CVShutdownTimer.Stop();dotNet.removeAllEventHandlers CVShutdownTimer;CVShutdownTimer.Dispose()
  CyrusPerfHeadless=undefined
  CSPWriteText (CVDir+"cleanup-complete.txt") "Original scene reopened, temporary callbacks removed, local command timers disposed. No save performed."
 )
 CVShutdownTimer=dotNetObject "System.Windows.Forms.Timer"
 CVShutdownTimer.Interval=1000
 dotNet.addEventHandler CVShutdownTimer "Tick" CVShutdownTick
 CVShutdownTimer.Start()
)
