    rollout setsUI "Paint sets" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,members=#()
        dropdownlist setList "Edit set" items:#() pos:[4,8] width:132
        button addButton "Add set" pos:[4,60] width:62
        button removeButton "Remove" pos:[72,60] width:64
        edittext nameEdit "Name:" pos:[4,90] width:132
        spinner weightSpin "Share weight:" pos:[4,120] width:132 fieldWidth:48 range:[0,10000,1]
        checkbox enabledCheck "Enable set" pos:[4,148] width:132
        checkbox visibleCheck "Show set" pos:[4,172] width:132
        button upButton "Move up" pos:[4,200] width:62
        button downButton "Move down" pos:[72,200] width:64
        label info "Sources, Brush and set rules edit this set. Population, transforms and cleanup belong to the layer." pos:[4,232] width:132 height:76
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (
            binding=true;members=root.layerSets owner
            local leaf=currentSet()
            setList.items=for member in members collect member.paintSetName
            setList.selection=findItem members leaf
            nameEdit.text=leaf.paintSetName;weightSpin.value=leaf.paintSetWeight
            enabledCheck.checked=leaf.paintSetEnabled;visibleCheck.checked=leaf.paintSetVisible
            removeButton.enabled=leaf!=owner;addButton.enabled=root.groupPolicy==2 and root.layerObjects.count<10
            upButton.enabled=root.groupPolicy==3 and findItem members leaf>1;downButton.enabled=root.groupPolicy==3 and findItem members leaf<members.count
            controlsReady=true;binding=false
        )
        on setsUI open do bind owner
        on setsUI close do controlsReady=false
        on setList selected i do if not binding and i>0 do (CyrusStopBrush();owner.uiPaintSetID=members[i].layerID;panel.bindEditors())
        on addButton pressed do try(root.addPaintSet owner label:("Paint "+(((root.layerSets owner).count+1) as string));panel.bind())catch(messageBox (getCurrentException()) title:"Cyrus paint set")
        on removeButton pressed do try(root.removePaintSet (currentSet());panel.bind())catch(messageBox (getCurrentException()) title:"Cyrus paint set")
        on nameEdit entered value do if not binding and value!="" do (undo "Cyrus set name" on (currentSet()).paintSetName=value;panel.bindEditors())
        on weightSpin changed value do if not binding do (undo "Cyrus set weight" on (currentSet()).paintSetWeight=value;root.invalidateGroups())
        on enabledCheck changed value do if not binding do (undo "Cyrus set enabled" on (currentSet()).paintSetEnabled=value;root.invalidateGroups())
        on visibleCheck changed value do if not binding do (undo "Cyrus set visible" on (currentSet()).paintSetVisible=value;root.procSyncEditVisibility();CyrusViewportRedraw())
        on upButton pressed do try(root.procMove (currentSet()) -1 sets:true;panel.bind())catch(messageBox (getCurrentException()) title:"Cyrus order")
        on downButton pressed do try(root.procMove (currentSet()) 1 sets:true;panel.bind())catch(messageBox (getCurrentException()) title:"Cyrus order")
    )
