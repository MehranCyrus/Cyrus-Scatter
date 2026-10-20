(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2027/" do throw "Owned real-library host required"
 local output=createFile (MCPFixtureDir+"library-layers-08672.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn drain root=(
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  for i=1 to 3 do root.mainUI.slots[i].open=true
  root.mainUI.layoutPanels()
  local deadline=timeStamp()+15000
  while root.mainUI.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();if root.mainUI.controlsReady and not CyrusInteractionHeld() do root.mainUI.pageTimer.tick())
  root.bindNativeUI()
  if root.mainUI.bindTimer.active do root.mainUI.bindTimer.tick()
 )
 try(
  select LNode;max modify mode;drain LRoot
  LRoot.mainUI.selectLayerView LLayer;drain LRoot
  CyrusOpenRecipeLibrary LRoot
  local browser=CyrusRecipeBrowser
  browser.bindingControls=true;browser.panel.SearchText="Sycamore Leaf 04";browser.bindingControls=false;browser.action "search"
  check (browser.panel.Gallery.ItemCount>0) "Second real leaf found in library" output
  local flags=dotNet.combineEnums (dotNetClass "System.Reflection.BindingFlags").Instance (dotNetClass "System.Reflection.BindingFlags").NonPublic
  local button=((browser.panel.GetType()).GetField "load" flags).GetValue browser.panel
  button.PerformClick()
  check (LLayer.sources.count==2 and isValidNode LLayer.sources[2]) "Actual library load adds second leaf to original layer" output
  destroyDialog browser;drain LRoot
  LRoot.managerUI.flow_layersUI_addButton.pressed();drain LRoot
  local next=LRoot.selectedLayer(),receiver=(LLayer.validSurfaces())[1]
  check ((next.validSurfaces()).count==1 and (next.validSurfaces())[1]==receiver) "New layer after two leaves inherits current receiving plane" output
  check (next.sources.count==0 and next.distributionMode!=3 and not next.paintEnabled) "New layer starts without imported source or mask state" output
  check (LRoot.modelsUI.sourceUI_obj==next and LRoot.modelsUI.sourceUI_controlsReady) "Models controls bind to the new layer" output
  LRoot.modelsUI.sourceUI_addPoint.pressed();drain LRoot
  check (next.sources.count==1 and next.isPointSource 1) "Actual Add Point button adds a source to the new layer" output
  next.amount=20000;next.procSelfOverride=true;next.procSelfEnabled=false;next.procLayerSelfEnabled=false
  LRoot.setGroupDisplay 1;LRoot.refreshAll();LRoot.evaluateProcedural();drain LRoot
  check (LRoot.groupSnapshotRows[LRoot.activeLayer].count==20000 and next.previewError=="") "New Point layer accepts the requested 20000 placements" output
  local source=sphere radius:1 pos:[600,0,0];hide source
  LRoot.modelsUI.sourceUI_replacePoint.picked source;drain LRoot
  LRoot.refreshAll();LRoot.evaluateProcedural();drain LRoot
  check (next.sources[1]==source and LRoot.groupSnapshotRows[LRoot.activeLayer].count==20000 and next.previewError=="") "Pick object replaces Point with sphere without Empty result" output
  check (LLayer.sources.count==2 and (LLayer.validSurfaces())[1]==receiver) "Original leaf layer keeps both sources and surface" output
  LRoot.mainUI.selectLayerView LLayer;drain LRoot
  check (LRoot.modelsUI.sourceUI_plantList_colored.Items.Count==2) "Original layer displays both leaf rows" output
  LRoot.mainUI.selectLayerView next;drain LRoot
  check (LRoot.managerUI.flow_layersUI_layerList_colored.Items.Count==2 and LRoot.modelsUI.sourceUI_plantList_colored.Items.Count==1) "Both layer rows and replacement source stay visible" output
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
 close output
)
