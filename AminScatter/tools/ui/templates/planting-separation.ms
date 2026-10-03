    rollout separationUI "Group spacing / Cleanup" width:#cmdPanel (
        local obj=undefined,parentView=undefined,controlsReady=false,refreshing=true,blockerRows=#(),peerID=""
        label policyInfo "Higher priority occupies space first." pos:[8,8] width:146 height:32
        spinner prioritySpin "Priority:" type:#integer range:[-100000,100000,0] fieldWidth:54 pos:[8,44] width:146
        listbox peerList "Spacing with group" items:#() pos:[8,74] width:146 height:5
        multiListBox blockerList "Legacy blocking groups (Ctrl/Shift)" items:#() pos:[8,74] width:146 height:5
        checkbox overlapCheck "Keep this pair apart" pos:[8,192] width:146
        dropdownlist radiusMode "Distance rule" items:#("Centre distance","Footprints + gap") pos:[8,220] width:146
        spinner gapSpin "Distance / gap:" type:#worldunits range:[0,1e9,10] fieldWidth:58 pos:[8,272] width:146
        spinner radiusSpin "Legacy radius:" type:#worldunits range:[0,1e9,10] fieldWidth:58 pos:[8,300] width:146
        checkbox planarCheck "XY distance (ignore Z)" checked:true pos:[8,328] width:146
        label overlapInfo "Eligible / Removed / Placed" pos:[8,356] width:146
        label overlapCounts "-- / -- / --" pos:[8,378] width:146
        button statsButton "Update planting" pos:[8,404] width:146
        label finalTitle "Final cleanup" pos:[8,440] width:146
        checkbox cleanCheck "Remove isolated plants" pos:[8,466] width:146
        spinner neighborSpin "Neighbor distance:" type:#worldunits range:[0.001,1e9,100] fieldWidth:58 pos:[8,494] width:146
        spinner minNeighborSpin "Minimum neighbors:" type:#integer range:[0,10000,2] fieldWidth:58 pos:[8,522] width:146
        spinner minIslandSpin "Minimum island size:" type:#integer range:[0,100000,5] fieldWidth:58 pos:[8,550] width:146
        checkbox boundaryRelaxCheck "Boundary Relax" pos:[8,582] width:146
        spinner finalStrengthSpin "Strength:" range:[0,1,.3] fieldWidth:58 pos:[8,610] width:146
        spinner finalIterSpin "Iterations:" type:#integer range:[0,100,5] fieldWidth:58 pos:[8,638] width:146
        spinner finalMoveSpin "Max movement:" type:#worldunits range:[0,1e9,10] fieldWidth:58 pos:[8,666] width:146
        label relaxHint "" pos:[8,696] width:146 height:54
        fn currentLayer = (this.selectedLayer())
        fn currentPeer = (
            if peerList.selection>0 and peerList.selection<=blockerRows.count then obj.layerObjects[blockerRows[peerList.selection]] else undefined
        )
        fn syncFinalRelaxAvailability = (
            local before=refreshing;refreshing=true
            local group=currentLayer(),valid=group!=undefined
            local paused=valid and (group.brushMaskActive() or obj.groupPolicy==2),active=valid and group.finalRelax and not paused
            boundaryRelaxCheck.checked=valid and group.finalRelax;boundaryRelaxCheck.enabled=valid and not paused
            finalStrengthSpin.enabled=active;finalIterSpin.enabled=active;finalMoveSpin.enabled=active
            relaxHint.text=if paused then "Boundary Relax paused.\nManual edits are preserved.\nXY ignores height." else "Spatial distance includes height.\nFootprints are radius approximations."
            refreshing=before
        )
        fn syncPair = (
            refreshing=true
            local group=currentLayer(),peer=currentPeer(),valid=group!=undefined and (obj.groupPolicy==1 or peer!=undefined)
            for c in #(overlapCheck,gapSpin,planarCheck,radiusMode) do c.enabled=valid
            if obj.groupPolicy==2 then (
                local pair=if valid then obj.groupPair group peer else 0
                if peer!=undefined do peerID=peer.layerID
                overlapCheck.checked=pair>0 and obj.groupRuleEnabled[pair]
                gapSpin.value=if pair>0 then obj.groupRuleGap[pair] else 10
                radiusMode.selection=if pair>0 and obj.groupRuleFootprints[pair] then 2 else 1
                planarCheck.checked=pair==0 or obj.groupRulePlanar[pair]
            ) else if group!=undefined do (
                overlapCheck.checked=group.overlapEnabled;radiusSpin.value=group.overlapRadius;gapSpin.value=group.overlapGap
                radiusMode.selection=if group.overlapSourceRadius then 2 else 1;planarCheck.checked=group.overlapPlanar
            )
            refreshing=false
        )
        fn refreshOverlap = (
            refreshing=true
            local group=currentLayer(),labels=#(),chosen=#{},peerIndex=0,shared=obj.groupPolicy==2
            peerList.visible=shared;blockerList.visible=not shared;radiusSpin.visible=not shared;prioritySpin.enabled=shared and group!=undefined
            overlapCheck.text=if shared then "Keep this pair apart" else "Enable legacy overlap removal"
            policyInfo.text=if shared then "Higher priority wins.\nTies use creation order." else "Legacy spacing is preserved.\nUpgrade from Plant groups when ready."
            blockerRows=#()
            if group!=undefined do (
                prioritySpin.value=group.groupPriority
                for i=1 to obj.layerObjects.count where obj.layerObjects[i]!=group do (
                    append blockerRows i;append labels obj.layerNames[i]
                    if obj.layerObjects[i].layerID==peerID do peerIndex=blockerRows.count
                    if findItem group.overlapBlockers i>0 do chosen[blockerRows.count]=true
                )
                cleanCheck.checked=group.finalCleanup;neighborSpin.value=group.finalNeighborRadius;minNeighborSpin.value=group.finalMinNeighbors;minIslandSpin.value=group.finalMinIsland
                finalStrengthSpin.value=group.finalStrength;finalIterSpin.value=group.finalIterations;finalMoveSpin.value=group.finalMaxMove
                local stats=group.overlapStats();overlapCounts.text=(stats[1] as string)+" / "+(stats[2] as string)+" / "+(stats[3] as string)
            )
            peerList.items=labels;peerList.selection=if peerIndex>0 then peerIndex else (if labels.count>0 then 1 else 0)
            blockerList.items=labels;blockerList.selection=chosen
            refreshing=false;syncPair();syncFinalRelaxAvailability()
        )
        fn changedOverlap = (obj.invalidateGroups())
        fn savePair = (
            if refreshing or currentLayer()==undefined do return false
            local group=currentLayer()
            if obj.groupPolicy==2 then (
                local peer=currentPeer()
                if peer!=undefined do obj.setGroupPair group peer overlapCheck.checked gapSpin.value (radiusMode.selection==2) planarCheck.checked
            ) else (
                undo "Cyrus legacy spacing" on (
                    group.overlapEnabled=overlapCheck.checked;group.overlapRadius=radiusSpin.value;group.overlapGap=gapSpin.value
                    group.overlapSourceRadius=radiusMode.selection==2;group.overlapPlanar=planarCheck.checked
                )
                changedOverlap()
            )
        )
        on peerList selected value do if not refreshing do syncPair()
        on prioritySpin changed value do if not refreshing and currentLayer()!=undefined do (undo "Cyrus group priority" on (currentLayer()).groupPriority=value;changedOverlap())
        on overlapCheck changed value do savePair()
        on radiusMode selected value do savePair()
        on gapSpin changed value do savePair()
        on radiusSpin changed value do savePair()
        on planarCheck changed value do savePair()
        on blockerList selected value do if not refreshing and obj.groupPolicy==1 and currentLayer()!=undefined do (
            undo "Cyrus blocking groups" on (currentLayer()).overlapBlockers=(for k in blockerList.selection collect blockerRows[k]);changedOverlap()
        )
        on cleanCheck changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus cleanup" on (currentLayer()).finalCleanup=v;changedOverlap())
        on neighborSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus cleanup" on (currentLayer()).finalNeighborRadius=v;changedOverlap())
        on minNeighborSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus cleanup" on (currentLayer()).finalMinNeighbors=v;changedOverlap())
        on minIslandSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus cleanup" on (currentLayer()).finalMinIsland=v;changedOverlap())
        on boundaryRelaxCheck changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus boundary relax" on (currentLayer()).finalRelax=(v and obj.groupPolicy==1 and not (currentLayer()).brushMaskActive());changedOverlap())
        on finalStrengthSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus boundary relax" on (currentLayer()).finalStrength=v;changedOverlap())
        on finalIterSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus boundary relax" on (currentLayer()).finalIterations=v;changedOverlap())
        on finalMoveSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Cyrus boundary relax" on (currentLayer()).finalMaxMove=v;changedOverlap())
        on statsButton pressed do (obj.refreshAll();refreshOverlap())
        fn bind layer = (
            obj=this;parentView=this.mainUI;refreshing=true
            for c in separationUI.controls do c.enabled=layer!=undefined
            refreshOverlap();controlsReady=true;refreshing=false
        )
        on separationUI open do bind (selectedLayer())
        on separationUI close do (controlsReady=false;refreshing=true)
    )
