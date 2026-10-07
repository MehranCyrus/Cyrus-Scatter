-- Current sole-model assignment consumes a real, matching Analyzer publication.
global U73AnalyzerAssignment
fn U73AnalyzerAssignment = (
    P07Checks=#();P07Case="unified Analyzer assignment";P07New count:1000
    local r=P07Root,a=P07Layer,s=P07Source
    local node=CyrusSurfaceAnalyzer name:"U73_Assignment_Analyzer",analyzer=node.baseObject
    analyzer.surface=P07Surface;analyzer.resolution=48;analyzer.pointRadius=10
    analyzer.fitRadius=20;analyzer.relaxIterations=0;analyzer.updateMode=1
    analyzer.runAnalysis()
    P07Assert (analyzer.boundaryVertices.count>0) "Analyzer has no published boundary"
    a.diversityMode=4;a.analyzerNode=node;a.patternLines=#(node)
    -- Side 2 is the inside border. The receiver equals this boundary, so
    -- the outside-border channel correctly has no receiving surface here.
    a.patternWidths=#(80.0);a.strokeSides=#(2);a.strokeModes=#(2)
    a.strokeSourceRows=#(1);a.strokeSourceNodes=#(s);a.strokeMin=#(.8);a.strokeMax=#(1.2)
    local other=box name:"U73_Assignment_Other" width:4 length:4 height:6 pos:[1200,30,0]
    local b=r.addPaintSet a label:"Unassigned";b.sources=#(other);b.paintEnabled=false
    local rows=r.evaluateGroups()
    P07Record "analyzer_border_probe" #((for v in rows collect v.count),analyzer.boundaryVertices.count)
    P07Assert (rows[1].count>0 and rows[2].count==0) "Analyzer band source choices leaked across sets"
    local first=rows[1].count
    -- Fixed edge anchors must survive an enlarged requested prefix.
    a.strokeSides=#(7);a.patternWidths=#(100.0);rows=r.evaluateGroups()
    P07Assert (rows[1].count>4 and rows[2].count==0) "Analyzer edge anchors were gated or assigned to a missing source"
    local ids=for row in rows[1] collect row[3],positions=for row in rows[1] collect row[1].row4
    a.amount=1200;rows=r.evaluateGroups()
    for i=1 to ids.count do (
        local matches=for row in rows[1] where row[3]==ids[i] collect row
        P07Assert (matches.count==1 and distance matches[1][1].row4 positions[i]<.0001) "Analyzer anchor identity changed with population"
    )
    local fingerprint=P07Fingerprint r,builds=(a.procStatistics())[3],runs=analyzer.getAnalysisRuns()
    P07Assert ((P07Fingerprint r) as string==fingerprint as string and (a.procStatistics())[3]==builds and analyzer.getAnalysisRuns()==runs) "Cached assignment did extra preparation/analysis"
    local scene=MCPFixtureDir+"Unified073-Analyzer-Assignment.max"
    saveMaxFile scene quiet:true;loadMaxFile scene quiet:true
    local reopened=(getNodeByName "P07_Controller").baseObject
    P07Assert ((P07Fingerprint reopened) as string==fingerprint as string) "Analyzer assignment changed after reopen"
    P07Record "analyzer_assignment" #(first,ids.count,runs,scene)
    true
)
