(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-grid0850-*/" do throw "Owned grid host required."
    if (maxVersion())[1]!=29000 do throw "Max 2027 only."
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"closed-owned-session.txt") MCPFixtureLast
    quitMAX #noPrompt quiet:true exitCode:0
)
