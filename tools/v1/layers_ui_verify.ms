(
    local root=LFRoot.baseObject,p=root.layerPanels[1],rect=windows.getWindowPos root.layersUI.hwnd
    if not p.mounted or p.editors.count!=10 do throw "One-click expansion did not mount the features"
    if root.layerObjects[1].amount!=121 or root.layerObjects[2].amount!=90 do throw "Clicked Grass control did not affect only Grass"
    if rect.w!=LFClickBefore.w or rect.h!=LFClickBefore.h do throw "Clicking internal sections resized Layers"
    if root.layerObjects[1].generatedCount!=100 or not root.layerObjects[1].dirty do throw "Manual count edit rebuilt before Update"
    root.refreshAll()
    if root.layerObjects[1].generatedCount!=121 or root.layerObjects[2].generatedCount!=90 do throw "Update did not apply clicked layer count"
    CSPWriteText (BLDir+"layers-native-clicks.json") (CSPObject #(#("single_click_expansion",true),#("native_spinner_owner",true),#("root_frame_stable",true),#("manual_pending_then_update",true)))
)
