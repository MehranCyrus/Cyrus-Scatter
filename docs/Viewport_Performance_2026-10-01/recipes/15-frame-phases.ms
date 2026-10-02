try (
 CVBCallbacks()
 local rows=#()
 for i=1 to 60 do (
  CVBScatterMS=0.0d0;CVBAnalyzerMS=0.0d0;CVBScatterCalls=0;CVBAnalyzerCalls=0
  local c=CVBClockClass.StartNew()
  viewport.setTM ((rotateZMatrix (6*cos(i*6.0)))*CVOriginalView)
  local setTime=c.Elapsed.TotalMilliseconds,setCalls=CVBScatterCalls
  redrawViews()
  local redrawTime=c.Elapsed.TotalMilliseconds,redrawCalls=CVBScatterCalls
  windows.processPostedMessages()
  c.Stop()
  append rows #(i,setTime,redrawTime-setTime,c.Elapsed.TotalMilliseconds-redrawTime,setCalls,redrawCalls-setCalls,CVBScatterCalls-redrawCalls)
 )
 local w=CSPWriter (CVDir+"frame-phases.csv") "frame,set_tm_ms,redraw_ms,pump_ms,set_tm_callbacks,redraw_callbacks,pump_callbacks"
 for row in rows do CSPRow w row
 w.Dispose()
 CVBFrameRows=#();CVBCaseRows=#();makeDir (CVDir+"stationary")
 for r=1 to 3 do CVBRunCase "stationary_redraw" frames:40 warmup:6 repeat:r move:false
 CVBWrite (CVDir+"stationary")
 CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
)catch(
 try(CVBRestoreCallbacks())catch()
 CSPWriteText (CVDir+"phases-error.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace()))
)
