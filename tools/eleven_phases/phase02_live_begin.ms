(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P02 host required"
    global P02LiveNode,P02LiveRoot,P02LiveLeaf,P02LiveEpoch,P02LiveTarget,P02LiveBefore,P02LiveProposal
    deleteFile (MCPFixtureDir+"phase02-live-ready.txt")
    deleteFile (MCPFixtureDir+"phase02-live-setup-ready.txt")
    global P02LiveSetupTimer,P02LiveSetupTick,P02LiveSetupEpoch,P02LiveSetupQuiet
    try(P02LiveSetupTimer.Stop();P02LiveSetupTimer.Dispose())catch()
    CyrusPerfHeadless=true;resetMaxFile #noPrompt
    P02LiveNode=AminScatterObject name:"P02 Live scheduling";P02LiveRoot=P02LiveNode.baseObject
    P02LiveRoot.updateMode=1;P02LiveRoot.autoRender=false
    local receiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
    P02LiveRoot.newLayer();P02LiveLeaf=P02LiveRoot.selectedLayer()
    P02LiveRoot.setLayerSurfaces P02LiveLeaf #(receiver);P02LiveLeaf.addPointSource()
    P02LiveLeaf.amount=40;P02LiveLeaf.procSelfOverride=true;P02LiveLeaf.procSelfEnabled=false
    P02LiveRoot.refreshAll();CyrusPointSync()
    P02LiveTarget=CyrusPresetMakeBinding P02LiveRoot P02LiveLeaf "population"
    local values=CyrusPresetCapture P02LiveTarget
    values[1]=75;values[4]=12345;values[6]=3;values[7]=2
    CyrusPerfHeadless=false;select P02LiveNode;max modify mode;modPanel.setCurrentObject P02LiveRoot
    if not P02LiveRoot.mainUI.controlsReady do P02LiveRoot.mainUI.mountTimer.tick()
    P02LiveRoot.updateMode=2
    P02LiveProposal=#("population","Live",values)
    -- Queued receiver creation notifications can outlive this request. Establish
    -- a stable baseline in separate host events before measuring the Apply action.
    P02LiveSetupEpoch=P02LiveRoot.procEpoch;P02LiveSetupQuiet=0
    fn P02LiveSetupTick sender args = (
        if P02LiveRoot.procEpoch==P02LiveSetupEpoch and not CyrusPointPending and not CyrusPointBusy then P02LiveSetupQuiet+=1
        else (P02LiveSetupEpoch=P02LiveRoot.procEpoch;P02LiveSetupQuiet=0)
        if P02LiveSetupQuiet>=10 do (
            P02LiveSetupTimer.Stop()
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase02-live-setup-ready.txt") (P02LiveSetupEpoch as string)
        )
    )
    P02LiveSetupTimer=dotNetObject "System.Windows.Forms.Timer";P02LiveSetupTimer.Interval=100
    dotNet.addEventHandler P02LiveSetupTimer "Tick" P02LiveSetupTick;P02LiveSetupTimer.Start()
)
