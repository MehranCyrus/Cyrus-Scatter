-- Scene previews captured directly by MAXScript; no Computer Use.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-feature-demo0824-*/" do throw "Owned feature-demo host required."
    local root=(getNodeByName "CYRUS 0.82.4 | SELECT ME - five feature layers").baseObject
    CyrusPerfHeadless=false;CyrusClearMeshMaskPreview undefined
    for spec in #(#("CAM 01 | Overview","Preview - Overview.png"),#("CAM 02 | Plane - density Paint Bands","Preview - Plane.png"),#("CAM 03 | Mountain - normals and filters","Preview - Mountain.png"),#("CAM 04 | Top plan","Preview - Top.png")) do (
        viewport.setCamera (getNodeByName spec[1]);CyrusPointSync();completeRedraw()
        local image=gw.getViewportDib();image.filename=MCPFixtureDir+spec[2];save image;close image
    )
    viewport.setCamera (getNodeByName "CAM 01 | Overview");completeRedraw()
)
