-- Synthetic product acceptance. No live artist scene is touched.
global CyrusV1BrushNode,CyrusV1BrushSurface,CyrusV1BrushSource,CyrusV1BrushLayer
(
    local surface=plane name:"CYRUS_V1_BRUSH_SURFACE" width:200 length:200 widthsegs:16 lengthsegs:16
    local source=cone name:"CYRUS_V1_BRUSH_SOURCE" radius1:2 radius2:0 height:10 sides:8 heightsegs:1 capsegs:1 pos:[125,0,0]
    local node=CyrusScatterObject name:"CYRUS_V1_BRUSH_SCATTER"
    local root=node.baseObject
    root.surfaceNodes=#(surface);root.viewportMode=3;root.autoRender=false
    root.newLayer()
    local layer=root.layerObjects[1]
    layer.sources=#(source);layer.amount=4000;layer.randomSeed=73
    root.syncLayerSurface layer
    local legacy=layer.placements #(source) previewOnly:true
    layer.paintDocument=cyrusBrushCreate surface;layer.paintIdentity=true;layer.paintEnabled=true
    cyrusBrushSettings layer.paintDocument 45 1 0 false 1
    cyrusBrushFill layer.paintDocument 1.0
    local full=layer.placements #(source) previewOnly:true
    if full.count!=legacy.count do throw "Full Brush base changed population"
    for i=1 to full.count do (
        if full[i].count!=5 do throw "Candidate has no canonical identity"
        if full[i][1]!=legacy[i][1] or full[i][2]!=legacy[i][2] do throw "Full Brush changed legacy placement"
    )
    cyrusBrushFill layer.paintDocument 0.0
    if (layer.placements #(source) previewOnly:true).count!=0 do throw "Empty Brush did not empty layer"
    if not (cyrusBrushDab layer.paintDocument [0,0,100] [0,0,-1] true) do throw "Brush did not hit plane"
    local painted=layer.placements #(source) previewOnly:true
    if painted.count<100 or painted.count>=full.count do throw "Paint footprint is incorrect"
    local signature=layer.paintPopulation
    local paintKeys=for row in painted collect row[3]
    cyrusBrushSettings layer.paintDocument 18 1 0 true 1
    cyrusBrushDab layer.paintDocument [0,0,100] [0,0,-1] true
    local erased=layer.placements #(source) previewOnly:true
    if erased.count>=painted.count do throw "Erase did not remove candidates"
    if layer.paintPopulation!=signature do throw "Brush changed population binding"
    for row in erased where findItem paintKeys row[3]==0 do throw "Erase introduced different candidate IDs"
    max undo
    if (layer.placements #(source) previewOnly:true).count!=painted.count do throw "Stroke Undo did not restore population"
    max redo
    if (layer.placements #(source) previewOnly:true).count!=erased.count do throw "Stroke Redo did not restore population"
    cyrusBrushStroke layer.paintDocument 2 false 1 18 0 true
    if (layer.placements #(source) previewOnly:true).count!=painted.count do throw "Disabling erase did not restore density"
    root.updateMode=1;root.refreshAll()
    local before=layer.cacheSnapshot()
    cyrusBrushStroke layer.paintDocument 2 true 1 18 0 true
    layer.checkPaintRevision();CyrusViewportRedraw()
    if (layer.cacheSnapshot())[6]!=before[6] do throw "Manual Brush rebuilt plants without Update"
    root.refreshAll()
    if (layer.cacheSnapshot())[5]!=erased.count do throw "Manual Update did not commit Brush density"
    root.layerVisible[1]=false;CyrusViewportRedraw()
    if (root.viewportLayerEntries false).count!=0 do throw "Hidden Brush still draws"
    if (root.layerEntries()).count!=1 do throw "Hidden Brush was disabled from final output"
    root.layerVisible[1]=true
    select node;max modify mode;root.bindNativeUI()
    if root.brushUI.obj!=layer do throw "Native Brush editor is not bound to layer"
    cyrusBrushRefreshMask layer.paintDocument
    local state=cyrusBrushStats layer.paintDocument
    if state[16]<100 or state[16]>2048 do throw "Independent mask overlay is unbounded or missing"
    local copyDoc=copy layer.paintDocument
    cyrusBrushFill copyDoc 1.0
    if (cyrusBrushStats layer.paintDocument)[2]!=2 do throw "Copied Brush edits affected original"
    saveMaxFile (BLDir+"brush-product.max") quiet:true
    CyrusV1BrushNode=node;CyrusV1BrushSurface=surface;CyrusV1BrushSource=source;CyrusV1BrushLayer=layer
    CSPWriteText (BLDir+"brush-acceptance.json") (CSPObject #(#("base_count",full.count),#("painted",painted.count),#("erased",erased.count),#("population",signature),#("stable_ids",true),#("undo_redo",true),#("manual_update",true),#("visible_render_separate",true),#("overlay",state[16]),#("native_brush_ui",true)))
)
