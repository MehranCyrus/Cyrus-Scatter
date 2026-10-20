(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned viewport host required"
 local output=createFile (MCPFixtureDir+"source-controls.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 try(
  select VController;max modify mode;VRoot.bindNativeUI()
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  local page=VRoot.modelsUI
  VRoot.mainUI.slots[3].open=true
  VRoot.mainUI.bindSection page
  format "BIND ready % owner % target %\n" page.sourceUI_controlsReady page.sourceUI_obj VLayer to:output
  check (not isProperty page #sourceUI_addSelected) "Add scene selection control is absent" output
  check (page.sourceUI_addPlant.text=="+") "Object addition uses the plus control" output
  page.sourceUI_addPoint.pressed()
  if VRoot.mainUI.bindTimer.active do VRoot.mainUI.bindTimer.tick()
  check (VLayer.sources.count==2 and VLayer.isPointSource 2) "Actual Add Point handler adds one source" output
  VLayer.setSourceLabel 2 "Stable source"
  VLayer.sourceWeights[2]=0.7;VLayer.sourceScales[2]=1.25;VLayer.sourceZOffsetsWU[2]=2.5
  VLayer.setSourceRadius #{2} 8.
  local id=VLayer.sourceRowIDs[2],first=sphere name:"Replacement one" radius:5 pos:[1000,0,0],second=box name:"Replacement two" width:6 length:8 height:10 pos:[1100,0,0]
  page.sourceUI_plantList.selection=#{2};page.sourceUI_focusedRow=2;page.sourceUI_showSelectedColor()
  check page.sourceUI_replacePoint.enabled "Pick object is enabled on a Point" output
  page.sourceUI_replacePoint.picked first
  if VRoot.mainUI.bindTimer.active do VRoot.mainUI.bindTimer.tick()
  check (VLayer.sources[2]==first and not VLayer.isPointSource 2) "Pick object replaces the Point" output
  check page.sourceUI_replacePoint.enabled "Pick object remains enabled on a model" output
  page.sourceUI_replacePoint.picked second
  if VRoot.mainUI.bindTimer.active do VRoot.mainUI.bindTimer.tick()
  check (VLayer.sources[2]==second and VLayer.sourceRowIDs[2]==id and VLayer.sourceLabel 2=="Stable source") "Model replacement keeps source identity and name" output
  check (VLayer.sourceWeight 2==0.7 and VLayer.sourceScale 2==1.25 and VLayer.sourceZOffset 2==2.5 and VLayer.sourceRadius 2==8.) "Replacement preserves weight, scale, offset and radius" output
  check (isValidNode first and isValidNode second) "Replacing a source preserves both scene objects" output
  max undo
  check (VLayer.sources[2]==first and VLayer.sourceRowIDs[2]==id) "Undo restores the previous model in the same row" output
  max redo
  check (VLayer.sources[2]==second and VLayer.sourceRowIDs[2]==id) "Redo restores the replacement" output
  check (not VLayer.replacePointSource 2 VSource and VLayer.sources[2]==second) "Duplicate source picks are rejected without row changes" output
  check (not VLayer.replacePointSource 2 (VLayer.validSurfaces())[1]) "Receiver cannot replace a source" output
  page.sourceUI_makePoint.pressed()
  if VRoot.mainUI.bindTimer.active do VRoot.mainUI.bindTimer.tick()
  check (VLayer.isPointSource 2 and VLayer.sourceRowIDs[2]==id and isValidNode second) "Make point retains identity, settings and scene object" output
  page.sourceUI_replacePoint.picked first
  if VRoot.mainUI.bindTimer.active do VRoot.mainUI.bindTimer.tick()
  check (VLayer.sources[2]==first and VLayer.sourceRowIDs[2]==id) "Point can be converted back through Pick object" output
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
