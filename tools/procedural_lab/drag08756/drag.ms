-- Sequential native Edit transformations while the script's drag-held predicate
-- is true. This tests publication before release, not OS mouse/input latency.
global DGSavedHeld
(
    DGSavedHeld=CyrusInteractionHeld
    local file=createFile (GardenRun+(CVProfileCase as string)+".txt"),start,oldTM=viewport.getTM()
    try(
        format "before:%\n" (WFRoot.interactionsStatistics()) to:file
        fn CyrusInteractionHeld = true
        for step=1 to 12 do (
            start=timeStamp()
            cyrusEditCommand WFEdit 4 (transMatrix [(if step<=6 then 5 else -5),0,0])
            local changed=timeStamp()-start
            redrawViews()
            format "STEP % native_ms:% redraw_ms:% stats:%\n" step changed (timeStamp()-start-changed) (WFRoot.interactionsStatistics()) to:file
        )
        local info=WFRoot.interactionsStatistics()
        for step=1 to 12 do (
            start=timeStamp();viewport.setTM ((rotateZMatrix (step*.8))*oldTM);redrawViews()
            format "ORBIT % ms:%\n" step (timeStamp()-start) to:file
        )
        format "after-navigation:%\n" (WFRoot.interactionsStatistics()) to:file
    )catch(format "ERROR %\n" (getCurrentException()) to:file)
    CyrusInteractionHeld=DGSavedHeld;viewport.setTM oldTM;close file
)
