-- Separate hidden batch process only. Loads a saved scene; never saves it.
(
    global CyrusBench,AminScatterObject,CyrusSurfaceAnalyzer,AminScatterRenderRedrawHeld
    global CyrusPFTimer,CyrusReleaseTimer,CyrusAnalyzerTimer,AminScatterNodeEvents,CyrusAnalyzerEvents
    global cyrusScatterCPUThreads,cyrusScatterComputeStats
    local cfg=CyrusBench,log=createFile (cfg[3]+"result.txt")
    fn require value reason = (if not value do throw reason)
    fn stopAutomation = (
        try(CyrusPFTimer.Stop())catch();try(CyrusReleaseTimer.Stop())catch();try(CyrusAnalyzerTimer.Stop())catch()
        try(AminScatterNodeEvents.enabled=false)catch();try(CyrusAnalyzerEvents.enabled=false)catch()
        try(unRegisterRedrawViewsCallback AminScatterObjectDraw)catch()
        try(unRegisterRedrawViewsCallback CyrusSurfaceAnalyzerDraw)catch()
        AminScatterRenderRedrawHeld=true
    )
    fn rowsFile path rows = (
        local stream=fopen path "wb"
        if stream==undefined do throw "Could not create ordered fixture"
        try (
            writeLong stream rows.count
            for row in rows do (
                for k=1 to 4 do (
                    local v=row[1][k]
                    writeFloat stream v.x;writeFloat stream v.y;writeFloat stream v.z
                )
                writeLong stream row[2]
            )
            fclose stream
        ) catch(fclose stream;throw())
    )
    fn elapsedMS clock = (formattedPrint (clock.Elapsed.TotalMilliseconds as double) format:".6f")
    try (
        require ((maxVersion())[1]==29000) "Expected Max 2027"
        fileIn cfg[1];fileIn cfg[2];stopAutomation()
        if cyrusScatterCPUThreads!=undefined do cyrusScatterCPUThreads cfg[5]
        require (loadMaxFile cfg[4] quiet:true useFileUnits:true) "Could not load scene"
        stopAutomation()
        local owner=getNodeByName "Cyrus Scatter001"
        local surface=getNodeByName "Plane001"
        require (isValidNode owner and classof owner.baseObject==AminScatterObject) "Controller not found"
        require (isValidNode surface and classof surface.baseObject==Editable_Poly) "Expected Plane001 Editable Poly"
        local controller=owner.baseObject
        local analyzers=for n in objects where classof n.baseObject==CyrusSurfaceAnalyzer collect n.baseObject
        local original=for i=1 to polyop.getNumVerts surface collect (in coordsys world polyop.getVert surface i)
        local border=polyop.getOpenEdges surface,left=0,right=0,minimum=1e30,maximum=-1e30
        for e in border do (
            local ids=polyop.getEdgeVerts surface e
            local mid=(original[ids[1]]+original[ids[2]])*.5
            if mid.x<minimum do (minimum=mid.x;left=e)
            if mid.x>maximum do (maximum=mid.x;right=e)
        )
        require (left>0 and right>0 and left!=right) "Could not choose boundary edges"
        local displacement=units.decodeValue "150cm"
        local recipe=createFile (cfg[3]+"recipe.txt")
        format "Scene: %\nController: %\nSurface: %\nWorld X left edge: % vertices %\nWorld X right edge: % vertices %\nDisplacement: 150 centimeters in world X\nUndo: exactly one Max Undo per move\n%\n" cfg[4] owner.name surface.name left (polyop.getEdgeVerts surface left) right (polyop.getEdgeVerts surface right) (maxVersion()) to:recipe
        for i=1 to original.count do format "vertex %: %\n" i original[i] to:recipe
        close recipe
        local timings=createFile (cfg[3]+"timings.csv")
        format "phase,kind,layer,trial,elapsed_ms,rows,participants,cluster_queries\n" to:timings
        fn evaluatePhase label controller analyzers cfg timings log = (
            with undo off for analyzer in analyzers do analyzer.runAnalysis()
            -- Warm cache/allocation before timed refreshes. Full rebuild explicitly
            -- changes the manual revision, so blocker work is included each time.
            with undo off controller.refreshAll()
            for trial=1 to cfg[6] do (
                local clock=dotNetObject "System.Diagnostics.Stopwatch"
                clock.Start();with undo off controller.refreshAll();clock.Stop()
                format "%,controller_refresh,all,%,%,0,0,0\n" label trial (elapsedMS clock) to:timings;flush timings
            )
            for entry in controller.layerEntries() do (
                local layer=entry[2],plants=layer.validSources(),rows=#()
                for trial=1 to cfg[6] do (
                    local clock=dotNetObject "System.Diagnostics.Stopwatch"
                    clock.Start();with undo off rows=layer.placements plants previewOnly:true;clock.Stop()
                    local stats=if cyrusScatterComputeStats!=undefined then cyrusScatterComputeStats() else #(1,0)
                    format "%,placements,%,%,%,%,%,%\n" label entry[1] trial (elapsedMS clock) rows.count stats[1] stats[2] to:timings;flush timings
                )
                rowsFile (cfg[3]+label+"-layer-"+(entry[1] as string)+".bin") rows
                -- Render filtering is part of the exact output gate too.
                with undo off rows=layer.placements plants
                rowsFile (cfg[3]+label+"-render-"+(entry[1] as string)+".bin") rows
                local state=layer.cacheSnapshot()
                require (state[4]=="") ("Preview error: "+state[4])
                format "PASS % layer % (% rows)\n" label entry[1] rows.count to:log;flush log
            )
        )
        evaluatePhase "base" controller analyzers cfg timings log
        undo "Cyrus benchmark right extension" on (in coordsys world polyop.moveVert surface (polyop.getEdgeVerts surface right) [displacement,0,0])
        update surface
        evaluatePhase "right_extend" controller analyzers cfg timings log
        max undo
        for i=1 to original.count do require ((in coordsys world polyop.getVert surface i)==original[i]) "Undo did not restore right edge"
        evaluatePhase "undo_right" controller analyzers cfg timings log
        undo "Cyrus benchmark left expansion" on (in coordsys world polyop.moveVert surface (polyop.getEdgeVerts surface left) [-displacement,0,0])
        update surface
        evaluatePhase "left_expand" controller analyzers cfg timings log
        max undo
        for i=1 to original.count do require ((in coordsys world polyop.getVert surface i)==original[i]) "Undo did not restore left edge"
        evaluatePhase "undo_left" controller analyzers cfg timings log
        close timings
        format "SUCCESS\n" to:log;close log
        stopAutomation()
    ) catch (
        format "FAILED: %\n" (getCurrentException()) to:log;close log
        stopAutomation();throw()
    )
)
