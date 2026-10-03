    parameters plantingSettings (
        groupPolicy type:#integer default:2
        groupPriority type:#integer default:0
        groupRuleA type:#stringTab tabSize:0 tabSizeVariable:true
        groupRuleB type:#stringTab tabSize:0 tabSizeVariable:true
        groupRuleEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        groupRuleGap type:#floatTab tabSize:0 tabSizeVariable:true
        groupRuleFootprints type:#boolTab tabSize:0 tabSizeVariable:true
        groupRulePlanar type:#boolTab tabSize:0 tabSizeVariable:true
        groupCenters type:#boolean default:false
        on groupPolicy set value do dirty=true
        on groupPriority set value do dirty=true
    )
    local groupSnapshotKey="",groupSnapshotRows=#(),groupSolving=false,groupDisplayOnly=false
    local groupBuilds=0,groupHits=0,groupPrepareKey="",groupPrepareRows=#(),groupPrepareBuilds=0
    local groupEligible=0,groupConflicts=0,groupRemoved=0
    fn sharedSpacing = (overlapOwner!=undefined and overlapOwner.groupPolicy==2)
    fn invalidateGroups = (for group in this.layerObjects do group.dirty=true;CyrusViewportRedraw())
    fn groupCounters = (#(groupBuilds,groupHits,groupPrepareBuilds))
    fn groupStats = (#(groupEligible,groupRemoved,groupConflicts))
    fn setGroupDisplay mode = (
        if mode<1 or mode>4 do throw "Unknown Cyrus display mode."
        groupCenters=mode==4;viewportMode=if mode==4 then 1 else mode
        if groupPolicy==1 do for group in this.layerObjects do group.showCenters=groupCenters
        this.refreshDisplay()
    )
    fn groupPair a b = (
        for i=1 to groupRuleA.count where (groupRuleA[i]==a.layerID and groupRuleB[i]==b.layerID) or (groupRuleA[i]==b.layerID and groupRuleB[i]==a.layerID) do return i
        0
    )
    fn setGroupPair a b enabled gap footprints planar = (
        if a==b or findItem this.layerObjects a==0 or findItem this.layerObjects b==0 do throw "Choose two groups in this planting setup."
        if gap<0 do throw "Group spacing cannot be negative."
        this.syncLayerIdentity()
        undo "Cyrus group spacing rule" on (
            local i=this.groupPair a b
            if i==0 do (
                append groupRuleA a.layerID;append groupRuleB b.layerID
                append groupRuleEnabled false;append groupRuleGap 0.0;append groupRuleFootprints false;append groupRulePlanar true
                i=groupRuleA.count
            )
            groupRuleEnabled[i]=enabled;groupRuleGap[i]=gap;groupRuleFootprints[i]=footprints;groupRulePlanar[i]=planar
        )
        this.invalidateGroups()
    )
    fn removeGroupRules group = (
        for i=groupRuleA.count to 1 by -1 where groupRuleA[i]==group.layerID or groupRuleB[i]==group.layerID do (
            deleteItem groupRuleA i;deleteItem groupRuleB i;deleteItem groupRuleEnabled i
            deleteItem groupRuleGap i;deleteItem groupRuleFootprints i;deleteItem groupRulePlanar i
        )
    )
    fn copyGroupRules origin destination = (
        for other in this.layerObjects where other!=origin and other!=destination do (
            local pair=this.groupPair origin other
            if pair>0 do this.setGroupPair destination other groupRuleEnabled[pair] groupRuleGap[pair] groupRuleFootprints[pair] groupRulePlanar[pair]
        )
    )
    fn publishGroupEdits rows = (
        for node in refs.dependentNodes this where node.baseObject==this do (
            local mods=for m in node.modifiers where classof m==CyrusScatterEdit and m.enabled collect m
            if mods.count>0 do for i=1 to this.layerObjects.count do cyrusEditPublish mods this.layerObjects[i].editLayerKey rows[i]
        )
    )
    fn groupInputKey = (
        local s=stringStream ""
        with printAllElements on (
            format "%|%|%|%|%|%|%|%|%|%|%|" currentTime CyrusPFRevision CyrusPFManualRevision cyrusEnabled this.layerEnabled groupRuleA groupRuleB groupRuleEnabled groupRuleGap groupRuleFootprints groupRulePlanar to:s
            format "Edit:%|" (CyrusEditStackKey this) to:s
            for group in this.layerObjects do (
                format "Group:%:%:%:%:%|" group.layerID group.groupPriority (group.paintBaseInputKey (group.validSources()) true) (group.paintKey()) group.paintDensity to:s
                for key in #(#paintEnabled,#collisionEnabled,#collisionRadius,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#sourceRadii,#sourceFollowScale) do format "%:%|" key (getProperty group key) to:s
            )
        )
        s as string
    )
    fn prepareGroup = (
        local plants=this.validSources()
        if this.paintDocument!=undefined and this.paintEnabled do (
            local targets=overlapOwner.validSurfaces()
            if targets.count!=1 or (cyrusBrushTarget this.paintDocument)!=targets[1] do throw "Paint target differs from the shared surface. Restore the shared surface or explicitly reset this group's coverage. Saved strokes are preserved."
        )
        local key=(this.paintBaseInputKey plants true)+"|"+(this.paintKey())+"|"+(paintEnabled as string)+"|"+(paintDensity as string)+"|"+(CyrusEditStackKey overlapOwner)
        if key!=groupPrepareKey then (
            local rows=this.cspImpl_placements plants previewOnly:true rawOnly:true
            if diversityMode==4 and (borderFaceOut or streetFaceOut or (findItem strokeSides 7>0)) and rows.count>0 do (
                local forward=if plants.count==0 then #(1) else for n in plants collect sourceForward (sourceRow n)
                local offsets=if plants.count==0 then #(0.0) else for n in plants collect sourceZOffset (sourceRow n)
                rows=cyrusOrientRows rows (lineInputs plants previewOnly:true) forward offsets
            )
            rows=CyrusEditApplyLayer overlapOwner this rows
            groupPrepareRows=rows;groupPrepareKey=key;groupPrepareBuilds+=1
        )
        groupPrepareRows
    )
    fn setGroupResult eligibleCount finalCount conflicts = (
        groupEligible=eligibleCount;groupRemoved=eligibleCount-finalCount;groupConflicts=conflicts
        overlapBefore=eligibleCount;overlapAfter=finalCount
    )
    fn evaluateGroups = (
        if groupSolving do throw "Recursive planting group evaluation."
        for group in this.layerObjects do this.syncLayerSurface group
        local key=this.groupInputKey()
        if key==groupSnapshotKey do (groupHits+=1;return groupSnapshotRows)
        groupSolving=true
        try (
            local prepared=for group in this.layerObjects collect #(),accepted=for group in this.layerObjects collect #(),pins=for group in this.layerObjects collect #()
            local order=#(),results=for group in this.layerObjects collect #(0,0,0)
            for i=1 to this.layerObjects.count where cyrusEnabled and this.layerEnabled[i] do (
                local group=this.layerObjects[i]
                prepared[i]=group.prepareGroup()
                pins[i]=for row in prepared[i] where row.count==4 and row[4]==true collect row
                append order i
            )
            -- Insertion order is persisted through stable Edit keys, not UI selection.
            for i=2 to order.count do (
                local chosen=order[i],j=i-1
                while j>0 and (this.layerObjects[order[j]].groupPriority<this.layerObjects[chosen].groupPriority or (this.layerObjects[order[j]].groupPriority==this.layerObjects[chosen].groupPriority and this.layerObjects[order[j]].editLayerKey>this.layerObjects[chosen].editLayerKey)) do (order[j+1]=order[j];j-=1)
                order[j+1]=chosen
            )
            local completed=#{}
            for i in order do (
                local group=this.layerObjects[i],rows=prepared[i],rules=#(),plants=group.validSources()
                for j in order where j!=i do (
                    local pair=this.groupPair group this.layerObjects[j]
                    if pair>0 and groupRuleEnabled[pair] do (
                        local blockers=if completed[j] then accepted[j] else pins[j]
                        if blockers.count>0 do (
                            local own=if groupRuleFootprints[pair] and plants.count>0 then group.placementRadii rows plants else for row in rows collect 0.0
                            local otherPlants=this.layerObjects[j].validSources()
                            local other=if groupRuleFootprints[pair] and otherPlants.count>0 then this.layerObjects[j].placementRadii blockers otherPlants else for row in blockers collect 0.0
                            append rules #(blockers,groupRuleGap[pair],groupRulePlanar[pair],own,other)
                        )
                    )
                )
                local resolved=cyrusResolveGroup rows (if group.collisionEnabled then 2*group.collisionRadius else 0.0) rules
                local finalRows=resolved[1]
                if group.finalCleanup and finalRows.count>0 do finalRows=cyrusCleanupGroup finalRows group.finalNeighborRadius group.finalMinNeighbors group.finalMinIsland group.overlapPlanar
                accepted[i]=finalRows;completed[i]=true;results[i]=#(rows.count,finalRows.count,resolved[2])
            )
            -- Commit only after every enabled group succeeded.
            this.publishGroupEdits accepted
            groupSnapshotRows=accepted;groupSnapshotKey=this.groupInputKey();groupBuilds+=1
            for i=1 to this.layerObjects.count do this.layerObjects[i].setGroupResult results[i][1] results[i][2] results[i][3]
            groupSolving=false;groupSnapshotRows
        ) catch (groupSolving=false;throw())
    )
    fn groupPlacements group plants previewOnly = (
        local i=findItem this.layerObjects group
        if i==0 do return #()
        local snapshot=if groupDisplayOnly and groupSnapshotKey!="" then groupSnapshotRows else this.evaluateGroups()
        local rows=snapshot[i]
        if not previewOnly do (
            if plants.count==0 and rows.count>0 do throw "Assign plant assets to this group before final output."
            if plants.count>0 do (
                local keep=for n in plants collect not (group.isPointSource (group.sourceRow n))
                rows=group.filterSourceRowsByPolicy rows keep
            )
        )
        rows
    )
    fn groupConversion = (
        if groupPolicy==2 do return false
        local owners=for node in refs.dependentNodes this where node.baseObject==this collect node
        for node in owners do for modifier in node.modifiers where classof modifier==CyrusScatterEdit do throw "This setup contains CS Edit. Keep its existing spacing policy; conversion with existing Edit bindings is not supported. Saved edits have not been reset."
        undo "Cyrus use shared group spacing" on (
            this.syncLayerIdentity()
            for i=1 to this.layerObjects.count do (
                local group=this.layerObjects[i]
                group.paintIdentity=true;group.groupPriority=this.layerObjects.count-i
                if group.overlapEnabled do for j in group.overlapBlockers where j>0 and j<=this.layerObjects.count and j!=i do (
                    local pair=this.groupPair group this.layerObjects[j]
                    local gap=if group.overlapSourceRadius then group.overlapGap else group.overlapRadius+group.overlapGap
                    if pair>0 do gap=amax gap groupRuleGap[pair]
                    this.setGroupPair group this.layerObjects[j] true gap group.overlapSourceRadius group.overlapPlanar
                )
            )
            groupPolicy=2
        )
        this.invalidateGroups();this.bindNativeUI();true
    )
    fn setGroupCoverage group painted reset:false = (
        if group==undefined do return false
        CyrusStopBrush()
        if painted then (
            local targets=if groupPolicy==1 and group.paintDocument!=undefined and not reset then #(cyrusBrushTarget group.paintDocument) else this.validSurfaces()
            if targets.count!=1 or not isValidNode targets[1] do throw "Choose one shared receiving surface before painting. Curved meshes are supported."
            if group.paintDocument!=undefined and cyrusBrushTarget group.paintDocument!=targets[1] and not reset do throw "This group has strokes on another surface. Restore that surface or use Reset coverage to explicitly create an empty mask."
            undo "Cyrus painted coverage" on (
                if group.paintDocument==undefined or reset do group.paintDocument=cyrusBrushCreate targets[1]
                group.paintIdentity=true;group.paintEnabled=true
            )
        ) else undo "Cyrus whole surface coverage" on group.paintEnabled=false
        this.invalidateGroups();this.bindNativeUI();true
    )
