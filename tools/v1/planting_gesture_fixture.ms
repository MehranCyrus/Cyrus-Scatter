(
 local root=(getNodeByName "Cyrus_Scatter_1_Demo").baseObject,layer=root.layerObjects[2]
 local state=cyrusBrushStats layer.paintDocument,history=cyrusBrushHistory layer.paintDocument
 if state[5]!=0 or state[6]!=0 or history.count!=CyrusGroupsUIHistory+1 or history[history.count][6]<2 do throw "Native mouse stroke not committed/stopped"
 if layer.generatedCount!=CyrusGroupsUICount or not layer.dirty do throw "Manual stroke republished without Update"
 if state[20]==0 do throw "Native viewport overlay was never drawn"
 CSPWriteText (BLDir+"groups-ui-gesture.json") (CSPObject #(#("native_start_and_mouse_drag",true),#("right_click_stop",true),#("samples",history[history.count][6]),#("manual_pending",true),#("tint_triangles",state[19]),#("overlay_draws",state[20])))
 root.refreshAll()
 if layer.generatedCount<=CyrusGroupsUICount do throw "Update did not publish added flower patch"
 if layer.dirty do throw "Update left the group pending"
 if root.brushUI.controlsReady and findString root.brushUI.brushState.text "Changes pending"!=undefined do throw "Brush status stayed stale after Update"
)
