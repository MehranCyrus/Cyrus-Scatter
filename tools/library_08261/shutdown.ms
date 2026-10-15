-- Host-exit qualification only. Never called in an artist profile.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-library08261-*/" do throw "Owned library host required."
    if (maxVersion())[1]!=29000 do throw "Max 2027 only."
    if CyrusRecipeBrowser!=undefined do CyrusRecipeBrowser.closeButton.pressed()
    local token=cyrusRecipeLibraryStart #(MCPFixtureDir+"large-10000")
    local state=cyrusRecipeLibraryPage token "" "" 1
    if state[1]!="scanning" do throw "Exit witness requires an active worker."
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"shutdown-start.txt") ("Active file-only scan; request="+MCPFixtureLast)
    quitMAX #noPrompt quiet:true exitCode:0
)
