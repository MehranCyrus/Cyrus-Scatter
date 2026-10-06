    rollout surfaceUI "Surface Scatter" width:162 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,controlsReady=false,binding=false
        pickbutton sharedPick "Pick receiving surface" filter:AminScatterSourceFilter pos:[8,8] width:(surfaceUI.width-16) tooltip:"Choose the surface on which every layer in this setup scatters."
        label sharedInfo "Choose a receiving surface." pos:[8,38] width:(surfaceUI.width-16) height:32
        button surfacesButton "Receiving surfaces..." pos:[8,76] width:(surfaceUI.width-16) tooltip:"Choose multiple receiving surfaces by name. Brush needs one shared surface."
        button policyButton "Shared spacing active" pos:[8,106] width:(surfaceUI.width-16) tooltip:"Explicitly convert to procedural evaluation. Existing scenes retain their policy until conversion."
        label countInfo "Add a layer in Layer Manager." pos:[8,136] width:(surfaceUI.width-16) height:42
        checkbutton containersToggle "Global source rectangles" pos:[8,188] width:(surfaceUI.width-16) height:26 tooltip:"Optional shared source pool. Enable Global containers in a layer's Assets tab."
        listbox globalContainers "Global source containers" items:#() pos:[8,224] width:(surfaceUI.width-16) height:4
        button createContainer "Create source rectangle" pos:[8,320] width:(surfaceUI.width-16) tooltip:"Create a source rectangle shared by owners that explicitly use the global pool."
        pickbutton pickContainer "Pick source rectangle" filter:CyrusSourceContainerFilter pos:[8,350] width:(surfaceUI.width-16) tooltip:"Register an existing unmodified Rectangle in the global source pool."
        button removeContainer "Unlink selected rectangle" pos:[8,380] width:(surfaceUI.width-16) tooltip:"Unlink the rectangle while keeping its scene node and registered model settings."
        label containerInfo "Choose Global containers under Assets in each layer's editor." pos:[8,414] width:(surfaceUI.width-16) height:48
        fn arrangeContainers = (
            for c in #(globalContainers,createContainer,pickContainer,removeContainer,containerInfo) do c.visible=containersToggle.checked
            surfaceUI.height=if containersToggle.checked then 470 else 222
        )
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
            controlsReady=true;binding=false;refreshStats();arrangeContainers()
        )
        fn setSurfaces nodes = (
            CyrusStopBrush();undo "Cyrus receiving surface" on (root.surfaceNodes=nodes;root.surface=undefined)
            root.invalidateGroups();root.bindNativeUI()
        )
        on surfaceUI open do bind undefined
        on surfaceUI close do controlsReady=false
        on containersToggle changed value do arrangeContainers()
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
