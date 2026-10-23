fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
QSetup analyzer:true
case QScenarioID of (
 "R1-M01": (
    QRequire (not isProperty QGuide #analysisCurrent) "This reproduction requires the preserved old Analyzer pair"
    local old=QFingerprint(),epoch=QRoot.procEpoch,error=""
    QLayer.diversityMode=4;QLayer.analyzerNode=QGuide
    try(QCalculate())catch(error=getCurrentException())
    QRequire (matchPattern error pattern:"*matching Surface Analyzer*") "Old pair did not reject with compatibility guidance"
    QRequire (QFingerprint()==old and QRoot.procEpoch==epoch) "Compatibility failure changed publication"
 )
 "R1-M02": (
    QRequire (cyrusAnalyzerContractVersion()==1 and isProperty QGuide #analysisCurrent) "Matching Analyzer capability missing"
    QRequire (QAnalyzer.analysisCurrent()) "Fresh result was stale"
 )
 "R1-M03": (
    QLayer.diversityMode=4;QLayer.analyzerNode=QGuide;QMount()
    local band=QLayer.addStroke QGuide side:2;QLayer.patternWidths[band]=60
    QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1]);QCalculate()
    QRoot.bindNativeUI();QSettle 200
    QRequire (QRoot.groupSnapshotRows[1].count>0) "Analyzer border has no output"
    for side in #(3,4,5,7) do (
        QLayer.removeStroke band;band=QLayer.addStroke QGuide side:side;QLayer.patternWidths[band]=60
        QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1]);QCalculate()
        QRequire (QRoot.groupSnapshotRows[1].count>0) ("Analyzer channel has no output: "+side as string)
    )
    local before=QAnalyzer.getAnalysisRuns();QClick QRoot.layoutUI.diversityUI_updateAnalyzer
    QRequire (QAnalyzer.getAnalysisRuns()==before+1) ("Actual Analyze button did not run once: "+QRoot.layoutUI.diversityUI_analyzerStatus.text)
    QClick QRoot.layoutUI.diversityUI_selectAnalyzer;QRequire (selection.count==1 and selection[1]==QGuide) "Select Analyzer targeted a different node"
 )
 "R1-M04": (
    for kind in #(1,2,3) do (
        QLayer.areaAnalyzer=QGuide;QLayer.areaUseLine=(kind==1);QLayer.areaUsePoints=(kind==2)
        QLayer.areaLineWidth=80;QLayer.areaPointRadius=45;QLayer.fallAnalyzer=QGuide;QLayer.fallDelete=(kind==3);QLayer.fallDeleteWidth=50
        QCalculate();QRequire (QRoot.groupSnapshotRows[1].count>0 and QRoot.groupSnapshotRows[1].count<400) "Analyzer mask/falloff failed"
    )
 )
 "R1-M05": (
    QLayer.areaAnalyzer=QGuide;QLayer.areaUseLine=true;QCalculate()
    local before=QFingerprint(),epoch=QRoot.procEpoch,runs=QAnalyzer.getAnalysisRuns(),error=""
    QAnalyzer.fitRadius=30;QRequire (not QAnalyzer.analysisCurrent()) "Pending guide stayed fresh"
    QCalculate();QRequire (QFingerprint()==before and QAnalyzer.getAnalysisRuns()==runs) "Cached read implicitly analyzed"
    QLayer.amount=500;try(QCalculate())catch(error=getCurrentException())
    QRequire (matchPattern error pattern:"*out of date*") "Stale successor accepted"
    QRequire (QRoot.procEpoch==epoch and QFingerprint()==before) "Stale rejection lost previous result"
    QAnalyzer.runAnalysis();QCalculate()
 )
 "R1-M06": (
    local before=QAnalyzer.getAnalysisRuns();QAnalyzer.updateMode=2;QAnalyzer.resolution=72;QSettle 900
    QRequire (QAnalyzer.getAnalysisRuns()==before+1 and not CyrusAnalyzerTimer.Enabled) "Real-time did not settle exactly once"
    before=QAnalyzer.getAnalysisRuns();local unrelated=box pos:[2000,0,0];unrelated.pos.x+=10;QSettle 700
    QRequire (QAnalyzer.getAnalysisRuns()==before and not CyrusAnalyzerTimer.Enabled) "Unrelated edit reanalyzed"
    local parentNode=point name:"Q animated receiver parent";QSurface.parent=parentNode;QSettle 900
    before=QAnalyzer.getAnalysisRuns();parentNode.pos.x+=10;QSettle 900
    QRequire (QAnalyzer.getAnalysisRuns()==before+1 and QAnalyzer.analysisCurrent()) "Relevant parent transform did not settle once"
    with animate on (at time 0 parentNode.pos=[10,0,0];at time 10 parentNode.pos=[30,0,0])
    QSettle 900;before=QAnalyzer.getAnalysisRuns();sliderTime=5;QSettle 900
    QRequire (QAnalyzer.getAnalysisRuns()==before+1 and QAnalyzer.analysisCurrent() and not CyrusAnalyzerTimer.Enabled) "Relevant animation did not settle once"
 )
 "R1-M07": (
    local old=QAnalyzer.fitRadius,oldGuides=QAnalyzer.boundaryVertices as array
    undo "Q Analyzer settings and Analyze" on (QAnalyzer.fitRadius=30;QAnalyzer.runAnalysis())
    max undo;QRequire (QAnalyzer.fitRadius==old and QAnalyzer.boundaryVertices as string==oldGuides as string) "Analyzer Undo changed its prior state"
    max redo;QRequire (QAnalyzer.fitRadius==30 and QAnalyzer.analysisCurrent()) "Analyzer Redo freshness failed"
 )
 "R1-M08": (
    local scene=MCPFixtureDir+"analyzer-fresh.max"
    saveMaxFile scene quiet:true;resetMaxFile #noPrompt;units.SystemType=#centimeters;loadMaxFile scene quiet:true
    QGuide=getNodeByName "Q Analyzer";QAnalyzer=QGuide.baseObject;QRequire (QAnalyzer.analysisCurrent()) "Saved-unit freshness lost"
    QAnalyzer.fitRadius=30;saveMaxFile (MCPFixtureDir+"analyzer-pending.max") quiet:true
    resetMaxFile #noPrompt;units.SystemType=#centimeters;loadMaxFile (MCPFixtureDir+"analyzer-pending.max") quiet:true
    QRequire (not (getNodeByName "Q Analyzer").analysisCurrent()) "Pending freshness fabricated on reopen"
 )
 "R1-M09": (
    local before=QAnalyzer.boundaryVertices as string,error="",invalid=box()
    QAnalyzer.surface=invalid;try(QAnalyzer.runAnalysis())catch(error=getCurrentException())
    QRequire (error!="" and QAnalyzer.boundaryVertices as string==before) "Invalid receiver lost guides"
    QAnalyzer.surface=QSurface;QAnalyzer.runAnalysis();QRequire (QAnalyzer.analysisCurrent()) "Analyzer did not recover"
 )
 default: throw ("This scenario needs its separate installer/legacy-profile driver: "+QScenarioID)
)
QAssert true (QScenarioID+"-01") "Analyzer scenario completed with all required checks"
