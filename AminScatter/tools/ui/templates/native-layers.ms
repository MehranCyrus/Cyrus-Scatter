    -- Native rollups: one editor per controller, bound to the selected layer.
    -- UI browsing never rebuilds a rollout or a placement cache.
    fn selectedLayer = (
        if activeLayer>0 and activeLayer<=layerObjects.count then layerObjects[activeLayer] else undefined
    )
    fn syncLayerIdentity = (
        undo off (
            while layerVisible.count<layerObjects.count do append layerVisible true
            while layerVisible.count>layerObjects.count do deleteItem layerVisible layerVisible.count
            for layer in layerObjects where layer.layerID=="" do layer.layerID=CyrusNewLayerID()
        )
    )
    fn visibleLayer i = (i>0 and i<=layerObjects.count and (i>layerVisible.count or layerVisible[i]))
    fn copySelectedLayer = (
        local origin=selectedLayer()
        if origin==undefined do return false
        local label=layerNames[activeLayer]
        undo "Cyrus copy layer" on (
            newLayer()
            local destination=selectedLayer()
            AminScatterCopyLayer origin destination
            destination.bakedNodes=#()
            layerNames[activeLayer]=label+" copy"
        )
        this.bindNativeUI();CyrusViewportRedraw()
    )
    fn bindNativeUI = (
        if this.mainUI.controlsReady do this.mainUI.bind()
        local layer=selectedLayer()
        for r in this.nativeEditors() where r.controlsReady do r.bind layer
        true
    )
    fn syncBrushCompatibility = (
        if this.spacingUI.controlsReady do this.spacingUI.syncRelaxAvailability()
        if this.separationUI.controlsReady do this.separationUI.syncFinalRelaxAvailability()
    )
    rollout mainUI "Cyrus Scatter 1.0 | Layers" width:#cmdPanel (
        local controlsReady=false,binding=false,dpiScale=1.0,lastRows=#()
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,8] width:146
        listbox layerList "Layer / placed / state" items:#() pos:[8,34] width:146 height:7
        button addButton "Add" pos:[8,190] width:46 tooltip:"Create a new procedural layer."
        button copyButton "Copy" pos:[58,190] width:46 tooltip:"Copy settings and an independent Brush history into a new layer."
        button removeButton "Remove" pos:[108,190] width:46
        edittext nameEdit "Name:" pos:[8,222] width:146
        checkbox visibleCheck "Visible in viewport" pos:[8,250] width:146 tooltip:"Hides this layer's preview. Cached placement and final rendering are preserved."
        checkbox renderCheck "Enabled in final output" pos:[8,276] width:146 tooltip:"Disables this layer's placement, final rendering and blocking of other layers."
        label countInfo "No layer selected." pos:[8,306] width:146 height:76
        label countHelp "Counts show the last build.\nStale = Update is needed." pos:[8,387] width:146 height:36
        button helpButton "Layer details / help" pos:[8,430] width:146
        timer statusTimer interval:1000 active:false
        fn layoutPanels = true -- Native Max owns rollup sizing and expansion.
        fn refreshTitles = true
        fn refreshStats = (
            if not controlsReady or binding do return false
            local rows=#(),detail="No layer selected."
            for i=1 to layerObjects.count do (
                local layer=layerObjects[i],state=layer.uiLayerStats()
                local status=CyrusUILayerState state layerEnabled[i] cyrusEnabled (visibleLayer i and (layer.showPoints or layer.showCenters))
                append rows (layerNames[i]+" | "+(if state.hasResult then CyrusUICount state.placements compact:true else "--")+" | "+status[1])
                if i==activeLayer do (
                    detail=status[2]+"\nPlaced: "+(if state.hasResult then CyrusUICount state.placements else "--")
                    detail+="\n"+(if state.mode==1 then "Preview points: " else "Preview instances: ")+(if state.hasResult then CyrusUICount state.previewCount else "--")
                    detail+="\nBuild: "+(if state.hasResult then (state.buildMs as string)+" ms" else "--")
                    if layer.brushRelaxPaused() do detail+="\nRelax paused by Brush."
                    if state.errorText!="" do detail+="\n"+state.errorText
                )
            )
            local rowsChanged=rows.count!=lastRows.count
            if not rowsChanged do for i=1 to rows.count where rows[i]!=lastRows[i] do rowsChanged=true
            if rowsChanged do (
                binding=true;layerList.items=rows;layerList.selection=activeLayer;lastRows=rows;binding=false
            )
            if countInfo.text!=detail do countInfo.text=detail
            this.syncBrushCompatibility()
            true
        )
        fn bind = (
            binding=true
            local valid=selectedLayer()!=undefined
            enabledCheck.checked=cyrusEnabled
            layerList.selection=activeLayer
            for c in #(removeButton,nameEdit,visibleCheck,renderCheck) do c.enabled=valid
            addButton.enabled=layerObjects.count<10
            copyButton.enabled=valid and layerObjects.count<10
            nameEdit.text=if valid then layerNames[activeLayer] else ""
            visibleCheck.checked=valid and visibleLayer activeLayer
            renderCheck.checked=valid and layerEnabled[activeLayer]
            binding=false;refreshStats()
        )
        fn rebuild = bindNativeUI()
        fn rebuildLayers = bindNativeUI()
        fn selectLayerView layer expand:false = (
            local i=findItem layerObjects layer
            if i>0 do selectLayer i
            bindNativeUI()
        )
        on mainUI open do (syncLayerIdentity();controlsReady=true;statusTimer.active=true;bind())
        on mainUI close do (controlsReady=false;statusTimer.active=false)
        on statusTimer tick do if mainUI.open and not CyrusInteractionHeld() do refreshStats()
        on layerList selected i do if not binding and i>0 do (selectLayer i;bindNativeUI())
        on enabledCheck changed value do if not binding do (undo "Cyrus Scatter enabled" on cyrusEnabled=value;CyrusViewportRedraw();bind())
        on visibleCheck changed value do if not binding and selectedLayer()!=undefined do (
            undo "Cyrus layer viewport visibility" on layerVisible[activeLayer]=value
            CyrusViewportRedraw();bind()
        )
        on renderCheck changed value do if not binding and selectedLayer()!=undefined do (
            undo "Cyrus layer output enabled" on layerEnabled[activeLayer]=value
            CyrusViewportRedraw();bind()
        )
        on nameEdit entered value do if not binding and selectedLayer()!=undefined and value!="" do (
            undo "Cyrus layer name" on layerNames[activeLayer]=value
            bindNativeUI()
        )
        on addButton pressed do (newLayer();syncLayerIdentity();bindNativeUI();CyrusViewportRedraw())
        on copyButton pressed do copySelectedLayer()
        on removeButton pressed do (removeLayer();bindNativeUI();CyrusViewportRedraw())
        on helpButton pressed do (
            local layer=selectedLayer(),message="Select a layer to edit its sources and settings.\nNative rollout headers open with one click.\n\nVisible in viewport hides only the cached preview.\nEnabled in final output controls generation, rendering and blockers.\nPlaced is the last generated count; Preview counts visible points or instances within the current display budget.\nLimited means the geometry preview displays a subset; check its instance/face budget.\nBuild is preview preparation time, not FPS.\nStale means settings changed and Update is needed.\n\nBrush: choose one static receiving mesh, then Paint or Erase. Count/density and randomization remain procedural. Manual mode publishes plants on Update.\nPainted density pauses Relax and Boundary Relax without changing their saved settings. Turn off Use painted density to use Relax. Collision and final cleanup remain available."
            if layer!=undefined do (message="Layer: "+layerNames[activeLayer]+"\n"+countInfo.text+"\n\n"+message;if layer.previewError!="" do message+="\n\nFull error:\n"+layer.previewError)
            messageBox message title:"Cyrus Scatter 1.0"
        )
    )
