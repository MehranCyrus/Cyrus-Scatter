global CyrusRecipeRemapPreparedID,CyrusRecipeInteractionFields,CyrusRecipeCaptureAuthored,CyrusRecipeRestoreAuthored,CyrusRecipeRestoreEdits
CyrusRecipeInteractionFields=#(#interactionCollider,#interactionReact,#interactionCoverRoots,#interactionGapWU,#interactionStiffness,#interactionColliderMode,#interactionMinimumM,#interactionFoliage,#interactionConnectionM,#interactionMaxVertices,#interactionMaxTriangles,#interactionMaxParts,#interactionMaxGuides,#interactionMaxPreview,#interactionMemoryMiB,#interactionWorkMillions,#interactionHideMarginWU,#interactionHideArea)
fn CyrusRecipeCaptureAuthored context = (
    if context.root.interactionSceneColliders.count>0 do throw "Scene collider references require a Scene preset. Portable recipes do not store scene colliders yet."
    for owner in context.owners where owner.interactionReact and (owner.interactionResponse!=0 or owner.interactionNeighbors) do throw "Branch adaptation requires a Scene preset. Portable recipes currently store Detailed contact only."
    local definitions=#(),interactions=#(),edits=#(),bindings=#(),unitsNow=(units.decodeValue "1m") as double
    for owner in context.owners do (
        append bindings #(owner.editLayerKey,owner.layerID,(owner.procSourceEditBinding (owner.validSources()) owner.procPreparedRows))
        if owner.interactionUnitsPending do throw "Repair the layer's preparation units before saving its recipe. The source scene is preserved."
        local settings=for key in CyrusRecipeInteractionFields collect (local value=getProperty owner key;if findItem #(#interactionGapWU,#interactionHideMarginWU) key>0 then value/unitsNow else value)
        local prepared=#(),proxies=#()
        for i=1 to owner.interactionSourceIDs.count do (
            if i>owner.interactionDefinitions.count do throw "Incomplete prepared source history. Prepare the affected source again."
            local saved=owner.interactionDefinitions[i],index=findItem definitions saved
            if index==0 do (append definitions saved;index=definitions.count)
            append prepared #(owner.interactionSourceIDs[i],index)
        )
        for i=1 to owner.interactionProxySourceIDs.count do (
            if i>owner.interactionProxyNodes.count or not isValidNode owner.interactionProxyNodes[i] do throw "A custom collider link is missing. Repair that link before saving."
            append proxies #(owner.interactionProxySourceIDs[i],(CyrusRecipeRole context owner.interactionProxyNodes[i] "node" "interactionCollider"))
        )
        if owner.interactionCollider or owner.interactionReact or prepared.count>0 or proxies.count>0 do append interactions (CyrusRecipeObject #(#("owner",owner.layerID),#("settings",settings),#("definitions",prepared),#("proxies",proxies)))
    )
    for editMod in context.root.procModifiers() do (
        local payload=cyrusEditRecipeExport editMod bindings
        if payload!="" do append edits (CyrusRecipeObject #(#("enabled",editMod.enabled),#("data",payload)))
    )
    CyrusRecipeObject #(#("version",1),#("definitions",definitions),#("interactions",interactions),#("edits",edits))
)
fn CyrusRecipeRemapPreparedID owner oldRows extraOld extraNew id = (
    local index=findItem oldRows id
    if index>0 do return owner.sourceRowIDs[index]
    index=findItem extraOld id
    if index==0 do (append extraOld id;append extraNew (CyrusNewLayerID());index=extraOld.count)
    extraNew[index]
)
fn CyrusRecipeRestoreAuthored owner record authored bindings = (
    owner.interactionResponse=0;owner.interactionNeighbors=false
    local oldRows=CyrusRecipeGet (CyrusRecipeGet record "settings") "sourceRowIDs",extraOld=#(),extraNew=#(),metres=(units.decodeValue "1m") as double
    for state in (CyrusRecipeGet authored "interactions") where (CyrusRecipeGet state "owner")==(CyrusRecipeGet record "id") do (
        local settings=CyrusRecipeGet state "settings"
        for i=1 to CyrusRecipeInteractionFields.count do (
            local key=CyrusRecipeInteractionFields[i],value=settings[i]
            if findItem #(#interactionGapWU,#interactionHideMarginWU) key>0 do value*=metres
            setProperty owner key value
        )
        owner.interactionMinimumWU=owner.interactionMinimumM*metres;owner.interactionUnitsPending=false
        owner.interactionSourceIDs=#();owner.interactionDefinitions=#();owner.interactionProxySourceIDs=#();owner.interactionProxyNodes=#()
        local definitions=CyrusRecipeGet authored "definitions"
        for pair in (CyrusRecipeGet state "definitions") do (append owner.interactionSourceIDs (CyrusRecipeRemapPreparedID owner oldRows extraOld extraNew pair[1]);append owner.interactionDefinitions definitions[pair[2]])
        for pair in (CyrusRecipeGet state "proxies") do (append owner.interactionProxySourceIDs (CyrusRecipeRemapPreparedID owner oldRows extraOld extraNew pair[1]);append owner.interactionProxyNodes (CyrusRecipeResolve bindings pair[2]))
        owner.interactionDefinitionRevision+=1
    )
    true
)
fn CyrusRecipeRestoreEdits root document identityMap = (
    local authored=CyrusRecipeGet document "authored",stacks=CyrusRecipeGet authored "edits"
    if stacks.count==0 do return true
    if cyrusEditVersion()!=5 do throw "Edited recipes require the matched Cyrus Scatter 0.87.6.7 Edit module. Restart Max after installing."
    local editMods=root.procModifiers(),hasContacts=false
    for leaf in root.layerObjects where leaf.interactionCollider or leaf.interactionReact do hasContacts=true
    if hasContacts and (stacks.count>1 or editMods.count>1) do throw "Interactions support one Cyrus Edit modifier per setup. Save/load this edited interaction recipe with one modifier."
    if editMods.count>0 and stacks.count>1 do throw "Load this multi-modifier edited recipe into a new setup. Existing modifier order is preserved."
    local cloneMap=cyrusEditRecipeCloneMap (for stack in stacks collect (CyrusRecipeGet stack "data")),mapping=#(),records=CyrusRecipeGet document "layers"
    for record in records do (
        local owner=CyrusRecipeResolve identityMap (CyrusRecipeGet record "id"),old=CyrusRecipeGet (CyrusRecipeGet record "settings") "procSourceIDs",sources=#()
        if old.count!=owner.procSourceIDs.count do throw "Imported Edit source history is incomplete."
        for i=1 to old.count do append sources #(old[i],owner.procSourceIDs[i])
        append mapping #((CyrusRecipeGet record "id"),owner.editLayerKey,sources)
    )
    if editMods.count>0 then (
        if editMods[1].enabled!=(CyrusRecipeGet stacks[1] "enabled") do throw "The destination Edit modifier has a different enabled state. Load this recipe into a new setup to preserve both states."
        cyrusEditRecipeImport editMods[1] (CyrusRecipeGet stacks[1] "data") mapping cloneMap
    ) else (
        local node=CyrusRecipeOwnerNode root
        for i=stacks.count to 1 by -1 do (
            local editMod=CyrusScatterEdit();editMod.enabled=CyrusRecipeGet stacks[i] "enabled"
            addModifier node editMod
            cyrusEditRecipeImport editMod (CyrusRecipeGet stacks[i] "data") mapping cloneMap
        )
    )
    true
)
