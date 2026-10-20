(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-*-2027/" do throw "Owned clearance host required"
 local output=createFile (MCPFixtureDir+"scope-repro.txt")
 try (
  VRoot.newLayer()
  select VController;max modify mode
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  for slot in VRoot.mainUI.slots do slot.open=true
  VRoot.mainUI.bindEditors()
  local deadline=timeStamp()+20000
  while VRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do (
   windows.processPostedMessages()
   if VRoot.mainUI.controlsReady and not CyrusInteractionHeld() do VRoot.mainUI.pageTimer.tick()
  )
  VRoot.bindNativeUI()
  local ui=VRoot.spacingUI
  for index in #(1,2,1,2) do (
   ui.proceduralUI_scopeList.selection=index
   try (
    -- Dropdown .selected is a text property, not an invocable event method.
    -- Call the exact generated callback body for the causal reproduction.
    ui.proceduralUI_bindRule resetPeer:true
    format "OK scope=% peers=%\n" index ui.proceduralUI_peerList.items to:output
   ) catch(format "ERROR scope=% %\n%\n" index (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
   flush output
  )
  format "DONE\n" to:output
 ) catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
