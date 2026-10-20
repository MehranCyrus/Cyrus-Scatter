(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-hide*-202*/" do throw "Owned hide-surface host required"
 local output=createFile (MCPFixtureDir+"hide-repro.txt")
 try (
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  for i=1 to VRoot.mainUI.slots.count do VRoot.mainUI.slots[i].open=true
  VRoot.mainUI.layoutPanels()
  local deadline=timeStamp()+15000
  while VRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();if VRoot.mainUI.controlsReady and not CyrusInteractionHeld() do VRoot.mainUI.pageTimer.tick())
  VRoot.bindNativeUI()
  local ui=VRoot.surfacesUI,receiver=(VLayer.validSurfaces())[1]
  for selected in #(#{1},#{}) do (
   ui.flow_surfaceUI_receiversList.selection=selected
   ui.flow_surfaceUI_receiversList.selectionEnd()
   format "SELECTION % ROWS % CLASS %\n" selected ui.flow_surfaceUI_receiverRows (classOf ui.flow_surfaceUI_receiverRows) to:output
   local before=objects.count
   try (ui.flow_surfaceUI_surfaceVisibility.pressed();format "CLICK OK hidden=%\n" (cyrusSurfaceHidden receiver) to:output)
   catch (format "CLICK ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
   format "SCENE NODE DELTA %\n" (objects.count-before) to:output
   flush output
  )
  local rows=#(receiver)
  try(format "GLOBAL COPY %\n" (copy rows) to:output)catch(format "GLOBAL COPY ERROR %\n" (getCurrentException()) to:output)
  format "DONE\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
