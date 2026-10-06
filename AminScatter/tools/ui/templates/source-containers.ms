    -- Persistent source rows own artist settings. Containers only admit/park
    -- those rows; they never compact the registered list on boundary crossing.
    fn containerRoot = (if overlapOwner==undefined then this else overlapOwner)
    fn containerProvider = (
        if not this.proceduralPolicy() or containerMode==1 do return undefined
        local root=this.containerRoot()
        case containerMode of (
            2:(if overlapOwner==undefined or logicalParentID=="" then root else (root.logicalParent this).containerProvider())
            3: root
            4: this
            default:(throw "Unknown source-container mode.")
        )
    )
    fn effectiveContainers = (
        local provider=this.containerProvider()
        if provider==undefined then #() else if provider==this.containerRoot() then provider.containerGlobalNodes as array else provider.containerNodes as array
    )
    fn containerSourceKey plants = (
        if this.containerProvider()==undefined then plants else (for n in plants collect (if classof n==Integer then n else if isValidNode n then getHandleByAnim n else 0))
    )
    fn containerFrames = (
        local result=#(),nodes=this.effectiveContainers()
        if nodes.count>32 do throw "A source pool supports at most 32 rectangles."
        for n in nodes where isValidNode n do (
            if classof n.baseObject!=Rectangle or n.modifiers.count>0 do throw "Source containers require ordinary Rectangle splines without modifiers."
            local tm=n.objectTransform,volume=(length tm.row1)*(length tm.row2)*(length tm.row3)
            if volume<=0 or abs(dot tm.row1 (cross tm.row2 tm.row3))<=volume*1e-8 do throw "A source container has a singular transform. Restore its scale."
            if n.width<=0 or n.length<=0 do throw "Source container dimensions must be positive."
            if isProperty n #cornerRadius and n.cornerRadius!=0 do throw "Source containers require square rectangle corners."
            append result #((inverse tm),n.width/2,n.length/2)
        )
        result
    )
    fn containerContains node frames = (
        if not isValidNode node do return false
        local pivot=node.transform.row4
        for frame in frames do (
            local p=pivot*frame[1],epsilon=(amax 1e-4 ((amax frame[2] frame[3])*1e-6))
            if abs p.x<=frame[2]+epsilon and abs p.y<=frame[3]+epsilon do return true
        )
        false
    )
    fn containerEligible node excluded = (
        if not isValidNode node or superclassof node!=GeometryClass or isGroupHead node do return false
        if not this.usableSource node or classof node.baseObject==CyrusPointDisplay do return false
        if getUserProp node "CyrusPFTransient"==true do return false
        if findItem excluded node>0 do return false
        canConvertTo node Editable_Mesh
    )
    fn containerRegister node = (
        if findItem sources node>0 do return false
        if sources.count>=1024 do throw "Source registration is full (1,024 rows). Remove unused rows explicitly."
        -- Fill optional tabs before appending so a new source cannot inherit
        -- a prior row's sparse setting. Automatic registration survives parking.
        undo off (
            syncColors()
            for spec in #(#(#sourceWeights,1.0),#(#sourceZOffsets,0.0),#(#sourceScales,1.0),#(#sourceForwardAxes,1),#(#sourceRadii,0.0),#(#sourceFollowScale,false),#(#sourceShowRadius,false),#(#sourcePoint,false),#(#sourceEmpty,false)) do (
                local values=getProperty this spec[1]
                while values.count<sources.count do append values spec[2]
                append values spec[2]
            )
            append sources node;append sourceColors (this.sourceColor sources.count)
        )
        dirty=true;true
    )
    fn containerRefresh = (
        if containerReconciling do return false
        if this.containerProvider()==undefined do (containerActive=#();containerMembershipKey="manual";return false)
        containerReconciling=true
        try (
            local nodes=this.effectiveContainers(),changed=false
            local state=for n in nodes collect (
                if isValidNode n then (
                    if classof n.baseObject!=Rectangle do throw "Source containers require ordinary Rectangle splines."
                    #(n,n.objectTransform,n.width,n.length,n.modifiers.count,if isProperty n #cornerRadius then n.cornerRadius else 0)
                ) else #(undefined)
            )
            local configurationChanged=containerConfigKey=="" or state.count!=containerFrameState.count
            if not configurationChanged do for i=1 to state.count while not configurationChanged do (
                if state[i].count!=containerFrameState[i].count then configurationChanged=true
                else for j=1 to state[i].count where state[i][j]!=containerFrameState[i][j] do configurationChanged=true
            )
            if configurationChanged do (containerScan=true;containerCachedFrames=this.containerFrames())
            local frames=containerCachedFrames
            local candidates=if containerScan then (geometry as array) else containerPending as array
            if containerScan do containerScans+=1
            local excluded=#()
            if candidates.count>0 do for controller in objects where classof controller.baseObject==AminScatterObject do (
                join excluded (controller.baseObject.validSurfaces())
                for leaf in controller.baseObject.layerObjects do join excluded (leaf.bakedNodes as array)
            )
            for node in candidates where findItem sources node==0 do (
                containerTests+=1
                if this.containerContains node frames and this.containerEligible node excluded do changed=(this.containerRegister node) or changed
            )
            local membershipChanged=configurationChanged or sources.count!=containerTrackedSources.count or sources.count!=containerActive.count
            if not membershipChanged do for i=1 to sources.count while not membershipChanged do (
                local node=sources[i],pivot=if isValidNode node then node.transform.row4 else undefined
                if node!=containerTrackedSources[i] or pivot!=containerTrackedPivots[i] do membershipChanged=true
            )
            if membershipChanged do (
                containerActive=for node in sources collect (this.containerContains node frames)
                containerTrackedSources=sources as array
                containerTrackedPivots=for node in sources collect (if isValidNode node then node.transform.row4 else undefined)
                containerMembershipBuilds+=1
            )
            containerConfigKey="ready";containerFrameState=state;containerPending=#();containerScan=false
            local membership=stringStream ""
            with printAllElements on format "%" containerActive to:membership
            local nextMembership=membership as string
            if nextMembership!=containerMembershipKey or changed do containerUIChanged=true
            containerMembershipKey=nextMembership
            containerReconciling=false;changed
        )catch(containerReconciling=false;throw())
    )
    fn containerFilter rows plants = (
        if this.containerProvider()==undefined do return rows
        if plants.count==0 do return #()
        local keep=for node in plants collect (
            local i=this.sourceRow node
            i>0 and i<=containerActive.count and containerActive[i]
        )
        this.filterSourceRowsByPolicy rows keep
    )
    fn containerNote event nodes = (
        if groupPolicy!=3 do return false
        local interested=false
        for leaf in layerObjects where leaf.containerProvider()!=undefined do (
            -- Deletion payloads may no longer resolve to nodes. Keep the
            -- existing conservative reconciliation for genuine deletions; the
            -- dispatcher already filters our known deleted helper handles.
            local relevant=event==#deleted,frames=undefined,rectangles=leaf.effectiveContainers()
            if relevant do leaf.containerScan=true
            for rectangle in rectangles where isValidNode rectangle do (
                local parent=rectangle
                while isValidNode parent and not relevant do (
                    if findItem nodes parent>0 do relevant=true
                    parent=parent.parent
                )
            )
            -- A moved parent may carry previously unregistered children into a
            -- rectangle. Traverse only this changed subtree, never every frame.
            -- Keep callback work bounded. A large changed subtree requests one
            -- conservative scan during normal reconciliation, not in this hook.
            -- A new array also avoids appending children to the caller's batch.
            local pending=(for i=1 to (amin nodes.count 512) collect nodes[i]),index=1
            if nodes.count>512 do (leaf.containerScan=true;relevant=true)
            while index<=pending.count do (
                local node=pending[index];index+=1
                if isValidNode node do (
                    local generated=classof node.baseObject==AminScatterObject or classof node.baseObject==CyrusPointDisplay or getUserProp node "CyrusPFTransient"==true
                    if not generated do (
                        if findItem leaf.sources node>0 then relevant=true
                        else if superclassof node==GeometryClass and not isGroupHead node do (
                            -- An unrelated helper or a model outside the pool
                            -- must not mark every container-backed layer dirty.
                            try (
                                if frames==undefined do frames=leaf.containerFrames()
                                if leaf.containerContains node frames do (appendIfUnique leaf.containerPending node;relevant=true)
                            )catch(relevant=true)
                        )
                    )
                    for child in node.children while pending.count<512 do appendIfUnique pending child
                    if pending.count>=512 do (leaf.containerScan=true;relevant=true)
                )
            )
            if relevant do (leaf.dirty=true;interested=true)
            CyrusDiagnosticEmit "container.notification" "host_callback" leaf.layerID leaf.procEpoch (if relevant then "reconcile_needed" else "unrelated")
        )
        interested
    )
    fn procExternalChanged event nodes = (
        local inputs=this.validSurfaces(),affected=false
        local staging=this.containerProvider()!=undefined and findItem #(#controllerOtherEvent,#controllerStructured,#linkChanged) event>0
        if not staging do join inputs (sources as array)
        join inputs (areaNodes as array);join inputs (patternLines as array)
        join inputs #(analyzerNode,areaAnalyzer,fallAnalyzer)
        for input in inputs where isValidNode input do (
            local dep=input
            while isValidNode dep and not affected do (
                if findItem nodes dep>0 do affected=true
                dep=dep.parent
            )
        )
        if event==#deleted do affected=true
        if affected do (procGeometryRevision+=1;dirty=true)
        CyrusDiagnosticEmit "input.classified" "host_callback" layerID procEpoch (if affected then "geometry_dependency" else "unrelated")
        affected
    )
    fn containerSetMode mode = (
        if not this.proceduralPolicy() do throw "Enable Procedural 0.7 to use source containers."
        if mode<1 or mode>4 do throw "Unknown source-container mode."
        undo "Cyrus source pool" on containerMode=mode
        containerScan=true;containerConfigKey="";dirty=true
        local root=this.containerRoot();root.invalidateGroups();root.bindNativeUI()
    )
    fn containerAdd node globalPool:false = (
        if not isValidNode node or classof node.baseObject!=Rectangle do throw "Pick an ordinary Rectangle spline."
        local target=if globalPool then this.containerRoot() else this,key=if globalPool then #containerGlobalNodes else #containerNodes
        local nodes=(getProperty target key) as array
        if findItem nodes node==0 do (
            if nodes.count>=32 do throw "A source pool supports at most 32 rectangles."
            undo "Cyrus add source container" on (append nodes node;setProperty target key nodes)
        )
        local root=this.containerRoot();root.invalidateGroups();root.bindNativeUI();true
    )
    fn containerRemove index globalPool:false = (
        local target=if globalPool then this.containerRoot() else this,key=if globalPool then #containerGlobalNodes else #containerNodes
        local nodes=(getProperty target key) as array
        if index>0 and index<=nodes.count do undo "Cyrus remove source container" on (deleteItem nodes index;setProperty target key nodes)
        local root=this.containerRoot();root.invalidateGroups();root.bindNativeUI()
    )
    fn containerCreate globalPool:false = (
        local root=this.containerRoot(),label=if globalPool then "Global sources" else root.layerCaption (root.logicalParent this),node
        undo "Cyrus create source container" on (
            node=rectangle name:(uniqueName ("CS Sources - "+label+" ")) width:500 length:300
            local receivers=root.validSurfaces()
            if receivers.count>0 do (local bounds=nodeGetBoundingBox receivers[1] (matrix3 1);node.pos=[bounds[2].x+350,bounds[1].y,0])
            node.wirecolor=color 80 180 240
            this.containerAdd node globalPool:globalPool
        )
        node
    )
