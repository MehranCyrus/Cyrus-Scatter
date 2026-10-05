-- Disposable runtime campaign. Call only through the private fixture launcher.
global P07Checks,P07Case,P07Node,P07Root,P07Layer,P07Source,P07Surface
global P07Assert,P07Record,P07New,P07Fingerprint,P07Acceptance
global CyrusProcedural07Fixture
fn P07Assert ok message = (if not ok do throw ("["+P07Case+"] "+message);true)
fn P07Record name data = (
    append P07Checks #(name,data)
    CSPWriteText (MCPFixtureDir+"procedural-acceptance.json") (CSPObject P07Checks)
)
fn P07Fingerprint root = (for rows in root.evaluateGroups() collect cyrusEditFingerprint rows "proc07")
fn P07New count:1000 curved:false = (
    cyrusBrushStop();resetMaxFile #noPrompt
    P07Surface=if curved then sphere name:"P07_Receiver" radius:100 segs:40 else plane name:"P07_Receiver" width:1000 length:1000 widthsegs:12 lengthsegs:12
    P07Source=cone name:"P07_Asset" radius1:4 radius2:0 height:20 sides:8 heightsegs:1 pos:[1200,0,0]
    hide P07Source
    P07Node=AminScatterObject name:"P07_Controller";P07Root=P07Node.baseObject
    P07Root.setLayerTransfer true
    P07Root.autoRender=false;P07Root.updateMode=1;P07Root.surfaceNodes=#(P07Surface);P07Root.newLayer()
    P07Layer=P07Root.selectedLayer();P07Layer.amount=count;P07Layer.sources=#(P07Source);P07Layer.sourceWeights=#(1.0);P07Layer.paintEnabled=false;P07Layer.randomSeed=42
    P07Root.setLayerTransfer false;P07Root.procUpgrade();P07Root.evaluateGroups()
    P07Root
)
fn P07Acceptance = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private qualification session required."
    P07Checks=#()
    P07Case="core fixture"
    resetMaxFile #noPrompt
    fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\procedural_lab\Max_Procedural_07_Fixture.ms"
    local core=CyrusProcedural07Fixture()
    P07Record P07Case core[2]

    P07Case="brush and background"
    P07New count:4000
    local r=P07Root,a=P07Layer,s=P07Source
    r.setGroupCoverage a true;cyrusBrushFill a.paintDocument 0
    cyrusBrushSettings a.paintDocument 240 1 0 false 1
    P07Assert (cyrusBrushDab a.paintDocument [0,0,500] [0,0,-1] true) "Flat dab missed"
    local b=r.addPaintSet a label:"Grass"
    b.sources=#(s);b.sourceWeights=#(1.0);b.paintEnabled=false
    b.procBackground=2;b.procBackgroundIDs=#(a.layerID)
    local rows=r.evaluateGroups(),inside=rows[1].count,outside=rows[2].count
    P07Assert (inside>100 and outside>100) "Painted/background populations missing"
    for row in rows[1] do P07Assert (length row[1].row4<240.01) "Flower outside painted disc"
    for row in rows[2] do P07Assert (length row[1].row4>=239.99) "Background enters painted disc"
    local baseBuild=(a.paintCacheStats())[1],before=P07Fingerprint r
    cyrusBrushSettings a.paintDocument 100 1 0 true 1
    cyrusBrushDab a.paintDocument [0,0,500] [0,0,-1] true
    local erased=P07Fingerprint r
    P07Assert ((r.evaluateGroups())[1].count<inside and (r.evaluateGroups())[2].count>outside) "Erase did not complement both fields"
    P07Assert ((a.paintCacheStats())[1]==baseBuild) "Brush regenerated candidates"
    max undo
    P07Assert ((P07Fingerprint r) as string==before as string) "Brush Undo differs"
    max redo
    P07Assert ((P07Fingerprint r) as string==erased as string) "Brush Redo differs"
    a.paintSetVisible=false
    P07Assert ((P07Fingerprint r) as string==erased as string) "Hide changed background coverage"
    a.paintSetEnabled=false;rows=r.evaluateGroups()
    P07Assert (rows[1].count==0 and rows[2].count==4000) "Disabled set still blocks background"
    a.paintSetEnabled=true;a.paintSetVisible=true;a.paintEnabled=false
    rows=r.evaluateGroups();P07Assert (rows[2].count==0) "Whole-surface coverage not respected"
    a.paintEnabled=true;b.procBackground=4
    r.procSetPair 1 a b true 0 35 false
    rows=r.evaluateGroups()
    for x in rows[1] do for y in rows[2] do P07Assert (distance x[1].row4 y[1].row4>=34.99) "Combined spacing leaked"
    a.procPopulation=2;a.procAttemptFactor=8
    rows=r.evaluateGroups()
    P07Assert (rows[1].count==2000) "Accepted target did not refill painted region"
    P07Record P07Case #("outside, erase/undo/redo, Whole, disabled, combined, refill",inside,outside,(for row in rows collect row.count))

    P07Case="three spacing scopes and radii"
    P07New count:500
    r=P07Root;a=P07Layer;s=P07Source
    a.sourceRadii=#(12.0);a.sourceFollowScale=#(true);a.sourceScales=#(2.0)
    a.procSelfOverride=true;a.procSelfEnabled=true;a.procSelfMultiplier=1;a.procSelfGap=4
    b=r.addPaintSet a label:"Second";b.paintEnabled=false;b.sources=#(s);b.sourceRadii=#(5.0)
    r.procSetPair 1 a b true 1 6 false
    r.newLayer();local c=r.selectedLayer();c.sources=#(s);c.amount=300;c.sourceRadii=#(10.0);c.paintEnabled=false
    r.procSetPair 2 a c true 1 8 false
    rows=r.evaluateGroups()
    local radii=for i=1 to 3 collect r.layerObjects[i].procRadii rows[i] (r.layerObjects[i].validSources())
    P07Assert (abs(radii[1][1]-24)<0.001) "Source scale not applied to radius"
    for i=1 to rows[1].count do for j=i+1 to rows[1].count do P07Assert (distance rows[1][i][1].row4 rows[1][j][1].row4>=51.99) "Self clearance failed"
    for i=1 to rows[1].count do for j=1 to rows[2].count do P07Assert (distance rows[1][i][1].row4 rows[2][j][1].row4>=radii[1][i]+radii[2][j]+5.99) "Sibling clearance failed"
    for k in #(1,2) do for i=1 to rows[k].count do for j=1 to rows[3].count do P07Assert (distance rows[k][i][1].row4 rows[3][j][1].row4>=radii[k][i]+radii[3][j]+7.99) "Layer clearance failed"
    r.procSetPair 2 a c true 0 1e6 false;rows=r.evaluateGroups()
    P07Assert (rows[3].count==0) "Later layer did not yield"
    r.procMove c -1;rows=r.evaluateGroups()
    P07Assert (rows[3].count==300 and rows[1].count==0 and rows[2].count==0) "Layer ordering ignored"
    r.procSetPair 2 a c false 1 0 false;rows=r.evaluateGroups()
    P07Assert (rows[1].count>0 and rows[2].count>0) "Disabled pair remains active"
    P07Record P07Case #(for item in rows collect item.count)

    P07Case="include exclude and stable subset"
    P07New count:2000
    r=P07Root;a=P07Layer;s=P07Source
    local full=(r.evaluateGroups())[1]
    local includeShape=rectangle width:600 length:600,excludeShape=rectangle width:160 length:160
    a.areaNodes=#(includeShape,excludeShape);a.areaModes=#(1,2)
    rows=(r.evaluateGroups())[1]
    P07Assert (rows.count>100 and rows.count<2000) "Area did not filter"
    for row in rows do (
        local p=row[1].row4
        P07Assert (abs p.x<=300.01 and abs p.y<=300.01 and (abs p.x>=79.99 or abs p.y>=79.99)) "Include/exclude leak"
        local originals=#()
        for old in full do if old[3]==row[3] do append originals old
        P07Assert (originals.count==1 and originals[1][1]==row[1]) "Area changed surviving candidate transform"
    )
    a.amount=2500
    local grown=(r.evaluateGroups())[1]
    for row in rows do (
        local matches=0
        for x in grown do if x[3]==row[3] and x[1]==row[1] do matches+=1
        P07Assert (matches==1) "Count growth moved old candidate"
    )
    P07Record P07Case #(rows.count,grown.count)

    P07Case="copy remove and undo"
    P07New count:1000
    r=P07Root;a=P07Layer;s=P07Source
    r.setGroupCoverage a true;cyrusBrushFill a.paintDocument .7
    b=r.addPaintSet a label:"Flowers";b.sources=#(s);cyrusBrushFill b.paintDocument .4
    r.procMove b -1 sets:true
    a.procBackground=2;a.procBackgroundIDs=#(b.layerID)
    r.procSetPair 1 a b true 0 5 false
    before=P07Fingerprint r
    local duplicate=r.copyLogicalLayer a,members=r.layerSets duplicate
    P07Assert (members.count==2 and members[1]!=duplicate) "Copied order lost reordered Base"
    P07Assert (duplicate.procBackgroundIDs[1]==members[1].layerID) "Copied reference not remapped"
    P07Assert ((r.procPair 1 duplicate members[1])>0) "Copied internal pair missing"
    rows=r.evaluateGroups()
    P07Assert (cyrusEditFingerprint rows[3] "proc07"==before[1] and cyrusEditFingerprint rows[4] "proc07"==before[2]) "Copy changed seeded placements"
    cyrusBrushFill duplicate.paintDocument 0
    P07Assert ((P07Fingerprint r)[1]==before[1]) "Copy shares brush document"
    r.removeLogicalLayer duplicate
    P07Assert (r.layerObjects.count==2 and r.procRuleA.count==1) "Remove left rule endpoints"
    max undo
    P07Assert (r.layerObjects.count==4 and r.procRuleA.count==2) "Remove Undo lost rules"
    max redo
    P07Assert (r.layerObjects.count==2 and r.procRuleA.count==1) "Remove Redo differs"
    P07Record P07Case true

    P07Case="manual live and atomic error recovery"
    P07New count:100
    r=P07Root;a=P07Layer
    r.refreshAll();local epoch=(a.procStatistics())[5]
    a.amount=150;CyrusViewportRedraw();completeRedraw()
    P07Assert (a.generatedCount==100 and a.dirty) "Manual computed early"
    r.setGroupDisplay 3;P07Assert (a.generatedCount==100 and (a.procStatistics())[5]==epoch) "Manual mode switch recalculated"
    r.refreshAll();P07Assert (a.generatedCount==150) "Update did not publish"
    r.updateMode=2;a.amount=200;CyrusViewportRedraw();completeRedraw()
    P07Assert (a.generatedCount==200) "Live failed to publish"
    local good=a.cacheSnapshot(),goodStats=a.procStatistics()
    a.sourceRadii=#(-1.0);CyrusViewportRedraw();completeRedraw()
    P07Assert (a.previewError!="" and (a.cacheSnapshot())[1]==good[1] and (a.procStatistics())[5]==goodStats[5]) "Failure lost preceding result"
    a.sourceRadii=#(0.0);a.amount=220;CyrusViewportRedraw();completeRedraw()
    P07Assert (a.previewError=="" and a.generatedCount==220) "Live did not recover"
    P07Record P07Case true

    P07Case="curved brush and persistence"
    P07New count:4000 curved:true
    r=P07Root;a=P07Layer
    P07Surface.scale=[1.3,.8,1.1]
    r.setGroupCoverage a true;cyrusBrushFill a.paintDocument 0
    cyrusBrushSettings a.paintDocument 55 1 .5 false 1
    P07Assert (cyrusBrushDab a.paintDocument [0,-250,0] [0,1,0] true) "Curved dab missed"
    rows=(r.evaluateGroups())[1]
    P07Assert (rows.count>25 and rows.count<2000) "Curved coverage missing/leaked"
    local history=(cyrusBrushHistory a.paintDocument) as string,signature=P07Fingerprint r
    P07Surface.segs=24
    local rejected=false
    try(r.evaluateGroups())catch(rejected=true)
    P07Assert rejected "Topology mismatch accepted"
    P07Assert ((cyrusBrushHistory a.paintDocument) as string==history) "Topology change lost strokes"
    P07Surface.segs=40
    P07Assert ((P07Fingerprint r) as string==signature as string) "Topology restoration differs"
    r.updateMode=1;r.refreshAll()
    local path=MCPFixtureDir+"Procedural07-Curved.max"
    saveMaxFile path quiet:true
    loadMaxFile path quiet:true
    P07Node=getNodeByName "P07_Controller";r=P07Node.baseObject;a=r.layerObjects[1]
    P07Assert (r.groupPolicy==3 and (P07Fingerprint r) as string==signature as string) "Save/reopen differs"
    P07Assert ((cyrusBrushHistory a.paintDocument) as string==history) "Save lost strokes"
    P07Root=r;P07Layer=a;P07Surface=getNodeByName "P07_Receiver";P07Source=getNodeByName "P07_Asset"
    P07Record P07Case #(rows.count,path)
    P07Record "complete" true
    true
)
