(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-feature-demo0824-*/" do throw "Owned feature-demo host required."
    for node in objects where classof node==Text and node.layer.name=="DEMO | Labels" do (
        local intended=node.pos.x,bounds=nodeGetBoundingBox node (matrix3 1)
        move node [intended-bounds[1].x,0,0]
    )
    viewport.setCamera (getNodeByName "CAM 01 | Overview");completeRedraw()
    saveMaxFile (MCPFixtureDir+"CyrusScatter 0.82.4 Feature Demo.max") quiet:true
)
