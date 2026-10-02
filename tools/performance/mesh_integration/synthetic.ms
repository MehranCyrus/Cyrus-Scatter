(
    global MIBenchmark,MINativeNodes
    fileIn (RIRoot+"tools/performance/mesh_integration/benchmark.ms")
    RINode.viewportMode=3;RINode.viewportInstances=5000;RINode.viewportFaces=2000000
    RISource.sides=128;RISource.heightsegs=16
    RINode.layerObjects[1].amount=200;RINode.refreshAll();MISettle()
    local layer=RINode.layerObjects[1],rows=layer.placements (layer.validSources()) previewOnly:true
    RIAssert (rows.count==200) "Synthetic population changed"
    with redraw off undo off (
        delete (for n in objects where matchPattern n.name pattern:"MI_Native_Control*" collect n)
        MINativeNodes=for row in rows collect (
            local node=instance RISource
            node.name="MI_Native_Control";node.transform=row[1];node.wireColor=RISource.wireColor;node
        )
        hide MINativeNodes
    )
    local cache=layer.previewCache()
    local tri=cyrusPreviewTriangles cache false 1
    local mesh=snapshotAsMesh MINativeNodes[1],face=getFace mesh 1
    -- snapshotAsMesh evaluates this node in world coordinates.
    for corner=1 to 3 do RIAssert (distance (getVert mesh face[corner]) tri[1][corner]<0.01) "Native control geometry or placement mismatch"
    RIAssert (mesh.numfaces*MINativeNodes.count==cyrusPreviewFaces cache) "Native comparison count mismatch"
    delete mesh
    MIBenchmark "synthetic-200-dense" native:true
    undo off delete MINativeNodes;MINativeNodes=#()
    RISource.sides=16;RISource.heightsegs=1
    layer.amount=5000;RINode.refreshAll();MISettle()
)
