-- Exercise actual generated rollout handlers in a disposable Max 2027 profile.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"thumbnail-checks.txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  CyrusClearMeshMaskPreview undefined
  DRoot.mainUI.slots[6].open=true;DRoot.mainUI.bindSection DRoot.mainUI.editors[6]
  local page=DRoot.mainUI.editors[6],original=DLayer.densityMap
  check (page.isDisplayed and page.distributionUI_obj==DLayer) "Amount is mounted and bound to the actual selected layer" log
  local epoch=DRoot.procEpoch,builds=DRoot.groupBuilds,stats=DLayer.densityCacheStats()
  for mapValue in #(undefined,Noise(),Bitmaptexture(),Bitmaptexture filename:(MCPFixtureDir+"does-not-exist.png"),original,undefined,original) do (
   page.distributionUI_densityButton.picked mapValue
   check (DLayer.densityMap==mapValue) "Actual texture picker handler retains the selected map (including Clear)" log
   local shown=page.distributionUI_imageThumbnail.bitmap
   if classof mapValue==Bitmaptexture and mapValue.filename!="" and doesFileExist mapValue.filename then
    check (classof shown==Bitmap) "Actual image control displays a readable bitmap" log
   else check (shown==undefined) "Empty, procedural and unreadable maps clear the actual image control" log
   page.advancedToggle.checked=false;page.layout();page.distributionUI_syncControls()
   page.advancedToggle.checked=true;page.layout();page.distributionUI_syncControls()
   check (page.controlsReady and not page.binding) "Basic and Advanced Amount controls remain usable" log
  )
  check (page.distributionUI_imageThumbnail.style==#bmp_stretch) "Thumbnail scales the complete tile instead of cropping the source pixels" log
  check (page.distributionUI_imageThumbnail.transparent!=(color 0 0 0)) "Black density-mask pixels are not the transparency key" log
  local shown=page.distributionUI_imageThumbnail.bitmap,sourceImage=original.bitmap
  check (shown.filename==sourceImage.filename and shown.width==sourceImage.width and shown.height==sourceImage.height and (getPixels sourceImage [0,0] 1).count==1) "Thumbnail uses the selected image and leaves its source bitmap readable" log
  local afterEdits=DLayer.densityCacheStats()
  format "COUNTERS before=%/%/% after edits=%/%/%\n" epoch builds stats DRoot.procEpoch DRoot.groupBuilds afterEdits to:log
  check (DRoot.procEpoch==epoch and DRoot.groupBuilds==builds and stats[1]==afterEdits[1]) "Map selection in Manual with mask hidden does not solve, prepare or bake" log
  for i=1 to 50 do page.distributionUI_syncControls()
  check (DRoot.procEpoch==epoch and DRoot.groupBuilds==builds and CyrusPresetSameValues afterEdits (DLayer.densityCacheStats())) "50 passive panel bindings leave all density counters unchanged" log
  global ThumbnailOriginal=original
  page.distributionUI_densityButton.picked undefined
  check (DLayer.densityMap==undefined) "Clear leaves the authored map empty without a rollout exception" log
  format "PASS: complete\n" to:log;close log
 ) catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
