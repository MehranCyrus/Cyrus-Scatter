    rollout containerUI "Source Container" width:#cmdPanel category:0 autoLayoutOnResize:true (
        local view=undefined,controlsReady=false,binding=false
        checkbox enabledCheck "Enable collection" pos:[6,6] width:(containerUI.width-12) tooltip:"Collect models whose pivots are inside this rectangle. Off lets you position it without collecting or moving models. Manual mode needs Update."
        label consumerCaption "Edit linked Scatter layer" pos:[6,30] width:(containerUI.width-12) height:18
        dropdownlist consumerList "" items:#() pos:[6,50] width:(containerUI.width-12) tooltip:"Choose a linked setup or layer. Inactive pools remain editable; this changes the view only."
        label widthCaption "Width:" pos:[6,74] width:(containerUI.width-90) height:18
        spinner widthSpin "" type:#worldUnits range:[.01,1e9,500] pos:[6,74] width:(containerUI.width-12) fieldWidth:66 tooltip:"Resize the boundary. Source models keep their transforms."
        label lengthCaption "Length:" pos:[6,98] width:(containerUI.width-90) height:18
        spinner lengthSpin "" type:#worldUnits range:[.01,1e9,300] pos:[6,98] width:(containerUI.width-12) fieldWidth:66
        checkbox labelCheck "Show viewport label" pos:[6,122] width:(containerUI.width-12)
        label sourceCaption "Active / parked source models" pos:[6,146] width:(containerUI.width-12) height:18
        listbox sourceList "" items:#() pos:[6,166] width:(containerUI.width-12) height:5
        button assignOwner "Follow this container" pos:[6,226] width:(containerUI.width-12) height:22 tooltip:"Resolve overlapping movement ownership for the selected source. Its usage and settings in other sets are unchanged."
        label statusInfo "Unlinked source container" pos:[6,252] width:(containerUI.width-12) height:80
        button editLayer "Edit layer..." pos:[6,336] width:(containerUI.width-12) height:22 tooltip:"Open the optional layer editor for the current consumer."
        fn layout = (
            local available=amax 128 (containerUI.width-12),capacity=amax 1 (floor ((available-4)/5.2)),lines=0
            for paragraph in filterString statusInfo.text "\n" splitEmptyTokens:true do (
                local occupied=0;lines+=1
                for word in filterString paragraph " " do (
                    local size=word.count+(if occupied==0 then 0 else 1)
                    if occupied>0 and occupied+size>capacity do (lines+=1;occupied=0;size=word.count)
                    lines+=floor ((amax 0 (size-1))/capacity);occupied=(mod (amax 0 (size-1)) capacity)+1+occupied
                )
            )
            widthSpin.pos=[containerUI.width-18,74];lengthSpin.pos=[containerUI.width-18,98]
            assignOwner.pos=[6,sourceList.pos.y+sourceList.height+4]
            statusInfo.height=amax 18 (lines*14+2);statusInfo.pos=[6,assignOwner.pos.y+26]
            editLayer.pos=[6,statusInfo.pos.y+statusInfo.height+4]
            containerUI.height=editLayer.pos.y+26;true
        )
        fn bind = (
            binding=true
            consumerList.items=view.consumerLabels
            local chosen=0
            for i=1 to view.consumerRows.count where view.consumerRows[i][2]==view.contextRootID and view.consumerRows[i][3]==view.contextSetID do chosen=i
            consumerList.selection=chosen;enabledCheck.checked=view.collectEnabled;widthSpin.value=view.width;lengthSpin.value=view.length;labelCheck.checked=view.showLabel
            local nodes=refs.dependentNodes view,node=if nodes.count==1 then nodes[1] else undefined
            sourceList.items=for model in view.savedSources collect (
                local active=false
                if view.collectEnabled and isValidNode model and isValidNode node do active=CyrusContainerInside model node
                (if active then "Active | " else "Parked | ")+(if isValidNode model then model.name else "<deleted>")
            )
            statusInfo.text=view.cachedLabel+"\n"+view.movementStatus+"\nLast move: "+(view.movementStats())[5]
            local context=CyrusContainerResolve view
            editLayer.enabled=context!=undefined and context[2]!=undefined
            controlsReady=true;binding=false;layout()
        )
        on containerUI open do (view=this;bind())
        on containerUI close do controlsReady=false
        fn selectConsumer index = if controlsReady and not binding and index>0 and index<=view.consumerRows.count do (
            CyrusStopBrush();max select
            undo off (view.contextRootID=view.consumerRows[index][2];view.contextSetID=view.consumerRows[index][3])
            view.mainUI.mountTimer.active=true;CyrusContainerRefreshAll();bind()
        )
        on consumerList selected index do selectConsumer index
        on enabledCheck changed value do if controlsReady and not binding do (local container=view;undo "Cyrus container collection" on container.collectEnabled=value;bind())
        on widthSpin changed value do if controlsReady and not binding do (undo "Cyrus container width" on view.width=value;CyrusScheduleRelease())
        on lengthSpin changed value do if controlsReady and not binding do (undo "Cyrus container length" on view.length=value;CyrusScheduleRelease())
        on labelCheck changed value do if controlsReady and not binding do undo "Cyrus container label" on view.showLabel=value
        on assignOwner pressed do if sourceList.selection>0 and sourceList.selection<=view.savedSources.count do (
            local model=view.savedSources[sourceList.selection],nodes=refs.dependentNodes view
            if isValidNode model and nodes.count==1 do (
                undo "Cyrus container movement owner" on (
                    for controller in CyrusTimeOwners where isValidNode controller do for leaf in controller.baseObject.layerObjects do for node in leaf.effectiveContainers() where isValidNode node do (
                        local i=findItem node.baseObject.movementSources model
                        if i>0 do deleteItem node.baseObject.movementSources i
                    )
                    appendIfUnique view.movementSources model
                )
                CyrusContainerRefreshAll();bind()
            )
        )
        on editLayer pressed do (local context=CyrusContainerResolve view;if context!=undefined and context[2]!=undefined do CyrusOpenLayerEditor context[1] (context[1].logicalParent context[2]))
    )
