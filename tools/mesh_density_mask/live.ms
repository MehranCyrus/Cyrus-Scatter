-- Separate host events qualify real Live callbacks and quiet windows.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-meshmask-*/" do throw "Owned mask host required"
    global MeshLiveStage,MeshLiveEpoch,MeshLiveNative,MeshLivePrepared,MeshLivePreview,MeshLiveUnrelated
    if MeshLiveStage==undefined do MeshLiveStage=0
    global MeshLiveTimer,MeshLiveTicks,MeshLiveArm,MeshLiveTick
    fn MeshLiveTick sender args = (
        MeshLiveTicks+=1
        if MeshLiveTicks>=20 do (
            MeshLiveTimer.Stop()
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"mesh-live-ready.txt") "ready"
        )
    )
    fn MeshLiveArm = (
        try(MeshLiveTimer.Stop();MeshLiveTimer.Dispose())catch()
        deleteFile (MCPFixtureDir+"mesh-live-ready.txt")
        MeshLiveTicks=0;MeshLiveTimer=dotNetObject "System.Windows.Forms.Timer";MeshLiveTimer.Interval=100
        dotNet.addEventHandler MeshLiveTimer "Tick" MeshLiveTick;MeshLiveTimer.Start()
    )
    local stage=MeshLiveStage+1,root=MeshMaskRoot,leaf=MeshMaskLeaf,receiver=MeshMaskReceiver
    local log=if stage==1 then createFile (MCPFixtureDir+"mesh-mask-live.txt") else openFile (MCPFixtureDir+"mesh-mask-live.txt") mode:"a"
    fn verify pass label log = (format "%: %\n" (if pass then "PASS" else "FAIL") label to:log;flush log;if not pass do throw label)
    try (
        case stage of (
            1: (
                CyrusPerfHeadless=false;select MeshMaskNode;max modify mode
                if modPanel.getCurrentObject()!=root do modPanel.setCurrentObject root
                if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
                root.populationUI.open=true;root.mainUI.bindSection root.populationUI
                verify (root.populationUI.distributionUI_meshCheck.checked and root.populationUI.distributionUI_meshChannelSpin.value==1) "Native Amount view binds the current mesh mask owner" log
                root.updateMode=2;root.refreshAll();CyrusPointSync()
                MeshLiveEpoch=root.procEpoch
                root.populationUI.distributionUI_meshInvertCheck.changed true
                MeshLiveArm()
            )
            2: (
                verify (leaf.meshMaskInvert and leaf.generatedCount==0 and root.procEpoch==MeshLiveEpoch+1) "Actual Invert UI handler publishes exactly one Live successor" log
                MeshLiveEpoch=root.procEpoch
                for i=1 to meshop.getNumMapVerts receiver 1 do meshop.setMapVert receiver 1 i [0,0,0]
                update receiver;MeshLiveArm()
            )
            3: (
                verify (leaf.generatedCount==1000 and root.procEpoch==MeshLiveEpoch+1) "Real mapping notification updates Live channel-only changes exactly once" log
                root.updateMode=1;MeshLiveEpoch=root.procEpoch
                root.populationUI.distributionUI_meshInvertCheck.changed false
                MeshLiveArm()
            )
            4: (
                verify (not leaf.meshMaskInvert and leaf.generatedCount==1000 and root.procEpoch==MeshLiveEpoch) "Manual UI edits remain pending through real idle callbacks" log
                root.refreshAll()
                verify (leaf.generatedCount==0) "Explicit Update publishes pending Manual mesh mask" log
                root.updateMode=2;leaf.meshMaskInvert=true;MeshLiveArm()
            )
            5: (
                verify (leaf.generatedCount==1000) "Live recovery restores prior base edits and plants" log
                MeshLiveUnrelated=box name:"Mask unrelated" pos:[1000,1000,0]
                with animate on (at time 0 MeshLiveUnrelated.pos=[1000,1000,0];at time 10 MeshLiveUnrelated.pos=[1001,1000,0])
                MeshLiveEpoch=root.procEpoch;MeshLiveNative=cyrusMeshDensityStats();MeshLivePrepared=leaf.procPreparedBuilds;MeshLivePreview=leaf.previewBuildCount
                sliderTime=10;root.coverageUI.open=true;root.mainUI.bindSection root.coverageUI
                MeshLiveArm()
            )
            6: (
                verify (root.procEpoch==MeshLiveEpoch and leaf.procPreparedBuilds==MeshLivePrepared and leaf.previewBuildCount==MeshLivePreview) "Unrelated animation and panel browsing reuse placements and preview" log
                verify ((cyrusMeshDensityStats() as string)==(MeshLiveNative as string)) "Unrelated animation and browsing perform zero mesh channel reads/filter queries" log
                MeshLiveEpoch=root.procEpoch;leaf.meshMaskChannel=98;MeshLiveArm()
            )
            7: (
                verify (leaf.generatedCount==1000 and root.procEpoch==MeshLiveEpoch) "Missing Live channel retains complete prior output and epoch" log
                leaf.meshMaskChannel=1;MeshLiveArm()
            )
            8: (
                verify (leaf.generatedCount==1000 and (root.procEpoch==MeshLiveEpoch or root.procEpoch==MeshLiveEpoch+1) and leaf.previewError=="" and root.previewError=="") "Restoring Live channel recovers complete output and clears errors, reusing the prior publication when identical" log
                CyrusShowMeshMaskPreview leaf
                verify (CyrusMeshMaskPreviewRows.count>0 and CyrusMeshMaskPreviewRows.count<=2048) "Explicit preview creates bounded grayscale snapshots" log
                MeshLiveNative=cyrusMeshDensityStats();MeshLiveEpoch=root.procEpoch;MeshLivePrepared=leaf.procPreparedBuilds;MeshLivePreview=leaf.previewBuildCount
                MeshLiveArm()
            )
            9: (
                verify ((cyrusMeshDensityStats() as string)==(MeshLiveNative as string) and root.procEpoch==MeshLiveEpoch and leaf.procPreparedBuilds==MeshLivePrepared and leaf.previewBuildCount==MeshLivePreview) "Quiet idle with mask preview performs zero channel reads, solves or preview builds" log
                CyrusClearMeshMaskPreview undefined
                verify (CyrusMeshMaskPreviewRows.count==0) "Hide preview clears only cached marker display" log
                MeshLiveTimer.Dispose();format "COMPLETE\n" to:log
            )
        )
        MeshLiveStage=stage;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
