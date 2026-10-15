(
    local s=stringStream ""
    format "holding=% suspended=% busy=% timeowners=% error=%\n" (theHold.Holding()) CyrusPointSuspended CyrusPointBusy CyrusTimeOwners.count CyrusPointLastError to:s
    local n=getNodeByName "Recipe 0.82.5 source"
    format "node=% native=%\n" n (if n!=undefined then CyrusPointOwner n else undefined) to:s
    for n in CyrusTimeOwners do format "time=% show=% cache=%\n" n.name n.baseObject.showPoints n.baseObject.groupSnapshotRows.count to:s
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-state.txt") (s as string)
)
