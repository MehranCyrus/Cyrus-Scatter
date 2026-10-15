(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-meshmask-*/" do throw "Owned mask host required"
    global MeshQuietStage,MeshQuietCounters,MeshQuietNative,MeshQuietRetained,MeshQuietTimer,MeshQuietTicks,MeshQuietTick
    if MeshQuietStage==undefined do MeshQuietStage=0
    fn MeshQuietTick sender args = (
        MeshQuietTicks+=1
        if MeshQuietTicks>=50 do (
            MeshQuietTimer.Stop()
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"mesh-quiet-ready.txt") "ready"
        )
    )
    local root=MeshHeavyRoot,leaf=MeshHeavyLeaf,owner=CyrusPointOwner MeshHeavyNode
    local log=if MeshQuietStage==0 then createFile (MCPFixtureDir+"mesh-mask-heavy-quiet.txt") else openFile (MCPFixtureDir+"mesh-mask-heavy-quiet.txt") mode:"a"
    fn verify pass label log = (format "%: %\n" (if pass then "PASS" else "FAIL") label to:log;flush log;if not pass do throw label)
    if MeshQuietStage==0 then (
        CyrusPerfHeadless=false;select MeshHeavyNode;max modify mode
        if modPanel.getCurrentObject()!=root do modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.populationUI.open=true;root.mainUI.bindSection root.populationUI
        CyrusShowMeshMaskPreview leaf
        root.refreshAll();CyrusPointSync()
        MeshQuietCounters=#(root.procEpoch,root.groupBuilds,root.groupHits,leaf.procPreparedBuilds,leaf.previewBuildCount,leaf.inputTimeQueries)
        MeshQuietNative=cyrusMeshDensityStats();MeshQuietRetained=cyrusRetainedStats owner
        deleteFile (MCPFixtureDir+"mesh-quiet-ready.txt")
        MeshQuietTicks=0;MeshQuietTimer=dotNetObject "System.Windows.Forms.Timer";MeshQuietTimer.Interval=100
        dotNet.addEventHandler MeshQuietTimer "Tick" MeshQuietTick;MeshQuietTimer.Start()
        MeshQuietStage=1
    ) else (
        local current=#(root.procEpoch,root.groupBuilds,root.groupHits,leaf.procPreparedBuilds,leaf.previewBuildCount,leaf.inputTimeQueries),retained=cyrusRetainedStats owner
        verify ((current as string)==(MeshQuietCounters as string)) "Five-second heavy idle preserves epoch, evaluations, preparation, preview and time-query counters" log
        verify ((cyrusMeshDensityStats() as string)==(MeshQuietNative as string)) "Five-second heavy idle performs zero new mesh channel reads/filter queries" log
        for i in #(1,2,3,4,5,6,7,9,10,11,12,13) do verify (retained[i]==MeshQuietRetained[i]) ("Heavy idle retained buffer field "+(i as string)+" unchanged") log
        verify (leaf.generatedCount==MeshHeavyCount and not leaf.dirty and not CyrusPointPending and not CyrusViewportRecordsDirty) "Heavy idle keeps complete placements and clears pending work" log
        MeshQuietTimer.Dispose();format "COMPLETE\n" to:log;MeshQuietStage=2
    )
    close log
)
