(
    local history=cyrusBrushHistory LFMouseSet.paintDocument,state=cyrusBrushStats LFMouseSet.paintDocument
    if history.count!=LFMouseHistory[3]+1 or history[history.count][6]<2 do throw "Native gesture did not commit a sampled stroke"
    if state[5]!=0 or state[6]!=0 do throw "Brush did not stop on right click"
    for i in #(2,4) do if (cyrusBrushHistory LFMouseRoot.layerObjects[i].paintDocument).count!=LFMouseHistory[i] do throw "Painting Blue changed another set"
    if LFMouseSet.generatedCount!=LFMouseBuild[5] or (LFMouseSet.cacheSnapshot())[6]!=LFMouseBuild[6] or not LFMouseSet.dirty do throw "Native gesture ignored Manual mode"
    LFMouseRoot.refreshAll()
    if LFMouseSet.dirty or LFMouseSet.previewError!="" do throw "Update failed after native gesture"
    CSPWriteText (BLDir+"layers-native-brush.json") (CSPObject #(#("painted_set","Blue"),#("mouse_stroke_samples",history[history.count][6]),#("other_sets_preserved",true),#("right_click_stop",true),#("manual_pending_then_update",true)))
)
