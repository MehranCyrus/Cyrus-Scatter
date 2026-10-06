    rollout proceduralUI "Spacing rules - selected scope" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=true,peers=#()
        dropdownlist scopeList "Spacing scope" items:#("This paint set","Default between sets","Pair of paint sets","Pair of layers") pos:[4,12] width:132 selection:1
        dropdownlist peerList "Other owner" items:#() pos:[4,64] width:132
        checkbox enabledCheck "Enable this spacing" pos:[4,118] width:132
        spinner multiplierSpin "Radius factor:" range:[0,10000,1] pos:[4,146] width:132 fieldWidth:44
        spinner gapSpin "Extra gap:" range:[0,1e9,0] type:#worldUnits pos:[4,174] width:132 fieldWidth:44
        checkbox planarCheck "XY distance (off = 3D)" pos:[4,202] width:132
        label ruleInfo "Factor x (radius A + radius B) + gap" pos:[4,230] width:132 height:40
        button resetRule "Use inherited / default" pos:[4,274] width:132
        fn currentSet = (root.selectedPaintSet owner)
        fn bindRule resetPeer:false = (
            local wasBinding=binding,leaf=currentSet(),scope=scopeList.selection,rule,previous=undefined
            if not resetPeer and peerList.selection>0 and peerList.selection<=peers.count do previous=peers[peerList.selection]
            binding=true
            try (
            peers=case scope of (
                3:(for p in root.layerSets owner where p!=leaf collect p)
                4:(for p in root.logicalLayers() where p!=owner collect p)
                default:#()
            )
            peerList.items=for p in peers collect (if scope==4 then root.layerCaption p else p.paintSetName)
            peerList.selection=if peers.count==0 then 0 else amax 1 (findItem peers previous)
            local editable=root.groupPolicy==3 and (scope<3 or peers.count>0)
            peerList.enabled=editable and scope>=3
            for c in #(enabledCheck,multiplierSpin,gapSpin,planarCheck,resetRule) do c.enabled=editable
            rule=case scope of (
                1: leaf.procSelfRule()
                2:#(owner.procSiblingEnabled,owner.procSiblingMultiplier,owner.procSiblingGap,owner.procSiblingPlanar)
                default:#(false,1.0,0.0,false)
            )
            if scope>=3 and peerList.selection>0 do (
                local i=root.procPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection]
                if i>0 then rule=#(root.procRuleEnabled[i],root.procRuleMultiplier[i],root.procRuleGap[i],root.procRulePlanar[i])
                else if scope==3 do rule=#(owner.procSiblingEnabled,owner.procSiblingMultiplier,owner.procSiblingGap,owner.procSiblingPlanar)
            )
            enabledCheck.checked=rule[1];multiplierSpin.value=rule[2];gapSpin.value=rule[3];planarCheck.checked=rule[4]
            ruleInfo.text=if not editable and scope>=3 then "Add another owner to set pair spacing." else if scope==1 and not leaf.procSelfOverride then "Inherited: 2 x Collision radius. Edit to override this set." else "Factor x (radius A + radius B) + gap. Changes save automatically."
            binding=wasBinding
            )catch(binding=wasBinding;throw())
        )
        fn bind layer = (
            binding=true
            for c in proceduralUI.controls do c.enabled=root.groupPolicy==3
            bindRule();controlsReady=true;binding=false
            if root.groupPolicy!=3 do ruleInfo.text="Use the preserved legacy spacing controls, or enable Procedural in the Modify panel."
        )
        on proceduralUI open do bind owner
        on proceduralUI close do controlsReady=false
        fn saveRule = (
            if binding or not controlsReady or root.groupPolicy!=3 do return false
            local leaf=currentSet(),scope=scopeList.selection
            if scope>=3 and (peerList.selection<1 or peerList.selection>peers.count) do return false
            try (
            undo "Cyrus procedural spacing" on case scope of (
                1:(leaf.procSelfOverride=true;leaf.procSelfEnabled=enabledCheck.checked;leaf.procSelfMultiplier=multiplierSpin.value;leaf.procSelfGap=gapSpin.value;leaf.procSelfPlanar=planarCheck.checked)
                2:(owner.procSiblingEnabled=enabledCheck.checked;owner.procSiblingMultiplier=multiplierSpin.value;owner.procSiblingGap=gapSpin.value;owner.procSiblingPlanar=planarCheck.checked)
                default:(if peerList.selection<1 do throw "Choose a peer.";root.procSetPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection] enabledCheck.checked multiplierSpin.value gapSpin.value planarCheck.checked)
            )
            -- Save the rule only. The normal Manual/Live pipeline decides when
            -- to publish placements. Do not reset peer selection or spinner
            -- focus by rebinding every control during a drag.
            ruleInfo.text="Factor x (radius A + radius B) + gap. Changes save automatically."
            root.invalidateGroups();true
            )catch(bindRule();messageBox (getCurrentException()) title:"Cyrus spacing";false)
        )
        on scopeList selected i do if not binding do bindRule resetPeer:true
        on peerList selected index do if not binding and index>0 do bindRule()
        on enabledCheck changed value do saveRule()
        on multiplierSpin changed value do saveRule()
        on gapSpin changed value do saveRule()
        on planarCheck changed value do saveRule()
        on resetRule pressed do try(
            local leaf=currentSet(),scope=scopeList.selection
            undo "Cyrus spacing inheritance" on case scope of (
                1: leaf.procSelfOverride=false
                2:(owner.procSiblingEnabled=false;owner.procSiblingMultiplier=1;owner.procSiblingGap=0;owner.procSiblingPlanar=false)
                default:(if peerList.selection>0 do root.procRemoveRule (root.procPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection]))
            )
            root.invalidateGroups();bind owner
        )catch(messageBox (getCurrentException()) title:"Cyrus spacing")
    )
