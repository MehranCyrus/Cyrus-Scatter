-- End only a completed disposable library qualification session.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-library08261-*/" do throw "Owned library host required."
    if (maxVersion())[1]!=29000 do throw "Max 2027 only."
    if CyrusRecipeBrowser!=undefined do CyrusRecipeBrowser.closeButton.pressed()
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"closed-owned-session.txt") MCPFixtureLast
    quitMAX #noPrompt quiet:true exitCode:0
)
