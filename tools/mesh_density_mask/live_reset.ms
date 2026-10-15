(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-meshmask-*/" do throw "Owned mask host required"
    try(MeshLiveTimer.Stop();MeshLiveTimer.Dispose())catch()
    MeshLiveStage=0
    MeshMaskRoot.updateMode=1;MeshMaskLeaf.meshMaskChannel=1;MeshMaskLeaf.meshMaskInvert=false
    for i=1 to meshop.getNumMapVerts MeshMaskReceiver 1 do meshop.setMapVert MeshMaskReceiver 1 i [1,1,1]
    update MeshMaskReceiver;MeshMaskRoot.refreshAll()
)
