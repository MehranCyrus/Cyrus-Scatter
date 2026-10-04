(
    local node=getNodeByName "CYRUS_V1_NAVIGATION",root=node.baseObject,leaf=root.layerObjects[1],results=#()
    for mode=1 to 4 do (
        root.viewportInstances=20000;root.previewBudget=500000
        root.setGroupDisplay mode
        for j=1 to 4 do completeRedraw()
        local before=leaf.cacheSnapshot(),paint=leaf.paintCacheStats(),brush=cyrusBrushStats leaf.paintDocument
        local base=viewport.getTM(),owner=CyrusPointOwner node
        local retained=if isValidNode owner then cyrusRetainedStats owner else undefined
        for j=1 to 30 do (
            local tm=copy base;tm.row4+=[sin(j*9)*20,cos(j*9)*20,0]
            viewport.setTM tm;completeRedraw()
        )
        local after=leaf.cacheSnapshot(),afterPaint=leaf.paintCacheStats(),afterBrush=cyrusBrushStats leaf.paintDocument
        if before[6]!=after[6] or paint[1]!=afterPaint[1] do throw "Mode navigation regenerated placements"
        for k in #(8,9,10,15) where brush[k]!=afterBrush[k] do throw "Mode navigation queried Brush"
        if retained!=undefined do (
            local now=cyrusRetainedStats owner
            for k in #(3,4,5,6,7) where retained[k]!=now[k] do throw "Mode navigation uploaded buffers"
        )
        append results #((#("Point Cloud","Proxy","Mesh","Plant centres"))[mode],#(after[5],after[2],true))
    )
    CSPWriteText (BLDir+"navigation-all-modes.json") (CSPObject results)
)
