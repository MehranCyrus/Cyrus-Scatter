(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global BLayoutPages,BLayoutContext
CyrusStopBrush();CyrusCloseLayerEditor()
select BNode;max modify mode;modPanel.setCurrentObject BRoot
if not BRoot.mainUI.controlsReady do BRoot.mainUI.mountTimer.tick()
for page in BRoot.mainUI.editors do (page.open=true;page.advancedToggle.checked=true;BRoot.mainUI.bindSection page)
windows.processPostedMessages()
BLayoutPages=BRoot.mainUI.editors;BLayoutContext="main-advanced"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/layout_inspect.py"
for page in BRoot.mainUI.editors do (page.advancedToggle.checked=false;page.layout())
BLayoutContext="main-basic"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/layout_inspect.py"
CyrusOpenLayerEditor BRoot BLayer
for size in #([720,500],[920,650],[1280,720]) do (
 setDialogSize CyrusLayerEditor size;windows.processPostedMessages()
 for topic=1 to 6 do (
  CyrusLayerEditor.showTopic topic rebind:true;windows.processPostedMessages()
  BLayoutPages=CyrusLayerEditor.activeEditors()
  for page in BLayoutPages do (page.open=true;page.advancedToggle.checked=true;page.bind BLayer)
  BLayoutContext="popup-"+(size as string)+"-topic-"+(topic as string)
  python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/layout_inspect.py"
 )
)
CyrusCloseLayerEditor()
)
