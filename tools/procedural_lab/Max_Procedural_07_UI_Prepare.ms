-- Load a copy of the example only in the new private qualification session.
if findString MCPFixtureDir "/procedural07-ui-"==undefined do throw "Private UI fixture required"
global P07Node,P07Root,P07Layer,P07Assert,P07Case,P07Fingerprint
global CSPWriteText,CSPObject,CyrusPerfHeadless=true
clearSelection()
fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\AminScatter\scripts\AminScatterObject.ms"
fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\performance\CyrusPerformanceMonitor.ms"
fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\procedural_lab\Max_Procedural_07_Acceptance.ms"
python.Execute "import host_fixture; host_fixture.PANEL.hide() if host_fixture.PANEL is not None else None"
loadMaxFile @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\procedural-0.7-candidate\CyrusScatter-0.7-Example-Max2027.max" quiet:true useFileUnits:true
P07Node=getNodeByName "Cyrus_07_Procedural_Example"
P07Root=P07Node.baseObject;P07Layer=P07Root.layerObjects[1]
select P07Node;max modify mode;modPanel.setCurrentObject P07Root
if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick()
P07Root.bindNativeUI()
P07Root.refreshAll()
saveMaxFile (MCPFixtureDir+"PRIVATE-UI-TEST.max") quiet:true
CSPWriteText (MCPFixtureDir+"ui-prepared.json") (CSPObject #(#("native_flow",P07Root.mainUI.nativeFlow),#("main_height",P07Root.mainUI.height),#("rows",for r in (join (P07Root.nativeEditors()) P07Root.layerPanels) collect #(r.title,r.hwnd as string))))
