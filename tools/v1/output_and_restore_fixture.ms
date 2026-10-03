-- Final-output policy, texture dispatch and scene persistence.
(
    local node=CyrusV1BrushNode,root=node.baseObject,layer=CyrusV1BrushLayer
    local source=CyrusV1BrushSource,document=layer.paintDocument
    cyrusBrushFill document 1.0
    layer.wholeScaleMin=1;layer.wholeScaleMax=1;layer.sourceZOffsets=#();layer.sourceScales=#()
    layer.amount=64;layer.randomSeed=73
    while node.modifiers.count>0 do deleteModifier node 1
    local second=sphere name:"CYRUS_V1_SECOND_SOURCE" radius:2 segs:8 pos:[130,0,0]
    layer.sources=#(source,second);layer.sourceWeights=#(.25,.75)
    layer.sourceEmpty=#(false,true);layer.sourcePoint=#(false,false)
    local filtered=layer.placements (layer.validSources()) previewOnly:true
    if filtered.count==0 or filtered.count>=64 do throw "Weighted Empty source policy failed"
    for row in filtered where row[2]!=1 or row.count!=5 do throw "Source policy lost canonical rows"
    layer.sourcePoint=#(false,true)
    local preview=layer.placements (layer.validSources()) previewOnly:true
    local production=layer.placements (layer.validSources())
    if preview.count!=64 or production.count!=filtered.count do throw "Point-only source leaked into final output"
    layer.sourceEmpty=#();layer.sourcePoint=#();layer.sourceWeights=#();layer.sources=#(source)
    layer.collisionEnabled=true;layer.collisionRadius=5
    local spaced=layer.placements #(source) previewOnly:true
    if spaced.count==0 do throw "Brush collision removed every candidate"
    for row in spaced where row.count!=5 do throw "Collision lost canonical identity"
    layer.collisionEnabled=false
    layer.finalCleanup=true;layer.finalNeighborRadius=200;layer.finalMinNeighbors=1;layer.finalMinIsland=1
    if (layer.placements #(source) previewOnly:true).count!=64 do throw "Brush final cleanup lost valid candidates"
    layer.finalCleanup=false
    layer.paintEnabled=false;layer.paintIdentity=false
    layer.distributionMode=3;layer.advancedAxes=false
    layer.densityMap=Gradient color1:black color2:black color3:black
    if (layer.placements #(source) previewOnly:true).count!=0 do throw "Black density map bypassed native density dispatch"
    layer.densityMap=Gradient color1:white color2:white color3:white
    if (layer.placements #(source) previewOnly:true).count!=64 do throw "White density map underfilled constant field"
    layer.distributionMode=1;layer.densityMap=undefined;layer.paintIdentity=true;layer.paintEnabled=true
    root.layerVisible[1]=false
    local rows=layer.placements #(source)
    local baked=layer.bakeInstances node
    if baked!=rows.count or layer.bakedNodes.count!=rows.count do throw "Hidden layer did not bake exact final output"
    for i=1 to rows.count do for axis=1 to 4 where distance (layer.bakedNodes[i].transform)[axis] rows[i][1][axis]>0.0001 do throw "Bake changed plant transforms beyond host float precision"
    layer.clearBaked node;layer.showPoints=true
    for other in objects where classof other.baseObject==CyrusScatterObject do other.baseObject.autoRender=false
    layer.autoRender=true;root.autoRender=true
    local before=objects.count
    AminScatterRenderBegin()
    local emitted=0
    for data in CyrusPFData do emitted+=data.count
    if emitted!=64 do throw "Production bridge did not include hidden layer"
    for n in CyrusPFNodes where not isValidNode n do throw "Production bridge created an invalid instance"
    AminScatterRenderEnd()
    CyrusPFClear()
    if objects.count!=before do throw "Production bridge leaked transient scene nodes"
    root.layerVisible[1]=true;root.autoRender=false;layer.autoRender=false
    cyrusBrushFill document 0.0
    cyrusBrushSettings document 45 1 0 false 1
    cyrusBrushDab document [0,0,100] [0,0,-1] true
    root.updateMode=1;root.refreshAll()
    local records=#()
    for n in #(CyrusV1BrushNode,$CYRUS_V1_CURVED_SCATTER) where isValidNode n do (
        local r=n.baseObject,l=r.layerObjects[1]
        r.updateMode=1;r.refreshAll()
        append records #(n.name,l.layerID,l.editLayerKey,cyrusEditFingerprint (l.placements (l.validSources()) previewOnly:true) "reopen",(cyrusBrushHistory l.paintDocument) as string)
    )
    local expected=createFile (BLDir+"reopen-expected.ms")
    with printAllElements on format "global CyrusV1ReopenExpected=%\n" records to:expected
    close expected
    saveMaxFile (BLDir+"v1-qualified.max") quiet:true
    CSPWriteText (BLDir+"output-restore-prepared.json") (CSPObject #(#("texture_dispatch",true),#("point_empty_policy",true),#("collision_keyed",true),#("final_cleanup",true),#("hidden_bake_exact",true),#("production_bridge",true),#("transients_cleaned",true),#("scene",BLDir+"v1-qualified.max")))
)
