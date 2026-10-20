(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned panel host required"
 local output=createFile (MCPFixtureDir+"panel-acceptance.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn drain main = (
  local deadline=timeStamp()+15000
  while main.mountQueue.count>0 and timeStamp()<deadline do (
   windows.processPostedMessages()
   if main.controlsReady and not (CyrusInteractionHeld()) do main.pageTimer.tick()
  )
  if main.mountQueue.count>0 do throw "Queued sections did not finish within the fixture deadline."
 )
 try(
  select VController;max modify mode
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  local main=VRoot.mainUI,epoch=VRoot.procEpoch,builds=VRoot.groupBuilds
  for slot in main.slots do slot.open=true
  main.bindEditors()
  drain main
  check ((for page in main.editors where page.controlsReady collect page).count==12) "All twelve queued sections finish with valid owners" output
  for page in main.editors do (page.advancedToggle.checked=true;page.layout();page.advancedToggle.checked=false;page.layout())
  check (VRoot.procEpoch==epoch and VRoot.groupBuilds==builds) "Opening sections and Advanced does not rebuild placements" output
  local amount=VRoot.populationUI,transforms=VRoot.transformsUI,stamp=transforms.lastLayoutStamp
  amount.distributionUI_countSpin.changed 203
  check (VLayer.amount==203 and VRoot.procEpoch==epoch) "Amount handler preserves pending Manual edits" output
  check (main.bindTimer.active and findItem main.pendingPages 6>0 and findItem main.pendingPages 9==0) "Amount refresh queues affected pages, excluding Transforms" output
  main.bindTimer.tick()
  check (amount.distributionUI_countSpin.value==203 and CyrusPresetSameValues stamp transforms.lastLayoutStamp) "Scoped flush updates Amount and preserves unchanged Transform layout" output
  amount.distributionUI_populationRadio.changed 2
  if main.bindTimer.active do main.bindTimer.tick()
  VRoot.bindNativeUI();VRoot.bindNativeUI()
  check (amount.distributionUI_densitySpin.visible and not amount.distributionUI_countSpin.visible) "Density/Count conditional controls survive repeated warm binding" output
  amount.distributionUI_populationRadio.changed 1
  if main.bindTimer.active do main.bindTimer.tick()
  check (amount.distributionUI_countSpin.visible and not amount.distributionUI_densitySpin.visible) "Returning to Count restores the correct field" output
  max undo
  VRoot.bindNativeUI()
  check (VRoot.procEpoch==epoch) "Undo and full fallback refresh preserve Manual publication" output
  local original=VLayer
  VRoot.newLayer()
  local other=VRoot.selectedLayer()
  main.selectLayerView original
  amount.distributionUI_countSpin.changed 204
  main.selectLayerView other
  if main.bindTimer.active do main.bindTimer.tick()
  check (main.owner==other and amount.owner==other and amount.distributionUI_countSpin.value==other.amount) "Pending refresh resolves the current layer after selection changes" output
  main.selectLayerView original
  VRoot.setGroupDisplay 4;VRoot.bindNativeUI();VRoot.bindNativeUI()
  check (VRoot.displayUI.flow_previewUI_navigationPointsSpin.visible and VRoot.displayUI.flow_previewUI_budgetSpin.visible) "Group-center display fields survive repeat binding" output
  VRoot.setGroupDisplay 3;VRoot.bindNativeUI()
  local lastEpoch=VRoot.procEpoch,lastBuilds=VRoot.groupBuilds,stream=cyrusRetainedStreamStats()
  for i=1 to 10 do VRoot.bindNativeUI()
  check (VRoot.procEpoch==lastEpoch and VRoot.groupBuilds==lastBuilds and (cyrusRetainedStreamStats())[2]==stream[2]) "Ten warm binds perform no placement build or source extraction" output
  main.rememberViews()
  local state=deepcopy VRoot.uiPresentationState
  clearSelection();select VController
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  main=VRoot.mainUI
  check (main.mountQueue.count>0) "All-open selection defers later sections in complete batches" output
  clearSelection()
  check (not main.pageTimer.active and main.mountQueue.count==0) "Deselect cancels queued section creation" output
  select VController
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  main=VRoot.mainUI
  drain main
  check (CyrusPresetSameValues state VRoot.uiPresentationState) "Open/Advanced preferences survive deselect and remount" output
  format "SUCCESS scale %\n" (GetUIScaleFactor()) to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
