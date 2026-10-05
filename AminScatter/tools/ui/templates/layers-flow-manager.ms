    rollout layersUI "Layer Manager" width:162 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,controlsReady=false,binding=false,members=#()
        listbox layerList "Layer | placed | status" pos:[8,8] width:(layersUI.width-16) height:6
        button addButton "Add Layer" pos:[8,138] width:(layersUI.width-16)
        button copyButton "Copy" pos:[8,166] width:((layersUI.width-22)/2)
        button removeButton "Remove" pos:[(layersUI.width/2+3),166] width:((layersUI.width-22)/2)
        edittext nameEdit "Name:" pos:[8,196] width:(layersUI.width-16)
        checkbox visibleCheck "Visible in viewport" pos:[8,226] width:(layersUI.width-16)
        checkbox enabledCheck "Enabled in final output" pos:[8,250] width:(layersUI.width-16)
        label countInfo "Select a layer." pos:[8,280] width:(layersUI.width-16) height:46
        button upButton "Move up" pos:[8,334] width:((layersUI.width-22)/2)
        button downButton "Move down" pos:[(layersUI.width/2+3),334] width:((layersUI.width-22)/2)
        fn currentLayer = (local leaf=root.selectedLayer();if leaf==undefined then undefined else root.logicalParent leaf)
        fn refreshStats = (
            if not controlsReady do return false
            local rows=#(),selected=currentLayer(),selectedSummary=undefined
            for member in members do (
                local summary=CyrusFlowLayerSummary root member
                append rows ((root.layerCaption member)+" | "+(CyrusUICount summary[1] compact:true)+" | "+summary[3])
                if member==selected do selectedSummary=summary
            )
            binding=true
            if layerList.items as string!=rows as string do layerList.items=rows
            layerList.selection=findItem members selected
            local text=if selectedSummary==undefined then "Select a layer." else "Placed: "+(CyrusUICount selectedSummary[1])+" | Shown: "+(CyrusUICount selectedSummary[2])+"\n"+selectedSummary[3]+"\nCounts describe the last build."
            if countInfo.text!=text do countInfo.text=text
            binding=false
        )
        fn bind layer = (
            binding=true;members=root.logicalLayers()
            local selected=currentLayer(),index=findItem root.layerObjects selected,valid=index>0
            for c in #(copyButton,removeButton,nameEdit,visibleCheck,enabledCheck) do c.enabled=valid
            nameEdit.text=if valid then root.layerNames[index] else ""
            visibleCheck.checked=valid and root.layerVisible[index]
            enabledCheck.checked=valid and root.layerEnabled[index]
            addButton.enabled=root.layerObjects.count<10
            upButton.enabled=root.groupPolicy==3 and findItem members selected>1;downButton.enabled=root.groupPolicy==3 and findItem members selected<members.count
            controlsReady=true;binding=false;refreshStats()
        )
        on layersUI open do bind undefined
        on layersUI close do controlsReady=false
        on layerList selected i do if not binding and i>0 do (root.mainUI.selectLayerView members[i];bind undefined)
        on layerList doubleClicked i do if not binding and i>0 do root.mainUI.selectLayerView members[i] expand:true
        on addButton pressed do (
            root.newLayer();root.bindNativeUI();root.invalidateGroups()
            root.mainUI.selectLayerView (root.selectedLayer()) expand:true
        )
        on copyButton pressed do try(
            local parent=root.copyLogicalLayer (currentLayer())
            root.mainUI.selectLayerView parent expand:true
        )catch(messageBox (getCurrentException()) title:"Cyrus layer")
        on removeButton pressed do try(root.removeLogicalLayer (currentLayer()))catch(messageBox (getCurrentException()) title:"Cyrus layer")
        on nameEdit entered value do if not binding and value!="" do (
            undo "Cyrus layer name" on root.layerNames[findItem root.layerObjects (currentLayer())]=value
            root.mainUI.refreshTitles();refreshStats()
        )
        on visibleCheck changed value do if not binding do (
            undo "Cyrus layer visibility" on root.layerVisible[findItem root.layerObjects (currentLayer())]=value
            root.procSyncEditVisibility();CyrusViewportRedraw();root.mainUI.refreshStats()
        )
        on enabledCheck changed value do if not binding do (
            undo "Cyrus layer enabled" on root.layerEnabled[findItem root.layerObjects (currentLayer())]=value
            root.invalidateGroups();root.mainUI.refreshStats()
        )
        on upButton pressed do try(root.procMove (currentLayer()) -1)catch(messageBox (getCurrentException()) title:"Cyrus order")
        on downButton pressed do try(root.procMove (currentLayer()) 1)catch(messageBox (getCurrentException()) title:"Cyrus order")
    )
