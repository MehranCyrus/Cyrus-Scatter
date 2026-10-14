(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 local log=createFile (MCPFixtureDir+"phase05-live-probe.txt")
 format "stage=% epoch=% expected=% revision=% expected=% rowsSame=% geometryRevision=% secondRevision=%\n" P05Stage P05Root.procEpoch P05Epoch (cyrusBrushStats P05Area.paintDocument)[1] P05Revision (with printAllElements on ((P05Root.groupSnapshotRows[1] as string)==P05First)) P05Leaf.procGeometryRevision P05Other.procGeometryRevision to:log
 close log
)
