(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p02-*/" do throw "Owned P02 host required"
    local log=createFile (MCPFixtureDir+"phase02-live.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log
        if not value do throw label
    )
    try (
        format "EPOCH before:% after:% builds:% dirty:%\n" P02LiveEpoch P02LiveRoot.procEpoch P02LiveRoot.groupBuilds P02LiveLeaf.dirty to:log
        format "STATE suspended:% busy:% renderHeld:% mouseHeld:% rootMode:% leafMode:% error:%\n" CyrusPointSuspended CyrusPointBusy AminScatterRenderRedrawHeld (CyrusInteractionHeld()) P02LiveRoot.updateMode P02LiveLeaf.updateMode P02LiveLeaf.previewError to:log
        verify (P02LiveLeaf.generatedCount==75 and P02LiveLeaf.randomSeed==12345) "Real Live callback accepts the complete new preset" log
        verify (P02LiveRoot.procEpoch==P02LiveEpoch+1) "Live Apply publishes exactly one successor" log
        verify (cyrusEditFingerprint P02LiveRoot.groupSnapshotRows[1] "live"!=P02LiveBefore) "Live successor replaces the old placements" log
        local epoch=P02LiveRoot.procEpoch,builds=P02LiveRoot.groupBuilds,prepared=P02LiveLeaf.procPreparedBuilds
        CyrusOpenPresets P02LiveRoot P02LiveLeaf "population"
        for i=1 to 30 do CyrusPresetBrowser.refreshList.pressed()
        destroyDialog CyrusPresetBrowser
        verify (P02LiveRoot.procEpoch==epoch and P02LiveRoot.groupBuilds==builds and P02LiveLeaf.procPreparedBuilds==prepared) "Passive Live browser adds no generation or preparation" log
        verify (not theHold.Holding()) "Live UI leaves no active transaction" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
