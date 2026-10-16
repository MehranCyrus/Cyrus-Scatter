-- This helper is never packaged. Only completed disposable profiles use it.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
 if (maxVersion())[1]!=29000 do throw "Max 2027 only."
 if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
 if CyrusRecipeSaveEditor!=undefined do destroyDialog CyrusRecipeSaveEditor
 if CyrusRecipeLoadEditor!=undefined do destroyDialog CyrusRecipeLoadEditor
 if CyrusAssetImportEditor!=undefined do destroyDialog CyrusAssetImportEditor
 if CyrusAssetExportEditor!=undefined do destroyDialog CyrusAssetExportEditor
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"closed-owned-session.txt") MCPFixtureLast
 quitMAX #noPrompt quiet:true exitCode:0
)
