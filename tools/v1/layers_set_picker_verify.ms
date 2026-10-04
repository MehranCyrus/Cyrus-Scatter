(
    local root=(getNodeByName "Cyrus_Scatter_1_Demo").baseObject,parent=root.layerObjects[2],blue=root.layerObjects[3],panel=root.layerPanels[2]
    if (root.selectedPaintSet parent)!=blue or panel.editors[2].obj!=blue or panel.editors[4].obj!=blue or panel.editors[7].obj!=parent do throw "Native set selection redirected the common layer controls"
    CSPWriteText (BLDir+"layers-set-picker.json") (CSPObject #(#("native_dropdown_selected_blue",true),#("assets_brush_bound_to_blue",true),#("common_controls_bound_to_parent",true)))
)
