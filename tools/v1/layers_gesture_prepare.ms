(
    global LFMouseRoot=(getNodeByName "Cyrus_Scatter_1_Demo").baseObject
    global LFMouseSet=LFMouseRoot.layerObjects[3]
    LFMouseRoot.updateMode=1;LFMouseRoot.layerObjects[2].uiPaintSetID=LFMouseSet.layerID
    LFMouseRoot.bindNativeUI()
    global LFMouseHistory=for leaf in LFMouseRoot.layerObjects collect (if leaf.paintDocument!=undefined then (cyrusBrushHistory leaf.paintDocument).count else 0)
    global LFMouseBuild=LFMouseSet.cacheSnapshot()
    cyrusBrushSettings LFMouseSet.paintDocument 28 1 .2 false 1
    CyrusStartBrush LFMouseRoot LFMouseSet
    completeRedraw()
)
