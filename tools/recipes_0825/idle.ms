-- A 60-second event-loop observation on a 200k-candidate two-layer scene.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
    global RecipeIdleRoot,RecipeIdleNode,RecipeIdleTimer,RecipeIdleClock,RecipeIdleBefore,RecipeIdleAfter,RecipeIdleSnapshot,RecipeIdleTick,RecipeIdlePhase=0
    CyrusPerfHeadless=false;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    RecipeIdleNode=AminScatterObject name:"Recipe idle 200k";RecipeIdleRoot=RecipeIdleNode.baseObject
    local root=RecipeIdleRoot,terrain=plane width:100 length:100 widthsegs:30 lengthsegs:30,source=pyramid width:0.3 depth:0.3 height:0.7 pos:[60,0,0]
    convertToMesh terrain;root.updateMode=2;root.autoRender=false;root.viewportMode=3;root.viewportInstances=1000
    for i=1 to 2 do (
        root.newLayer();local leaf=root.selectedLayer();root.setLayerSurfaces leaf #(terrain)
        leaf.sources=#(source);leaf.ensureSourceRows();leaf.amount=100000;leaf.procLayerSelfEnabled=false
    )
    root.refreshAll();CyrusPointSync();completeRedraw();completeRedraw()
    fn RecipeIdleSnapshot = (
        local root=RecipeIdleRoot,native=cyrusRetainedStats (CyrusPointOwner RecipeIdleNode),stream=stringStream ""
        local values=#(root.procEpoch,root.groupBuilds,(for leaf in root.layerObjects collect leaf.procPreparedBuilds),(for leaf in root.layerObjects collect leaf.receiverCacheStats()),cyrusMeshDensityStats(),native[6],native[7],(for rows in root.groupSnapshotRows collect cyrusEditFingerprint rows "recipe-idle"))
        with printAllElements on format "%" values to:stream
        stream as string
    )
    fn RecipeIdleTick sender args = (
        if RecipeIdlePhase==0 and RecipeIdleClock.ElapsedMilliseconds>=5000 do (
            RecipeIdleBefore=RecipeIdleSnapshot();RecipeIdleClock.Restart();RecipeIdlePhase=1
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-idle-started.txt") RecipeIdleBefore
        )
        if RecipeIdlePhase==1 and RecipeIdleClock.ElapsedMilliseconds>=60000 do (
            RecipeIdleTimer.Stop();RecipeIdleClock.Stop();RecipeIdleAfter=RecipeIdleSnapshot();RecipeIdlePhase=2
            local text="candidates=200000\nseconds="+(RecipeIdleClock.Elapsed.TotalSeconds as string)+"\nunchanged="+((RecipeIdleAfter==RecipeIdleBefore) as string)+"\nbefore="+RecipeIdleBefore+"\nafter="+RecipeIdleAfter
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-idle.txt") text
        )
    )
    try(RecipeIdleTimer.Stop();RecipeIdleTimer.Dispose())catch()
    RecipeIdleClock=dotNetObject "System.Diagnostics.Stopwatch";RecipeIdleClock.Start()
    RecipeIdleTimer=dotNetObject "System.Windows.Forms.Timer";RecipeIdleTimer.Interval=1000
    dotNet.addEventHandler RecipeIdleTimer "Tick" RecipeIdleTick;RecipeIdleTimer.Start()
)
