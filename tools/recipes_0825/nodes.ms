-- Owned disposable host diagnostic, no artist scene.
(
    local result=loadMaxFile (MCPFixtureDir+"recipe-qualified.max") quiet:true useFileUnits:true
    local s=stringStream ""
    format "load=% hold=%\n" result (theHold.Holding()) to:s
    for n in objects do format "% | %\n" n.name (classof n.baseObject) to:s
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-nodes.txt") (s as string)
)
