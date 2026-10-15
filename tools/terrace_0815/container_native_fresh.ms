(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-terrace0815-candidate*" do throw "Owned terrace host required"
    local out=createFile (MCPFixtureDir+"container-native-fresh.txt")
    try (
        if theHold.Holding() do throw "Host already has an enclosing hold"
        CyrusPerfHeadless=true
        resetMaxFile #noPrompt
        local n=AminScatterObject name:"Native container witness",root=n.baseObject
        root.updateMode=1;root.autoRender=false;root.newLayer()
        local leaf=root.selectedLayer(),surface=plane width:400 length:400
        root.setLayerSurfaces leaf #(surface)
        local c=leaf.containerCreate(),models=#()
        c.pos=[1000,0,0]
        for i=1 to 20 do append models (box width:2 length:2 height:5 pos:[1000+(mod i 5)*10,(floor(i/5))*10,0])
        c.collectEnabled=true;leaf.containerScan=true;leaf.containerRefresh();CyrusContainerRefreshAll()
        if c.movementSources.count!=20 do throw "Fixture membership differs"
        if theHold.Holding() do throw "Container setup left an open hold"
        local before=for s in models collect s.pos,original=c.pos
        undo "Native source Move" on move c [75,0,0]
        if theHold.Holding() do throw "Native Move left an open hold"
        for i=1 to models.count do if distance models[i].pos (before[i]+[75,0,0])>.01 do throw "Native Move left a source behind"
        format "PASS Move: % sources; stats %\n" models.count (c.movementStats()) to:out
        max undo
        if distance c.pos original>.01 do throw "Undo did not restore container"
        for i=1 to models.count do if distance models[i].pos before[i]>.01 do throw "Undo did not restore source"
        format "PASS Undo\n" to:out
        max redo
        for i=1 to models.count do if distance models[i].pos (before[i]+[75,0,0])>.01 do throw "Redo did not restore source"
        format "PASS Redo\n" to:out
        local current=for s in models collect s.pos
        undo "Native rectangle resize" on c.width=1200
        CyrusContainerRefreshAll()
        for i=1 to models.count do if distance models[i].pos current[i]>.01 do throw "Resize moved a source"
        format "PASS Resize preserves source positions\n" to:out
        close out
    )catch(format "FAIL: % | holding=% depth=%\n" (getCurrentException()) (theHold.Holding()) (theHold.GetBeginDepth()) to:out;close out;throw())
)
