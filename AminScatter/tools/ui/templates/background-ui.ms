    rollout backgroundUI "Background fill - paint set" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=true,backgrounds=#()
        dropdownlist backgroundList "This set: background" items:#("Off","Outside painted coverage","Between plants","Outside + between") pos:[4,8] width:132
        multiListBox referenceList "Earlier paint sets" items:#() pos:[4,60] width:132 height:4
        button applyBackground "Apply background" pos:[4,152] width:132
        label backgroundInfo "Outside uses earlier sibling coverage. Between plants uses the rules on the Spacing tab." pos:[4,182] width:132 height:62
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (
            binding=true
            for c in backgroundUI.controls do c.enabled=root.groupPolicy==3
            local leaf=currentSet()
            backgroundList.selection=leaf.procBackground;backgrounds=#()
            for p in root.layerSets owner while p!=leaf do append backgrounds p
            referenceList.items=for p in backgrounds collect p.paintSetName
            referenceList.selection=for i=1 to backgrounds.count where findItem leaf.procBackgroundIDs backgrounds[i].layerID>0 collect i
            controlsReady=true;binding=false
        )
        on backgroundUI open do bind owner
        on backgroundUI close do controlsReady=false
        on applyBackground pressed do try(
            local leaf=currentSet(),ids=for i in referenceList.selection collect backgrounds[i].layerID
            if backgroundList.selection!=1 and ids.count==0 do throw "Choose at least one earlier paint set."
            undo "Cyrus background coverage" on (leaf.procBackground=backgroundList.selection;leaf.procBackgroundIDs=if backgroundList.selection==1 then #() else ids)
            root.invalidateGroups();bind owner
        )catch(messageBox (getCurrentException()) title:"Cyrus background")
    )
