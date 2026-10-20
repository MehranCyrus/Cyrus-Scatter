global CyrusPrepareFixtureOutput,CyrusPrepareFixtureRestore,CyrusPrepareFixtureSource,CyrusPrepareFixturePrepared,CyrusPrepareTranslate
(
    if MCPFixtureDir==undefined or not doesFileExist CyrusPrepareFixtureRestore do throw "Owned fixture request required."
    try (
        if not loadMaxFile CyrusPrepareFixtureSource useFileUnits:true quiet:true allowPrompts:false do throw "Source fixture did not load."
        local camera=getNodeByName "Existing animated camera",times=#(0,7.5,15,22.5,30)
        local cameraPoses=(for t in times collect (at time t #(camera.transform,camera.fov)))
        local keyCount=numKeys camera.position.controller
        if not loadMaxFile CyrusPrepareFixturePrepared useFileUnits:true quiet:true allowPrompts:false do throw "Prepared fixture did not reopen."
        camera=getNodeByName "Existing animated camera"
        for i=1 to times.count do at time times[i] (
            if camera.transform!=cameraPoses[i][1] or camera.fov!=cameraPoses[i][2] do throw "Prepared scene changed the original camera pose/lens."
        )
        if numKeys camera.position.controller!=keyCount do throw "Prepared scene changed camera keys."
        local a=getNodeByName "Hidden prototype A",b=getNodeByName "Visible protected B",c=getNodeByName "Reduced owner C",d=getNodeByName "Reduced placement D"
        if not a.isHidden or not c.isFrozen do throw "Hidden/frozen state was not preserved."
        if not areNodesInstances a b or not areNodesInstances c d do throw "Prepared instance sharing was not retained."
        if c.material.name!="FixtureRed" or d.material.name!="FixtureBlue" do throw "Per-instance material assignment changed."
        if c.parent.name!="Source hierarchy" or d.parent.name!="Source hierarchy" do throw "Original hierarchy changed."
        local boxNode=getNodeByName "Material ID witness",multi=boxNode.material
        if multi.materialIDList.count!=2 or multi.materialIDList[1]!=3 or multi.materialIDList[2]!=7 do throw "MultiMaterial IDs changed."
        local mesh=snapshotAsMesh boxNode
        for i=1 to mesh.numfaces where findItem #(3,7) (getFaceMatID mesh i)==0 do throw "Face material ID is not retained."
        mesh=undefined
        local empty=getNodeByName "Empty mesh witness",emptyMesh=snapshotAsMesh empty
        if emptyMesh!=undefined and emptyMesh.numfaces!=0 do throw "The empty source acquired geometry."
        emptyMesh=undefined
        for map in getClassInstances BitmapTexture where not doesFileExist map.filename do throw "Prepared texture is unavailable after publication."
        CyrusPrepareTranslate CyrusPrepareFixtureOutput [10,20,30] (1.0/(units.decodeValue "1m"))
        local check=createFile (CyrusPrepareFixtureOutput+"host-checks.txt") encoding:#utf8 writeBOM:false
        format "PASS prepared Max reopen\nPASS existing camera pose/lens/key counts\nPASS hidden/frozen state\nPASS instance sharing and per-instance materials\nPASS source hierarchy\nPASS MultiMaterial slot/face IDs\nPASS empty mesh remains empty\nPASS published texture paths resolve\nPASS sampled recentering retains source animation\n" to:check;close check
        if not loadMaxFile CyrusPrepareFixtureRestore useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg do throw "Prepared building did not restore."
        (dotNetClass "System.IO.File").WriteAllText (CyrusPrepareFixtureOutput+"complete.txt") "PASS"
    ) catch (
        try(loadMaxFile CyrusPrepareFixtureRestore useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg)catch()
        throw()
    )
)
