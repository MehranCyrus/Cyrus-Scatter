    rollout surfaceUI "Surface Scatter" width:162 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,controlsReady=false,binding=false
        pickbutton sharedPick "Pick receiving surface" filter:AminScatterSourceFilter pos:[8,8] width:(surfaceUI.width-16)
        label sharedInfo "Choose a receiving surface." pos:[8,38] width:(surfaceUI.width-16) height:32
        button surfacesButton "Receiving surfaces..." pos:[8,76] width:(surfaceUI.width-16)
        button policyButton "Shared spacing active" pos:[8,106] width:(surfaceUI.width-16)
        label countInfo "Add a layer in Layer Manager." pos:[8,136] width:(surfaceUI.width-16) height:42
        listbox globalContainers "Global source containers" items:#() pos:[8,188] width:(surfaceUI.width-16) height:4
        button createContainer "Create source rectangle" pos:[8,284] width:(surfaceUI.width-16)
        pickbutton pickContainer "Pick source rectangle" filter:CyrusSourceContainerFilter pos:[8,314] width:(surfaceUI.width-16)
        button removeContainer "Unlink selected rectangle" pos:[8,344] width:(surfaceUI.width-16)
        label containerInfo "Choose Global containers in each layer's Source containers section." pos:[8,378] width:(surfaceUI.width-16) height:48
        fn refreshStats = (
            local total=0,pending=0
            for leaf in root.layerObjects do (local state=leaf.uiLayerStats();if state.hasResult do total+=state.placements;if state.needsUpdate do pending+=1)
            local text=((root.logicalLayers()).count as string)+" layers | "+(CyrusUICount total)+" cached plants\n"+(root.layerObjects.count as string)+" / 10 populations"+(if pending>0 then " | Pending update" else "")
            if countInfo.text!=text do countInfo.text=text
        )
        fn bind layer = (
            binding=true
            local targets=root.validSurfaces()
            sharedInfo.text=if targets.count==1 then targets[1].name else (targets.count as string)+" surfaces; paint needs one"
            policyButton.enabled=root.groupPolicy!=3;policyButton.text=if root.groupPolicy==3 then "Procedural 0.7 active" else "Enable Procedural 0.7..."
            globalContainers.items=for node in root.containerGlobalNodes collect (if isValidNode node then node.name else "<deleted rectangle>")
            for control in #(globalContainers,createContainer,pickContainer,removeContainer) do control.enabled=root.groupPolicy==3
            controlsReady=true;binding=false;refreshStats()
        )
        fn setSurfaces nodes = (
            CyrusStopBrush();undo "Cyrus receiving surface" on (root.surfaceNodes=nodes;root.surface=undefined)
            root.invalidateGroups();root.bindNativeUI()
        )
        on surfaceUI open do bind undefined
        on surfaceUI close do controlsReady=false
        on sharedPick picked node do setSurfaces #(node)
        on surfacesButton pressed do (
            local nodes=selectByName title:"Cyrus receiving surfaces" buttonText:"Use selected" filter:AminScatterSourceFilter single:false
            if nodes!=undefined and nodes.count>0 do setSurfaces nodes
        )
        on policyButton pressed do try(root.procUpgrade();root.refreshAll();bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus spacing")
        on createContainer pressed do try(root.containerCreate globalPool:true;bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on pickContainer picked node do try(root.containerAdd node globalPool:true;bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on removeContainer pressed do try(root.containerRemove globalContainers.selection globalPool:true;bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
    )
