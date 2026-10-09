RSAssert()
(
    local original=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vendor-surface-paint-20261009-01/host/vendor-fixture.max"
    if not doesFileExist original do throw "Prior owned fixture missing"
    loadMaxFile original quiet:true
    local scatter=getNodeByName "VP_Scatter" exact:true
    if scatter==undefined do throw "Paint fixture missing"
    local s=stringStream ""
    format "points % records % layers %\n" scatter.layerData.count scatter.layerRecords.count scatter.layerList.count to:s
    for i=1 to scatter.layerData.count do (
        local p=scatter.layerData[i]
        format "point\t%\t%\t%\t%\n" i p.x p.y (bit.floatAsInt p.z) to:s
    )
    for i=1 to scatter.layerRecords.count do (
        local p=scatter.layerRecords[i],packed=bit.floatAsInt p.z
        format "record\t%\t%\t%\t%\t%\t%\n" i (bit.floatAsInt p.x) (bit.floatAsInt p.y) (bit.shift packed -16) (bit.and packed 65535) p.w to:s
    )
    for i=1 to scatter.targetNodes.count do (
        local node=scatter.targetNodes[i],mesh=snapshotAsMesh node
        format "receiver\t%\t%\t%\t%\n" i node.name mesh.numfaces node.transform to:s
        for j=1 to mesh.numfaces do (
            local face=getFace mesh j
            format "triangle\t%\t%\t%\t%\t%\n" i (j-1) (getVert mesh face.x) (getVert mesh face.y) (getVert mesh face.z) to:s
        )
        delete mesh
    )
    RSWrite "saved-paint-decoded.tsv" (s as string);close s
    RSWrite "stage.txt" "Saved artist-authored paint decoded; no paint tables modified"
)
