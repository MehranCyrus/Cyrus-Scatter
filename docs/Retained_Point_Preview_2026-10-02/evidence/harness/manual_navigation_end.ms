(
    completeRedraw();windows.processPostedMessages()
    local after=RIStats RIQualityNode
    callbacks.removeScripts id:#RIManualFileTrace
    CSPWriteText (RIDir+"manual-navigation-raw.json") (CSPObject #(#("before",RIManualBefore),#("after",after),#("file_events",RIManualFileEvents)))
    RIAssert (viewport.getTM()!=RIManualView) "No viewport movement was observed"
    RIAssert (after[8]>RIManualBefore[8]) "No native draws during mouse navigation"
    for index in #(1,3,6,9,13) do RIAssert (after[index]==RIManualBefore[index]) "Mouse navigation mutated the published data"
    RIAssert ((RIQualityNode.layerObjects[1].previewStats())[1]==RIManualBuilds) "Mouse navigation rebuilt placements"
    RICapture "manual-pan-after"
    CSPWriteText (RIDir+"manual-navigation.json") (CSPObject #(#("passed",true),#("method","Max Pan View tool and native mouse drag; functional check, not FPS measurement"),#("before",RIManualBefore),#("after",after),#("file_events",RIManualFileEvents),#("view_before",RIManualView),#("view_after",viewport.getTM())))
)
