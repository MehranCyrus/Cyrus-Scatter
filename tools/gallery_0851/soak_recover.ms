(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-soak-*/" do throw "Owned soak only."
 if CyrusAssetImportEditor!=undefined do destroyDialog CyrusAssetImportEditor
 if (theHold.GetUndoNames())[1]!="Cyrus import recipe" do throw "Unexpected history; do not remove anything."
 max undo
 if (for n in objects where classof n.baseObject==AminScatterObject collect n).count!=1 do throw "Failed fixture cleanup did not restore the original controller."
)
