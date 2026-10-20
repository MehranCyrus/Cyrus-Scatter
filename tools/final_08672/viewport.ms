(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned host required"
 local output=createFile (MCPFixtureDir+"viewport-08672.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn drain main=(
  local deadline=timeStamp()+15000
  while main.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();if main.controlsReady and not CyrusInteractionHeld() do main.pageTimer.tick())
  if main.mountQueue.count>0 do throw "Mount queue timeout"
 )
 fn shown control=(local result=true;for h in control.hwnd where h!=0 do result=result and (bit.get (windows.getWindowLong h #style) 29);result)
 try(
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  for i=1 to VRoot.mainUI.slots.count do VRoot.mainUI.slots[i].open=true
  VRoot.mainUI.layoutPanels();drain VRoot.mainUI;VRoot.bindNativeUI()
  local ui=VRoot.displayUI,receiver=(VLayer.validSurfaces())[1],epoch=VRoot.procEpoch
  check (VRoot.uiVersion()=="0.86.7.2") "Current script loaded" output
  check (ui.flow_previewUI_displayModeDrop.items[5]=="Textured mesh" and ui.flow_previewUI_displayModeDrop.items[4]=="Placement points") "Display menu offers explicit Textured mesh and Placement points" output
  VLayer.amount=27
  for mode in #(1,2,3,4,5) do (
   local combo=ui.flow_previewUI_displayModeDrop
   combo.selection=mode
   for handle in combo.hwnd where (windows.getHWNDData handle)[4]=="ComboBox" do (
    local id=windows.getWindowLong handle #id
    windows.sendMessage (windows.getParentHWND handle) 0x111 (id+65536) handle
   )
   VRoot.mainUI.layoutPanels();drain VRoot.mainUI;redrawViews();completeRedraw()
   check (VRoot.procEpoch==epoch and VRoot.groupSnapshotRows[1].count==9) ("Display "+(mode as string)+" retains pending Manual placements") output
   check (ui.flow_previewUI_displayModeDrop.selection==mode) "Mode survives control binding" output
   check ((shown ui.flow_previewUI_identificationDrop)==(mode!=5)) "Color by is conditional; texture choice is not offered for points" output
   if mode==5 do check (VRoot.viewportMode==3 and VRoot.identificationMode==4 and shown ui.flow_previewUI_faceLimitSpin) "Textured mode uses Mesh and keeps triangle budgets" output
  )
  local surfaceUI=VRoot.surfacesUI
  surfaceUI.flow_surfaceUI_receiversList.selection=#{1};surfaceUI.flow_surfaceUI_receiversList.selectionEnd()
  local renderable=receiver.renderable,hidden=receiver.isHidden
  surfaceUI.flow_surfaceUI_surfaceVisibility.pressed()
  check (cyrusSurfaceHidden receiver and receiver.renderable==renderable) "Surface button sets only viewport preference" output
  check (VRoot.procEpoch==epoch and VRoot.groupSnapshotRows[1].count==9) "Hiding receiver does not apply Manual edits" output
  max undo
  check (not cyrusSurfaceHidden receiver) "Undo restores surface visibility" output
  max redo
  check (cyrusSurfaceHidden receiver) "Redo restores viewport hiding" output
  surfaceUI.flow_surfaceUI_surfaceVisibility.pressed()
  check (not cyrusSurfaceHidden receiver and receiver.isHidden==hidden) "Surface button restores original hidden flag" output
  VRoot.managerUI.flow_layersUI_addButton.pressed();drain VRoot.mainUI
  local next=VRoot.selectedLayer()
  check ((next.validSurfaces()).count==1 and (next.validSurfaces())[1]==receiver) "Add Layer inherits selected layer receiving surface" output
  VRoot.modelsUI.sourceUI_addPoint.pressed();drain VRoot.mainUI
  next.amount=25;VRoot.refreshAll();VRoot.evaluateProcedural()
  check (VRoot.groupSnapshotRows[VRoot.activeLayer].count==25 and next.previewError=="") "Point in new layer scatters on inherited surface" output
  local sphereSource=sphere radius:3 pos:[600,0,0];hide sphereSource
  VRoot.modelsUI.sourceUI_replacePoint.picked sphereSource;drain VRoot.mainUI
  VRoot.refreshAll();VRoot.evaluateProcedural()
  check (VRoot.groupSnapshotRows[VRoot.activeLayer].count==25 and next.sources[1]==sphereSource) "Pick object replaces Point with sphere and preserves placements" output
  VRoot.setLayerSurfaces next #();VRoot.refreshAll();VRoot.evaluateProcedural()
  check ((VLayer.validSurfaces()).count==1) "New layer surface list is independent" output
  check (findString (CyrusUIResultText VRoot next) "Add a receiving surface"!=undefined) "Missing surface has an actionable diagnostic" output
  VRoot.setLayerSurfaces next #(receiver)
  VRoot.updateMode=2;next.amount=31;next.markInputDirty()
  local deadline=timeStamp()+15000
  while timeStamp()<deadline and VRoot.groupSnapshotRows[VRoot.activeLayer].count!=31 do (windows.processPostedMessages();redrawViews();completeRedraw())
  check (VRoot.groupSnapshotRows[VRoot.activeLayer].count==31) "Live update works after new layer, Point and replacement" output
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
