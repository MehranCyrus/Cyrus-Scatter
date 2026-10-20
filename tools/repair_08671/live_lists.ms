(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2027/" do throw "Owned Live fixture required"
 local output=createFile (MCPFixtureDir+"live-lists.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn shown control=(local result=true;for h in control.hwnd where h!=0 do result=result and bit.get (windows.getWindowLong h #style) 29;result)
 try(
  select VController;max modify mode
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  for i in #(1,2,3,6) do (VRoot.mainUI.slots[i].open=true;VRoot.mainUI.bindSection VRoot.mainUI.editors[i])
  VRoot.mainUI.updateRadio.changed 2
  VRoot.populationUI.distributionUI_countSpin.changed 12
  local deadline=timeStamp()+15000
  while VRoot.groupSnapshotRows[1].count!=12 and timeStamp()<deadline do (
   redrawViews();windows.processPostedMessages();sleep 0.05
  )
  check (VRoot.groupSnapshotRows[1].count==12 and VLayer.previewError=="") "Live Amount edit publishes twelve placements" output
  for i=1 to 5 do VRoot.bindNativeUI()
  check (shown VRoot.managerUI.flow_layersUI_layerList_colored and shown VRoot.modelsUI.sourceUI_plantList_colored) "Live publication and warm binds keep lists visible" output
  CyrusOpenRecipeLibrary VRoot
  local browser=CyrusRecipeBrowser,before=VLayer.sources.count
  browser.panel.SearchText="Sycamore Leaf 15"
  local flags=dotNet.combineEnums (dotNetClass "System.Reflection.BindingFlags").Instance (dotNetClass "System.Reflection.BindingFlags").NonPublic
  local kind=browser.panel.GetType(),button=(kind.GetField "load" flags).GetValue browser.panel
  button.PerformClick()
  check (VLayer.sources.count==before+1 and findString browser.panel.NoticeText "Live mode"!=undefined) "Actual library load gives Live feedback and adds source" output
  for i=1 to 5 do (windows.processPostedMessages();VRoot.bindNativeUI())
  check (VRoot.modelsUI.sourceUI_plantList_colored.Items.Count==before+1 and shown VRoot.modelsUI.sourceUI_plantList_colored) "Imported source stays visible in Live mode" output
  destroyDialog browser
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
 close output
)
