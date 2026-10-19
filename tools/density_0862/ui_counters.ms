(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned density profile required"
    local f=openFile (MCPFixtureDir+"ui-counters.txt") mode:"a"
    if f==undefined do f=createFile (MCPFixtureDir+"ui-counters.txt")
    format "% epoch=% solves=% receivers=% maps=% mask=% dirty=% error=%\n" (timeStamp()) DRoot.procEpoch DRoot.groupBuilds (DLayer.receiverCacheStats()) (DLayer.densityCacheStats()) (cyrusDensityOverlayStats()) DLayer.dirty DLayer.previewError to:f
    close f
)
