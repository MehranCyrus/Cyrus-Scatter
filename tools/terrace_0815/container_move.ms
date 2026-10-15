-- Native Undo event, deliberately outside the enclosing pymxs execution hold.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-terrace0815-candidate*" do throw "Owned terrace host required"
    local stream=createFile (MCPFixtureDir+"container-native-move.txt")
    try (
        max select
        if theHold.Holding() do throw "Unexpected enclosing test hold"
        local c=TerraceMovingRectangle
        -- The preceding Python witness ended before EndHold; preserve its
        -- failure receipt and cancel only that owned, unfinished gesture.
        if (c.movementStats())[6] do cyrusContainerGesture c.delegate 2
        CyrusContainerRefreshAll()
        local members=c.movementSources as array,before=for n in c.movementSources collect n.transform,start=c.transform
        local delta=[75,0,0],stats=c.movementStats()
        undo "Terrace native Move" on move c delta
        if (c.movementStats())[6] do throw "Native move did not finish its hold"
        for i=1 to members.count do if distance members[i].pos (before[i].row4+delta)>.01 do throw "Native Move left a source behind"
        format "PASS Move: % models; stats %\n" members.count (c.movementStats()) to:stream
        max undo
        if distance c.pos start.row4>.01 do throw "Undo did not restore rectangle"
        for i=1 to members.count do if distance members[i].pos before[i].row4>.01 do throw "Undo did not restore source"
        format "PASS Undo\n" to:stream
        max redo
        for i=1 to members.count do if distance members[i].pos (before[i].row4+delta)>.01 do throw "Redo did not restore source"
        format "PASS Redo\n" to:stream
        local positions=for n in members collect n.pos
        undo "Terrace resize" on c.width=1200
        CyrusContainerRefreshAll()
        for i=1 to members.count do if distance members[i].pos positions[i]>.01 do throw "Resize moved a source"
        format "PASS Resize retains model positions\n" to:stream
        close stream
    ) catch (format "FAIL %\n" (getCurrentException()) to:stream;close stream;throw())
)
