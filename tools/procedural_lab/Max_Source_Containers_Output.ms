if findString MCPFixtureDir "/procedural07-ui-"==undefined do throw "Private container fixture required"
P07Case="source containers: exact, PFlow and bake mapping"
CyrusPFTimer.Stop()
try (
    P07New count:100
    local r=P07Root,a=P07Layer,first=P07Source
    first.pos=[1000,0,0]
    local second=box width:4 length:4 height:6 pos:[1050,0,0]
    local rect=CyrusSourceContainer width:300 length:200 pos:[1000,0,0]
    a.containerMode=4;a.containerNodes=#(rect);r.autoRender=true;r.refreshAll()
    P07Assert (a.previewError=="" and a.sources.count==2) "Current container fixture failed to publish two enrolled sources"
    local total=0
    P07Assert (CyrusPFBuild()) CyrusPFLastError
    for group in CyrusPFData do total+=group.count
    P07Assert (total==100 and CyrusPFData.count==2) "Initial PFlow source mapping differs"
    first.pos=[1400,0,0]
    P07Assert ((a.placements (a.outputSources())).count==100) "Pending Manual membership changed exact output"
    r.refreshAll()
    local expected=a.generatedCount,exact=a.placements (a.outputSources())
    P07Assert (expected>0 and expected<100 and exact.count==expected) "Exact source mask differs"
    P07Assert (CyrusPFBuild()) CyrusPFLastError
    P07Assert (CyrusPFData.count==1 and CyrusPFData[1].count==expected) "PFlow did not use surviving source mapping"
    CyrusPFClear()
    a.bakeInstances P07Node
    P07Assert (a.bakedNodes.count==expected) "Baked instance count differs"
    local maxTransformError=0.0
    for i=1 to a.bakedNodes.count do (
        P07Assert (a.bakedNodes[i].baseObject==second.baseObject) "Baked the parked source instead of the active source"
        for j=1 to 4 do maxTransformError=amax maxTransformError (length(a.bakedNodes[i].transform[j]-exact[i][1][j]))
    )
    P07Assert (maxTransformError<1e-5) "Baked transform differs beyond host decomposition roundoff"
    a.bakedNodes[1].pos=[1000,0,0];a.containerScan=true;a.containerRefresh()
    P07Assert (a.sources.count==2) "Disposable baked output was automatically enrolled"
    CSPWriteText (MCPFixtureDir+"source-container-output.json") (CSPObject #(#("passed",true),#("initial",100),#("active_exact_pflow_bake",expected),#("baked_source_and_transforms",true),#("maximum_matrix_row_error",maxTransformError),#("baked_excluded",true)))
    CyrusPFTimer.Start()
)catch(CyrusPFTimer.Start();throw())
