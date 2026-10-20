-- Disposable derivative only. ProOptimizer caches can invalidate after later edits.
-- Freeze each evaluated result and explicitly reconnect its original instances.
(
    if MCPFixtureDir==undefined or CyrusBuildingStudyModifiers==undefined do throw "Owned prepared scene required."
    local log=createFile (MCPFixtureDir+"geometry-freeze-v1.jsonl") encoding:#utf8 writeBOM:false
    local oldPropagation=InstanceMgr.autoMtlPropagation,originalDelta=0
    InstanceMgr.autoMtlPropagation=false
    try (
        for record in CyrusBuildingStudyModifiers do (
            local node=record[1],op=record[2],members=record[5]
            local states=(for n in members collect #(n.transform,n.material,n.handle,n.name,n.layer.name))
            select node;max modify mode;modPanel.setCurrentObject op node:node
            local warm=snapshotAsMesh node;warm=undefined
            if not op.Calculate do op.Calculate=true
            local percent=op.VertexPercent;op.VertexPercent=percent
            local evaluated=snapshotAsMesh node
            if evaluated==undefined do throw ("No reduced mesh: "+node.name)
            local faces=evaluated.numfaces,verts=evaluated.numverts;evaluated=undefined
            if faces<=0 or faces>=record[3][1] do throw ("Reduction was not retained: "+node.name)
            convertToMesh node
            for i=1 to members.count do (
                local n=members[i],state=states[i]
                if not areNodesInstances n node do instanceReplace n node
                local mesh=snapshotAsMesh n
                if mesh==undefined or mesh.numfaces!=faces or mesh.numverts!=verts do throw "Frozen mesh differs from the validated result."
                mesh=undefined
                if n.transform!=state[1] or n.material!=state[2] or n.handle!=state[3] or n.name!=state[4] or n.layer.name!=state[5] do throw "Frozen instance changed node identity, placement, material or layer."
            )
            originalDelta+=(record[3][1]-faces)*members.count
            format "{\"handle\":%,\"name\":%,\"beforeFaces\":%,\"afterFaces\":%,\"instances\":%,\"percent\":%}\n" node.handle (CyrusBuildingJsonString node.name) record[3][1] faces members.count percent to:log
            flush log
        )
        local facesTotal=0,verticesTotal=0
        for n in geometry where n.renderable and not n.isHidden do (
            local mesh=snapshotAsMesh n
            if mesh!=undefined do (facesTotal+=mesh.numfaces;verticesTotal+=mesh.numverts)
            mesh=undefined
        )
        format "{\"summary\":true,\"evaluatedBeforeFaces\":%,\"evaluatedAfterFaces\":%,\"evaluatedAfterVertices\":%}\n" (facesTotal+originalDelta) facesTotal verticesTotal to:log
        close log;InstanceMgr.autoMtlPropagation=oldPropagation;clearSelection()
        if not saveMaxFile (MCPFixtureDir+"project/scenes/Big-building-geometry-frozen-v1.max") quiet:true do throw "Frozen geometry checkpoint failed."
        (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"geometry-freeze-v1-complete.txt") "PASS"
    ) catch (try(close log)catch();InstanceMgr.autoMtlPropagation=oldPropagation;throw())
)
