-- Owned recipe fixture only; allow Max file/display callbacks an event-loop turn.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
    if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
    if not (loadMaxFile (MCPFixtureDir+"recipe-qualified.max") quiet:true useFileUnits:true) do throw "Owned recipe scene did not load"
    CyrusPerfHeadless=false
    local n=getNodeByName "Recipe 0.82.5 source"
    n.baseObject.refreshAll();CyrusPointSync();completeRedraw()
)
