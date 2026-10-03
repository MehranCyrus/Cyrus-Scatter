-- Run in a fresh process loaded from output_and_restore_fixture's saved scene.
global CyrusV1ReopenExpected
(
    fileIn (BLDir+"reopen-expected.ms")
    for record in CyrusV1ReopenExpected do (
        local node=getNodeByName record[1],root=node.baseObject,layer=root.layerObjects[1]
        if layer.layerID!=record[2] or layer.editLayerKey!=record[3] do throw "Layer identity did not survive reopening"
        if (cyrusBrushHistory layer.paintDocument) as string!=record[5] do throw "Brush history did not survive reopening"
        -- This edit occurs before requesting placements; restored native
        -- surfaces must validate lazily instead of demanding an earlier build.
        local h=cyrusBrushHistory layer.paintDocument
        cyrusBrushStroke layer.paintDocument 1 false h[1][4] h[1][3] h[1][5] h[1][2]
        max undo
        local rows=layer.placements (layer.validSources()) previewOnly:true
        if (cyrusEditFingerprint rows "reopen")!=record[4] do throw "Saved placement output changed after reopening"
        hide (cyrusBrushTarget layer.paintDocument)
        cyrusBrushStroke layer.paintDocument 1 false h[1][4] h[1][3] h[1][5] h[1][2]
        max undo
        unhide (cyrusBrushTarget layer.paintDocument)
    )
    select (getNodeByName CyrusV1ReopenExpected[1][1]);max modify mode
    local root=selection[1].baseObject
    root.bindNativeUI()
    CSPWriteText (BLDir+"reopen-acceptance.json") (CSPObject #(#("fresh_process",true),#("saved_rows_match",true),#("persistent_layer_ids",true),#("history_edit_before_generation",true),#("hidden_target_history_edit",true),#("native_ui",true)))
)
