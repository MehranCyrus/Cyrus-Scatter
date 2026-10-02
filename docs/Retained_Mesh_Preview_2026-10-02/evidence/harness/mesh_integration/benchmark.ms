(
    global MIBenchmark,MIBenchmarkArm,MINativeNodes=#()
    fn MIBenchmarkArm nodes mode = (
        if MINativeNodes.count>0 do (if mode=="native" then unhide MINativeNodes else hide MINativeNodes)
        for node in nodes do node.showPoints=(mode!="off" and mode!="native")
        CyrusRetainedMeshDrawing (mode!="gw")
        MISettle()
    )
    fn MIBenchmark label frames:45 repeats:2 native:false = (
        local nodes=for n in objects where classof n.baseObject==AminScatterObject and not n.isHidden collect n
        local baseTM=viewport.getTM()
        local writer=CSPWriter (RIDir+label+"-frames.csv") "case,arm,repeat,frame,start_ms,end_ms,step_ms"
        local trials=#()
        try (
            for repeat=1 to repeats do (
                local arms=if mod repeat 2==0 then #("retained","gw","off") else #("off","gw","retained")
                if native do append arms "native"
                for mode in arms do (
                    gc();MIBenchmarkArm nodes mode
                    for i=1 to 4 do (viewport.setTM ((rotateZMatrix (4.0*sin(i*7.0)))*baseTM);completeRedraw();windows.processPostedMessages())
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
                        RIAssert (before[i][3]==after[i][3] and before[i][6]==after[i][6] and before[i][9]==after[i][9] and before[i][13]==after[i][13]) "Navigation rebuilt native data or failed"
                        RIAssert ((for entry in nodes[i].layerEntries() collect (entry[2].previewStats())[1]) as string==cacheBuilds[i] as string) "Navigation rebuilt preview cache"
                        if mode=="retained" do RIAssert (after[i][8]-before[i][8]>=frames) "No retained mesh drawing"
                    )
                    append trials #(#("arm",mode),#("repeat",repeat),#("before",before),#("after",after),#("builds",cacheBuilds))
                    CSPWriteText (RIDir+label+"-progress.json") (CSPObject #(#("arm",mode),#("repeat",repeat)))
                )
            )
            writer.Close()
        )catch(writer.Close();throw())
        viewport.setTM baseTM;MIBenchmarkArm nodes "retained"
        CSPWriteText (RIDir+label+"-trials.json") (CSPJson trials)
        RICapture (label+"-retained")
        MIBenchmarkArm nodes "gw";RICapture (label+"-gw");MIBenchmarkArm nodes "retained"
        CSPWriteText (RIDir+label+"-metadata.json") (CSPObject #(#("viewport_pixels",#(gw.getWinSizeX(),gw.getWinSizeY())),#("render_level",viewport.getRenderLevel() as string),#("scene",maxFilePath+maxFileName),#("controllers",for n in nodes collect #(n.name,RIStats n,MIStats n)),#("metric","synchronous completeRedraw camera step plus message processing; not presented FPS")))
    )
)
