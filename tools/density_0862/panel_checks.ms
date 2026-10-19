(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 global DCheckRootPanels
 fn DCheckRootPanels root label = (
  local log=createFile (MCPFixtureDir+"panels-"+label+".txt")
  try (
   if not root.mainUI.controlsReady do throw "Actual Modify panel must be mounted before checking"
   local epoch=root.procEpoch,builds=root.groupBuilds,stats=for leaf in root.layerObjects collect leaf.densityCacheStats()
   for index=1 to root.layerObjects.count do (
    root.selectLayer index;root.bindNativeUI()
    local main=root.mainUI
    main.slots[6].open=true;main.bindSection main.editors[6]
    local page=main.editors[6]
    if not page.isDisplayed or page.distributionUI_obj!=root.layerObjects[index] do throw "Amount has the wrong owner"
    page.distributionUI_syncControls();page.advancedToggle.checked=true;page.layout();page.distributionUI_syncControls()
    page.advancedToggle.checked=false;page.layout()
    if not page.controlsReady or page.binding do throw "Amount binding did not finish"
    format "PASS: layer % / % / map % / Basic and Advanced\n" index root.layerNames[index] (classof root.layerObjects[index].densityMap) to:log
   )
   if root.procEpoch!=epoch or root.groupBuilds!=builds or not (CyrusPresetSameValues stats (for leaf in root.layerObjects collect leaf.densityCacheStats())) do throw "Layer browsing recalculated or rebaked"
   format "PASS: all layer owners checked; no placement, preparation or tile bake during browsing\nPASS: complete\n" to:log;close log
  )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
 )
)
