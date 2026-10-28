-- Load only the three explicit delivery copies; never save an artist input.
(
    if not matchPattern GardenRun pattern:"*/build/adaptation08754-20261028-01/host-*/" do throw "Owned adaptation host required."
    if theHold.Holding() or theHold.IsSuspended() do throw "Finish the current operation first."
    local folder=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Interaction 0.87.5.4\",rows=#(),failure=""
    try (
        for entry in #(#("Scene_Collider_Grass_0.87.5.4.max",1000),#("Scene_Collider_Fern_0.87.5.4.max",12),#("Branch_Tree_Neighbors_0.87.5.4.max",6)) do (
            if not loadMaxFile (folder+entry[1]) quiet:true useFileUnits:true missingDLLsAction:#logmsg do throw ("Cannot reopen "+entry[1])
            local owners=for node in objects where classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined collect node
            if owners.count!=1 do throw "Expected one Scatter setup in the trial."
            WFOwner=owners[1];WFRoot=WFOwner.baseObject;WFGrass=WFRoot.layerObjects[1]
            if WFRoot.interactionSceneColliders.count!=1 or not isValidNode WFRoot.interactionSceneColliders[1] do throw "Trial collider reference is missing."
            ADWall=WFRoot.interactionSceneColliders[1]
            if WFGrass.amount!=entry[2] or WFGrass.interactionResponse!=3 do throw "Trial response/count did not persist."
            WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
            if WFRoot.interactionError!="" do throw WFRoot.interactionError
            append rows (ADNativeObject #(#("file",entry[1]),#("amount",WFGrass.amount),#("statistics",WFRoot.interactionsStatistics())))
        )
    )catch(failure=getCurrentException())
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"reopen-trials.json") (ADNativeJSON (ADNativeObject #(#("status",if failure=="" then "pass" else "failed"),#("trials",rows),#("error",failure))))
    if failure!="" do throw failure
)
