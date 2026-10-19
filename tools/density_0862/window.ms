if matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" then (
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"window.txt") ((windows.getMAXHWND()) as string)
) else throw "Owned profile required"
