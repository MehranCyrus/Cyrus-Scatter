    rollout populationPolicyUI "Target and retry limits - layer" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=false
        dropdownlist populationList "Layer population" items:#("Candidate budget","Accepted target") pos:[4,8] width:132
        spinner attemptSpin "Attempt factor:" range:[1,32,8] type:#integer pos:[4,58] width:132 fieldWidth:44
        spinner roundSpin "Max rounds:" range:[1,16,8] type:#integer pos:[4,86] width:132 fieldWidth:44
        checkbox repairCheck "Retry cleanup gaps" pos:[4,114] width:132
        label info "Candidate budget makes one bounded population. Accepted target retries rejected candidates up to these limits; it can finish short." pos:[4,152] width:132 height:64
        fn bind layer = (
            binding=true
            for c in populationPolicyUI.controls do c.enabled=root.groupPolicy==3
            populationList.selection=owner.procPopulation;attemptSpin.value=owner.procAttemptFactor;roundSpin.value=owner.procRounds;repairCheck.checked=owner.procRepair
            local retry=root.groupPolicy==3 and owner.procPopulation==2
            attemptSpin.enabled=retry;roundSpin.enabled=retry;repairCheck.enabled=retry
            info.enabled=true;controlsReady=true;binding=false
        )
        fn changeLayer key value = (if not binding do (undo "Cyrus procedural settings" on setProperty owner key value;root.invalidateGroups();bind owner))
        on populationPolicyUI open do bind owner
        on populationPolicyUI close do controlsReady=false
        on populationList selected i do changeLayer #procPopulation i
        on attemptSpin changed v do changeLayer #procAttemptFactor v
        on roundSpin changed v do changeLayer #procRounds v
        on repairCheck changed v do changeLayer #procRepair v
    )
