(
 global CVBCallbacks,CVBRunCase,CVBWrite,CVBRestoreCallbacks
 fileIn "F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/performance/CyrusViewportBenchmark.ms"
 CVBControllers=CVControllers;CVBAnalyzers=CVAnalyzers;CVBBaseTM=CVOriginalView
 makeDir (CVDir+"pilot")
 CVBCallbacks()
 CVBRunCase "original_realtime" frames:20 warmup:3
 CVBWrite (CVDir+"pilot")
 CVBCallbacks scatter:false
 CVBRunCase "scatter_callback_off" frames:20 warmup:3
 CVBWrite (CVDir+"pilot")
 CVBCallbacks analyzer:false
 CVBRunCase "analyzer_callback_off" frames:20 warmup:3
 CVBWrite (CVDir+"pilot")
 CVBCallbacks scatter:false analyzer:false
 CVBRunCase "both_callbacks_off" frames:20 warmup:3
 CVBWrite (CVDir+"pilot")
 CVBRestoreCallbacks()
 viewport.setTM CVOriginalView
 redrawViews()
)
