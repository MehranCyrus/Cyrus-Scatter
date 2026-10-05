    -- Policy 3 owns its persisted recipe. Old policies are deliberately unchanged.
    parameters proceduralSettings (
        procOrder type:#integer default:0
        procSetOrder type:#integer default:0
        procSamplingSalt type:#integer default:0
        procPopulation type:#integer default:1
        procAttemptFactor type:#integer default:8
        procRounds type:#integer default:8
        procRepair type:#boolean default:true
        procSelfOverride type:#boolean default:false
        procSelfEnabled type:#boolean default:true
        procSelfMultiplier type:#float default:1.0
        procSelfGap type:#worldUnits default:0.0
        procSelfPlanar type:#boolean default:false
        procSiblingEnabled type:#boolean default:false
        procSiblingMultiplier type:#float default:1.0
        procSiblingGap type:#worldUnits default:0.0
        procSiblingPlanar type:#boolean default:false
        procBackground type:#integer default:1
        procBackgroundIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procRadiusIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procRadiusModes type:#intTab tabSize:0 tabSizeVariable:true
        procRadiusValues type:#floatTab tabSize:0 tabSizeVariable:true
        procRadiusBinding type:#string default:""
        procSourceNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        procSourceIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procSourceSlots type:#stringTab tabSize:0 tabSizeVariable:true
        procReceiverNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        procReceiverIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procReceiverID type:#string default:""
        procRuleScope type:#intTab tabSize:0 tabSizeVariable:true
        procRuleA type:#stringTab tabSize:0 tabSizeVariable:true
        procRuleB type:#stringTab tabSize:0 tabSizeVariable:true
        procRuleEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        procRuleMultiplier type:#floatTab tabSize:0 tabSizeVariable:true
        procRuleGap type:#floatTab tabSize:0 tabSizeVariable:true
        procRulePlanar type:#boolTab tabSize:0 tabSizeVariable:true
        containerMode type:#integer default:1
        containerNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        containerGlobalNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
    )
    local procCandidateCount=undefined,procPreparedKey="",procPreparedRows=#(),procBindingKey="",procBoundBase=undefined,procSurfaceKey=""
    local procLastStats=#(),procLastRounds=#(),procPreparedBuilds=0,procPreparedHits=0,procEpoch=0,procPublishedDisplayKey="",procManualRevision=0
    local procPublishedOwners=#(),procPublishedSources=#(),procPublishedFinalKeep=#()
    local procDensityMap=undefined,procDensityWatch=undefined,procDensityRevision=0
    local procGeometryRevision=0,containerConfigKey="",containerPending=#(),containerScan=true,containerScans=0,containerTests=0
    local containerMembershipKey="",containerActive=#(),containerReconciling=false
    local containerTrackedSources=#(),containerTrackedPivots=#(),containerCachedFrames=#(),containerFrameState=#(),containerMembershipBuilds=0
    local containerUIChanged=false
    fn proceduralPolicy = (if overlapOwner==undefined then groupPolicy==3 else overlapOwner.groupPolicy==3)
    fn procWatchDensity = (
        global CyrusDensityMapChanged
        if procDensityMap!=densityMap do (
            if procDensityWatch!=undefined do deleteChangeHandler procDensityWatch
            procDensityWatch=undefined;procDensityMap=densityMap;procDensityRevision+=1
            if densityMap!=undefined do procDensityWatch=when parameters densityMap changes id:#CyrusDensityMap affected do (CyrusDensityMapChanged affected)
        )
        procDensityRevision
    )
    fn procReadSnapshot = (
        -- A reopened scene has no transient publication and reconstructs once.
        -- After that, only Live or explicit Update may publish pending settings.
        if updateMode==2 or groupSnapshotKey=="" do this.evaluateProcedural()
        groupSnapshotRows
    )
    fn outputSources = (
        if not this.proceduralPolicy() or overlapOwner==undefined do return this.validSources()
        local root=overlapOwner
        root.procReadSnapshot()
        local i=findItem root.procPublishedOwners this
        if i==0 do return #()
        local plants=root.procPublishedSources[i]
        for n in plants where classof n!=Integer do if not isValidNode n do throw "A published source was deleted. Restore it or Update before exact output."
        plants
    )
    fn procStatistics = (#(procLastStats as array,procLastRounds as array,procPreparedBuilds,procPreparedHits,procEpoch))
    fn procSort members sets:false = (
        local result=members as array
        for i=2 to result.count do (
            local chosen=result[i],j=i-1,key=if sets then chosen.procSetOrder else chosen.procOrder
            while j>0 and (if sets then result[j].procSetOrder else result[j].procOrder)>key do (result[j+1]=result[j];j-=1)
            result[j+1]=chosen
        )
        result
    )
    fn procMove item delta sets:false = (
        if groupPolicy!=3 do throw "Enable Procedural 0.7 before changing evaluation order."
        local members=if sets then this.layerSets (this.logicalParent item) else this.logicalLayers()
        local i=findItem members item,j=i+delta
        if i==0 or j<1 or j>members.count do return false
        -- Reject a reordering which would turn a background reference forward.
        members[i]=members[j];members[j]=item
        if sets do for k=1 to members.count do for id in members[k].procBackgroundIDs do (
            local found=0
            for p=1 to k-1 where members[p].layerID==id do found=p
            if found==0 do throw "Move would place a background reference after its consumer. Change the reference first."
        )
        undo "Cyrus evaluation order" on for k=1 to members.count do setProperty members[k] (if sets then #procSetOrder else #procOrder) k
        this.invalidateGroups();this.bindNativeUI();true
    )
    fn procModifiers = (
        local result=#()
        for node in refs.dependentNodes this where node.baseObject==this do for m in node.modifiers where classof m==CyrusScatterEdit do appendIfUnique result m
        result
    )
    fn procEditKey = (
        local text="ProceduralEdit1"
        for m in this.procModifiers() do text+="|"+(getHandleByAnim m as string)+":"+(m.enabled as string)+":"+(cyrusEditLocalRevision m as string)
        text
    )
    fn procSyncEditVisibility = (
        if groupPolicy!=3 do return false
        for m in this.procModifiers() do (
            cyrusEditActiveLayers m (for i=1 to layerObjects.count where cyrusEnabled and this.enabledLayer i collect layerObjects[i].editLayerKey)
            for i=1 to layerObjects.count do cyrusEditGroupVisibility m layerObjects[i].editLayerKey (cyrusEnabled and this.visibleLayer i)
        )
        true
    )
    fn procEnsureSources = (
        -- Keep correspondence history so replacing a node and Undo can recover
        -- its original binding. This metadata never becomes an artist Undo step.
        undo off (
            local ids=#()
            for i=1 to sources.count do (
                local node=sources[i]
                if isValidNode node then (
                    local index=findItem procSourceNodes node
                    if index==0 do (
                        if procSourceNodes.count>=1024 do throw "Source identity history is full. Create a new setup before enrolling more assets."
                        append procSourceNodes node;append procSourceIDs (CyrusNewLayerID());index=procSourceNodes.count
                    )
                    append ids procSourceIDs[index]
                ) else append ids ("placeholder:"+(i as string))
            )
            local same=procSourceSlots.count==ids.count
            if same do for i=1 to ids.count where ids[i]!=procSourceSlots[i] do same=false
            if not same do procSourceSlots=ids
            local receiverKey=""
            for node in this.validSurfaces() do (
                local index=findItem procReceiverNodes node
                if index==0 do (
                    if procReceiverNodes.count>=128 do throw "Receiver identity history is full. Create a new setup before enrolling more surfaces."
                    append procReceiverNodes node;append procReceiverIDs (CyrusNewLayerID());index=procReceiverNodes.count
                )
                receiverKey+=procReceiverIDs[index]+"|"
            )
            if procReceiverID!=receiverKey do procReceiverID=receiverKey
        )
    )
    fn procPair scope a b = (
        for i=1 to procRuleA.count where procRuleScope[i]==scope and ((procRuleA[i]==a.layerID and procRuleB[i]==b.layerID) or (procRuleA[i]==b.layerID and procRuleB[i]==a.layerID)) do return i
        0
    )
    fn procSetPair scope a b enabled multiplier gap planar = (
        if scope!=1 and scope!=2 do throw "Unknown spacing scope."
        if a==b or findItem layerObjects a==0 or findItem layerObjects b==0 do throw "Choose two existing owners."
        if scope==1 and (this.logicalParent a)!=(this.logicalParent b) do throw "Paint-set rules require siblings."
        if scope==2 and (a.logicalParentID!="" or b.logicalParentID!="") do throw "Layer rules require logical layers."
        if multiplier<0 or gap<0 do throw "Spacing values must be nonnegative."
        undo "Cyrus scoped spacing" on (
            local i=this.procPair scope a b
            if i==0 do (
                append procRuleScope scope;append procRuleA a.layerID;append procRuleB b.layerID
                append procRuleEnabled false;append procRuleMultiplier 1.0;append procRuleGap 0.0;append procRulePlanar false;i=procRuleA.count
            )
            procRuleEnabled[i]=enabled;procRuleMultiplier[i]=multiplier;procRuleGap[i]=gap;procRulePlanar[i]=planar
        )
        this.invalidateGroups()
    )
    fn procRemoveRule i = (
        if i>0 do for key in #(#procRuleScope,#procRuleA,#procRuleB,#procRuleEnabled,#procRuleMultiplier,#procRuleGap,#procRulePlanar) do deleteItem (getProperty this key) i
    )
    fn procRemoveOwner leaf = (
        for i=procRuleA.count to 1 by -1 where procRuleA[i]==leaf.layerID or procRuleB[i]==leaf.layerID do this.procRemoveRule i
        for member in layerObjects do member.procBackgroundIDs=for id in member.procBackgroundIDs where id!=leaf.layerID collect id
    )
    fn procCopyRelations originals copies = (
        -- Remap references inside the copy; preserve external layer rules.
        (
            for s=1 to copies.count do (
                local leaf=copies[s]
                leaf.procRadiusIDs=#();leaf.procRadiusModes=#();leaf.procRadiusValues=#();leaf.procRadiusBinding=""
                leaf.procBackgroundIDs=for id in originals[s].procBackgroundIDs collect (
                    local replacement=id
                    for j=1 to originals.count where originals[j].layerID==id do replacement=copies[j].layerID
                    replacement
                )
            )
            local count=procRuleA.count
            for i=1 to count do (
                local a=undefined,b=undefined,changed=false
                for j=1 to originals.count do (
                    if procRuleA[i]==originals[j].layerID do (a=copies[j];changed=true)
                    if procRuleB[i]==originals[j].layerID do (b=copies[j];changed=true)
                )
                if changed do (
                    if a==undefined do for leaf in layerObjects where leaf.layerID==procRuleA[i] do a=leaf
                    if b==undefined do for leaf in layerObjects where leaf.layerID==procRuleB[i] do b=leaf
                    if a!=undefined and b!=undefined do this.procSetPair procRuleScope[i] a b procRuleEnabled[i] procRuleMultiplier[i] procRuleGap[i] procRulePlanar[i]
                )
            )
            if copies.count>0 do copies[1].procOrder=nextEditLayerKey
        )
    )
    fn procSelfRule = (
        if procSelfOverride then #(procSelfEnabled,procSelfMultiplier,procSelfGap,procSelfPlanar)
        else #(collisionEnabled,0.0,2*collisionRadius,false)
    )
    fn procRadii rows plants = (
        if rows.count==0 do return #()
        if procRadiusIDs.count>0 and procRadiusBinding!=procBindingKey do throw "Instance radius overrides belong to a different generation binding. Restore the recipe or explicitly clear this set's overrides."
        local radii=if plants.count==0 then #(0.0) else for n in plants collect sourceRadius (sourceRow n)
        local follow=if plants.count==0 then #(false) else for n in plants collect sourceFollows (sourceRow n)
        cyrusProceduralRadii rows radii follow (procRadiusIDs as array) (procRadiusModes as array) (procRadiusValues as array)
    )
    fn procSelectedRadius mode value reset:false = (
        if overlapOwner==undefined or not this.proceduralPolicy() do throw "Select a paint set using Procedural 0.7."
        if mode<1 or mode>2 or value<0 do throw "Invalid instance radius."
        if not reset and (procBindingKey=="" or (procRadiusIDs.count>0 and procRadiusBinding!=procBindingKey)) do throw "Update a valid binding or clear old radius overrides before assigning new ones."
        local ids=cyrusEditSelectedIDs (overlapOwner.procModifiers()) editLayerKey
        if ids.count==0 do throw "Select plant instances in CS Edit first."
        undo "Cyrus selected instance radii" on (
        for id in ids do (
            local i=findItem procRadiusIDs id
            if reset then (if i>0 do (deleteItem procRadiusIDs i;deleteItem procRadiusModes i;deleteItem procRadiusValues i))
            else (
                if i==0 do (append procRadiusIDs id;append procRadiusModes mode;append procRadiusValues value;i=procRadiusIDs.count)
                procRadiusModes[i]=mode;procRadiusValues[i]=value
            )
        )
        procRadiusBinding=if procRadiusIDs.count>0 then procBindingKey else ""
        )
        overlapOwner.invalidateGroups()
    )
    fn procClearRadii = (
        undo "Cyrus clear set radius overrides" on (procRadiusIDs=#();procRadiusModes=#();procRadiusValues=#();procRadiusBinding="")
        if overlapOwner!=undefined do overlapOwner.invalidateGroups()
    )
    fn procBackgroundMembers = (
        if overlapOwner==undefined do return #()
        local members=overlapOwner.layerSets (overlapOwner.logicalParent this),before=#(),found=false
        for member in members while member!=this do append before member
        for id in procBackgroundIDs do if (for member in before where member.layerID==id collect member).count!=1 do throw "Background must reference earlier paint sets in the same layer."
        for member in before where findItem procBackgroundIDs member.layerID>0 and overlapOwner.enabledLayer (findItem overlapOwner.layerObjects member) collect member
    )
    fn procCoverageKey = (
        local stream=stringStream ""
        format "%:%:%:%:%|" (this.paintKey()) paintEnabled paintDensity procBackground procBackgroundIDs to:stream
        if procBackground!=1 do for member in this.procBackgroundMembers() do format "%:%:%|" member.layerID member.paintEnabled (member.paintKey()) to:stream
        stream as string
    )
    fn procApplyPaint rows = (
        local sampling="CyrusStableMask1:"+(this.effectiveSeed() as string)
        local outside=procBackground==2 or procBackground==4,refs=if outside then this.procBackgroundMembers() else #()
        if outside and refs.count>0 then (
            local targets=this.validSurfaces()
            if targets.count!=1 do throw "Outside coverage requires one shared receiver."
            local docs=#(if paintEnabled then paintDocument else undefined)
            for member in refs do append docs (if member.paintEnabled then member.paintDocument else undefined)
            cyrusBrushCompositeFilter rows docs (if paintEnabled then paintDensity else 1.0) sampling targets[1]
        ) else if this.brushMaskActive() then cyrusBrushFilter paintDocument rows sampling paintDensity else cyrusClonePlacementRows rows
    )
    fn procBinding plants rows = (
        if distributionMode==3 or procBoundBase!=paintBaseRows or procSurfaceKey=="" do (
            procSurfaceKey=cyrusProceduralSurfaceKey (this.validSurfaces());procBoundBase=paintBaseRows
        )
        local stream=stringStream ""
        with printAllElements on (
            format "CyrusBinding1:%:%:%|" procReceiverID procSurfaceKey (this.effectiveSeed()) to:stream
            for n in plants do (local i=sourceRow n;format "%|" (if i>0 and i<=procSourceSlots.count then procSourceSlots[i] else "preview") to:stream)
            for key in #(#distributionMode,#clusterCount,#clusterRadius,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#sourceWeights,#sourceColors,#sourceEmpty,#sourcePoint,#sourceScales,#sourceZOffsets,#advancedAxes,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#wholeScaleMin,#wholeScaleMax,#projectMove,#alignNormal) do format "%:%|" key (getProperty this key) to:stream
        )
        stream as string
    )
    fn procUpgrade = (
        if groupPolicy==3 do return false
        if (this.procModifiers()).count>0 do throw "Preserve existing CS Edit bindings. Duplicate this setup and remove CS Edit from that copy before switching evaluation policy."
        for leaf in layerObjects where leaf.diversityMode>=3 do throw "Line Pattern / Analyzer assignment stays on the existing policy. Random and Clusters support Procedural 0.7."
        undo "Cyrus Procedural 0.7 policy" on (
            if groupPolicy==1 do this.groupConversion()
            this.syncLayerIdentity()
            local parents=this.logicalLayers()
            for l=1 to parents.count do (
                local parent=parents[l],members=this.layerSets parent
                parent.procOrder=l;parent.procSiblingEnabled=parent.collisionEnabled
                parent.procSiblingMultiplier=0;parent.procSiblingGap=2*parent.collisionRadius
                for s=1 to members.count do (
                    members[s].procSetOrder=s;members[s].procSamplingSalt=if members[s]==parent then 0 else members[s].editLayerKey
                    members[s].paintIdentity=true;members[s].procEnsureSources()
                )
            )
            for i=1 to groupRuleA.count do (
                local a=undefined,b=undefined
                for leaf in parents do (if leaf.layerID==groupRuleA[i] do a=leaf;if leaf.layerID==groupRuleB[i] do b=leaf)
                if a!=undefined and b!=undefined do this.procSetPair 2 a b groupRuleEnabled[i] (if groupRuleFootprints[i] then 1.0 else 0.0) groupRuleGap[i] groupRulePlanar[i]
            )
            groupPolicy=3
        )
        this.invalidateGroups();this.bindNativeUI();true
    )
