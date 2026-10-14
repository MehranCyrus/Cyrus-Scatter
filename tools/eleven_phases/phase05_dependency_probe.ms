(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 local log=createFile (MCPFixtureDir+"phase05-dependency-probe.txt")
 format "epoch=% expected=% revision=% expected=% handles=% error=% sources=%\n" P05DRoot.procEpoch P05DEpoch P05DLeaf.procGeometryRevision P05DRevision P05DLeaf.procDependencyHandles P05DLeaf.previewError P05DLeaf.sources to:log
 close log
)
