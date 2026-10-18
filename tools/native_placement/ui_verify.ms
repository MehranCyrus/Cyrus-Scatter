(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native UI host required"
 local command=(dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")
 if command=="gallery" then CyrusRecipeBrowser.refresh()
 else (
  local after=#(UIRoot.procEpoch,UIRoot.groupBuilds,UILeaf.procPreparedBuilds,UILeaf.previewBuildCount,cyrusPlacementTransportStats())
  if not CyrusPresetSameValues UIBefore after do throw "Passive physical panel/library actions calculated placements"
  local f=createFile(MCPFixtureDir+"native-ui-passive.txt")
  format "PASS configured scale=% before=% after=%\n" (GetUIScaleFactor()) UIBefore after to:f
  if CyrusRecipeBrowser!=undefined do format "Gallery bounds: % x %\n" CyrusRecipeBrowser.width CyrusRecipeBrowser.height to:f
  close f
 )
)
