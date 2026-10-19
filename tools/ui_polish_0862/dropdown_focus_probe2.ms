(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 DropFocusTest.Enabled=false
 dotNet.loadAssembly "F:/Cursor/_Cyrus_Apps/CyrusScatter/build/ui-polish-0862-20261019/DropFocusProbe2.dll"
 global DropFocusTest2=dotNetObject "DropFocusProbe2" DropProbePage.distributionUI_coordinatesList.hwnd[1]
 DropFocusTest2.Enabled=true
 (dotNetClass "DropFocusProbe2").Reset (windows.getMAXHWND())
)
