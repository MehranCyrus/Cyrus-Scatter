-- Owned host only. The calling request defines the fresh output and saved scene.
global CyrusPrepareGeometry,CyrusPrepareFixtureOutput,CyrusPrepareFixtureRestore
(
    if MCPFixtureDir==undefined or CyrusPrepareFixtureOutput==undefined or CyrusPrepareFixtureRestore==undefined do throw "Owned fixture request required."
    if not doesFileExist CyrusPrepareFixtureRestore do throw "Saved preparation scene is missing."
    try (
        resetMaxFile #noPrompt
        local reduceLayer=LayerManager.newLayerFromName "Reduce",protectLayer=LayerManager.newLayerFromName "Protected"
        local red=glTFMaterial name:"FixtureRed" baseColor:(color 160 40 30),blue=glTFMaterial name:"FixtureBlue" baseColor:(color 30 70 150)
        local a=sphere name:"Shared conservative A" radius:8 segments:64 mapCoords:true
        local b=instance a;b.name="Shared conservative B";b.pos=[30,0,0]
        reduceLayer.addNode a;protectLayer.addNode b
        local c=sphere name:"Reduced owner C" radius:6 segments:64 mapCoords:true pos:[60,0,0]
        local d=instance c;d.name="Reduced placement D";d.pos=[80,10,3];d.scale=[-1,2,1];d.rotation=angleaxis 25 [0,0,1]
        reduceLayer.addNode c;reduceLayer.addNode d
        InstanceMgr.autoMtlPropagation=false;a.material=red;b.material=blue;c.material=red;d.material=blue
        local meshA=snapshotAsMesh a,meshC=snapshotAsMesh c,beforeA=meshA.numfaces,beforeC=meshC.numfaces
        meshA=undefined;meshC=undefined
        local states=(for n in #(a,b,c,d) collect #(n.handle,n.name,n.transform,n.material,n.layer.name,n.parent))
        local originalPropagation=InstanceMgr.autoMtlPropagation
        local result=CyrusPrepareGeometry CyrusPrepareFixtureOutput 1 #(#("Reduce",50,true)) #("Protected")
        if InstanceMgr.autoMtlPropagation!=originalPropagation do throw "Instance material propagation was not restored."
        if not areNodesInstances a b or not areNodesInstances c d do throw "Shared owners were not preserved."
        for i=1 to 4 do (
            local n=(#(a,b,c,d))[i],state=states[i]
            if n.handle!=state[1] or n.name!=state[2] or n.transform!=state[3] or n.material!=state[4] or n.layer.name!=state[5] or n.parent!=state[6] do throw "Instance identity or placement changed."
        )
        local afterA=snapshotAsMesh a,afterC=snapshotAsMesh c,afterD=snapshotAsMesh d
        if afterA.numfaces!=beforeA do throw "A shared protected member was reduced."
        if afterC.numfaces<=0 or afterC.numfaces>=beforeC or afterD.numfaces!=afterC.numfaces do throw "The reducible owner did not freeze consistently."
        if c.modifiers.count!=0 or d.modifiers.count!=0 do throw "Temporary ProOptimizer remains in the delivered stack."
        if getNumTVerts afterC==0 or getNumTVerts afterD==0 do throw "UV channel was lost."
        local check=createFile (CyrusPrepareFixtureOutput+"host-checks.txt") encoding:#utf8 writeBOM:false
        format "PASS shared conservative rule\nPASS one reduction per owner\nPASS immediate freeze\nPASS per-placement material, transform, name, handle, layer and parent\nPASS UV channel retained\nPASS no temporary modifier\nprotectedFaces=% sourceReducedOwnerFaces=% afterReducedOwnerFaces=%\n" beforeA beforeC afterC.numfaces to:check;close check
        afterA=undefined;afterC=undefined;afterD=undefined
        if not loadMaxFile CyrusPrepareFixtureRestore useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg do throw "Saved prepared scene failed to restore."
        (dotNetClass "System.IO.File").WriteAllText (CyrusPrepareFixtureOutput+"complete.txt") "PASS"
    ) catch (
        try(loadMaxFile CyrusPrepareFixtureRestore useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg)catch()
        throw()
    )
)
