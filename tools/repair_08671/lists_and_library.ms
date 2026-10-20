(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned panel host required"
 local output=createFile (MCPFixtureDir+"lists-and-library.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn shown control = (
  local visibleState=true
  for handle in control.hwnd where handle!=0 do visibleState=visibleState and (bit.get (windows.getWindowLong handle #style) 29)
  visibleState
 )
 fn drain main = (
  local deadline=timeStamp()+15000
  while main.mountQueue.count>0 and timeStamp()<deadline do (
   windows.processPostedMessages()
   if main.controlsReady and not CyrusInteractionHeld() do main.pageTimer.tick()
  )
  if main.mountQueue.count>0 do throw "Deferred pages did not mount."
 )
 fn lists root layer expected output label = (
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  drain root.mainUI
  if root.mainUI.bindTimer.active do root.mainUI.bindTimer.tick()
  for i=1 to 3 do root.bindNativeUI()
  check (root.managerUI.flow_layersUI_layerList_colored.Items.Count==root.layerObjects.count and shown root.managerUI.flow_layersUI_layerList_colored) (label+": visible Layers matches model") output
  check (root.modelsUI.sourceUI_plantList_colored.Items.Count==expected and shown root.modelsUI.sourceUI_plantList_colored) (label+": visible Models matches model") output
  check (root.surfacesUI.flow_surfaceUI_receiversList.items.count==(layer.validSurfaces()).count and shown root.surfacesUI.flow_surfaceUI_receiversList) (label+": visible Surfaces matches model") output
 )
 try(
  select VController;max modify mode
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  drain VRoot.mainUI
  for i=1 to 3 do VRoot.mainUI.slots[i].open=true
  VRoot.mainUI.bindSection VRoot.managerUI;VRoot.mainUI.bindSection VRoot.modelsUI;VRoot.mainUI.bindSection VRoot.surfacesUI
  local receiver=(VLayer.validSurfaces())[1],epoch=VRoot.procEpoch,builds=VRoot.groupBuilds
  lists VRoot VLayer VLayer.sources.count output "Initial warm binding"
  VRoot.managerUI.flow_layersUI_addButton.pressed()
  local newLayer=VRoot.selectedLayer()
  check (newLayer!=VLayer and VRoot.layerObjects.count==2) "Actual plus button adds a layer" output
  lists VRoot newLayer newLayer.sources.count output "Immediately after adding layer"
  VRoot.setLayerSurfaces newLayer #(receiver)
  VRoot.modelsUI.sourceUI_addPoint.pressed()
  lists VRoot newLayer 1 output "Point and surface added"
  VRoot.modelsUI.sourceUI_plantList.selection=#{1}
  VRoot.modelsUI.sourceUI_removePlant.pressed()
  lists VRoot newLayer 0 output "Last source removed"
  max undo
  lists VRoot newLayer 1 output "Source removal undone"
  VRoot.mainUI.selectLayerView VLayer
  lists VRoot VLayer VLayer.sources.count output "Original layer selected"
  check (VRoot.procEpoch==epoch and VRoot.groupBuilds==builds) "UI operations preserve published Manual result" output
  for page in #(VRoot.managerUI,VRoot.modelsUI,VRoot.surfacesUI) do (
   page.advancedToggle.checked=true;page.layout();page.layout()
   page.advancedToggle.checked=false;page.layout();page.layout()
  )
  lists VRoot VLayer VLayer.sources.count output "Advanced toggled"
  VRoot.mainUI.rememberViews()
  clearSelection();select VController
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  drain VRoot.mainUI
  VRoot.mainUI.bindSection VRoot.managerUI;VRoot.mainUI.bindSection VRoot.modelsUI;VRoot.mainUI.bindSection VRoot.surfacesUI
  lists VRoot VLayer VLayer.sources.count output "Deselect and remount"
  CyrusOpenRecipeLibrary VRoot
  local browser=CyrusRecipeBrowser,before=VLayer.sources.count
  browser.bindingControls=true
  browser.panel.SearchText="Sycamore Leaf 15";browser.bindingControls=false
  browser.action "search"
  check (browser.panel.Gallery.ItemCount>0) "Real leaf appears in library search" output
  local entry=browser.selectedModel()
  local flags=dotNet.combineEnums (dotNetClass "System.Reflection.BindingFlags").Instance (dotNetClass "System.Reflection.BindingFlags").NonPublic
  local panelType=browser.panel.GetType(),loadButton=(panelType.GetField "load" flags).GetValue browser.panel
  local nodeCount=objects.count
  loadButton.PerformClick()
  if (maxVersion())[1]==29000 then (
   check (VLayer.sources.count==before+1) "Actual load button imports real leaf into destination layer" output
   check (findString browser.panel.NoticeText ("Added "+entry.Name+" to ")==1 and findString browser.panel.NoticeText "Press Update scatter"!=undefined) "Success feedback names the imported model and Manual update action" output
   lists VRoot VLayer (before+1) output "After real library import"
   local source=VLayer.sources[VLayer.sources.count]
   check (isValidNode source and source.material!=undefined) "Imported leaf keeps its material" output
  ) else (
   check (findString browser.panel.NoticeText "unavailable material or texture map"!=undefined) "Missing renderer dependencies produce visible failure feedback" output
   check (VLayer.sources.count==before and objects.count==nodeCount) "Failed import rolls back nodes and preserves source rows" output
   check (selection.count==1 and selection[1]==VController) "Rejected import restores the selected controller" output
   lists VRoot VLayer before output "After rejected library import"
  )
  local notice=(panelType.GetField "notice" flags).GetValue browser.panel
  check (notice.Visible and notice.Height>20) "Result banner is visible above the gallery" output
  local size=getDialogSize browser
  browser.panel.width=700;browser.panel.height=550
  check (notice.Visible and notice.Width>200) "Notice remains visible after resizing" output
  local deadline=timeStamp()+15000
  while browser.panel.Gallery.IsLoading and timeStamp()<deadline do (
   (dotNetClass "System.Windows.Forms.Application").DoEvents();sleep 0.01
  )
  check (not browser.panel.Gallery.IsLoading) "Thumbnail completes with the result banner displayed" output
  local image=dotNetObject "System.Drawing.Bitmap" browser.panel.width browser.panel.height
  browser.panel.DrawToBitmap image (dotNetObject "System.Drawing.Rectangle" 0 0 browser.panel.width browser.panel.height)
  image.Save (MCPFixtureDir+"library-success.png");image.Dispose()
  destroyDialog browser
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
 close output
)
