(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-list*-202*/" do throw "Owned list host required"
 local output=createFile (MCPFixtureDir+"list-visibility.txt")
 fn visibleHost control = (
  local shown=true
  for handle in control.hwnd where handle!=0 do shown=shown and (bit.get (windows.getWindowLong handle #style) 29)
  shown
 )
 fn inspect root label output = (
  local layers=root.managerUI,models=root.modelsUI
  format "% layers=% shown=% sources=% shown=%\n" label layers.flow_layersUI_layerList_colored.Items.Count (visibleHost layers.flow_layersUI_layerList_colored) models.sourceUI_plantList_colored.Items.Count (visibleHost models.sourceUI_plantList_colored) to:output
  flush output
 )
 try(
  select VController;max modify mode
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  VRoot.mainUI.slots[1].open=true;VRoot.mainUI.slots[3].open=true
  VRoot.mainUI.bindSection VRoot.managerUI;VRoot.mainUI.bindSection VRoot.modelsUI
  VRoot.managerUI.lastLayoutStamp=undefined;VRoot.modelsUI.lastLayoutStamp=undefined
  VRoot.managerUI.layout();VRoot.modelsUI.layout()
  inspect VRoot "full layout" output
  VRoot.managerUI.layout();VRoot.modelsUI.layout()
  inspect VRoot "cached layout" output
  for i=1 to 5 do VRoot.bindNativeUI()
  inspect VRoot "five warm binds" output
  if not (visibleHost VRoot.managerUI.flow_layersUI_layerList_colored) or not (visibleHost VRoot.modelsUI.sourceUI_plantList_colored) do throw "Populated visible lists became hidden"
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
