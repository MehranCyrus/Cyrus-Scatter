(
 local f=createFile (MCPFixtureDir+"ui-events-accepted.txt"),ui=CLRRoot.spacingUI
 try(
  format "flags: %= % %= % root=% owner=% eventDepth=%\n" ui.controlsReady ui.binding ui.proceduralUI_controlsReady ui.proceduralUI_binding ui.proceduralUI_root ui.proceduralUI_owner CLRRoot.mainUI.eventDepth to:f
  for index in #(1,2,1,2) do (
   local handle=ui.proceduralUI_scopeList.hwnd[1],identifier=windows.getWindowLong handle #id
   ui.proceduralUI_scopeList.selection=index
   local result=windows.sendMessage (windows.getParentHWND handle) 0x0111 (identifier+9*65536) handle
   format "index=% handle=% id=% returned=% scope=% peers=% flags=%/%\n" index handle identifier result (ui.proceduralUI_currentScope()) ui.proceduralUI_peerList.items ui.proceduralUI_controlsReady ui.proceduralUI_binding to:f
  )
 )catch(format "ERROR %\n" (getCurrentException()) to:f)
 close f
)
