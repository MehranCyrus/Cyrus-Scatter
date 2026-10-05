-- Review regressions. Run only in a private Max session with a matching build.
if findString MCPFixtureDir "/procedural07-ui-"==undefined do throw "Private UI fixture required"
global P07New,P07Root,P07Node,P07Layer,P07Source,P07Assert,P07Case,CSPWriteText,CSPObject
global P07RegressionResults=#()
fn P07RegressionRecord name data = (
    append P07RegressionResults #(name,data)
    CSPWriteText (MCPFixtureDir+"review-regressions.json") (CSPObject P07RegressionResults)
)
fn P07PublishedText root = (local s=stringStream "";with printAllElements on format "%" root.groupSnapshotRows to:s;s as string)

P07Case="Manual exact output and render publication"
CyrusPFTimer.Stop()
try (
    P07New count:100
    local r=P07Root,a=P07Layer
    r.autoRender=true;r.refreshAll()
    P07Assert (CyrusPFBuild()) CyrusPFLastError
    local epoch=r.procEpoch,full=P07PublishedText r,build=CyrusPFBuilds
    a.amount=150
    P07Assert ((a.placements (a.outputSources())).count==100 and r.procEpoch==epoch) "Exact consumer published pending Manual amount"
    P07Assert (P07PublishedText r==full) "Manual exact read changed full rows"
    r.refreshAll();AminScatterRenderBegin()
    P07Assert (CyrusPFData.count==1 and CyrusPFData[1].count==150 and CyrusPFBuilds==build+1) "Manual Update did not reach PFlow"
    AminScatterRenderEnd()
    local original=P07Source,replacement=box name:"Replacement" pos:[1600,0,0]
    hide replacement;a.sources=#(replacement)
    P07Assert ((a.outputSources())[1]==original) "Pending source list replaced published source mapping"
    P07Assert ((a.placements (a.outputSources())).count==150) "Pending source change broke exact output"
    local rejected=false
    try(a.placements (a.validSources()))catch(rejected=true)
    P07Assert rejected "Stale row source indices were allowed against a different source list"
    r.refreshAll();AminScatterRenderBegin()
    P07Assert ((a.outputSources())[1]==replacement and CyrusPFData[1].count==150) "Source update did not publish"
    AminScatterRenderEnd();CyrusPFClear();r.autoRender=false
    P07RegressionRecord P07Case #(true,100,150,"pending source mapping preserved")

    P07Case="Live root pair rules reach render"
    P07New count:100;r=P07Root;a=P07Layer
    r.newLayer();local b=r.selectedLayer();b.sources=#(P07Source);b.amount=100;b.paintEnabled=false
    r.updateMode=2;r.autoRender=true;r.refreshAll();P07Assert (CyrusPFBuild()) CyrusPFLastError
    local key=CyrusPFSignature
    r.procSetPair 2 a b true 0 100000 false
    AminScatterRenderBegin()
    P07Assert (b.generatedCount==0 and CyrusPFData.count==1 and CyrusPFData[1].count==100) "Live pair rule left stale render rows"
    P07Assert (CyrusPFSignature!=key) "Live root rule did not change render signature"
    AminScatterRenderEnd();CyrusPFClear();r.autoRender=false
    P07RegressionRecord P07Case #(true,100,0)

    P07Case="same density map and nested map invalidation"
    P07New count:500;r=P07Root;a=P07Layer;r.updateMode=2
    local texture=checker color1:black color2:black
    a.distributionMode=3;a.densityMap=texture;r.refreshAll()
    P07Assert (a.generatedCount==0) "Black density fixture is not empty"
    local oldKey=r.procInputKey(),prepared=a.procPreparedBuilds
    texture.color1=white;texture.color2=white
    P07Assert (r.procInputKey()!=oldKey) "In-place map edit was not invalidated"
    local result=a.placements (a.outputSources())
    P07Assert (result.count==500 and a.procPreparedBuilds>prepared) "Same white map reused black-map rows"
    texture.map1=Noise();oldKey=r.procInputKey();texture.map1.size=7
    P07Assert (r.procInputKey()!=oldKey) "Nested texture edit was not invalidated"
    local unchanged=r.procInputKey()
    for i=1 to 20 do P07Assert (r.procInputKey()==unchanged) "Reading texture key changes it"
    P07RegressionRecord P07Case #(true,0,500,"nested map observed; stable reads")

    P07Case="disabled saved radius owner"
    P07New count:30;r=P07Root;a=P07Layer
    r.newLayer();b=r.selectedLayer();b.sources=#(P07Source);b.amount=20
    local edit=CyrusScatterEdit();addModifier P07Node edit;r.evaluateGroups()
    cyrusEditSelect edit #(1);a.procSelectedRadius 1 7;r.evaluateGroups()
    r.layerEnabled[1]=false;r.refreshAll()
    saveMaxFile (MCPFixtureDir+"Disabled-Radius-Regression.max") quiet:true
    loadMaxFile (MCPFixtureDir+"Disabled-Radius-Regression.max") quiet:true useFileUnits:true
    P07Node=getNodeByName "P07_Controller";r=P07Node.baseObject;a=r.layerObjects[1]
    local rows=r.evaluateGroups()
    P07Assert (rows[1].count==0 and rows[2].count==20 and a.procRadiusIDs.count==1) "Disabled saved radius blocked enabled layer or was discarded"
    r.layerEnabled[1]=true;rows=r.evaluateGroups()
    P07Assert (rows[1].count==30 and a.procRadiusIDs.count==1) "Reenabled saved radius failed"
    P07RegressionRecord P07Case #(true,0,20,30)

    P07Case="cleanup limit retains atomic publication"
    P07New count:100;r=P07Root;a=P07Layer
    epoch=r.procEpoch;full=P07PublishedText r
    a.amount=8000;a.finalCleanup=true;a.finalNeighborRadius=1000000;a.finalMinNeighbors=1;a.finalMinIsland=2
    local failed=false,message=""
    try(r.evaluateGroups())catch(failed=true;message=getCurrentException())
    P07Assert (failed and findString message "cleanup work limit"!=undefined) "Dense cleanup did not hit bounded work limit"
    P07Assert (r.procEpoch==epoch and P07PublishedText r==full) "Cleanup failure partially published"
    P07Assert ((a.placements (a.outputSources())).count==100) "Manual exact result was lost after failed successor"
    P07RegressionRecord P07Case #(true,"50 million visits bounded","prior 100 rows retained")
    CyrusPFTimer.Start()
) catch (CyrusPFTimer.Start();throw())
