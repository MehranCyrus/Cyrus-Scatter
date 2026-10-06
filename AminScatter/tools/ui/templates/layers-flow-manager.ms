    rollout layersUI "Layer Manager" width:162 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,controlsReady=false,binding=false,members=#()
        listbox layerList "Layer | placed | status" pos:[8,8] width:(layersUI.width-16) height:6
        button editButton "Edit layer..." pos:[8,138] width:(layersUI.width-16) height:28 tooltip:"Open the reusable Layer Editor. Double-clicking a layer does the same."
        button addButton "Add layer" pos:[8,174] width:(layersUI.width-16) tooltip:"Add a layer and open its settings. Layers calculate from top to bottom."
        button copyButton "Copy" pos:[8,204] width:((layersUI.width-22)/2) tooltip:"Copy this layer, its paint sets and their settings."
        button removeButton "Remove" pos:[(layersUI.width/2+3),204] width:((layersUI.width-22)/2) tooltip:"Remove this layer and its paint sets. Undo restores them."
        edittext nameEdit "Name:" pos:[8,236] width:(layersUI.width-16) tooltip:"Rename the selected layer without changing its identity."
        checkbox visibleCheck "Visible in viewport" pos:[8,264] width:(layersUI.width-16) tooltip:"Hide display only. Hidden layers still calculate and affect spacing."
        checkbox enabledCheck "Enabled in output" pos:[8,288] width:(layersUI.width-16) tooltip:"Include this layer in calculation and final output."
        button upButton "Move up" pos:[8,318] width:((layersUI.width-22)/2) tooltip:"Evaluate earlier; earlier layers occupy space first."
        button downButton "Move down" pos:[(layersUI.width/2+3),318] width:((layersUI.width-22)/2) tooltip:"Evaluate after the preceding layers."
        label countInfo "Select a layer." pos:[8,350] width:(layersUI.width-16) height:46
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
            for c in #(editButton,copyButton,removeButton,nameEdit,visibleCheck,enabledCheck) do c.enabled=valid
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
        on editButton pressed do root.mainUI.selectLayerView (currentLayer()) expand:true
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
