    -- Append-only scene data. Prepared definitions are source-local, never poses.
    parameters interactionSettings (
        interactionCollider type:#boolean default:false
        interactionReact type:#boolean default:false
        interactionCoverRoots type:#boolean default:true
        interactionGapWU type:#worldUnits default:0.0
        interactionStiffness type:#float default:0.5
        interactionColliderMode type:#integer default:1
        interactionMinimumWU type:#worldUnits default:(units.decodeValue "5mm")
        interactionMinimumM type:#float default:0.005
        interactionUnitsPending type:#boolean default:false
        interactionUnitsNotice type:#string default:""
        interactionProxySourceIDs type:#stringTab tabSize:0 tabSizeVariable:true
        interactionProxyNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        interactionFoliage type:#float default:0.05
        interactionSourceIDs type:#stringTab tabSize:0 tabSizeVariable:true
        interactionDefinitions type:#stringTab tabSize:0 tabSizeVariable:true
        interactionDefinitionRevision type:#integer default:0
        on interactionCollider set v do this.interactionsChanged()
        on interactionReact set v do this.interactionsChanged()
        on interactionCoverRoots set v do this.interactionsChanged()
        on interactionGapWU set v do this.interactionsChanged()
        on interactionStiffness set v do this.interactionsChanged()
        on interactionColliderMode set v do this.interactionsChanged()
    )
    local interactionState=undefined,interactionStateKey="",interactionError="",interactionOutputNodes=#(),interactionOutputKey=""
    local interactionSourceCache=#(),interactionReview=undefined,interactionReviewNode=undefined,interactionGuides=#()
    fn interactionsRoot = (if overlapOwner==undefined then this else overlapOwner)
    fn interactionsChanged = (
        if this.getLayerTransfer() do return true
        local root=this.interactionsRoot()
        root.interactionStateKey="";CyrusViewportRecordsDirty=true
        if CyrusScheduleUI!=undefined do CyrusScheduleUI()
        true
    )
    fn interactionsClearGuides = (
        undo off for node in interactionGuides where isValidNode node do delete node
        interactionGuides=#();true
    )
    fn interactionsRepairSettings = (
        local minimum=if interactionUnitsPending then interactionMinimumWU/(units.decodeValue "1m") else interactionMinimumM
        local repaired=minimum<0.001 or minimum>0.10000001
        undo "Repair Cyrus preparation units" on (
            if repaired do (minimum=0.005;interactionSourceIDs=#();interactionDefinitions=#();interactionDefinitionRevision+=1)
            interactionMinimumM=minimum;interactionMinimumWU=minimum*(units.decodeValue "1m");interactionUnitsPending=false
            interactionUnitsNotice=if repaired then "Legacy minimum was outside 1-100 mm; repaired to 5 mm. Analyze and review this source again." else "Preparation distance stored in metres; scene geometry was not rescaled."
            if interactionFoliage<0.01 or interactionFoliage>0.25 do (interactionFoliage=0.05;interactionSourceIDs=#();interactionDefinitions=#();interactionDefinitionRevision+=1)
        )
        interactionSourceCache=#();interactionReview=undefined;this.interactionsChanged();interactionUnitsNotice
    )
    fn interactionsSettings = (
        if interactionUnitsPending do throw "Legacy preparation units need review. Click Repair settings or Analyze model; scene geometry will not be rescaled."
        if interactionMinimumM<0.001 or interactionMinimumM>0.10000001 do throw "Minimum stem must be between 1 mm and 100 mm. Use Repair settings to restore 5 mm."
        if interactionFoliage<0.01 or interactionFoliage>0.25 do throw "Preview leaves / blades must be between 1% and 25%."
        #(interactionMinimumM,interactionFoliage,1)
    )
    fn interactionsProxy node = (
        if interactionProxySourceIDs.count!=interactionProxyNodes.count do throw "Collider source bindings are incomplete; restore the saved scene or repair its source links."
        local row=this.sourceRow node,slot=if row>0 then findItem interactionProxySourceIDs sourceRowIDs[row] else 0
        if slot>0 and slot<=interactionProxyNodes.count and isValidNode interactionProxyNodes[slot] then interactionProxyNodes[slot] else undefined
    )
    fn interactionsSetProxy node proxy = (
        if not isValidNode proxy or node==proxy do throw "Pick a separate closed collider mesh."
        local row=this.sourceRow node
        if row<1 do throw "Choose the visual source model first."
        cyrusInteractionColliderSource node proxy 3
        local id=sourceRowIDs[row],slot=findItem interactionProxySourceIDs id
        if slot==0 then (if interactionProxySourceIDs.count>=512 do throw "Collider assignment budget: 512 source bindings.";append interactionProxySourceIDs id;append interactionProxyNodes proxy)
        else interactionProxyNodes[slot]=proxy
        interactionColliderMode=3;interactionDefinitionRevision+=1;this.interactionsChanged();true
    )
    fn interactionsBuildTrunks = (
        local created=#(),pending=#(),previousIDs=interactionProxySourceIDs as array,previousNodes=interactionProxyNodes as array,previousRevision=interactionDefinitionRevision
        try (
            for node in (this.validSources()) where this.interactionsProxy node==undefined do (
                local proxy=cyrusInteractionBuildTrunk node
                append created proxy;proxy.name=uniqueName (node.name+" - Trunk collider");setUserProp proxy "CyrusColliderProxy" true;append pending #(node,proxy)
            )
            for pair in pending do this.interactionsSetProxy pair[1] pair[2]
            interactionColliderMode=3;interactionCollider=true;interactionReact=false
        )catch(interactionProxySourceIDs=previousIDs;interactionProxyNodes=previousNodes;interactionDefinitionRevision=previousRevision;undo off for node in created where isValidNode node do delete node;throw())
        true
    )
    fn interactionsReviewCollider node = (
        local value=cyrusInteractionColliderSource node (this.interactionsProxy node) interactionColliderMode
        this.interactionsClearGuides()
        local frame=node.transform,root=this.interactionsRoot()
        for i=1 to root.procPublishedOwners.count where (root.logicalParent root.procPublishedOwners[i])==this do (
            local source=findItem root.procPublishedSources[i] node
            if source>0 do (local groups=cyrusPlacementTransformGroups root.groupSnapshotRows[i];if groups[source].count>0 do (frame=groups[source][1];exit))
        )
        undo off (local model=cyrusInteractionReviewModel value frame;model.wirecolor=(color 60 240 90);model.xray=true;setUserProp model "CyrusInteractionTransient" true;interactionGuides=#(model))
        true
    )
    fn interactionsAnalyze node = (
        if not CyrusLicenseCanEdit() do throw "Active Cyrus authoring license required to prepare a model."
        if cyrusInteractionVersion==undefined or cyrusInteractionVersion()!=2 do throw "Load the matched CyrusScatter 0.87 native modules and restart Max."
        if not isValidNode node or findItem (this.validSources()) node==0 do throw "Choose a current mesh model in this layer."
        if interactionUnitsPending do this.interactionsRepairSettings()
        this.interactionsClearGuides()
        local next=cyrusInteractionSource node undefined (this.interactionsSettings()) 1
        interactionReview=next;interactionReviewNode=node
        local paths=cyrusInteractionGuides next
        local frame=node.transform,root=this.interactionsRoot()
        -- Review a frozen copy at a published instance; library source nodes
        -- commonly live hidden, far outside the artist's working view.
        for i=1 to root.procPublishedOwners.count where (root.logicalParent root.procPublishedOwners[i])==this do (
            local source=findItem root.procPublishedSources[i] node
            if source>0 do (
                local groups=cyrusPlacementTransformGroups root.groupSnapshotRows[i]
                if groups[source].count>0 do (frame=groups[source][1];exit)
            )
        )
        if paths.count>0 do undo off (
            local model=cyrusInteractionReviewModel next frame
            setUserProp model "CyrusInteractionTransient" true
            interactionGuides=#(model)
            local shape=splineShape name:"Cyrus_Interaction_Guide_Review" wirecolor:(color 80 240 90)
            append interactionGuides shape
            for path in paths do (addNewSpline shape;for p in path do addKnot shape (numSplines shape) #corner #line p;updateShape shape)
            shape.transform=frame;shape.renderable=false;setUserProp shape "CyrusInteractionTransient" true
        )
        format "Cyrus source analysis:\n%\n" (cyrusInteractionSourceInfo next)
        cyrusInteractionSourceInfo next
    )
    fn interactionsAccept = (
        if interactionReview==undefined or not isValidNode interactionReviewNode do throw "Analyze a model and inspect its roots and branch guides first."
        local row=this.sourceRow interactionReviewNode
        if row<1 or row>sourceRowIDs.count do throw "The reviewed source was removed. Analyze again."
        -- Recapture verifies geometry, units and settings before acceptance.
        local current=cyrusInteractionSource interactionReviewNode undefined (this.interactionsSettings()) 1
        if (cyrusInteractionSourceInfo current)!=(cyrusInteractionSourceInfo interactionReview) do throw "The source changed after analysis. Analyze and review again."
        local accepted=cyrusInteractionAccept current,id=sourceRowIDs[row],slot=findItem interactionSourceIDs id
        undo "Accept Cyrus source guides" on (
            if slot==0 then (append interactionSourceIDs id;append interactionDefinitions (cyrusInteractionSerialize accepted))
            else interactionDefinitions[slot]=cyrusInteractionSerialize accepted
            interactionDefinitionRevision+=1
        )
        interactionSourceCache=#();interactionReview=undefined;this.interactionsClearGuides();this.interactionsChanged();true
    )
    fn interactionsSources plants role = (
        if role==0 do return #()
        local result=#(),flags=(if bit.get role 1 then 2 else 0)+(if bit.get role 2 then 1 else 0),settings=if role==2 then this.interactionsSettings() else undefined,nextCache=#()
        if interactionDefinitions.count!=interactionSourceIDs.count do throw "Prepared model data is incomplete. Analyze again."
        for node in plants do (
            if not isValidNode node do throw "Interactions require mesh models; Points and Empty sources are unsupported."
            local row=this.sourceRow node,slot=if row>0 then findItem interactionSourceIDs sourceRowIDs[row] else 0
            local saved=if bit.get role 2 then (if slot>0 then interactionDefinitions[slot] else throw ("Analyze and accept guides for "+node.name+" before enabling React to colliders.")) else undefined
            local value=if role==1 then cyrusInteractionColliderSource node (this.interactionsProxy node) interactionColliderMode else cyrusInteractionSource node saved settings flags
            append result value;append nextCache #(node,value)
        )
        interactionSourceCache=nextCache;result
    )
    fn interactionsKey owners epoch = (
        local stream=stringStream ""
        format "%|%|" epoch cyrusEnabled to:stream
        for leaf in owners do (
            local parent=this.logicalParent leaf
            format "%:%:%:%:%:%:%:%:%:%:%|" leaf.layerID parent.interactionCollider parent.interactionReact parent.interactionCoverRoots parent.interactionGapWU parent.interactionStiffness parent.interactionColliderMode parent.interactionMinimumM parent.interactionFoliage parent.interactionDefinitionRevision leaf.autoRender to:stream
        )
        stream as string
    )
    fn interactionsStage rows owners plants previous:undefined retargetEdits:false = (
        local active=false
        for leaf in owners do (local parent=this.logicalParent leaf;if parent.interactionCollider or parent.interactionReact do active=true)
        if not active and previous!=undefined and cyrusInteractionHasEdits!=undefined do active=cyrusInteractionHasEdits previous
        if not active or not cyrusEnabled do return undefined
        if cyrusInteractionVersion==undefined or cyrusInteractionVersion()!=2 do throw "CyrusScatter 0.87 requires its matched native interaction modules. Restart after installing."
        local payload=for i=1 to owners.count collect (
            local leaf=owners[i],parent=this.logicalParent leaf
            local role=(if parent.interactionCollider then 1 else 0)+(if parent.interactionReact then 2 else 0)
            if not this.enabledLayer (findItem layerObjects leaf) do role=0
            #(leaf.layerID,leaf.editLayerKey,rows[i],(parent.interactionsSources plants[i] role),role,parent.interactionCoverRoots,parent.interactionGapWU/(units.decodeValue "1m"),parent.interactionStiffness,leaf.autoRender)
        )
        if retargetEdits then cyrusInteractionRestage (CyrusRecipeOwnerNode this) payload previous else cyrusInteractionStageFrom (CyrusRecipeOwnerNode this) payload previous
    )
    fn interactionsEnsure = (
        if procPublishedOwners.count==0 do return undefined
        if interactionState!=undefined and not (cyrusInteractionOwner interactionState (CyrusRecipeOwnerNode this)) do (interactionState=undefined;interactionStateKey="";interactionOutputNodes=#();interactionOutputKey="")
        if interactionState!=undefined and not (cyrusInteractionSourcesFresh interactionState) do interactionStateKey=""
        local key=this.interactionsKey procPublishedOwners procEpoch,owner=CyrusRecipeOwnerNode this
        local outputKey=key+"|hidden:"+(if isValidNode owner then owner.isHidden as string else "true")
        local outputsValid=true
        for node in interactionOutputNodes where not isValidNode node do outputsValid=false
        if key==interactionStateKey and outputKey==interactionOutputKey and outputsValid do return interactionState
        if key!=interactionStateKey do for i=1 to procPublishedOwners.count do procPublishedOwners[i].procCheckPublishedGeometry procPublishedSources[i] procPublishedMetadata[i]
        local stage=if key==interactionStateKey then interactionState else this.interactionsStage groupSnapshotRows procPublishedOwners procPublishedSources previous:interactionState retargetEdits:true
        -- Source bindings and numeric solve must succeed before replacing state.
        local outputs=if stage==undefined or not isValidNode owner or owner.isHidden then #() else cyrusInteractionRenderNodes stage (for n in interactionOutputNodes where isValidNode n collect n)
        for node in outputs do setUserProp node "CyrusInteractionTransient" true
        if stage==undefined and interactionState!=undefined do cyrusInteractionLive interactionState false
        undo off for node in interactionOutputNodes where isValidNode node and findItem outputs node==0 do delete node
        interactionOutputNodes=outputs;interactionState=stage;interactionStateKey=key;interactionOutputKey=outputKey;interactionError=""
        stage
    )
    fn interactionsRestRows leaf original = (
        local state=this.interactionsEnsure(),slot=findItem procPublishedOwners leaf
        if state==undefined or slot==0 then original else leaf.filterSourceRowsByPolicy (cyrusInteractionRows state slot) procPublishedFinalKeep[slot]
    )
    fn interactionsStatus = (
        if interactionError!="" do return ("Previous contact result retained: "+interactionError)
        if interactionState==undefined then "No active contact result. Enable Collider on stones, analyze plant models, then enable React to colliders."
        else cyrusInteractionSummary interactionState
    )
    fn interactionsStatistics = (if interactionState==undefined then throw "No active interaction publication" else cyrusInteractionInfo interactionState)
    fn interactionsRelease = (
        this.interactionsClearGuides()
        interactionState=undefined;interactionStateKey="";interactionOutputKey="";interactionSourceCache=#();interactionReview=undefined;interactionReviewNode=undefined
        interactionOutputNodes=#();true
    )
    fn interactionsBeforeSave = (
        this.interactionsClearGuides()
        undo off for node in interactionOutputNodes where isValidNode node do delete node
        interactionOutputNodes=#();interactionOutputKey="";true
    )
