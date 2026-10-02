-- Fresh batch process; disposable scene and callback queues only.
(
    global AminScatterObject,CyrusSurfaceAnalyzer,AminScatterRenderRedrawHeld
    global CyrusPFTimer,CyrusReleaseTimer,CyrusAnalyzerTimer,AminScatterNodeEvents,CyrusAnalyzerEvents
    global CyrusScatterLiveBatchBegin,CyrusScatterLiveBatchEnd,CyrusScatterLiveBatchStats,AminScatterLiveChanged
    global cyrusScatterCPUThreads,cyrusScatterComputeStats,cyrusFilterSourceRows,cyrusApplySourceTransforms
    local root=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName()))+"../../")
    local log=createFile (root+"build/compute-performance-test/result.txt")
    fn require value reason = (if not value do throw reason)
    fn rowsEqual a b = (
        if a.count!=b.count do return false
        for i=1 to a.count do (
            if a[i][2]!=b[i][2] do return false
            for k=1 to 4 where a[i][1][k]!=b[i][1][k] do return false
        )
        true
    )
    fn rejected fnCall = (local failed=false;try(fnCall())catch(failed=true);failed)
    try (
        require ((maxVersion())[1]==29000) "Wrong Max version"
        fileIn (root+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
        fileIn (root+"AminScatter/scripts/AminScatterObject.ms")
        CyrusPFTimer.Stop();CyrusReleaseTimer.Stop();CyrusAnalyzerTimer.Stop()
        AminScatterNodeEvents.enabled=false;CyrusAnalyzerEvents.enabled=false
        unRegisterRedrawViewsCallback AminScatterObjectDraw
        unRegisterRedrawViewsCallback CyrusSurfaceAnalyzerDraw
        local rows=#(#(matrix3 1,1),#(matrix3 1,2),#(matrix3 1,3))
        local kept=cyrusFilterSourceRows rows #(true,false,true)
        require (kept.count==2 and kept[1]==rows[1] and kept[2]==rows[3]) "Unstable filter or copied rows"
        require ((cyrusFilterSourceRows rows #(false,false,false)).count==0) "All empty sources not removed"
        require ((cyrusFilterSourceRows #() #()).count==0) "Empty input failed"
        fn badRows = (cyrusFilterSourceRows rows #(true))
        require (rejected badRows) "Invalid source index accepted"
        format "PASS stable source filtering and errors\n" to:log;flush log
        local transforms=#(#((matrix3 [1.2,-.7,0] [.8,2,0] [0,0,-3] [14,-21,7]),1),#((matrix3 1),2))
        local expected=deepCopy transforms,actual=deepCopy transforms
        local scales=#(2.3,0.0),offsets=#(-7.8,13.0)
        for row in expected do (
            local tm=row[1],factor=scales[row[2]]
            tm.row1=tm.row1*factor;tm.row2=tm.row2*factor;tm.row3=tm.row3*factor
            tm.row4=tm.row4+[0,0,offsets[row[2]]];row[1]=tm
        )
        actual=cyrusApplySourceTransforms actual offsets scales
        require (rowsEqual actual expected) "Native source transforms differ"
        local before=deepCopy transforms
        fn badTransforms = (cyrusApplySourceTransforms transforms #(0.0) #(1.0))
        require (rejected badTransforms) "Invalid transform index accepted"
        require (rowsEqual before transforms) "Validation partially changed rows"
        format "PASS native source transforms and atomic validation\n" to:log;flush log
        local surface=plane length:1000 width:1000 lengthsegs:2 widthsegs:2
        local source=box length:10 width:10 height:30 pos:[1500,0,0]
        local owner=AminScatterObject(),controller=owner.baseObject
        controller.surfaceNodes=#(surface);controller.updateMode=2;controller.newLayer()
        local layer=controller.layerObjects[1]
        layer.sources=#(source);layer.addEmptySource();layer.addPointSource()
        layer.amount=6000;layer.sourceWeights=#(.2,1.0,.4);layer.sourceColors=#(red,blue,green)
        layer.diversityMode=2;layer.roughness=50;layer.blurryEdge=35;layer.diversityNoise=20
        layer.sourceScales=#(2.3,1,1);layer.sourceZOffsets=#(17,0,3)
        controller.syncLayerSurface layer
        local plants=layer.validSources()
        cyrusScatterCPUThreads 1
        local serial=layer.placements plants previewOnly:true
        local serialRender=layer.placements plants
        require (serial.count>serialRender.count) "Point placeholder test not exercised"
        cyrusScatterCPUThreads 4
        require (rowsEqual serial (layer.placements plants previewOnly:true)) "Worker mode changed preview rows"
        require (rowsEqual serialRender (layer.placements plants)) "Worker mode changed render rows"
        format "PASS actual layer preview/render, empty/point sources, scale/offset and serial/worker parity\n" to:log;flush log
        -- Real SDK node event dispatch, with polling for a deterministic queue.
        -- Redraw callbacks are absent so we measure requests, not GPU frames.
        global CyrusLiveBatchDepth,CyrusLiveBatchRedraw,CyrusLiveBatchCount,CyrusLiveRedrawRequests
        AminScatterRenderRedrawHeld=false
        local events=NodeEventCallback polling:true callbackBegin:CyrusScatterLiveBatchBegin callbackEnd:CyrusScatterLiveBatchEnd geometryChanged:AminScatterLiveChanged topologyChanged:AminScatterLiveChanged controllerStructured:AminScatterLiveChanged controllerOtherEvent:AminScatterLiveChanged
        triggerNodeEventCallback events
        layer.dirty=false
        require (not layer.dirty) "Could not establish a clean layer before notifications"
        local beforeStats=CyrusScatterLiveBatchStats()
        with undo off (surface.length=1100;surface.width=900;surface.pos=[20,0,0])
        triggerNodeEventCallback events
        local afterStats=CyrusScatterLiveBatchStats()
        require (afterStats[1]>beforeStats[1]) "No real callback batch received"
        require (afterStats[5]-beforeStats[5]>=2) "Multiple event types not exercised"
        require (afterStats[2]-beforeStats[2]==1) "More than one redraw for a callback batch"
        require (afterStats[3]==0 and not afterStats[4] and layer.dirty) "Pending batch state or lost invalidation"
        events.enabled=false;events=undefined
        format "PASS real callback dispatch: one redraw per batch and preserved invalidation\n" to:log;flush log
        cyrusScatterCPUThreads 0
        format "SUCCESS\n" to:log;close log
    ) catch (
        format "FAILED: %\n" (getCurrentException()) to:log;close log
        throw()
    )
)
