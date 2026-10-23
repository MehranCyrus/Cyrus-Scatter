fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/edit_0869/edit_workflow.ms"
global PRRun,UI91OldScene
fn PRRun scenario = (
 case scenario of (
  "old_scene": (
   loadMaxFile UI91OldScene quiet:true useFileUnits:true
   QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.layerObjects[1]
   local modifier=QNode.modifiers[QNode.modifiers.count],before=EWAuthored modifier
   local radiusBefore=for leaf in QRoot.layerObjects collect #((leaf.procRadiusIDs as array),(leaf.procRadiusModes as array),(leaf.procRadiusValues as array),(leaf.procRadiusDistances as array),leaf.procRadiusBinding)
   QRequire (before.count>=3 and QLayer.procRadiusIDs.count>0) "Prior-version fixture lacks authored edits/radii"
   QRoot.updateMode=1;CyrusPointSuspended=true;QCalculate()
   QAssert (EWNear (EWAuthored modifier) before) "old_edits" "A saved 0.86.9 scene retains every moved/deleted/cloned source-aware edit when evaluated by 0.86.9.1."
   local radiusAfter=for leaf in QRoot.layerObjects collect #((leaf.procRadiusIDs as array),(leaf.procRadiusModes as array),(leaf.procRadiusValues as array),(leaf.procRadiusDistances as array),leaf.procRadiusBinding)
   QAssert (EWNear radiusAfter radiusBefore) "old_radii" "The prior scene's IDs, radius modes/values, distances and binding remain intact."
  )
  "analyzer": (
   QSetup analyzer:true;QLayer.areaAnalyzer=QGuide;QLayer.areaUseLine=true;QLayer.areaLineWidth=80;QCalculate()
   local runs=QAnalyzer.getAnalysisRuns();QAnalyzer.fitRadius=30;QAnalyzer.runAnalysis();QCalculate()
   QAssert (QAnalyzer.getAnalysisRuns()==runs+1 and QAnalyzer.analysisCurrent() and QRoot.groupSnapshotRows[1].count>0) "analyzer_bridge" "The included Analyzer 0.14.2 completes a new analysis consumed by Scatter 0.86.9.1."
  )
  default:throw "Unknown preservation case"
 )
)
