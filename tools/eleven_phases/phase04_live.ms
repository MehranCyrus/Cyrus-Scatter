-- Invoke stages in separate host events, waiting for the observer file between
-- stages 2/3, 3/4 and 5/6. No explicit solve is used for the measured successors.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p04-*/" do throw "Owned P04 host required"
    global P04LiveStage,P04LiveNode,P04LiveRoot,P04LiveLeaf,P04LiveReceiver,P04LiveEpoch,P04LivePrepared
    global P04LiveUVCount,P04LiveReceiverBuilds
    global P04LiveBakes
    global P04LiveTimer,P04LiveTicks,P04LiveExpected,P04LiveReadyTick,P04LiveStart,P04LiveArm
    if P04LiveStage==undefined do P04LiveStage=0
    local stage=P04LiveStage+1
    fn P04LiveReadyTick sender args = (
        P04LiveTicks+=1
        if (P04LiveExpected>=0 and P04LiveLeaf.generatedCount==P04LiveExpected) or (P04LiveExpected<0 and P04LiveTicks>=5) do (
            P04LiveTimer.Stop()
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase04-live-ready.txt") ((timeStamp()-P04LiveStart) as string)
        )
    )
    fn P04LiveArm expected = (
        try(P04LiveTimer.Stop();P04LiveTimer.Dispose())catch()
        deleteFile (MCPFixtureDir+"phase04-live-ready.txt")
        P04LiveTicks=0;P04LiveExpected=expected;P04LiveStart=timeStamp()
        P04LiveTimer=dotNetObject "System.Windows.Forms.Timer";P04LiveTimer.Interval=100
        dotNet.addEventHandler P04LiveTimer "Tick" P04LiveReadyTick
        P04LiveTimer.Start()
    )
    local log=if stage==1 then createFile (MCPFixtureDir+"phase04-live.txt") else openFile (MCPFixtureDir+"phase04-live.txt") mode:"a"
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    try (
        case stage of (
            1: (
                CyrusPerfHeadless=true;resetMaxFile #noPrompt
                units.SystemType=#meters;units.SystemScale=1
                P04LiveNode=AminScatterObject name:"P04 Live";P04LiveRoot=P04LiveNode.baseObject
                P04LiveRoot.updateMode=1;P04LiveRoot.autoRender=false
                P04LiveReceiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
                P04LiveRoot.newLayer();P04LiveLeaf=P04LiveRoot.selectedLayer()
                P04LiveRoot.setLayerSurfaces P04LiveLeaf #(P04LiveReceiver);P04LiveLeaf.addPointSource()
                P04LiveLeaf.amount=80;P04LiveLeaf.procSelfOverride=true;P04LiveLeaf.procSelfEnabled=false
                P04LiveLeaf.distributionMode=3;P04LiveLeaf.densityMap=checker color1:white color2:white
                local unrelated=box name:"P04 unrelated animation" pos:[1000,1000,0]
                with animate on (at time 0 unrelated.pos=[1000,1000,0];at time 10 unrelated.pos=[1010,1000,10])
                sliderTime=0;P04LiveRoot.refreshAll();CyrusPointSync()
                CyrusPerfHeadless=false;select P04LiveNode;max modify mode;modPanel.setCurrentObject P04LiveRoot
                if not P04LiveRoot.mainUI.controlsReady do P04LiveRoot.mainUI.mountTimer.tick()
                P04LiveRoot.populationUI.open=true;P04LiveRoot.mainUI.bindSection P04LiveRoot.populationUI
                python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/eleven_phases/phase04_ui.py"
                P04LiveRoot.updateMode=2
            )
            2: (
                P04LiveEpoch=P04LiveRoot.procEpoch;P04LiveBakes=(P04LiveLeaf.densityCacheStats())[1]
                python.Execute "p04_choose_resolution(1)"
                P04LiveArm -1
            )
            3: (
                verify (P04LiveLeaf.densityResolution==64 and P04LiveRoot.procEpoch==P04LiveEpoch+1) "Actual native resolution event publishes exactly one Live successor" log
                verify ((P04LiveLeaf.densityCacheStats())[1]==P04LiveBakes+1) "Live resolution edit bakes exactly one new image" log
                P04LiveEpoch=P04LiveRoot.procEpoch;P04LivePrepared=P04LiveLeaf.procPreparedBuilds;P04LiveBakes=(P04LiveLeaf.densityCacheStats())[1]
                sliderTime=10;P04LiveArm -1
            )
            4: (
                verify (P04LiveRoot.procEpoch==P04LiveEpoch and P04LiveLeaf.procPreparedBuilds==P04LivePrepared and (P04LiveLeaf.densityCacheStats())[1]==P04LiveBakes) "Unrelated animation does not solve or bake a static map" log
                P04LiveRoot.updateMode=1;sliderTime=0
                with animate on (
                    at time 0 (P04LiveLeaf.densityMap.color1=white;P04LiveLeaf.densityMap.color2=white)
                    at time 10 (P04LiveLeaf.densityMap.color1=black;P04LiveLeaf.densityMap.color2=black)
                )
                P04LiveRoot.refreshAll();CyrusPointSync();P04LiveRoot.updateMode=2
            )
            5: (
                P04LiveEpoch=P04LiveRoot.procEpoch;P04LiveBakes=(P04LiveLeaf.densityCacheStats())[1]
                sliderTime=10;P04LiveArm 0
            )
            6: (
                verify (P04LiveLeaf.generatedCount==0 and P04LiveRoot.procEpoch>P04LiveEpoch and (P04LiveLeaf.densityCacheStats())[1]>P04LiveBakes) "Animated map validity expires and Live publishes black eligibility" log
                P04LiveRoot.updateMode=1;P04LiveEpoch=P04LiveRoot.procEpoch;P04LiveBakes=(P04LiveLeaf.densityCacheStats())[1];sliderTime=0
                for i=1 to 30 do (P04LiveRoot.mainUI.bindSection P04LiveRoot.populationUI;P04LiveRoot.mainUI.refreshStats())
                verify (P04LiveLeaf.generatedCount==0 and P04LiveRoot.procEpoch==P04LiveEpoch and (P04LiveLeaf.densityCacheStats())[1]==P04LiveBakes) "Manual timeline and passive UI preserve map result and bake" log
                P04LiveRoot.refreshAll()
                verify (P04LiveLeaf.generatedCount==80 and (P04LiveLeaf.densityCacheStats())[1]>P04LiveBakes) "Explicit Update consumes the pending animated map" log
                P04LiveLeaf.densityMap=checker color1:white color2:white
                with animate on (at time 0 P04LiveReceiver.pos=[0,0,0];at time 10 P04LiveReceiver.pos=[0,0,20])
                P04LiveRoot.refreshAll();CyrusPointSync();P04LiveRoot.updateMode=2
            )
            7: (
                P04LiveEpoch=P04LiveRoot.procEpoch;P04LiveBakes=(P04LiveLeaf.densityCacheStats())[1]
                sliderTime=10;P04LiveArm -1
            )
            8: (
                verify (P04LiveRoot.procEpoch>P04LiveEpoch and P04LiveLeaf.generatedCount==80 and abs(P04LiveRoot.groupSnapshotRows[1][1][1].row4.z-20)<0.001) "Relevant receiver animation updates mapped placements" log
                verify ((P04LiveLeaf.densityCacheStats())[1]==P04LiveBakes) "Static map bake survives relevant receiver animation" log
                verify (not theHold.Holding()) "Live controls leave no enclosing transaction" log
            )
            9: (
                P04LiveRoot.updateMode=1
                convertToMesh P04LiveReceiver
                for i=1 to meshop.getNumMapVerts P04LiveReceiver 1 do meshop.setMapVert P04LiveReceiver 1 i [0.1,0.1,0]
                meshop.setNumMaps P04LiveReceiver 3 keep:true;meshop.setMapSupport P04LiveReceiver 2 true
                meshop.setNumMapVerts P04LiveReceiver 2 (meshop.getNumMapVerts P04LiveReceiver 1)
                meshop.setNumMapFaces P04LiveReceiver 2 P04LiveReceiver.numfaces
                for i=1 to meshop.getNumMapVerts P04LiveReceiver 2 do meshop.setMapVert P04LiveReceiver 2 i [0.1,0.1,0]
                for i=1 to P04LiveReceiver.numfaces do meshop.setMapFace P04LiveReceiver 2 i (meshop.getMapFace P04LiveReceiver 1 i)
                update P04LiveReceiver
                P04LiveLeaf.densityMap=checker color1:white color2:black
                P04LiveRoot.refreshAll();CyrusPointSync()
                P04LiveUVCount=P04LiveLeaf.generatedCount
                verify (P04LiveUVCount==0 or P04LiveUVCount==80) "Constant UV channel samples one binary checker cell" log
                P04LiveRoot.updateMode=2
            )
            10: (
                P04LiveEpoch=P04LiveRoot.procEpoch;P04LiveBakes=(P04LiveLeaf.densityCacheStats())[1]
                for i=1 to meshop.getNumMapVerts P04LiveReceiver 1 do meshop.setMapVert P04LiveReceiver 1 i [0.1,0.6,0]
                update P04LiveReceiver;CyrusViewportRedraw();P04LiveArm (80-P04LiveUVCount)
            )
            11: (
                verify (P04LiveLeaf.generatedCount==80-P04LiveUVCount and P04LiveRoot.procEpoch>P04LiveEpoch) "Selected UV edit triggers Live generation from actual geometry notifications" log
                verify ((P04LiveLeaf.densityCacheStats())[1]==P04LiveBakes) "Selected UV edit retains static sampled map" log
                P04LiveReceiverBuilds=(P04LiveLeaf.receiverCacheStats())[1]
                for i=1 to meshop.getNumMapVerts P04LiveReceiver 2 do meshop.setMapVert P04LiveReceiver 2 i [0.3,0.4,0]
                update P04LiveReceiver;CyrusViewportRedraw();P04LiveArm -1
            )
            12: (
                verify ((P04LiveLeaf.receiverCacheStats())[1]==P04LiveReceiverBuilds and (P04LiveLeaf.densityCacheStats())[1]==P04LiveBakes and P04LiveLeaf.generatedCount==80-P04LiveUVCount) "Unselected UV edit reuses receiver candidates and map samples" log
                format "COMPLETE\n" to:log
            )
            default: throw "Unexpected Live fixture stage"
        )
        P04LiveStage=stage;format "STAGE %\n" stage to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
