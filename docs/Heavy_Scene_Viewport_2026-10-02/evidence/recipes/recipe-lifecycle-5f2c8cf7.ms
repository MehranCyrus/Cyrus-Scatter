-- Disposable-session ownership checks. Does not qualify production persistence/undo.
(
    HVPMode "retained"
    local records=#(), process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local original=aminScatterPreviewPoints HVPCaches[1]
    local originalCount=original.count, originalHash=(HVPStats())[11]
    local small=for i=1 to 1000 collect #([mod i 32*80-1200,(floor(i/32.0))*80-1200,300],red)
    with undo off (
        for cycle=1 to 12 do (
            cyrusPointProbeSet HVPNode small
            for i=1 to 3 do (completeRedraw(); windows.processPostedMessages())
            if (HVPStats())[1]!=1000 do throw "Replacement count mismatch"
            if cycle==1 do HVPCapture "lifecycle-replaced"
            local beforeHide=(HVPStats())[8]
            hide HVPNode
            completeRedraw(); windows.processPostedMessages()
            if (HVPStats())[8]!=beforeHide do throw "Hidden probe drew points"
            unhide HVPNode
            completeRedraw(); windows.processPostedMessages()
            local clone=copy HVPNode
            clone.pos=[200,100,0]
            completeRedraw(); windows.processPostedMessages()
            if (cyrusPointProbeStats clone)[1]!=1000 do throw "Clone lost immutable point data"
            delete clone
            cyrusPointProbeSet HVPNode #()
            for i=1 to 3 do (completeRedraw(); windows.processPostedMessages())
            local cleared=HVPStats()
            if cleared[1]!=0 or cleared[10]!=0 do throw "Clear left points or live render items"
            if cycle==1 do HVPCapture "lifecycle-cleared"
            cyrusPointProbeSet HVPNode original
            completeRedraw(); windows.processPostedMessages()
            local restored=HVPStats()
            if restored[1]!=originalCount or restored[11]!=originalHash do throw "Restoration changed point data"
            gc light:true
            process.Refresh()
            append records #(#("cycle",cycle),#("stats",restored),#("working_set_bytes",process.WorkingSet64 as double),#("private_bytes",process.PrivateMemorySize64 as double))
        )
    )
    local json="["
    for i=1 to records.count do (if i>1 do json+=","; json+=CSPObject records[i])
    CSPWriteText (HVPDir+"lifecycle.json") (json+"]")
    local beforeViews=HVPStats()
    viewport.setLayout #layout_4
    for i=1 to 4 do (
        viewport.activeViewport=i
        viewport.setType #view_persp_user
        viewport.setTM ((rotateZMatrix (i*20.0))*HVPBaseTM)
    )
    completeRedraw(); windows.processPostedMessages()
    local multi=HVPStats()
    if multi[6]!=beforeViews[6] do throw "Viewport layout change caused own buffer recreation"
    HVPCapture "lifecycle-four-views-active"
    viewport.setLayout #layout_1
    viewport.setType #view_persp_user; viewport.setTM HVPBaseTM
    select HVPNode
    completeRedraw(); windows.processPostedMessages()
    if (HVPStats())[11]!=originalHash do throw "Selection changed point data"
    clearSelection()
    CSPWriteText (HVPDir+"lifecycle-extra.json") (CSPObject #(#("before_views",beforeViews),#("after_views",multi),#("final",HVPStats()),#("selection_policy","Point picking and selection highlight not implemented in private probe")))
    CSPWriteText (HVPDir+"lifecycle-complete.txt") "SUCCESS"
)
