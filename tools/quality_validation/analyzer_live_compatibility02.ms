-- Top-level message-pump witness for the legacy host. It does not trigger the
-- input queue or call Analyze to manufacture progress, and claims no UI latency.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
(
 QSetup analyzer:true
 local before=QAnalyzer.getAnalysisRuns(),timings=#(),started=timeStamp()
 QAnalyzer.updateMode=2;QAnalyzer.resolution=72
 for i=1 to 10 while QAnalyzer.getAnalysisRuns()==before or CyrusAnalyzerTimer.Enabled do QSettle 300
 QRequire (QAnalyzer.getAnalysisRuns()==before+1 and not CyrusAnalyzerTimer.Enabled and QAnalyzer.analysisCurrent()) "Resolution did not settle exactly once"
 append timings (timeStamp()-started)
 before=QAnalyzer.getAnalysisRuns();local unrelated=box pos:[2000,0,0];unrelated.pos.x+=10;QSettle 900
 QRequire (QAnalyzer.getAnalysisRuns()==before and not CyrusAnalyzerTimer.Enabled) "Unrelated edit reanalyzed"
 local parentNode=point name:"Q bounded receiver parent";QSurface.parent=parentNode;QSettle 1200
 before=QAnalyzer.getAnalysisRuns();started=timeStamp();parentNode.pos.x+=10
 for i=1 to 10 while QAnalyzer.getAnalysisRuns()==before or CyrusAnalyzerTimer.Enabled do QSettle 300
 QRequire (QAnalyzer.getAnalysisRuns()==before+1 and not CyrusAnalyzerTimer.Enabled and QAnalyzer.analysisCurrent()) "Parent transform did not settle exactly once"
 append timings (timeStamp()-started);QSettle 900
 QRequire (QAnalyzer.getAnalysisRuns()==before+1 and not CyrusAnalyzerTimer.Enabled) "Parent transform repeated after settlement"
 with animate on (at time 0 parentNode.pos=[10,0,0];at time 10 parentNode.pos=[30,0,0])
 QSettle 1200;before=QAnalyzer.getAnalysisRuns();started=timeStamp();sliderTime=5
 for i=1 to 10 while QAnalyzer.getAnalysisRuns()==before or CyrusAnalyzerTimer.Enabled do QSettle 300
 QRequire (QAnalyzer.getAnalysisRuns()==before+1 and not CyrusAnalyzerTimer.Enabled and QAnalyzer.analysisCurrent()) "Relevant animation did not settle exactly once"
 append timings (timeStamp()-started);QSettle 900
 QRequire (QAnalyzer.getAnalysisRuns()==before+1 and not CyrusAnalyzerTimer.Enabled) "Relevant animation repeated after settlement"
 QAssert true (QScenarioID+"-01") ("Relevant changes settle once and unrelated edits stay idle; observed milliseconds: "+timings as string)
)
