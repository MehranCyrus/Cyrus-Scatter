    -- Append-only scene data. Prepared definitions are source-local, never poses.
    parameters interactionSettings (
        interactionCollider type:#boolean default:false
        interactionReact type:#boolean default:false
        interactionCoverRoots type:#boolean default:false
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
        -- Keep all original parameter IDs above unchanged for saved schema 61.
        interactionMaxVertices type:#integer default:2000000
        interactionMaxTriangles type:#integer default:4000000
        interactionMaxParts type:#integer default:100000
        interactionMaxGuides type:#integer default:8192
        interactionMaxPreview type:#integer default:500000
        interactionMemoryMiB type:#integer default:2048
        interactionWorkMillions type:#integer default:256
        interactionConnectionM type:#float default:0.15
        interactionHideMarginWU type:#worldUnits default:0.0
        interactionHideArea type:#integer default:2
        -- Schema 64: controller-owned scene references; layer-owned response.
        interactionSceneColliders type:#nodeTab tabSize:0 tabSizeVariable:true
        interactionResponse type:#integer default:1
        interactionBendStrength type:#float default:0.5
        interactionPruneAmount type:#float default:1.0
        interactionPruneThresholdWU type:#worldUnits default:0.0
        interactionNeighbors type:#boolean default:false
        -- Schema 65: per-layer artistic bend profile; no source re-analysis.
        interactionTrunkBend type:#float default:0.0
        interactionFixedBase type:#float default:0.0
        interactionBendTransition type:#float default:0.25
        on interactionTrunkBend set v do this.interactionsChanged()
        on interactionFixedBase set v do this.interactionsChanged()
        on interactionBendTransition set v do this.interactionsChanged()
        on interactionSceneColliders set v do this.interactionsChanged()
        on interactionResponse set v do this.interactionsChanged()
        on interactionBendStrength set v do this.interactionsChanged()
        on interactionPruneAmount set v do this.interactionsChanged()
        on interactionPruneThresholdWU set v do this.interactionsChanged()
        on interactionNeighbors set v do this.interactionsChanged()
        on interactionHideMarginWU set v do this.interactionsChanged()
        on interactionHideArea set v do this.interactionsChanged()
        on interactionCollider set v do this.interactionsChanged()
        on interactionReact set v do this.interactionsChanged()
        on interactionCoverRoots set v do this.interactionsChanged()
        on interactionGapWU set v do this.interactionsChanged()
        on interactionStiffness set v do this.interactionsChanged()
        on interactionColliderMode set v do this.interactionsChanged()
    )
    local interactionState=undefined,interactionStateKey="",interactionError="",interactionOutputNodes=#(),interactionOutputKey=""
    local interactionSourceCache=#(),interactionReview=undefined,interactionReviewNode=undefined,interactionGuides=#(),interactionReviewKind=undefined,interactionReviewApproved=false
    local interactionSceneDirty=true
    fn interactionsSceneNodes = (for node in interactionSceneColliders where isValidNode node collect node)
    fn interactionsSceneCommand nodes removeIndex:0 = (
        if overlapOwner!=undefined do return (this.interactionsRoot()).interactionsSceneCommand nodes removeIndex:removeIndex
        local next=interactionSceneColliders as array
        if removeIndex>0 then (if removeIndex<=next.count do deleteItem next removeIndex)
        else for node in nodes where isValidNode node do (
            if node==(CyrusRecipeOwnerNode this) or classof node.baseObject==AminScatterObject do throw "Choose an ordinary scene mesh, not a Scatter setup."
            appendIfUnique next node
        )
        if next.count>256 do throw "A setup supports at most 256 scene colliders."
        local command=this.sourceCommandBegin "Cyrus scene colliders" 4
        try(interactionSceneColliders=next;this.sourceCommandCommit command)catch(this.sourceCommandCancel command;throw())
        interactionSceneDirty=true
        if CyrusSceneColliderWatch!=undefined do CyrusSceneColliderWatch()
        true
    )
    fn interactionsResponseSetting key value = (
        local command=this.sourceCommandBegin "Cyrus branch response" 5
        try(setProperty this key value;if interactionResponse==0 do interactionNeighbors=false;this.sourceCommandCommit command)catch(this.sourceCommandCancel command;throw())
        this.interactionsChanged();true
    )
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
        interactionGuides=#();interactionReviewKind=undefined;true
    )
    fn interactionsForgetSource id = (
        -- Replacing an authored model preserves its placement identity, not a
        -- preparation or custom proxy inferred from a different mesh. Capture
        -- these changes in the replacement's Undo transaction. Do not advance
        -- the interaction revision: Manual still owns its frozen publication.
        if interactionSourceIDs.count!=interactionDefinitions.count or interactionProxySourceIDs.count!=interactionProxyNodes.count do throw "Source preparation bindings are incomplete. Restore the saved setup before replacing this model."
        local ids=for v in interactionSourceIDs collect v
        local definitions=for v in interactionDefinitions collect v
        local proxyIDs=for v in interactionProxySourceIDs collect v
        local proxies=for v in interactionProxyNodes collect v
        local slot=findItem ids id,proxySlot=findItem proxyIDs id
        if slot>0 do (deleteItem ids slot;deleteItem definitions slot;interactionSourceIDs=ids;interactionDefinitions=definitions)
        if proxySlot>0 do (deleteItem proxyIDs proxySlot;deleteItem proxies proxySlot;interactionProxySourceIDs=proxyIDs;interactionProxyNodes=proxies)
        interactionSourceCache=#();interactionReview=undefined;interactionReviewNode=undefined;interactionReviewApproved=false
        this.interactionsClearGuides();true
    )
    fn interactionsReviewVisible kind node = (interactionReviewKind==kind and interactionReviewNode==node and (for n in interactionGuides where isValidNode n collect n).count>0)
    fn interactionsReady plants = (
        if plants.count==0 or interactionDefinitions.count!=interactionSourceIDs.count do return false
        for node in plants do (
            if not isValidNode node do return false
            local row=this.sourceRow node,slot=if row>0 then findItem interactionSourceIDs sourceRowIDs[row] else 0
            if slot==0 or interactionDefinitions[slot]=="" do return false
        )
        true
    )
    fn interactionsPreparationStatus = (
        local plants=this.validSources(),ready=0
        for node in plants where isValidNode node do (local row=this.sourceRow node;if row>0 and findItem interactionSourceIDs sourceRowIDs[row]>0 do ready+=1)
        if plants.count==0 then "Add a source model in Models & Points."
        else if ready<plants.count then ((ready as string)+" / "+(plants.count as string)+" sources prepared. Select each source and click Prepare model. Instances react when all sources are ready.")
        else "All source models prepared. Contact changes update automatically; Manual placement edits still wait for Update scatter."
    )
    fn interactionsRepairSettings = (
        local minimum=if interactionUnitsPending then interactionMinimumWU/(units.decodeValue "1m") else interactionMinimumM
        local repaired=minimum<0.001 or minimum>0.10000001
        undo "Repair Cyrus preparation units" on (
            if repaired do (minimum=0.005;interactionSourceIDs=#();interactionDefinitions=#();interactionDefinitionRevision+=1)
            interactionMinimumM=minimum;interactionMinimumWU=minimum*(units.decodeValue "1m");interactionUnitsPending=false
            interactionUnitsNotice=if repaired then "Legacy minimum was outside 1-100 mm; repaired to 5 mm. Click Prepare model again." else "Preparation distance stored in metres; scene geometry was not rescaled."
            if interactionFoliage<0.01 or interactionFoliage>1.0 do (interactionFoliage=0.05;interactionSourceIDs=#();interactionDefinitions=#();interactionDefinitionRevision+=1)
        )
        interactionSourceCache=#();interactionReview=undefined;this.interactionsChanged();interactionUnitsNotice
    )
    fn interactionsSettings = (
        if interactionUnitsPending do throw "Legacy preparation units need review. Click Repair settings or Analyze model; scene geometry will not be rescaled."
        if interactionMinimumM<0.001 or interactionMinimumM>0.10000001 do throw "Minimum stem must be between 1 mm and 100 mm. Use Repair settings to restore 5 mm."
        if interactionFoliage<0.01 or interactionFoliage>1.0 do throw "Preview leaves / blades must be between 1% and 100%."
        #(interactionMinimumM,interactionFoliage,1,this.interactionsLimits(),interactionConnectionM)
    )
    fn interactionsLimits = (#(interactionMaxVertices,interactionMaxTriangles,interactionMaxParts,interactionMaxGuides,interactionMaxPreview,interactionMemoryMiB,interactionWorkMillions))
    fn interactionsLimitsChanged = (
        interactionSourceCache=#();interactionReview=undefined;interactionDefinitionRevision+=1;this.interactionsChanged();true
    )
    fn interactionsColliderValue node = (
        if interactionColliderMode==1 then cyrusInteractionSource node undefined #(0.005,0.05,1,this.interactionsLimits()) 2
        else cyrusInteractionColliderSource node (this.interactionsProxy node) interactionColliderMode
    )
    fn interactionsCleanProxies = (
        local ids=#(),nodes=#(),removed=0
        for i=1 to interactionProxySourceIDs.count do (
            if findItem sourceRowIDs interactionProxySourceIDs[i]>0 then (append ids interactionProxySourceIDs[i];append nodes interactionProxyNodes[i]) else removed+=1
        )
        undo "Clean unused Cyrus collider links" on (interactionProxySourceIDs=ids;interactionProxyNodes=nodes;interactionDefinitionRevision+=1)
        this.interactionsChanged();removed
    )
    fn interactionsSourceCaption node = (
        local row=this.sourceRow node,id=if row>0 then sourceRowIDs[row] else "",slot=findItem interactionSourceIDs id
        node.name+" | "+(if interactionCollider then (if interactionColliderMode==1 then "Full source" else if interactionColliderMode==2 then "Box" else if this.interactionsProxy node==undefined then "Missing collider" else "Separate collider") else if slot>0 then "Saved guides" else "Needs preparation")
    )
    fn interactionsCanAccept node:undefined = (
        if interactionReview==undefined or interactionReviewApproved or (node!=undefined and node!=interactionReviewNode) do return false
        local value=(dotNetClass "System.Text.RegularExpressions.Regex").IsMatch (cyrusInteractionSourceInfo interactionReview) "\"can_prepare\"\\s*:\\s*true"
        value
    )
    fn interactionsProxy node = (
        if interactionProxySourceIDs.count!=interactionProxyNodes.count do throw "Collider source bindings are incomplete; restore the saved scene or repair its source links."
        local row=this.sourceRow node,slot=if row>0 then findItem interactionProxySourceIDs sourceRowIDs[row] else 0
        if slot>0 and slot<=interactionProxyNodes.count and isValidNode interactionProxyNodes[slot] then interactionProxyNodes[slot] else undefined
    )
    fn interactionsValidateProxy node proxy = (
        if not isValidNode proxy do throw "Pick a closed mesh, or cancel to keep the current collider."
        if this.sourceRow node<1 do throw "Choose the visual source model first."
        if node==proxy then cyrusInteractionSource node undefined #(0.005,0.05,1,this.interactionsLimits()) 2
        else cyrusInteractionColliderSource node proxy 3
        true
    )
    fn interactionsSetProxy node proxy = (
        this.interactionsValidateProxy node proxy
        if node==proxy do (
            interactionColliderMode=1;this.interactionsChanged();return true
        )
        local row=this.sourceRow node
        if row<1 do throw "Choose the visual source model first."
        local id=sourceRowIDs[row],slot=findItem interactionProxySourceIDs id
        if slot==0 then (if interactionProxySourceIDs.count>=512 do throw "Collider assignment budget: 512 source bindings.";append interactionProxySourceIDs id;append interactionProxyNodes proxy)
        else interactionProxyNodes[slot]=proxy
        -- Validate every source before switching the layer to custom mode. A
        -- partial assignment is saved without breaking its current collider.
        local complete=true
        for source in (this.validSources()) where this.interactionsProxy source==undefined do complete=false
        if complete do interactionColliderMode=3
        interactionDefinitionRevision+=1;this.interactionsChanged();true
    )
    fn interactionsValidateColliderMode mode = (
        if mode<1 or mode>3 do throw "Choose a collider shape."
        for node in (this.validSources()) do (
            if not isValidNode node do throw "Collider layers require mesh source models."
            if mode==3 and this.interactionsProxy node==undefined do throw ("Assign a custom collider for "+node.name+" first. The current shape is still active.")
            if mode==1 then cyrusInteractionSource node undefined #(0.005,0.05,1,this.interactionsLimits()) 2
            else cyrusInteractionColliderSource node (this.interactionsProxy node) mode
        )
        true
    )
    fn interactionsSetColliderMode mode = (
        this.interactionsValidateColliderMode mode
        interactionColliderMode=mode;this.interactionsClearGuides();true
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
        local value=this.interactionsColliderValue node
        this.interactionsClearGuides()
        undo off (local model=cyrusInteractionReviewModel value node.transform true;model.wirecolor=(color 60 240 90);model.isFrozen=true;model.showFrozenInGray=false;model.xray=true;setUserProp model "CyrusInteractionTransient" true;interactionGuides=#(model))
        interactionReview=undefined;interactionReviewApproved=false;interactionReviewNode=node;interactionReviewKind=#collider
        true
    )
    fn interactionsShowGuides node = (
        if not isValidNode node or findItem (this.validSources()) node==0 do throw "Choose a current source model."
        if interactionReview==undefined or interactionReviewNode!=node do (
            local row=this.sourceRow node,slot=findItem interactionSourceIDs sourceRowIDs[row]
            if slot==0 do throw "Analyze this source model first."
            interactionReview=cyrusInteractionSource node interactionDefinitions[slot] (this.interactionsSettings()) 1
            interactionReviewNode=node;interactionReviewApproved=true
        )
        local value=interactionReview,paths=cyrusInteractionGuides value
        this.interactionsClearGuides()
        -- Source-local preparation is reviewed at the original source. Hidden
        -- library sources get a transient display copy without visibility edits.
        undo off (
            if node.isHidden do (local model=cyrusInteractionReviewModel value node.transform;setUserProp model "CyrusInteractionTransient" true;append interactionGuides model)
            if paths.count>0 do (
                local shape=splineShape name:"Cyrus_Interaction_Source_Guides" wirecolor:(color 80 240 90)
                append interactionGuides shape
                for path in paths do (addNewSpline shape;for p in path do addKnot shape (numSplines shape) #corner #line p;updateShape shape)
                shape.transform=node.transform;shape.renderable=false;shape.isFrozen=true;shape.showFrozenInGray=false;setUserProp shape "CyrusInteractionTransient" true
            )
        )
        interactionReviewNode=node;interactionReviewKind=#guides;true
    )
    fn interactionsAnalyze node = (
        if not CyrusLicenseCanEdit() do throw "Active Cyrus authoring license required to prepare a model."
        if cyrusInteractionVersion==undefined or cyrusInteractionVersion()!=15 do throw "Load the revised matched CyrusScatter 0.87.6 native modules and restart Max."
        if not isValidNode node or findItem (this.validSources()) node==0 do throw "Choose a current mesh model in this layer."
        if interactionUnitsPending do this.interactionsRepairSettings()
        this.interactionsClearGuides()
        local next=cyrusInteractionSource node undefined (this.interactionsSettings()) 1
        interactionReview=next;interactionReviewNode=node;interactionReviewApproved=false
        this.interactionsShowGuides node
        format "Cyrus source analysis:\n%\n" (cyrusInteractionSourceInfo next)
        cyrusInteractionSourceInfo next
    )
    fn interactionsAccept = (
        if interactionReview==undefined or not isValidNode interactionReviewNode do throw "Analyze a model and inspect its roots and branch guides first."
        if not this.interactionsCanAccept() do throw "This source is not ready. Inspect its retained analysis report and repair unresolved guides/attachments before accepting."
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
            interactionReact=true;interactionCollider=false
        )
        interactionSourceCache=#();interactionReview=accepted;interactionReviewApproved=true;this.interactionsClearGuides();this.interactionsChanged();true
    )
    fn interactionsPrepare nodes rebuild:true enable:true = (
        if not CyrusLicenseCanEdit() do throw "Active Cyrus authoring license required to prepare a model."
        if nodes.count==0 do return true
        if interactionUnitsPending do this.interactionsRepairSettings()
        -- ParamBlock2 tabs expose ArrayParameter wrappers; collect values, not the block.
        local settings=this.interactionsSettings()
        local ids=for value in interactionSourceIDs collect value
        local definitions=for value in interactionDefinitions collect value
        local reviewNode=if interactionReviewKind==#guides then interactionReviewNode else undefined
        -- Capture/validate every successor before changing persistent definitions.
        -- Instances share these source-local definitions; no placement is rebuilt.
        for node in nodes do (
            if not isValidNode node or findItem (this.validSources()) node==0 do throw "Choose a current source model."
            local row=this.sourceRow node,id=sourceRowIDs[row],slot=findItem ids id
            local saved=if slot>0 then definitions[slot] else undefined
            local value=cyrusInteractionSource node saved settings 1 rebuild
            local accepted=cyrusInteractionAccept value
            local definition=cyrusInteractionSerialize accepted
            if slot==0 then (append ids id;append definitions definition) else definitions[slot]=definition
        )
        interactionSourceIDs=ids;interactionDefinitions=definitions;interactionDefinitionRevision+=1
        if enable do (interactionReact=true;interactionCollider=false)
        interactionSourceCache=#();interactionReview=undefined;interactionReviewApproved=false;this.interactionsClearGuides();this.interactionsChanged()
        if isValidNode reviewNode and findItem nodes reviewNode>0 do this.interactionsShowGuides reviewNode
        true
    )
    fn interactionsRefreshPreparation rebuild:false = (
        local prepared=for node in this.validSources() where isValidNode node and findItem interactionSourceIDs sourceRowIDs[this.sourceRow node]>0 collect node
        if prepared.count>0 then this.interactionsPrepare prepared rebuild:rebuild enable:false else (this.interactionsLimitsChanged();true)
    )
    fn interactionsSources plants role = (
        if role==0 do return #()
        local result=#(),flags=(if bit.get role 1 then 2 else 0)+(if bit.get role 2 then 1 else 0),settings=if role==2 then this.interactionsSettings() else undefined,nextCache=#()
        if interactionDefinitions.count!=interactionSourceIDs.count do throw "Prepared model data is incomplete. Analyze again."
        for node in plants do (
            if not isValidNode node do throw "Interactions require mesh models; Points and Empty sources are unsupported."
            local row=this.sourceRow node,slot=if row>0 then findItem interactionSourceIDs sourceRowIDs[row] else 0
            local saved=if bit.get role 2 then (if slot>0 then interactionDefinitions[slot] else throw ("Click Prepare model for "+node.name+" before enabling React to colliders.")) else undefined
            local value=if role==1 then this.interactionsColliderValue node else cyrusInteractionSource node saved settings flags
            append result value;append nextCache #(node,value)
        )
        interactionSourceCache=nextCache;result
    )
    fn interactionsKey owners epoch = (
        local stream=stringStream ""
        format "%|%|" epoch cyrusEnabled to:stream
        format "%|" (for node in interactionSceneColliders collect (if isValidNode node then getHandleByAnim node else 0)) to:stream
        for leaf in owners do (
            local parent=this.logicalParent leaf
            format "%:%:%:%:%:%:%:%:%:%:%:%:%|" leaf.layerID parent.interactionCollider parent.interactionReact parent.interactionCoverRoots parent.interactionGapWU parent.interactionStiffness parent.interactionColliderMode parent.interactionMinimumM parent.interactionFoliage parent.interactionDefinitionRevision leaf.autoRender (parent.interactionsLimits()) parent.interactionConnectionM to:stream
            format "%:%|" parent.interactionHideMarginWU parent.interactionHideArea to:stream
            format "%:%:%:%:%:%:%:%|" parent.interactionResponse parent.interactionBendStrength parent.interactionPruneAmount parent.interactionPruneThresholdWU parent.interactionNeighbors parent.interactionTrunkBend parent.interactionFixedBase parent.interactionBendTransition to:stream
        )
        stream as string
    )
    fn interactionsStage rows owners plants previous:undefined retargetEdits:false = (
        local active=false
        for leaf in owners do (local parent=this.logicalParent leaf;if parent.interactionCollider or parent.interactionReact do active=true)
        if not active and previous!=undefined and cyrusInteractionHasEdits!=undefined do active=cyrusInteractionHasEdits previous
        if not active or not cyrusEnabled do return undefined
        if cyrusInteractionVersion==undefined or cyrusInteractionVersion()!=15 do throw "CyrusScatter 0.87.6 requires its revised matched native interaction modules. Restart after installing."
        local payload=for i=1 to owners.count collect (
            local leaf=owners[i],parent=this.logicalParent leaf
            local role=(if parent.interactionCollider then 1 else 0)+(if parent.interactionReact then 2 else 0)
            -- React is an authored intent. Incomplete source preparation stays
            -- visibly pending; it cannot fail an unrelated layer publication.
            if role==2 and not (parent.interactionsReady plants[i]) do role=0
            if not this.enabledLayer (findItem layerObjects leaf) do role=0
            #(leaf.layerID,leaf.editLayerKey,rows[i],(parent.interactionsSources plants[i] role),role,parent.interactionCoverRoots,parent.interactionGapWU/(units.decodeValue "1m"),parent.interactionStiffness,leaf.autoRender,parent.interactionHideMarginWU/(units.decodeValue "1m"),parent.interactionHideArea,parent.interactionResponse,parent.interactionBendStrength,parent.interactionPruneAmount,parent.interactionPruneThresholdWU/(units.decodeValue "1m"),parent.interactionNeighbors,parent.interactionTrunkBend,parent.interactionFixedBase,parent.interactionBendTransition)
        )
        if CyrusSceneColliderWatch!=undefined do CyrusSceneColliderWatch()
        if retargetEdits then cyrusInteractionRestage (CyrusRecipeOwnerNode this) payload previous (this.interactionsSceneNodes()) else cyrusInteractionStageFrom (CyrusRecipeOwnerNode this) payload previous (this.interactionsSceneNodes())
    )
    fn interactionsMembershipPending = (
        if procPublishedOwners.count==0 do return false
        if procPublishedOwners.count!=layerObjects.count or procPublishedSources.count!=procPublishedOwners.count do return true
        for i=1 to procPublishedOwners.count do (
            local leaf=procPublishedOwners[i]
            if leaf!=layerObjects[i] do return true
            local authored=leaf.validSources(),published=procPublishedSources[i]
            if authored.count!=published.count do return true
            for k=1 to authored.count where authored[k]!=published[k] do return true
        )
        false
    )
    fn interactionsEnsure = (
        if procPublishedOwners.count==0 do return undefined
        if interactionState!=undefined and not (cyrusInteractionOwner interactionState (CyrusRecipeOwnerNode this)) do (interactionState=undefined;interactionStateKey="";interactionOutputNodes=#();interactionOutputKey="")
        -- A Manual source replacement is not an instruction to recapture old
        -- published rows through the new authored source definitions. Preserve
        -- the exact prior contacts until the explicit placement update stages
        -- sources, rows and roles together. Live uses the ordinary successor.
        if updateMode==1 and not groupSolving and this.interactionsMembershipPending() do return interactionState
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
        undo off for node in outputs do setUserProp node "CyrusInteractionTransient" true
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
        if updateMode==1 and this.interactionsMembershipPending() do return "Source changes are pending. Click Update scatter to use the current models; the previous complete contact result is retained."
        if interactionError!="" do return ("Previous contact result retained: "+interactionError)
        if interactionState==undefined then "Choose a layer role. Prepare reacting source models once; contact updates are automatic."
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
        -- Layer objects are reference targets, not scene nodes: the scene's
        -- save callback reaches the root only. Review helpers belong to leaves.
        if overlapOwner==undefined do for leaf in layerObjects where leaf!=undefined and leaf!=this do leaf.interactionsBeforeSave()
        undo off for node in interactionOutputNodes where isValidNode node do delete node
        interactionOutputNodes=#();interactionOutputKey="";true
    )
