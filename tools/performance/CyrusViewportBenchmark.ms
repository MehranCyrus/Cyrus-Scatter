-- Investigation harness: synchronous navigation/redraw wall time, not GPU fences.
-- Load CyrusPerformanceMonitor.ms headlessly first for its JSON/CSV helpers.
-- Runs only when CVBRunCase is explicitly called. No scene save or installation.
global CVBOriginalScatter,CVBOriginalAnalyzer,CVBScatterWrapper,CVBAnalyzerWrapper
global CVBCallbacks,CVBCounts,CVBRunCase,CVBWrite,CVBRestoreCallbacks
try(unRegisterRedrawViewsCallback CVBScatterWrapper)catch()
try(unRegisterRedrawViewsCallback CVBAnalyzerWrapper)catch()
global CVBScatterMS=0.0d0,CVBAnalyzerMS=0.0d0,CVBScatterCalls=0,CVBAnalyzerCalls=0
global CVBFrameRows=#(),CVBCaseRows=#(),CVBBaseTM,CVBControllers,CVBAnalyzers
global CVBClockClass=dotNetClass "System.Diagnostics.Stopwatch"
CVBOriginalScatter=AminScatterObjectDraw
CVBOriginalAnalyzer=CyrusSurfaceAnalyzerDraw
fn CVBScatterWrapper = (
 local c=CVBClockClass.StartNew()
 CVBOriginalScatter()
 c.Stop();CVBScatterMS+=c.Elapsed.TotalMilliseconds;CVBScatterCalls+=1
)
fn CVBAnalyzerWrapper = (
 local c=CVBClockClass.StartNew()
 CVBOriginalAnalyzer()
 c.Stop();CVBAnalyzerMS+=c.Elapsed.TotalMilliseconds;CVBAnalyzerCalls+=1
)
fn CVBCallbacks scatter:true analyzer:true instrument:true = (
 unRegisterRedrawViewsCallback CVBOriginalScatter
 unRegisterRedrawViewsCallback CVBOriginalAnalyzer
 unRegisterRedrawViewsCallback CVBScatterWrapper
 unRegisterRedrawViewsCallback CVBAnalyzerWrapper
 if scatter do registerRedrawViewsCallback (if instrument then CVBScatterWrapper else CVBOriginalScatter)
 if analyzer do registerRedrawViewsCallback (if instrument then CVBAnalyzerWrapper else CVBOriginalAnalyzer)
)
fn CVBCounts = (
 local counts=#()
 for n in CVBControllers do for i=1 to n.layerObjects.count do (
  local l=n.layerObjects[i],s=l.cacheSnapshot()
  append counts #(n.handle,i,n.layerNames[i],n.layerEnabled[i],l.viewportMode,s[5],s[2],try(cyrusPreviewFaces s[1])catch(0),s[6],s[3],s[4],l.radiusDisplayCount())
 )
 counts
)
fn CVBRunCase label frames:30 warmup:5 repeat:1 move:true = (
 local before=CVBCounts(),analyzerBefore=for n in CVBAnalyzers collect n.getAnalysisRuns()
 local pfBefore=try(CyrusPFBuilds)catch(-1)
 viewport.setTM CVBBaseTM
 for f=1 to warmup do (if move do viewport.setTM ((rotateZMatrix (-6.0+12.0*f/warmup))*CVBBaseTM);redrawViews();windows.processPostedMessages())
 local beforeMeasured=CVBCounts(),analyzerMeasured=for n in CVBAnalyzers collect n.getAnalysisRuns()
 local localRows=#()
 for f=1 to frames do (
  CVBScatterMS=0.0d0;CVBAnalyzerMS=0.0d0;CVBScatterCalls=0;CVBAnalyzerCalls=0
  local c=CVBClockClass.StartNew()
  if move do (
   local angle=6.0*cos(360.0*(f-1)/(amax 1 (frames-1)))
   if not (viewport.setTM ((rotateZMatrix angle)*CVBBaseTM)) do throw "Viewport transform was not applied"
  )
  redrawViews()
  windows.processPostedMessages()
  c.Stop()
  append localRows #(label,repeat,f,c.Elapsed.TotalMilliseconds,CVBScatterMS,CVBAnalyzerMS,CVBScatterCalls,CVBAnalyzerCalls,try(viewport.GetFPS())catch(undefined))
 )
 join CVBFrameRows localRows
 append CVBCaseRows #(#("label",label),#("repeat",repeat),#("move",move),#("frames",frames),#("warmup",warmup),#("before_warmup",before),#("before_measured",beforeMeasured),#("after_measured",CVBCounts()),#("analyzer_before",analyzerBefore),#("analyzer_before_measured",analyzerMeasured),#("analyzer_after",for n in CVBAnalyzers collect n.getAnalysisRuns()),#("pflow_before",pfBefore),#("pflow_after",try(CyrusPFBuilds)catch(-1)),#("viewport_size",#(gw.getWinSizeX(),gw.getWinSizeY())),#("viewport_count",viewport.numViews))
 viewport.setTM CVBBaseTM
 true
)
fn CVBWrite folder = (
 local w=CSPWriter (folder+"/frames.csv") "case,repeat,frame,wall_ms,scatter_callback_ms,analyzer_callback_ms,scatter_calls,analyzer_calls,reported_fps_unverified"
 for row in CVBFrameRows do CSPRow w row
 w.Dispose()
 local text="["
 for i=1 to CVBCaseRows.count do (if i>1 do text+=",";text+=CSPObject CVBCaseRows[i])
 CSPWriteText (folder+"/cases.json") (text+"]")
)
fn CVBRestoreCallbacks = (CVBCallbacks instrument:false)
