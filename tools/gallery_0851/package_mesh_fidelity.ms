(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-mesh-fidelity-"+(timeStamp() as string)+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        resetMaxFile #noPrompt
        local original=box width:30 length:40 height:60 mapCoords:true name:"Owned offset mesh"
        convertToMesh original
        original.transform=(scaleMatrix [-1.2,0.8,1.7])*(rotateZMatrix 23)*(transMatrix [150,-210,32])
        original.objectOffsetPos=[12,-7,4];original.objectOffsetRot=quat 17 [0,1,0];original.objectOffsetScale=[0.8,1.3,1.1]
        local source=original.mesh
        for i=1 to source.numfaces do (setFaceSmoothGroup source i (bit.shift 1 (mod i 16));setFaceMatID source i (mod i 5+1))
        original.mesh=source;update original
        local metres=(units.decodeValue "1m") as double,path=MCPFixtureDir+"mesh-offset-"+CyrusNewLayerID()+".cmesh",info=cyrusAssetMeshExport original path metres
        theHold.Begin()
        local imported=cyrusAssetMeshCreate path info[1] metres original.name
        imported.transform=original.transform
        theHold.Accept "Owned mesh fidelity import"
        check (imported.name!=original.name and imported.isHidden) "Same-name source is independent, unique and hidden" log
        local restored=imported.mesh
        check (source.numverts==restored.numverts and source.numfaces==restored.numfaces) "Full topology counts retained" log
        local largest=0.0
        for i=1 to source.numverts do largest=amax largest (distance ((getVert source i)*original.objectTransform) ((getVert restored i)*imported.objectTransform))
        format "Maximum world-space vertex difference: %\n" largest to:log
        check (largest<0.0001) "Object offset, mirrored/nonuniform transform and pivot produce matching geometry" log
        for i=1 to source.numfaces do (
            check ((getFace source i)==(getFace restored i) and (getFaceSmoothGroup source i)==(getFaceSmoothGroup restored i) and (getFaceMatID source i)==(getFaceMatID restored i)) "Triangle, smoothing and material index retained" log
            for edge=1 to 3 do check ((getEdgeVis source i edge)==(getEdgeVis restored i edge)) "Edge visibility retained" log
        )
        check ((meshop.getNumMapVerts source 1)==(meshop.getNumMapVerts restored 1)) "UV count retained" log
        for i=1 to meshop.getNumMapVerts source 1 do check ((meshop.getMapVert source 1 i)==(meshop.getMapVert restored 1 i)) "UV coordinate retained" log
        for i=1 to source.numfaces do check ((meshop.getMapFace source 1 i)==(meshop.getMapFace restored 1 i)) "UV topology retained" log
        local handle=getHandleByAnim imported
        max undo;check (not isValidNode imported and isValidNode original) "Native created mesh belongs to the authored hold" log
        max redo;check (isValidNode imported and (getHandleByAnim imported)==handle) "Native redo restores the same node" log
        theHold.Begin();local scaled=cyrusAssetMeshCreate path info[1] (metres*0.1) "Owned changed units";theHold.Accept "Owned unit import"
        local converted=scaled.mesh
        for i=1 to restored.numverts do check ((distance ((getVert restored i)*0.1) (getVert converted i))<0.00001) "Geometry converts declared metres to destination units" log
        local before=objects as array,failed=false
        theHold.Begin();try(cyrusAssetMeshCreate path "0000000000000000000000000000000000000000000000000000000000000000" metres "Bad hash")catch(failed=matchPattern (getCurrentException()) pattern:"*Mesh payload changed*");theHold.Cancel()
        check (failed and CyrusPresetSameValues before (objects as array)) "Changed bytes reject without a scene object" log
        format "PASS: complete\n" to:log;close log
    )catch(if theHold.Holding() do theHold.Cancel();format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
