(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned density profile required"
    local log=createFile (MCPFixtureDir+"name-checks.txt"),expected="Long density layer name - mountain planting QA"
    fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    local epoch=DRoot.procEpoch,solves=DRoot.groupBuilds,hash=cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows
    local index=DRoot.activeLayer
    check (DRoot.layerNames[index]==expected) "Physical keyboard edit commits the full long name" log
    max undo
    check (DRoot.layerNames[index]==QNameBefore) "One Undo restores previous name" log
    max redo
    check (DRoot.layerNames[index]==expected) "Redo restores long name without changing layer identity" log
    check (DRoot.procEpoch==epoch and DRoot.groupBuilds==solves and (cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows)==hash) "Rename and its Undo/Redo do not solve or republish placements" log
    close log
)
