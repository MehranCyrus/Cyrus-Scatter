-- The driver binds installer-remediation-config.json in qualification.json.
-- All file destinations and the Max process must belong to the owned profile.
-- I02/I04 reject stale helpers before any Analyzer/Scatter installation action.
if (maxVersion())[1]!=29000 do throw "Installer remediation requires the owned Max 2027 host"
python.ExecuteFile ((getFilenamePath(getSourceFileName()))+"installer_remediation.py")
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
if QScenarioID=="R7-I03" do (
    QSetup analyzer:true
    QLayer.areaAnalyzer=QGuide;QLayer.areaUseLine=true;QLayer.areaLineWidth=80
    QCalculate()
    local runs=QAnalyzer.getAnalysisRuns()
    QAnalyzer.fitRadius=30
    QRequire (not QAnalyzer.analysisCurrent()) "Analyzer edit did not become pending"
    QAnalyzer.runAnalysis();QCalculate()
    QAssert (QAnalyzer.getAnalysisRuns()==runs+1 and QAnalyzer.analysisCurrent() and QRoot.groupSnapshotRows[1].count>0) "R7-I03-03" "Installed paired Analyzer explicitly analyzes, then Manual Scatter Update consumes a complete result after restart"
)
