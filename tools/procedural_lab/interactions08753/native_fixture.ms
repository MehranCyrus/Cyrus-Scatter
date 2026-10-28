-- Clean source/Undo fixture with no Python inside Max and no history repair.
-- Loading the owned copy discards only this campaign's disposable setup.
global WFOwner,WFRoot,WFGrass,WFCollider,WFEdit
global AuditStone,AuditPreparedA,AuditPreparedB,AuditReplacement,AuditProxyA,AuditProxyB
(
    if not matchPattern GardenRun pattern:"*/build/interactions08753-20261028-01/host-*/" do throw "Owned scene-repair host required."
    local project=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\",failure="",previousBusy=CyrusPointBusy
    local result=stringStream ""
    try (
        CyrusPointBusy=true;CyrusPointSuspended=true
        if not loadMaxFile (project+@"build\interactions08753-20261028-01\fixtures\New-Plants-22-input.max") quiet:true useFileUnits:true missingDLLsAction:#logmsg do throw "Cannot load owned input copy."
        ColorPipelineMgr.Mode=#OCIO_Default
        WFOwner=undefined
        for node in objects where classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined do WFOwner=node
        if not isValidNode WFOwner do throw "Owned input has no Scatter owner."
        WFRoot=WFOwner.baseObject;WFGrass=WFRoot.layerObjects[1];WFCollider=WFRoot.layerObjects[2]
        WFRoot.updateMode=1;WFGrass.amount=10;WFCollider.amount=1
        AuditStone=getNodeByName "Stone 1" exact:true
        if not isValidNode AuditStone do throw "Input stone missing."
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
        WFCollider.interactionCollider=false;WFCollider.interactionReact=false
        WFCollider.removeModelSources (for i=1 to WFCollider.sources.count collect i)
        AuditPreparedA=copy (WFGrass.validSources())[1];AuditPreparedA.name="Owned_prepared_source_A"
        AuditPreparedB=copy (WFGrass.validSources())[1];AuditPreparedB.name="Owned_prepared_source_B"
        AuditReplacement=copy AuditStone;AuditReplacement.name="Owned_source_replacement_stone"
        WFCollider.addModelSource AuditPreparedA;WFCollider.addModelSource AuditPreparedB
        for key in #(#interactionMinimumM,#interactionFoliage,#interactionConnectionM) do setProperty WFCollider key (getProperty WFGrass key)
        WFCollider.interactionUnitsPending=false
        WFCollider.interactionsPrepare #(AuditPreparedA,AuditPreparedB) rebuild:true enable:false
        local side=units.decodeValue "10cm"
        AuditProxyA=box name:"Owned_binding_proxy_A" length:side width:side height:side
        AuditProxyB=box name:"Owned_binding_proxy_B" length:side width:side height:side
        AuditProxyA.transform=AuditPreparedA.transform;AuditProxyB.transform=AuditPreparedB.transform
        WFCollider.interactionsSetProxy AuditPreparedA AuditProxyA;WFCollider.interactionsSetProxy AuditPreparedB AuditProxyB
        CyrusPointBusy=previousBusy;CyrusPointSuspended=false
        WFRoot.refreshAll();CyrusPointSync()
        undo off (
            select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot
            -- The command-panel mount timer must return before its separate
            -- journal-native-picker-ready callback binds source controls.
            for node in objects where node!=WFOwner and node!=AuditReplacement do hide node
            unhide AuditReplacement;unhide WFOwner
            local bounds=nodeGetBoundingBox AuditReplacement (matrix3 1),centre=(bounds[1]+bounds[2])*0.5
            local extent=amax (bounds[2].x-bounds[1].x) (amax (bounds[2].y-bounds[1].y) (bounds[2].z-bounds[1].z))
            local eye=centre+[extent*1.2,-extent*1.8,extent],back=normalize (eye-centre)
            local right=normalize (cross [0,0,1] back),up=cross back right
            viewport.setType #view_persp_user;viewport.setFOV 45;viewport.setTM (inverse (matrix3 right up back eye))
        )
        format "status=pass holding=% suspended=% definitions=% proxies=%" (theHold.Holding()) (theHold.IsSuspended()) WFCollider.interactionDefinitions.count WFCollider.interactionProxyNodes.count to:result
    )catch(failure=getCurrentException();format "status=failed error=% stack=%" failure (getCurrentExceptionStackTrace()) to:result)
    CyrusPointBusy=previousBusy;CyrusPointSuspended=false
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"native-fixture.txt") (result as string)
    if failure!="" do throw failure
)
