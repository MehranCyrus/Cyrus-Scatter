-- Test setup only: put focus on Max's top-level window before a real mouse click.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 dotNet.loadAssembly "F:/Cursor/_Cyrus_Apps/CyrusScatter/build/ui-polish-0862-20261019/DropFocusProbe2.dll"
 (dotNetClass "DropFocusProbe2").Reset (windows.getMAXHWND())
)
