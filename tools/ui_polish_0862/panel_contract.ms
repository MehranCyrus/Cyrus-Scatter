-- Actual generated controls, owned Max 2027 only; no scene mutation outside fixture.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"ui-polish-contract.txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  CyrusClearMeshMaskPreview undefined
  for i=1 to DRoot.mainUI.slots.count do DRoot.mainUI.slots[i].open=(i==1 or i==3 or i==6)
  DRoot.bindNativeUI()
  local amount=DRoot.mainUI.editors[6],models=DRoot.mainUI.editors[3],layers=DRoot.mainUI.editors[1]
  local epoch=DRoot.procEpoch,builds=DRoot.groupBuilds,fingerprint=cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows
  amount.distributionUI_densityButton.picked undefined
  amount.distributionUI_imageCheck.changed false
  amount.advancedToggle.checked=false;amount.layout()
  check (amount.distributionUI_imageButton.visible and amount.distributionUI_mapBrowseButton.visible and amount.distributionUI_mapBrowseButton.enabled) "Image and Map reachable with no image and Use image off" log
  check (amount.distributionUI_imageButton.pos.y==amount.distributionUI_mapBrowseButton.pos.y) "Image and Map share one row" log
  check (not amount.distributionUI_densityButton.visible) "Empty selected-map field consumes no row" log
  check (amount.distributionUI_patternButton.pos.y<amount.distributionUI_imageButton.pos.y) "Choose pattern remains above the Image/Map row" log
  check (not amount.distributionUI_imageThumbnail.visible and not amount.distributionUI_imageState.visible) "Empty image reserves no preview or description row" log
  check (not amount.distributionUI_coordinatesList.visible and not amount.distributionUI_meshChannelSpin.visible) "Disabled image and channel options stay compact" log
  check (amount.advancedToggle.text=="More settings" and not amount.distributionUI_resolutionList.visible and not amount.populationPolicyUI_populationList.visible) "More settings is collapsed by default" log
  amount.advancedToggle.checked=true;amount.layout()
  check (amount.advancedToggle.text=="Fewer settings" and amount.distributionUI_resolutionList.visible and amount.populationPolicyUI_populationList.visible) "More settings reveals sampling, mask display and retries" log
  for control in #(amount.distributionUI_resolutionList,amount.distributionUI_bakeImageButton,amount.distributionUI_maskDetailList,amount.distributionUI_opacitySpin,amount.populationPolicyUI_populationList) do check (control.pos.y>amount.advancedToggle.pos.y) "Extra controls appear below their disclosure" log
  amount.distributionUI_densityButton.picked (Noise name:"Direct Noise without image")
  check (classof DLayer.densityMap==Noise and DLayer.distributionMode==3 and amount.distributionUI_imageCheck.checked) "Map picker directly enables the chosen procedural density map" log
  check (DLayer.densityPatternID=="" and DLayer.densityPatternRevision=="") "Replacing a pattern with a map clears stale pattern identity" log
  check (not amount.distributionUI_imageThumbnail.visible and amount.distributionUI_mapBrowseButton.text=="Map" and amount.distributionUI_densityButton.visible) "Procedural map has no blank thumbnail; Map caption stays short and assigned map field appears" log
  amount.distributionUI_meshCheck.changed true
  check amount.distributionUI_meshChannelSpin.visible "Channel controls appear only when enabled" log
  amount.distributionUI_meshCheck.changed false
  local full="Long mountain planting name with separators | and non-ASCII باغ - full authored label"
  layers.flow_layersUI_nameEdit.entered full
  models.sourceUI_plantList.selection=#{1};models.sourceUI_focusedRow=1;models.sourceUI_showSelectedColor()
  models.sourceUI_sourceName.entered full
  models.sourceUI_showSelectedColor();layers.bind DLayer;models.layout()
  check (layers.flow_layersUI_nameEdit.text==full and models.sourceUI_sourceName.text==full) "Both full-width edits retain the complete authored label" log
  check (layers.flow_layersUI_nameEdit.width>=layers.lastLayoutWidth-13 and models.sourceUI_sourceName.width>=models.lastLayoutWidth-13) "Layer and Model edits use the full row" log
  check (models.sourceUI_sourceName.pos.y>models.sourceUI_sourceNameLabel.pos.y and models.sourceUI_idColor.pos.y==models.sourceUI_sourceNameLabel.pos.y) "Models show Name and color above the full-width edit" log
  local layerText=layers.flow_layersUI_layerList_colored.Items.Item[0] as string,modelText=models.sourceUI_plantList_colored.Items.Item[0] as string
  check (substring layerText 1 full.count==full and findString layerText " | "!=undefined and substring modelText 1 full.count==full) "List ellipsis is presentation only, including names containing separators" log
  check (DRoot.procEpoch==epoch and DRoot.groupBuilds==builds and (cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows)==fingerprint) "UI edits in Manual do not calculate or republish placements" log
  amount.distributionUI_densityButton.picked undefined
  amount.distributionUI_imageCheck.changed false;amount.advancedToggle.checked=false;amount.layout()
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
