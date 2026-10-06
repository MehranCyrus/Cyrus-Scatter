    rollout instanceRadiusUI "Instance radii - CS Edit" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,setSpecific=true
        dropdownlist radiusMode "Selected CS Edit instances" items:#("World radius","Radius multiplier") selection:1 pos:[4,8] width:132
        spinner radiusSpin "Value:" range:[0,1e9,1] pos:[4,60] width:132 fieldWidth:52
        button applyRadius "Set selected radii" pos:[4,88] width:132
        button resetRadius "Clear selected overrides" pos:[4,116] width:132
        button clearRadius "Clear this set's overrides" pos:[4,144] width:132
        label info "Select instances with CS Edit before applying a radius. Overrides follow their stable instance identities." pos:[4,180] width:132 height:54
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (for c in instanceRadiusUI.controls do c.enabled=root.groupPolicy==3;controlsReady=true)
        on instanceRadiusUI open do bind owner
        on instanceRadiusUI close do controlsReady=false
        on applyRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on resetRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value reset:true;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on clearRadius pressed do try((currentSet()).procClearRadii();bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
    )
