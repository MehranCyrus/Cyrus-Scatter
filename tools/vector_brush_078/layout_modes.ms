(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
CyrusStopBrush();CyrusCloseLayerEditor()
select BNode;max modify mode;modPanel.setCurrentObject BRoot
if not BRoot.mainUI.controlsReady do BRoot.mainUI.mountTimer.tick()
local epoch=BRoot.procEpoch,builds=BLayer.receiverCacheStats()
for page in BRoot.mainUI.editors do (page.open=true;page.advancedToggle.checked=true;BRoot.mainUI.bindSection page)
local page=BRoot.layoutUI
for mode=1 to 4 do (
 page.diversityUI_diversityRadio.state=mode
 for channel=1 to (if mode==4 then 5 else 1) do (
  page.diversityUI_analyzerChannel.selection=channel;page.layout()
  BLayoutPages=#(page);BLayoutContext="layout-mode-"+(mode as string)+"-channel-"+(channel as string)
  python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/layout_inspect.py"
 )
)
page.bind BLayer
page=BRoot.displayUI
for mode=1 to 3 do (
 page.flow_previewUI_displayModeDrop.selection=mode
 for colors=1 to 2 do (
  page.flow_previewUI_pointColorRadio.state=colors;page.layout()
  BLayoutPages=#(page);BLayoutContext="display-mode-"+(mode as string)+"-colors-"+(colors as string)
  python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/layout_inspect.py"
 )
)
page.bind BLayer
page=BRoot.populationUI
for mode=1 to 2 do (
 page.distributionUI_populationRadio.state=mode;page.distributionUI_modeRadio.state=2;page.layout()
 BLayoutPages=#(page);BLayoutContext="amount-mode-"+(mode as string)+"-density-map"
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/layout_inspect.py"
)
page.bind BLayer
BAssert (BRoot.procEpoch==epoch and (BLayer.receiverCacheStats())[1]==builds[1]) "Layout mode inspection does not publish or regenerate candidates"
)
