(
 local f=createFile (MCPFixtureDir+"ui-diagnostic-2.txt"),ui=CLRRoot.spacingUI,models=CLRRoot.modelsUI
 format "rootLayers=% ready=% owner=% binding=% scoped=% selection=% peers=%\n" CLRRoot.layerObjects.count ui.controlsReady ui.proceduralUI_owner ui.binding ui.proceduralUI_scopeList.items ui.proceduralUI_scopeList.selection ui.proceduralUI_peerList.items to:f
 for control in #(ui.proceduralUI_scopeList,models.sourceUI_clearanceOthersList) do (
  format "CONTROL % enabled=% handles=%\n" control control.enabled control.hwnd to:f
  for handle in control.hwnd do (
   format "HWND % parent=% id=% children=%\n" handle (windows.getParentHWND handle) (windows.getWindowLong handle #id) (windows.getChildrenHWND (windows.getParentHWND handle)) to:f
  )
 )
 try(ui.proceduralUI_bindRule resetPeer:true;format "direct peers=%\n" ui.proceduralUI_peerList.items to:f)catch(format "direct ERROR %\n" (getCurrentException()) to:f)
 close f
)
