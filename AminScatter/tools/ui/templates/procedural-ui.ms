    rollout proceduralUI "Procedural / Rules" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=true,peers=#(),backgrounds=#()
        label policyInfo "Enable Procedural 0.7 in Surface Scatter." pos:[4,8] width:132 height:40
        dropdownlist populationList "Layer population" items:#("Candidate budget","Accepted target") pos:[4,52] width:132
        spinner attemptSpin "Attempt factor:" range:[1,32,8] type:#integer pos:[4,102] width:132 fieldWidth:44
        spinner roundSpin "Max rounds:" range:[1,16,8] type:#integer pos:[4,130] width:132 fieldWidth:44
        checkbox repairCheck "Retry cleanup gaps" pos:[4,158] width:132
        dropdownlist scopeList "Spacing scope" items:#("This paint set","Default between sets","Pair of paint sets","Pair of layers") pos:[4,192] width:132 selection:1
        dropdownlist peerList "Other owner" items:#() pos:[4,244] width:132
        checkbox enabledCheck "Enable this spacing" pos:[4,298] width:132
        spinner multiplierSpin "Radius factor:" range:[0,10000,1] pos:[4,326] width:132 fieldWidth:44
        spinner gapSpin "Extra gap:" range:[0,1e9,0] type:#worldUnits pos:[4,354] width:132 fieldWidth:44
        checkbox planarCheck "XY distance (off = 3D)" pos:[4,382] width:132
        label ruleInfo "Factor x (radius A + radius B) + gap" pos:[4,410] width:132 height:40
        button resetRule "Use inherited / default" pos:[4,454] width:132
        dropdownlist backgroundList "This set: background" items:#("Off","Outside painted coverage","Between plants","Outside + between") pos:[4,494] width:132
        multiListBox referenceList "Earlier paint sets" items:#() pos:[4,546] width:132 height:4
        button applyBackground "Apply background" pos:[4,638] width:132
        label backgroundInfo "Outside uses earlier sibling coverage. Between plants uses the spacing rules above." pos:[4,668] width:132 height:62
        dropdownlist radiusMode "Selected CS Edit instances" items:#("World radius","Radius multiplier") selection:1 pos:[4,738] width:132
        spinner radiusSpin "Value:" range:[0,1e9,1] pos:[4,790] width:132 fieldWidth:52
        button applyRadius "Set selected radii" pos:[4,818] width:132
        button resetRadius "Clear selected overrides" pos:[4,846] width:132
        button clearRadius "Clear this set's overrides" pos:[4,874] width:132
        label cacheInfo "No completed procedural build." pos:[4,906] width:132 height:102
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
            local active=root.groupPolicy==3,leaf=currentSet()
            for c in proceduralUI.controls do c.enabled=active
            policyInfo.enabled=true
            policyInfo.text=if active then "Layer: "+(root.layerCaption owner)+"\nSet: "+leaf.paintSetName else "Enable Procedural 0.7 in Surface Scatter. Existing results keep their policy."
            populationList.selection=owner.procPopulation;attemptSpin.value=owner.procAttemptFactor;roundSpin.value=owner.procRounds;repairCheck.checked=owner.procRepair
            attemptSpin.enabled=active and owner.procPopulation==2
            backgroundList.selection=leaf.procBackground;backgrounds=#()
            for p in root.layerSets owner while p!=leaf do append backgrounds p
            referenceList.items=for p in backgrounds collect p.paintSetName
            referenceList.selection=for i=1 to backgrounds.count where findItem leaf.procBackgroundIDs backgrounds[i].layerID>0 collect i
            bindRule()
            local stats=leaf.procStatistics()
            cacheInfo.text=if stats[1].count==12 then "Last build: "+(stats[1][2] as string)+" kept\nShortfall: "+(stats[1][11] as string)+"\nAttempts: "+(stats[1][10] as string)+" | Rounds: "+(stats[2][1] as string)+"\nProtected conflicts: "+(stats[1][4] as string)+(if stats[2][2] then "\nRound limit reached" else "") else "No completed procedural build. Update to calculate."
            controlsReady=true;binding=false
        )
        fn changeLayer key value = (if not binding do (undo "Cyrus procedural settings" on setProperty owner key value;root.invalidateGroups();bind owner))
        on proceduralUI open do bind owner
        on proceduralUI close do controlsReady=false
        on populationList selected i do changeLayer #procPopulation i
        on attemptSpin changed v do changeLayer #procAttemptFactor v
        on roundSpin changed v do changeLayer #procRounds v
        on repairCheck changed v do changeLayer #procRepair v
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
        on applyBackground pressed do try(
            local leaf=currentSet(),ids=for i in referenceList.selection collect backgrounds[i].layerID
            if backgroundList.selection!=1 and ids.count==0 do throw "Choose at least one earlier paint set."
            undo "Cyrus background coverage" on (leaf.procBackground=backgroundList.selection;leaf.procBackgroundIDs=if backgroundList.selection==1 then #() else ids)
            root.invalidateGroups();bind owner
        )catch(messageBox (getCurrentException()) title:"Cyrus background")
        on applyRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on resetRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value reset:true;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on clearRadius pressed do try((currentSet()).procClearRadii();bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
    )
