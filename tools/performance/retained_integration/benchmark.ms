(
    global RIBenchmark,RIBenchmarkArm,RIBenchmarkLabel
    fn RIBenchmarkArm nodes mode = (
        for node in nodes do node.showPoints=(mode!="off")
        CyrusRetainedPointDrawing (mode!="gw")
        completeRedraw();windows.processPostedMessages();completeRedraw()
    )
    fn RIBenchmark label frames:90 repeats:3 = (
        local nodes=for n in objects where classof n.baseObject==AminScatterObject and not n.isHidden collect n
        local baseTM=viewport.getTM()
        local writer=CSPWriter (RIDir+label+"-frames.csv") "case,arm,repeat,frame,start_ms,end_ms,step_ms"
        local trials=#()
        try (
            for repeat=1 to repeats do (
                local arms=if mod repeat 2==0 then #("retained","gw","off") else #("off","gw","retained")
                for mode in arms do (
                    gc()
                    RIBenchmarkArm nodes mode
                    for i=1 to 12 do (viewport.setTM ((rotateZMatrix (4.0*sin(i*7.0)))*baseTM);completeRedraw();windows.processPostedMessages())
                    local before=for n in nodes collect RIStats n
                    local cacheBuilds=for n in nodes collect (for entry in n.layerEntries() collect (entry[2].previewStats())[1])
                    for frame=1 to frames do (
                        local started=RIStamp()
                        viewport.setTM ((rotateZMatrix (4.0*sin(frame*7.0)))*baseTM)
                        completeRedraw();windows.processPostedMessages()
                        local finished=RIStamp()
                        CSPRow writer #(label,mode,repeat,frame,started,finished,finished-started)
                    )
                    local after=for n in nodes collect RIStats n
                    for i=1 to nodes.count do (
                        RIAssert (before[i][3]==after[i][3] and before[i][6]==after[i][6] and before[i][9]==after[i][9] and before[i][13]==after[i][13]) "Unchanged navigation mutated native data or failed"
                        RIAssert ((for entry in nodes[i].layerEntries() collect (entry[2].previewStats())[1]) as string==cacheBuilds[i] as string) "Navigation recomputed placements"
                        if mode=="retained" do RIAssert (after[i][8]-before[i][8]>=frames) "No retained drawing"
                    )
                    append trials #(#("arm",mode),#("repeat",repeat),#("before",before),#("after",after),#("builds",cacheBuilds))
                )
            )
            writer.Close()
        )catch(writer.Close();throw())
        viewport.setTM baseTM;RIBenchmarkArm nodes "retained"
        CSPWriteText (RIDir+label+"-trials.json") (CSPJson trials)
        RICapture (label+"-retained")
        RIBenchmarkArm nodes "gw";RICapture (label+"-gw")
        RIBenchmarkArm nodes "retained"
        CSPWriteText (RIDir+label+"-metadata.json") (CSPObject #(#("viewport_pixels",#(gw.getWinSizeX(),gw.getWinSizeY())),#("render_level",viewport.getRenderLevel() as string),#("scene",maxFilePath+maxFileName),#("controllers",for n in nodes collect #(n.name,RIStats n)),#("metric","completeRedraw camera step with message processing; not completed FPS")))
    )
    RIBenchmark (if RIBenchmarkLabel==undefined then "point-cloud" else RIBenchmarkLabel)
    RIBenchmarkLabel=undefined
)
