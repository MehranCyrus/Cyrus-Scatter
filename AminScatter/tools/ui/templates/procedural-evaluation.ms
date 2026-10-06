    fn procInputKey = (
        local stream=stringStream ""
        with printAllElements on (
            format "Proc1:%:%:%:%:%:%:%:%|" currentTime 0 procManualRevision cyrusEnabled layerEnabled (this.procEditKey()) procRuleScope procRuleA to:stream
            format "%:%:%:%:%|" procRuleB procRuleEnabled procRuleMultiplier procRuleGap procRulePlanar to:stream
            for parent in this.logicalLayers() do for leaf in this.layerSets parent do (
                leaf.containerRefresh()
                format "Membership:%|" leaf.containerMembershipKey to:stream
                format "Texture:%|" (leaf.procWatchDensity()) to:stream
                format "%:%:%:%:%:%|" leaf.layerID leaf.logicalParentID leaf.procReceiverID leaf.procRadiusBinding (leaf.paintBaseInputKey (leaf.validSources()) true) (leaf.procCoverageKey()) to:stream
                for key in #(#procOrder,#procSetOrder,#procSamplingSalt,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procSourceIDs,#collisionEnabled,#collisionRadius,#sourceRadii,#sourceFollowScale,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#overlapPlanar) do format "%:%|" key (getProperty leaf key) to:stream
            )
        )
        stream as string
    )
    fn procQuota = (
        local parent=overlapOwner.logicalParent this,budget=parent.amount
        if parent.populationMode==2 do (
            local meters=units.decodeValue "1m",wanted=(aminScatterSurfaceArea (this.validSurfaces()))/(meters*meters)*parent.plantsPerM2
            densityCapped=wanted>100000;budget=(amin 100000 (floor(wanted+0.5))) as integer
        )
        (overlapOwner.populationAllocation this countOverride:budget)[1]
    )
    fn procPrepare pool plants = (
        if paintEnabled and paintDocument!=undefined do (
            local targets=this.validSurfaces()
            if targets.count!=1 or (cyrusBrushTarget paintDocument)!=targets[1] do throw "Paint target differs from the shared receiver. Saved strokes are preserved."
        )
        local key=(this.paintBaseInputKey plants true)+"|Texture:"+(this.procWatchDensity() as string)+"|Pool:"+(pool as string)+"|"+(this.procCoverageKey())+"|"+(overlapOwner.procEditKey())
        if key==procPreparedKey do (procPreparedHits+=1;return procPreparedRows)
        local rows
        procCandidateCount=pool
        try(rows=this.cspImpl_placements plants previewOnly:true rawOnly:true)catch(procCandidateCount=undefined;throw())
        procCandidateCount=undefined
        procBindingKey=this.procBinding plants rows
        rows=CyrusEditApplyLayer overlapOwner this rows
        procPreparedRows=rows;procPreparedKey=key;procPreparedBuilds+=1
        rows
    )
    fn procValidate = (
        if cyrusEvaluateProcedural==undefined or cyrusEditTransaction==undefined or cyrusProceduralPublicationVersion==undefined do throw "Procedural 0.7.1 requires the matching native plugin binaries. Restart the private test host with the complete matching script/native pair."
        if layerObjects.count>10 do throw "Procedural policy supports ten total populations."
        for parent in this.logicalLayers() do (
            if parent.procPopulation<1 or parent.procPopulation>2 or parent.procAttemptFactor<1 or parent.procAttemptFactor>32 or parent.procRounds<1 or parent.procRounds>16 do throw "Invalid procedural work limits."
            for leaf in this.layerSets parent where this.enabledLayer (findItem layerObjects leaf) do (
                if leaf.diversityMode>=3 do throw "Line Pattern / Analyzer assignment is not supported by Procedural 0.7. Keep that setup on its existing policy."
                if leaf.procBackground<1 or leaf.procBackground>4 do throw "Unknown background mode."
                if leaf.procBackground!=1 do leaf.procBackgroundMembers()
                if leaf.procBackground==3 or leaf.procBackground==4 do for member in leaf.procBackgroundMembers() do (
                    local pair=this.procPair 1 leaf member
                    local enabled=if pair>0 then procRuleEnabled[pair] else parent.procSiblingEnabled
                    local multiplier=if pair>0 then procRuleMultiplier[pair] else parent.procSiblingMultiplier
                    local gap=if pair>0 then procRuleGap[pair] else parent.procSiblingGap
                    if not enabled or (multiplier<=0 and gap<=0) do throw "Between plants requires a nonzero applicable set-pair spacing rule. Configure the rule before updating."
                )
                if leaf.procBackground==2 or leaf.procBackground==4 do (
                    if not leaf.projectMove and (leaf.movementRange!=0 or leaf.movXMin!=0 or leaf.movXMax!=0 or leaf.movYMin!=0 or leaf.movYMax!=0 or leaf.movZMin!=0 or leaf.movZMax!=0) do throw "Outside coverage needs projected movement."
                    for member in leaf.procBackgroundMembers() where member.paintEnabled and member.paintDocument==undefined do throw "A referenced painted set has no coverage document."
                )
                if parent.procPopulation==2 do for source in leaf.validSources() do (
                    local index=leaf.sourceRow source
                    if leaf.isEmptySource index and not leaf.isPointSource index and leaf.sourceWeight index>0 do throw "Accepted target does not refill weighted Empty assets. Use candidate budget, Point placeholders, or remove the Empty weight."
                )
            )
        )
        true
    )
    fn procDisplayInputKey epoch:undefined = (
        local stream=stringStream ""
        with printAllElements on (
            format "Display:%|" (if epoch==undefined then procEpoch else epoch) to:stream
            for leaf in layerObjects do for key in #(#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#previewBudget,#showCenters,#pointsPerPlant,#pointColorMode,#solidPointColor,#sourceShowRadius,#radiusDisplayLimit,#radiusDisplayAll) do format "%:%|" key (getProperty leaf key) to:stream
        )
        stream as string
    )
    fn procStagePreview data = (
        local start=timeStamp(),plants=this.validSources(),previousRadius=radiusPreview,radii
        try(cacheRadii data plants;radii=radiusPreview;radiusPreview=previousRadius)catch(radiusPreview=previousRadius;throw())
        local samples=if viewportMode!=1 then #() else if showCenters then (for i=1 to (amax 1 plants.count) collect #([0,0,0])) else (for n in plants collect (if classof n==Integer then (for p=1 to pointsPerPlant collect [0,0,0]) else pointSourceSamples n))
        local colors=if plants.count==0 then #(solidPointColor) else for n in plants collect sourceColor (sourceRow n)
        local cache=if data.count==0 then aminScatterBuildPreview #() #() #() 1 else if viewportMode==1 then aminScatterBuildPreview data samples colors (if showCenters then 500000 else previewBudget) else cyrusBuildGeometryPreview data (if plants.count==0 then #(-1) else plants) colors (if viewportMode==2 then proxyShape else 4) viewportInstances viewportFaces
        #(cache,(aminScatterPreviewCount cache),data.count,radii,(if viewportMode==1 and showCenters then 4 else viewportMode),timeStamp()-start,(if isValidNode areaAnalyzer then areaAnalyzer.getAnalysisRuns() else -1),(if isValidNode fallAnalyzer then fallAnalyzer.getAnalysisRuns() else -1))
    )
    fn procInstallPreview state pending = (
        cachedPoints=state[1];cachedPointCount=state[2];generatedCount=state[3];radiusPreview=state[4];uiPreviewMode=state[5]
        previewBuildMs=state[6];cachedAreaAnalyzerRun=state[7];cachedFallRun=state[8];cachedAnalyzerRun=-1
        previewBuildCount+=1;previewError="";dirty=pending
    )
    fn procEnsureDisplay pending:false = (
        local key=this.procDisplayInputKey()
        if key!=procPublishedDisplayKey do (
            local stage=for i=1 to layerObjects.count collect layerObjects[i].procStagePreview groupSnapshotRows[i]
            for i=1 to layerObjects.count do layerObjects[i].procInstallPreview stage[i] pending
            procPublishedDisplayKey=key
        )
    )
    fn procRefreshPreview = (
        local root=overlapOwner
        try (
            if not root.groupDisplayOnly or root.groupSnapshotKey=="" do root.evaluateProcedural()
            local pending=root.groupSnapshotKey!=root.procInputKey()
            root.procEnsureDisplay pending:pending
            dirty=pending;cachedPointCount
        ) catch (
            -- A failed successor cannot erase the preceding complete viewport.
            local failure=getCurrentException()
            for leaf in root.layerObjects do (leaf.previewError=failure;leaf.dirty=false)
            cachedPointCount
        )
    )
    fn evaluateProcedural = (
        if groupSolving do throw "Recursive procedural evaluation."
        this.syncLogicalSettings()
        for leaf in layerObjects do (this.syncLayerSurface leaf;leaf.containerRefresh();leaf.procEnsureSources())
        this.procValidate()
        local key=this.procInputKey()
        if key==groupSnapshotKey do (
            -- A correction may restore the exact last successful recipe.
            -- Reusing its publication is success; clear a prior failure status.
            for leaf in layerObjects do leaf.previewError=""
            groupHits+=1;return groupSnapshotRows
        )
        local mods=this.procModifiers(),active=for m in mods where m.enabled collect m
        local parents=this.logicalLayers(),mapping=#(),layers=#(),admission=0
        local requests=for leaf in layerObjects collect #(0,0,0)
        -- Admit the full bounded candidate pool before any Edit/publication mutation.
        for i=1 to layerObjects.count where cyrusEnabled and this.enabledLayer i do (
            local leaf=layerObjects[i],parent=this.logicalParent leaf,quota=leaf.procQuota()
            local attempts=if parent.procPopulation==2 then (amin 100000 (quota*parent.procAttemptFactor)) else quota
            local required=cyrusEditRequiredCandidates active leaf.editLayerKey
            local pool=amax attempts required
            if pool>100000 do throw "The required candidate pool exceeds 100,000 for a paint set."
            requests[i]=#(quota,attempts,pool);admission+=pool
        )
        if admission>1000000 do throw "Procedural candidate admission exceeds 1,000,000. Reduce population or attempt limits."
        groupSolving=true
        local transaction=false,previousBindings=for leaf in layerObjects collect leaf.procBindingKey
        try (
            cyrusEditTransaction mods 0;transaction=true
            for parent in parents do (
                local members=this.layerSets parent,sets=#(),indices=#()
                for leaf in members do (
                    local i=findItem layerObjects leaf,request=requests[i],plants=leaf.validSources(),rows=#()
                    if cyrusEnabled and this.enabledLayer i do rows=leaf.containerFilter (leaf.procPrepare request[3] plants) plants
                    append sets #(leaf.layerID,rows,(leaf.procRadii rows plants),(leaf.procSelfRule()),request[1],request[2])
                    append indices i
                )
                append layers #(parent.layerID,parent.procPopulation==2,parent.procRepair,parent.procRounds,#(parent.procSiblingEnabled,parent.procSiblingMultiplier,parent.procSiblingGap,parent.procSiblingPlanar),#(parent.finalCleanup,parent.finalNeighborRadius,parent.finalMinNeighbors,parent.finalMinIsland,parent.overlapPlanar),sets)
                append mapping indices
            )
            local pairs=for i=1 to procRuleA.count collect #(procRuleScope[i],procRuleA[i],procRuleB[i],#(procRuleEnabled[i],procRuleMultiplier[i],procRuleGap[i],procRulePlanar[i]))
            local resolved=cyrusEvaluateProcedural layers pairs 1000000
            local accepted=for leaf in layerObjects collect #(),stats=for leaf in layerObjects collect #(),rounds=for leaf in layerObjects collect #(),radii=for leaf in layerObjects collect #()
            for l=1 to mapping.count do for s=1 to mapping[l].count do (
                local i=mapping[l][s]
                accepted[i]=resolved[1][l][s];stats[i]=resolved[2][l][s];rounds[i]=resolved[3][l]
                radii[i]=resolved[4][l][s]
            )
            local display=for i=1 to layerObjects.count collect layerObjects[i].procStagePreview accepted[i]
            local displayKey=this.procDisplayInputKey epoch:(procEpoch+1)
            local publishedOwners=layerObjects as array,publishedSources=for leaf in layerObjects collect leaf.validSources()
            local finalKeep=for i=1 to layerObjects.count collect (for n in publishedSources[i] collect not (layerObjects[i].isPointSource (layerObjects[i].sourceRow n)))
            local publicationInfo=this.procStagePublication accepted requests publishedSources finalKeep
            -- Allocation and computation have finished; publish one coherent epoch.
            this.publishGroupEdits accepted
            this.procSyncEditVisibility()
            local finishedKey=this.procInputKey()
            cyrusEditTransaction mods 1;transaction=false
            procEpoch+=1
            for i=1 to layerObjects.count do (
                local leaf=layerObjects[i]
                leaf.procLastStats=stats[i];leaf.procLastRounds=rounds[i];leaf.procEpoch=procEpoch
                leaf.requestedCount=requests[i][1]
                -- Unconsumed refill capacity is not a rejected plant.
                leaf.setGroupResult (stats[i][1]-stats[i][9]) stats[i][2] stats[i][4]
                leaf.procInstallPreview display[i] false
            )
            procPublishedOwners=publishedOwners;procPublishedSources=publishedSources;procPublishedFinalKeep=finalKeep
            procPublishedRadii=radii;procPublishedInfo=publicationInfo
            groupSnapshotRows=accepted;groupSnapshotKey=finishedKey;procPublishedDisplayKey=displayKey;groupBuilds+=1
            groupSolving=false;accepted
        ) catch (
            local failure=getCurrentException()
            if transaction do cyrusEditTransaction mods 2
            for i=1 to layerObjects.count do (layerObjects[i].procPreparedKey="";layerObjects[i].procCandidateCount=undefined;layerObjects[i].procBindingKey=previousBindings[i])
            groupSolving=false;throw()
        )
    )
