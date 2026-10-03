-- Immutable base placements and independent copied layers.
(
    local root=CyrusV1BrushNode.baseObject,layer=CyrusV1BrushLayer,source=CyrusV1BrushSource
    layer.wholeScaleMin=.6;layer.wholeScaleMax=1.5
    layer.sourceZOffsets=#(3.0);layer.sourceScales=#(1.1)
    cyrusBrushFill layer.paintDocument 1.0
    local full=layer.placements #(source) previewOnly:true
    local before=layer.paintCacheStats()
    for round=1 to 5 do (
        local repeated=layer.placements #(source) previewOnly:true
        if repeated.count!=full.count do throw "Cached base changed population"
        for i=1 to full.count where repeated[i][1]!=full[i][1] or repeated[i][3]!=full[i][3] do throw "Source offsets mutated the cached base"
    )
    cyrusBrushSettings layer.paintDocument 45 1 0 true 1
    cyrusBrushDab layer.paintDocument [0,0,100] [0,0,-1] true
    local thinned=layer.placements #(source) previewOnly:true
    local after=layer.paintCacheStats()
    if after[1]!=before[1] or after[2]<before[2]+6 do throw "Brush-only changes regenerated the base distribution"
    if thinned.count==0 or thinned.count>=full.count do throw "Cached Brush did not apply current field"
    for row in thinned do (
        local index=(row[3] as integer)+1
        if full[index][3]!=row[3] or full[index][1]!=row[1] do throw "Brush compaction changed scale or source transform"
    )
    layer.paintEnabled=false
    local disabled=layer.placements #(source) previewOnly:true
    local repeated=layer.placements #(source) previewOnly:true
    for i=1 to disabled.count where disabled[i][1]!=repeated[i][1] do throw "Disabled Brush aliased cached transforms"
    layer.paintEnabled=true
    layer.paintDensity=.57
    thinned=layer.placements #(source) previewOnly:true
    if thinned.count==0 or thinned.count>=full.count do throw "Fractional density did not thin the masked population"
    root.activeLayer=1
    local originID=layer.layerID,originKey=layer.editLayerKey
    root.copySelectedLayer()
    local duplicate=root.selectedLayer()
    if duplicate.layerID==originID or duplicate.editLayerKey==originKey do throw "Layer copy reused identity"
    if duplicate.paintDocument==layer.paintDocument do throw "Layer copy aliased Brush document"
    local copied=duplicate.placements #(source) previewOnly:true
    if copied.count!=thinned.count do throw "Layer ownership changed fractional mask acceptance on copy"
    for i=1 to copied.count where copied[i][1]!=thinned[i][1] or copied[i][2]!=thinned[i][2] or copied[i][3]!=thinned[i][3] do throw "Copied layer changed seeded placements"
    cyrusBrushFill duplicate.paintDocument 0.0
    if (layer.placements #(source) previewOnly:true).count!=thinned.count do throw "Copied layer modified original field"
    root.removeLayer();root.activeLayer=1;root.bindNativeUI()
    layer.paintDensity=1
    local builds=(layer.paintCacheStats())[1]
    layer.randomSeed+=1
    layer.placements #(source) previewOnly:true
    if (layer.paintCacheStats())[1]!=builds+1 do throw "Changed generation settings reused a stale base"
    layer.randomSeed-=1
    layer.placements #(source) previewOnly:true
    CSPWriteText (BLDir+"cache-copy-acceptance.json") (CSPObject #(#("brush_reuses_base",true),#("base_hits",after[2]-before[2]),#("immutable_transforms",true),#("scale_stable_when_thinned",true),#("copied_layer_independent",true),#("fractional_copy_placements_identical",true),#("fractional_copy_count",copied.count),#("generation_change_invalidates",true)))
)
