(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-ui0852-*/" do throw "Owned UI host required."
 if (maxVersion())[1]!=29000 do throw "Max 2027 only."
 if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"closed-owned-session.txt") MCPFixtureLast
 quitMAX #noPrompt quiet:true exitCode:0
)
