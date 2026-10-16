(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned variation host required."
    if (maxVersion())[1]!=29000 do throw "Max 2027 only."
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"closed-owned-session.txt") MCPFixtureLast
    quitMAX #noPrompt quiet:true exitCode:0
)
