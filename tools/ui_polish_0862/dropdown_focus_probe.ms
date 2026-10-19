(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 dotNet.loadAssembly "F:/Cursor/_Cyrus_Apps/CyrusScatter/build/ui-polish-0862-20261019/DropFocusProbe.dll"
 global DropFocusTest=dotNetObject "DropFocusProbe" DropProbePage.distributionUI_coordinatesList.hwnd[1]
 DropFocusTest.Enabled=true
 (dotNetClass "DropFocusProbe").Reset (windows.getMAXHWND())
)
