(
    local root=(getNodeByName "Cyrus_Scatter_1_Demo").baseObject
    if CyrusBrushSessionLayer!=undefined or findString root.brushUI.brushState.text "Brush stopped"==undefined do throw "Native session end left stale UI status"
    if findString root.brushUI.brushState.text "L strokes"!=undefined do throw "Native integer formatting leaked into the UI"
    CSPWriteText (BLDir+"ui-status-acceptance.json") (CSPObject #(#("session_end_updates_label",true),#("native_count_format",true),#("status",root.brushUI.brushState.text)))
)
