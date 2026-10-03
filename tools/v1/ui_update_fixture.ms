-- Acceptance after the real native Update now button publishes the mouse stroke.
(
    local root=(getNodeByName "Cyrus_Scatter_1_Demo").baseObject,layer=root.layerObjects[1]
    if CyrusV1UIBaselineCount==undefined do throw "UI baseline was not recorded before painting"
    if layer.generatedCount<=CyrusV1UIBaselineCount or layer.dirty do throw "The native Update button did not publish the painted area"
    CSPWriteText (BLDir+"ui-update-acceptance.json") (CSPObject #(#("native_update_now",true),#("before",CyrusV1UIBaselineCount),#("after",layer.generatedCount),#("single_click_rollups",true),#("dirty_cleared",true)))
    -- Native session completion must refresh status even without a mask revision.
    CyrusStartBrush root layer
    cyrusBrushStop()
)
