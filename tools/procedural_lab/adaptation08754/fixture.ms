-- All mutating qualification operations run in a disposable profile and copy.
global WFOwner,WFRoot,WFGrass,WFCollider,WFEdit,ADWall,ADBox,ADTree
(
    if not matchPattern GardenRun pattern:"*/build/adaptation08754-20261028-01/host-*/" do throw "Owned adaptation host required."
    local project=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\",busy=CyrusPointBusy,suspended=CyrusPointSuspended,failure=""
    try (
        CyrusPointBusy=true;CyrusPointSuspended=true
        if not loadMaxFile (project+@"build\interactions08753-20261028-01\fixtures\New-Plants-22-input.max") quiet:true useFileUnits:true missingDLLsAction:#logmsg do throw "Cannot load preserved fixture copy."
        ColorPipelineMgr.Mode=#OCIO_Default
        WFOwner=undefined
        for node in objects where classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined do WFOwner=node
        if not isValidNode WFOwner do throw "Missing fixture owner."
        WFRoot=WFOwner.baseObject;WFGrass=WFRoot.layerObjects[1];WFCollider=WFRoot.layerObjects[2]
        WFEdit=undefined
        for modifier in WFOwner.modifiers where classof modifier==CyrusScatterEdit do WFEdit=modifier
        WFRoot.updateMode=1;WFGrass.amount=100;WFCollider.amount=1
        WFCollider.interactionCollider=false;WFCollider.interactionReact=false
        WFRoot.layerEnabled[2]=false
        WFGrass.interactionReact=true;WFGrass.interactionResponse=3;WFGrass.interactionBendStrength=.75;WFGrass.interactionPruneAmount=1;WFGrass.interactionPruneThresholdWU=0
        WFGrass.interactionGapWU=0;WFGrass.interactionFoliage=.25
        -- Resolve only uniquely present original asset paths in the two fixture roots.
        for leaf in WFRoot.layerObjects do for node in leaf.validSources() where isValidNode node and node.material!=undefined do (
            for map in getClassInstances Bitmaptexture target:node.material do (
                local raw=map.filename,found=undefined
                for base in #(project+@"Test Scene\Organized Models\Plants\Outdoor\Outdoor_Plants_01\",project+@"Test Scene\Rock_Boulder_10\") do (
                    local candidate=base+raw
                    if doesFileExist candidate do found=candidate
                )
                if found!=undefined do map.filename=found
            )
        )
        local side=units.decodeValue "1m"
        ADWall=box name:"AD_Ordinary_Wall_Move_Me" width:side length:side height:side
        ADWall.scale=[1.5,0.15,0.65];ADWall.wirecolor=orange
        WFRoot.interactionSceneColliders=#(ADWall)
        CyrusPointBusy=busy;CyrusPointSuspended=suspended
        WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
        local tm=(cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[1])[1][1]
        ADWall.pos=tm.row4
        cyrusInteractionSceneUpdate WFRoot.interactionState
        undo off (
            select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot
            local owner=CyrusPointOwner WFOwner
            if isValidNode owner do (local bounds=nodeGetBoundingBox owner (matrix3 1);viewport.ZoomToBounds false bounds[1] bounds[2])
        )
        if theHold.Holding() or theHold.IsSuspended() do throw "Fixture leaked an authored hold."
        if WFRoot.interactionError!="" do throw WFRoot.interactionError
    )catch(failure=getCurrentException())
    CyrusPointBusy=busy;CyrusPointSuspended=suspended
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"fixture.txt") (if failure=="" then "PASS" else failure+"\n"+getCurrentExceptionStackTrace())
    if failure!="" do throw failure
)
