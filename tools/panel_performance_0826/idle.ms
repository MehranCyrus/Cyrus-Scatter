-- Owned 60-second event-loop witness. The observer only reads counters.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-panel0826-*/" do throw "Owned panel host required"
    global PanelIdleTimer,PanelIdleClock,PanelIdlePhase=0,PanelIdleBefore,PanelIdleAfter,PanelIdleSnapshot,PanelIdleTick
    fn PanelIdleSnapshot = (
        local native=cyrusRetainedStats (CyrusPointOwner PanelNode),stream=stringStream ""
        local values=#(PanelRoot.procEpoch,PanelRoot.groupBuilds,
            (for leaf in PanelRoot.layerObjects collect #(leaf.procPreparedBuilds,leaf.previewBuildCount,leaf.procDensityBakes)),
            cyrusMeshDensityStats(),native[4],native[6],native[7])
        with printAllElements on format "%" values to:stream
        stream as string
    )
    fn PanelIdleTick sender args = (
        if PanelIdlePhase==0 and PanelIdleClock.ElapsedMilliseconds>=5000 do (
            PanelIdleBefore=PanelIdleSnapshot();PanelIdleClock.Restart();PanelIdlePhase=1
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"panel-idle-started.txt") PanelIdleBefore
        )
        if PanelIdlePhase==1 and PanelIdleClock.ElapsedMilliseconds>=60000 do (
            PanelIdleTimer.Stop();PanelIdleClock.Stop();PanelIdleAfter=PanelIdleSnapshot();PanelIdlePhase=2
            local text="seconds="+(PanelIdleClock.Elapsed.TotalSeconds as string)+"\nunchanged="+((PanelIdleAfter==PanelIdleBefore) as string)+"\nbefore="+PanelIdleBefore+"\nafter="+PanelIdleAfter
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"panel-idle.txt") text
        )
    )
    try(PanelIdleTimer.Stop();PanelIdleTimer.Dispose())catch()
    deleteFile (MCPFixtureDir+"panel-idle.txt")
    deleteFile (MCPFixtureDir+"panel-idle-started.txt")
    PanelIdleClock=dotNetObject "System.Diagnostics.Stopwatch";PanelIdleClock.Start()
    PanelIdleTimer=dotNetObject "System.Windows.Forms.Timer";PanelIdleTimer.Interval=1000
    dotNet.addEventHandler PanelIdleTimer "Tick" PanelIdleTick;PanelIdleTimer.Start()
)
