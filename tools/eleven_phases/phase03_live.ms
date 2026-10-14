-- Invoke stages in separate host events, waiting for the observer file between
-- stages 2/3, 3/4 and 5/6. No explicit solve is used for the measured successors.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p03-*/" do throw "Owned P03 host required"
    global P03LiveStage,P03LiveNode,P03LiveRoot,P03LiveLeaf,P03LiveReceiver,P03LiveEpoch,P03LivePrepared
    global P03LiveTimer,P03LiveTicks,P03LiveExpected,P03LiveReadyTick,P03LiveStart,P03LiveArm
    if P03LiveStage==undefined do P03LiveStage=0
    local stage=P03LiveStage+1
    fn P03LiveReadyTick sender args = (
        P03LiveTicks+=1
        if (P03LiveExpected>=0 and P03LiveLeaf.generatedCount==P03LiveExpected) or (P03LiveExpected<0 and P03LiveTicks>=5) do (
            P03LiveTimer.Stop()
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase03-live-ready.txt") ((timeStamp()-P03LiveStart) as string)
        )
    )
    fn P03LiveArm expected = (
        try(P03LiveTimer.Stop();P03LiveTimer.Dispose())catch()
        deleteFile (MCPFixtureDir+"phase03-live-ready.txt")
        P03LiveTicks=0;P03LiveExpected=expected;P03LiveStart=timeStamp()
        P03LiveTimer=dotNetObject "System.Windows.Forms.Timer";P03LiveTimer.Interval=100
        dotNet.addEventHandler P03LiveTimer "Tick" P03LiveReadyTick
        P03LiveTimer.Start()
    )
    local log=if stage==1 then createFile (MCPFixtureDir+"phase03-live.txt") else openFile (MCPFixtureDir+"phase03-live.txt") mode:"a"
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    try (
        case stage of (
            1: (
                CyrusPerfHeadless=true;resetMaxFile #noPrompt
                units.SystemType=#meters;units.SystemScale=1
                P03LiveNode=AminScatterObject name:"P03 Live";P03LiveRoot=P03LiveNode.baseObject
                P03LiveRoot.updateMode=1;P03LiveRoot.autoRender=false
                P03LiveReceiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
                P03LiveRoot.newLayer();P03LiveLeaf=P03LiveRoot.selectedLayer()
                P03LiveRoot.setLayerSurfaces P03LiveLeaf #(P03LiveReceiver);P03LiveLeaf.addPointSource()
                P03LiveLeaf.amount=80;P03LiveLeaf.procSelfOverride=true;P03LiveLeaf.procSelfEnabled=false
                P03LiveLeaf.altitudeEnabled=true;P03LiveLeaf.altitudeMinimum=-1;P03LiveLeaf.altitudeMaximum=1
                local unrelated=box name:"P03 unrelated animation" pos:[1000,1000,0]
                with animate on (at time 0 unrelated.pos=[1000,1000,0];at time 10 unrelated.pos=[1010,1000,10])
                sliderTime=0;P03LiveRoot.refreshAll();CyrusPointSync()
                CyrusPerfHeadless=false;select P03LiveNode;max modify mode;modPanel.setCurrentObject P03LiveRoot
                if not P03LiveRoot.mainUI.controlsReady do P03LiveRoot.mainUI.mountTimer.tick()
                P03LiveRoot.areasUI.open=true;P03LiveRoot.mainUI.bindSection P03LiveRoot.areasUI
                P03LiveRoot.updateMode=2
            )
            2: (
                P03LiveEpoch=P03LiveRoot.procEpoch;P03LivePrepared=P03LiveLeaf.procPreparedBuilds
                P03LiveRoot.areasUI.areaUI_altitudeMinSpin.changed 0.5
                P03LiveArm 0
            )
            3: (
                verify (P03LiveLeaf.generatedCount==0 and P03LiveRoot.procEpoch==P03LiveEpoch+1) "Actual Live filter callback publishes exactly one successor" log
                verify ((P03LiveLeaf.surfaceFilterStats())[2]==80) "Live diagnostics publish with rejected rows" log
                P03LiveLeaf.altitudeMinimum=-1;P03LiveRoot.refreshAll();CyrusPointSync()
                P03LiveEpoch=P03LiveRoot.procEpoch;P03LivePrepared=P03LiveLeaf.procPreparedBuilds
                sliderTime=10
                P03LiveArm -1
            )
            4: (
                verify (P03LiveRoot.procEpoch==P03LiveEpoch and P03LiveLeaf.procPreparedBuilds==P03LivePrepared and P03LiveLeaf.generatedCount==80) "Unrelated animation does not rebuild filtered static placements" log
                P03LiveRoot.updateMode=1;sliderTime=0
                with animate on (at time 0 P03LiveReceiver.pos=[0,0,0];at time 10 P03LiveReceiver.pos=[0,0,20])
                P03LiveRoot.refreshAll();CyrusPointSync();P03LiveRoot.updateMode=2
            )
            5: (
                P03LiveEpoch=P03LiveRoot.procEpoch
                sliderTime=10
                P03LiveArm 0
            )
            6: (
                verify (P03LiveLeaf.generatedCount==0 and P03LiveRoot.procEpoch>P03LiveEpoch) "Relevant receiver animation reevaluates world altitude in Live" log
                verify ((P03LiveLeaf.surfaceFilterStats())[2]==80) "Animated filter diagnostics agree with the published result" log
                P03LiveRoot.updateMode=1;P03LiveEpoch=P03LiveRoot.procEpoch;sliderTime=0
                for i=1 to 30 do (P03LiveRoot.mainUI.bindSection P03LiveRoot.areasUI;P03LiveRoot.mainUI.refreshStats())
                verify (P03LiveLeaf.generatedCount==0 and P03LiveRoot.procEpoch==P03LiveEpoch) "Manual time and passive UI preserve last accepted filter result" log
                P03LiveRoot.refreshAll()
                verify (P03LiveLeaf.generatedCount==80) "Explicit Update consumes the Manual receiver-time change" log
                verify (not theHold.Holding()) "Live controls leave no enclosing transaction" log
                format "COMPLETE\n" to:log
            )
            default: throw "Unexpected Live fixture stage"
        )
        P03LiveStage=stage;format "STAGE %\n" stage to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
