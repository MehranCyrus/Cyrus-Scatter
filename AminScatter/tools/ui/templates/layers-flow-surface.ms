    rollout surfaceUI "Surface Scatter" width:162 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,controlsReady=false,binding=false
        pickbutton sharedPick "Pick receiving surface" filter:AminScatterSourceFilter pos:[8,8] width:(surfaceUI.width-16)
        label sharedInfo "Choose a receiving surface." pos:[8,38] width:(surfaceUI.width-16) height:32
        button surfacesButton "Receiving surfaces..." pos:[8,76] width:(surfaceUI.width-16)
        button policyButton "Shared spacing active" pos:[8,106] width:(surfaceUI.width-16)
        label countInfo "Add a layer in Layer Manager." pos:[8,136] width:(surfaceUI.width-16) height:42
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
            policyButton.enabled=root.groupPolicy==1;policyButton.text=if root.groupPolicy==1 then "Upgrade legacy spacing..." else "Shared spacing active"
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
        on policyButton pressed do try(root.groupConversion();root.refreshAll();bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus spacing")
    )
