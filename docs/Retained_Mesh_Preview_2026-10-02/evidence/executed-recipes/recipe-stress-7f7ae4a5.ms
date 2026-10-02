-- Higher-detail retained-only case; no multi-second legacy warmup at this scale.
(
    local nodes=for n in objects where classof n.baseObject==AminScatterObject and not n.isHidden collect n
    local baseTM=viewport.getTM(),started=RIStamp()
    for n in nodes do (n.viewportFaces=20000000;n.refreshDisplay())
    MISettle()
    local initialMs=RIStamp()-started
    local before=for n in nodes collect RIStats n
    if (for n in nodes where (RIStats n)[12]!=1 collect n).count>0 do (
        CSPWriteText (RIDir+"stress-rejected.json") (CSPJson (for n in nodes collect #(RIStats n,MIStats n)))
        for n in nodes do (n.viewportFaces=2000000;n.refreshDisplay());MISettle()
        throw "Heavy Mesh used fallback"
    )
    local writer=CSPWriter (RIDir+"artist-mesh-20m-frames.csv") "case,arm,repeat,frame,start_ms,end_ms,step_ms"
    try (
        for frame=1 to 90 do (
            local begin=RIStamp()
            viewport.setTM ((rotateZMatrix (4.0*sin(frame*7.0)))*baseTM);completeRedraw();windows.processPostedMessages()
            local finish=RIStamp()
            CSPRow writer #("artist-mesh-20m","retained",1,frame,begin,finish,finish-begin)
        )
        writer.Close()
    )catch(writer.Close();throw())
    viewport.setTM baseTM;RICapture "artist-mesh-20m-retained"
    local after=for n in nodes collect RIStats n
    for i=1 to nodes.count do RIAssert (before[i][3]==after[i][3] and before[i][6]==after[i][6] and before[i][9]==after[i][9] and before[i][13]==after[i][13] and after[i][8]>before[i][8]) "Stress navigation rebuilt data or failed"
    CSPWriteText (RIDir+"artist-mesh-20m-metadata.json") (CSPObject #(#("viewport_pixels",#(gw.getWinSizeX(),gw.getWinSizeY())),#("first_update_redraw_ms",initialMs),#("before",before),#("after",after),#("mesh",for n in nodes collect MIStats n)))
    for n in nodes do (n.viewportFaces=2000000;n.refreshDisplay());MISettle()
)
