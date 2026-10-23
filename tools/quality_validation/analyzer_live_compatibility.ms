-- Explicit successor to the fixed 900 ms witness. Observe bounded settlement
-- without flushing the input queue or calling Analyze to manufacture progress.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
global QAwaitAnalyzer
fn QAwaitAnalyzer expected = (
 local start=timeStamp(),held=false
 while timeStamp()-start<5000 and ((QAnalyzer.getAnalysisRuns())<expected or QAnalyzer.livePending() or CyrusAnalyzerTimer.Enabled) do (
  held=held or ((dotNetClass "System.Windows.Forms.Control").MouseButtons!=(dotNetClass "System.Windows.Forms.MouseButtons").None)
  QSettle 50
 )
 QRequire ((QAnalyzer.getAnalysisRuns())==expected and not QAnalyzer.livePending() and not CyrusAnalyzerTimer.Enabled) "Bounded Live settlement did not complete exactly once"
 QRequire (QAnalyzer.analysisCurrent()) "Settled Analyzer was stale"
 QSettle 600
 QRequire ((QAnalyzer.getAnalysisRuns())==expected and not CyrusAnalyzerTimer.Enabled and QAnalyzer.analysisCurrent()) "Settled Analyzer repeated or became stale"
 #(timeStamp()-start,held)
)
(
 QSetup analyzer:true
 local before=QAnalyzer.getAnalysisRuns(),timings=#()
 QAnalyzer.updateMode=2;QAnalyzer.resolution=72;append timings (QAwaitAnalyzer (before+1))
 before=QAnalyzer.getAnalysisRuns();local unrelated=box pos:[2000,0,0];unrelated.pos.x+=10;QSettle 700
 QRequire (QAnalyzer.getAnalysisRuns()==before and not CyrusAnalyzerTimer.Enabled) "Unrelated edit reanalyzed"
 local parentNode=point name:"Q bounded receiver parent";QSurface.parent=parentNode
 local deadline=timeStamp()+5000
 while timeStamp()<deadline and (QAnalyzer.livePending() or CyrusAnalyzerTimer.Enabled) do QSettle 50
 QSettle 600;before=QAnalyzer.getAnalysisRuns();parentNode.pos.x+=10
 append timings (QAwaitAnalyzer (before+1))
 with animate on (at time 0 parentNode.pos=[10,0,0];at time 10 parentNode.pos=[30,0,0])
 QSettle 1200;before=QAnalyzer.getAnalysisRuns();sliderTime=5
 append timings (QAwaitAnalyzer (before+1))
 QAssert true (QScenarioID+"-01") ("Live relevant changes settle once, unrelated edits stay idle; elapsed milliseconds/mouse-held samples: "+timings as string)
)
