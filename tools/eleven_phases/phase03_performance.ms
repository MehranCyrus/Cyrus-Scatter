(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P03 host required"
    local log=createFile (MCPFixtureDir+"phase03-performance.txt")
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node=AminScatterObject name:"P03 bounded filter performance",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:1000 width:1000 lengthsegs:1 widthsegs:1
        for count in #(20000,20) do (
            root.newLayer();local leaf=root.selectedLayer()
            root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=count
            leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        )
        root.refreshAll();local first=root.layerObjects[1],second=root.layerObjects[2],rows=root.groupSnapshotRows[1]
        local start=timeStamp(),offTimes=#(),onTimes=#()
        for i=1 to 20 do (start=timeStamp();local result=first.applySurfaceFilter rows;append offTimes (timeStamp()-start);if result!=rows do throw "Disabled path copied rows")
        verify (first.procPreparedSurfaceStats[1]==-1) "Disabled filter bypasses native geometry and row allocation" log
        first.slopeEnabled=true;first.slopeMaximum=1
        for i=1 to 7 do (start=timeStamp();local result=first.applySurfaceFilter rows;append onTimes (timeStamp()-start);if result.count!=rows.count do throw "Neutral slope changed count")
        root.refreshAll();local epoch=root.procEpoch,prepared=first.procPreparedBuilds,receiverBuilds=(first.receiverCacheStats())[1]
        start=timeStamp()
        for i=1 to 100 do root.evaluateProcedural()
        local warm=timeStamp()-start
        verify (root.procEpoch==epoch and first.procPreparedBuilds==prepared and (first.receiverCacheStats())[1]==receiverBuilds) "100 warm reads preserve solve/preparation/receiver counters" log
        local before=first.surfaceFilterStats(),fingerprint=cyrusEditFingerprint rows "atomic"
        first.slopeMinimum=10;first.slopeMaximum=20;second.sourceWeights=#(-1.0)
        local failed=false
        try(root.evaluateProcedural())catch(failed=true)
        verify (failed and first.procPreparedSurfaceStats[2]==20000) "Later owner failure occurs after the first filter prepared its successor" log
        verify (first.surfaceFilterStats() as string==before as string and root.procEpoch==epoch and cyrusEditFingerprint root.groupSnapshotRows[1] "atomic"==fingerprint) "Failed successor retains published filter statistics and placements atomically" log
        second.sourceWeights=#(1.0);root.refreshAll()
        verify (first.generatedCount==0 and (first.surfaceFilterStats())[2]==20000) "Repair publishes matching new diagnostics and rows" log
        format "METRICS: 20000 rows / 2 receiver faces; disabled stage ms:%; enabled stage ms:%; 100 warm key reads ms:%\n" offTimes onTimes warm to:log
        format "Includes host allocation and runs on a shared workstation; not FPS or a latency guarantee.\nCOMPLETE\n" to:log
        close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
