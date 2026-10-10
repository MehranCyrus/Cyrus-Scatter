(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
local log=createFile (MCPFixtureDir+"session-diagnostic.txt")
format "Stats %\nRevision % session %\nCurrent % mode % epoch % error % held %\n" (cyrusBrushStats BD) CyrusBrushSessionRevision CyrusBrushSessionLayer BRoot.groupSnapshotRows[1].count BRoot.updateMode BRoot.procEpoch BLayer.previewError (CyrusInteractionHeld()) to:log
format "Key %\n" (BRoot.procInputKey()) to:log
local before=BRoot.groupSnapshotRows[1].count
BPump 2000
format "After pump % -> % stats %\n" before BRoot.groupSnapshotRows[1].count (cyrusBrushStats BD) to:log
CyrusBrushTick undefined undefined;BLayer.refreshPreview()
format "After refreshPreview % error %\n" BRoot.groupSnapshotRows[1].count BLayer.previewError to:log
local hits=cyrusPrivatePaintPath BD #([-65,-60,0],[0,-60,0],[65,-60,0]) false
format "Replay hits % stats %\n" hits (cyrusBrushStats BD) to:log
BPump 1800
format "Replay output % error %\n" BRoot.groupSnapshotRows[1].count BLayer.previewError to:log
close log
)
