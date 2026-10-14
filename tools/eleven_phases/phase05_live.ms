-- Each stage runs in a separate host event. The observer only reads counters.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
    global P05Stage,P05Root,P05Leaf,P05Area,P05Other,P05Curve,P05Epoch,P05First,P05Second,P05Revision,P05Timer,P05Stable,P05Seen,P05Arm,P05Tick
    if P05Stage==undefined do P05Stage=0
    fn P05Tick sender args = (
        local epoch=P05Root.procEpoch
        if epoch==P05Seen and not CyrusPointPending and not CyrusPointBusy then P05Stable+=1 else P05Stable=0
        P05Seen=epoch
        if P05Stable>=10 do (P05Timer.Stop();(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase05-live-ready.txt") (epoch as string))
    )
    fn P05Arm = (
        try(P05Timer.Stop();P05Timer.Dispose())catch()
        deleteFile (MCPFixtureDir+"phase05-live-ready.txt")
        P05Stable=0;P05Seen=P05Root.procEpoch
        P05Timer=dotNetObject "System.Windows.Forms.Timer";P05Timer.Interval=100
        dotNet.addEventHandler P05Timer "Tick" P05Tick;P05Timer.Start()
    )
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    fn rowKey root i = (with printAllElements on (root.groupSnapshotRows[i] as string))
    local stage=P05Stage+1
    local log=if stage==1 then createFile (MCPFixtureDir+"phase05-live.txt") else openFile (MCPFixtureDir+"phase05-live.txt") mode:"a"
    try (
        case stage of (
            1: (
                CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
                local node=AminScatterObject name:"P05 Live",receiver=plane length:60 width:60 lengthsegs:1 widthsegs:1
                P05Root=node.baseObject;P05Root.updateMode=1;P05Root.autoRender=false
                P05Root.newLayer();P05Leaf=P05Root.selectedLayer()
                P05Root.setLayerSurfaces P05Leaf #(receiver);P05Leaf.addPointSource();P05Leaf.amount=2000
                P05Leaf.procSelfOverride=true;P05Leaf.procSelfEnabled=false
                P05Area=P05Root.addPaintArea P05Leaf target:receiver;P05Curve=circle radius:20
                P05Root.importPaintSpline P05Area P05Curve tolerance:0.002
                P05Root.newLayer();P05Other=P05Root.selectedLayer()
                P05Root.setLayerSurfaces P05Other #(receiver);P05Other.addPointSource();P05Other.amount=80
                P05Other.procSelfOverride=true;P05Other.procSelfEnabled=false
                P05Root.refreshAll();CyrusPointSync()
                CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject P05Root
                if not P05Root.mainUI.controlsReady do P05Root.mainUI.mountTimer.tick()
                P05Root.updateMode=2;P05Arm()
            )
            2: (
                P05Epoch=P05Root.procEpoch;P05First=rowKey P05Root 1;P05Second=rowKey P05Root 2
                P05Curve.radius=10;P05Root.importPaintSpline P05Area P05Curve tolerance:0.002;P05Arm()
            )
            3: (
                verify (P05Root.procEpoch==P05Epoch+1 and (rowKey P05Root 1)!=P05First) "Import publishes exactly one Live successor" log
                verify ((rowKey P05Root 2)==P05Second) "Independent layer full placements stay unchanged" log
                P05Epoch=P05Root.procEpoch;P05First=rowKey P05Root 1;P05Revision=(cyrusBrushStats P05Area.paintDocument)[1]
                local exported=P05Root.exportPaintSpline P05Area
                verify (not (P05Root.importPaintSpline P05Area exported tolerance:0.002)) "Exact snapshot import is a no-op" log
                P05Arm()
            )
            4: (
                verify (P05Root.procEpoch==P05Epoch and (rowKey P05Root 1)==P05First and (cyrusBrushStats P05Area.paintDocument)[1]==P05Revision) "Export and no-op import schedule no Live successor" log
                P05Curve.radius=25;delete P05Curve;P05Arm()
            )
            5: (
                verify (P05Root.procEpoch==P05Epoch and (rowKey P05Root 1)==P05First and (cyrusBrushStats P05Area.paintDocument)[1]==P05Revision) "Source edits/deletion schedule no Live successor" log
                P05Root.updateMode=1;P05Curve=circle radius:15
                P05Root.importPaintSpline P05Area P05Curve tolerance:0.002;P05Arm()
            )
            6: (
                verify (P05Root.procEpoch==P05Epoch and (rowKey P05Root 1)==P05First) "Manual import remains pending across host events" log
                P05Root.refreshAll()
                verify ((rowKey P05Root 1)!=P05First and (rowKey P05Root 2)==P05Second) "Explicit Update publishes import and preserves unrelated layer" log
                verify (not theHold.Holding()) "Live and Manual commands leave no stranded hold" log
                format "COMPLETE\n" to:log
            )
        )
        P05Stage=stage;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
