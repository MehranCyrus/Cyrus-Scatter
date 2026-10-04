if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
(
    if not CFRoot.layerPanels[1].open or not CFRoot.layerPanels[1].mounted or CFRoot.layerPanels[2].open do throw "Expected only Grass opened by the observed single click"
    if CFRoot.layerPanels[1].editors.count!=10 do throw "First click did not mount all feature sections"
    for i=1 to CFRoot.layerObjects.count do (
        if CFUIBefore[i][6]!=(CFRoot.layerObjects[i].cacheSnapshot())[6] do throw "Opening the layer regenerated placements"
        if CFUIBeforePaint[i][1]!=(CFRoot.layerObjects[i].paintCacheStats())[1] do throw "Opening the layer evaluated paint"
    )
    local now=cyrusRetainedStats CFUIDisplay
    for k in #(3,4,5,6,7) do if CFUIBeforeRetained[k]!=now[k] do throw "Opening the layer uploaded display buffers"
    CSPWriteText (BLDir+"classic-ui-gesture.json") (CSPObject #(#("version",CFRoot.uiVersion()),#("grass_open_flowers_closed",true),#("ten_sections_mounted",true),#("no_generation_paint_or_upload",true)))
)
