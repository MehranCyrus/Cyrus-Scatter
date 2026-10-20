(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-hide*-202*/" do throw "Owned hide-surface host required"
 local output=createFile (MCPFixtureDir+"hide-acceptance.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn drain main=(
  local deadline=timeStamp()+15000
  while main.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();if main.controlsReady and not CyrusInteractionHeld() do main.pageTimer.tick())
  if main.mountQueue.count>0 do throw "Mount queue timeout"
 )
 fn clickSurface ui=(
  -- Exercise the native button notification, not only the MAXScript handler method.
  local button=ui.flow_surfaceUI_surfaceVisibility
  local handle=button.hwnd[1],id=windows.getWindowLong handle #id
  windows.sendMessage (windows.getParentHWND handle) 0x0111 id handle
  windows.processPostedMessages()
 )
 try (
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  for i=1 to VRoot.mainUI.slots.count do VRoot.mainUI.slots[i].open=true
  VRoot.mainUI.layoutPanels();drain VRoot.mainUI;VRoot.bindNativeUI()
  local ui=VRoot.surfacesUI,receiver=(VLayer.validSurfaces())[1]
  local handles=for node in objects collect getHandleByAnim node
  local epoch=VRoot.procEpoch,oldRows=VRoot.groupSnapshotRows[1].count,renderable=receiver.renderable
  VLayer.amount=27
  ui.flow_surfaceUI_receiversList.selection=#{}
  ui.flow_surfaceUI_receiversList.selectionEnd()
  check (ui.flow_surfaceUI_surfaceVisibility.enabled and ui.flow_surfaceUI_surfaceVisibility.text=="Hide surface") "Single receiver is actionable without a selected list row" output
  clickSurface ui
  check (cyrusSurfaceHidden receiver and ui.flow_surfaceUI_surfaceVisibility.text=="Show surface") "Native Hide click without row selection succeeds" output
  check (((for node in objects collect getHandleByAnim node) as string)==(handles as string)) "Hide creates, removes or replaces no scene nodes" output
  check (receiver.renderable==renderable and VRoot.procEpoch==epoch and VRoot.groupSnapshotRows[1].count==oldRows) "Render flag and pending Manual placement result stay unchanged" output
  max undo
  check (not cyrusSurfaceHidden receiver and objects.count==handles.count) "Undo restores visibility without scene copies" output
  max redo
  check (cyrusSurfaceHidden receiver and objects.count==handles.count) "Redo hides the same receiver without scene copies" output
  clickSurface ui
  check (not cyrusSurfaceHidden receiver and ui.flow_surfaceUI_surfaceVisibility.text=="Hide surface") "Native Show click without row selection succeeds" output
  ui.flow_surfaceUI_receiversList.selection=#{1};ui.flow_surfaceUI_receiversList.selectionEnd()
  clickSurface ui;check (cyrusSurfaceHidden receiver) "Selected receiver still hides" output
  clickSurface ui;check (not cyrusSurfaceHidden receiver) "Selected receiver still shows" output
  local second=box name:"Hide acceptance second receiver" width:40 length:40 height:40 pos:[-240,0,0]
  VRoot.setLayerSurfaces VLayer #(receiver,second);VRoot.bindNativeUI()
  ui.flow_surfaceUI_receiversList.selection=#{};ui.flow_surfaceUI_receiversList.selectionEnd()
  check (not ui.flow_surfaceUI_surfaceVisibility.enabled) "Multiple receivers with no selection disable ambiguous action" output
  ui.flow_surfaceUI_receiversList.selection=#{2};ui.flow_surfaceUI_receiversList.selectionEnd()
  clickSurface ui
  check (not cyrusSurfaceHidden receiver and cyrusSurfaceHidden second) "Selecting one receiver changes only that receiver" output
  ui.flow_surfaceUI_receiversList.selection=#{1,2};ui.flow_surfaceUI_receiversList.selectionEnd()
  clickSurface ui
  check (cyrusSurfaceHidden receiver and cyrusSurfaceHidden second) "Mixed multi-selection hides all selected receivers" output
  clickSurface ui
  check (not cyrusSurfaceHidden receiver and not cyrusSurfaceHidden second) "Hidden multi-selection shows all selected receivers" output
  check (objects.count==handles.count+1) "All repeated and multiple-target clicks avoid duplicates" output
  VRoot.setLayerSurfaces VLayer #();VRoot.bindNativeUI()
  check (not ui.flow_surfaceUI_surfaceVisibility.enabled) "No receiver disables surface action" output
  VRoot.setLayerSurfaces VLayer #(receiver)
  clearSelection();select VController;max modify mode
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  drain VRoot.mainUI;VRoot.bindNativeUI()
  ui=VRoot.surfacesUI
  ui.flow_surfaceUI_receiversList.selection=#{};ui.flow_surfaceUI_receiversList.selectionEnd()
  clickSurface ui;check (cyrusSurfaceHidden receiver) "Fallback survives deselect and reselect of Scatter" output
  clickSurface ui
  check (not cyrusSurfaceHidden receiver and objects.count==handles.count+1) "Reselected controller restores the same original surface" output
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
