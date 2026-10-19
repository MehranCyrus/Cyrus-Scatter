(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 dotNet.loadAssembly "F:/Cursor/_Cyrus_Apps/CyrusScatter/build/ui-polish-0862-20261019/DropTrace.dll"
 global DropMessageTraces=#()
 for h in DropProbePage.distributionUI_coordinatesList.hwnd do append DropMessageTraces (dotNetObject "DropTrace" h (MCPFixtureDir+"dropdown-messages.txt"))
 append DropMessageTraces (dotNetObject "DropTrace" DropProbePage.hwnd (MCPFixtureDir+"dropdown-messages.txt"))
)
