-- Read-only acceptance after the real native Start / drag / right-click UI test.
(
    local root=(getNodeByName "Cyrus_Scatter_1_Demo").baseObject,layer=root.layerObjects[1]
    if CyrusV1UIBaselineCount==undefined or CyrusV1UIBaselineHistory!=3 do throw "Run the clean demo before UI painting"
    local state=cyrusBrushStats layer.paintDocument,history=cyrusBrushHistory layer.paintDocument
    if state[5]!=0 or state[6]!=0 do throw "Right-click did not finish the native painting session"
    if history.count!=CyrusV1UIBaselineHistory+1 or history[history.count][6]<2 or state[7]<2 do throw "Mouse painting did not commit a connected stroke"
    if not layer.dirty or layer.generatedCount!=CyrusV1UIBaselineCount do throw "Manual painting republished plants before Update"
    CSPWriteText (BLDir+"ui-gesture-acceptance.json") (CSPObject #(#("real_native_start",true),#("mouse_paint_strokes",history.count),#("last_stroke_samples",history[history.count][6]),#("manual_cached_count",layer.generatedCount),#("right_click_stopped",true),#("canonical_picks",state[7])))
)
