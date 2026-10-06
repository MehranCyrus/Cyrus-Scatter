    local updateUI,surfaceUI,previewUI,layersUI,uiRootState=#()
    fn nativeEditors = (for r in #(updateUI,surfaceUI,previewUI,layersUI) where r!=undefined collect r)
    fn brushEditors = (CyrusLayerEditorSections this method:#refreshHistory)
    fn refreshBrushEditors history:false = (for r in this.brushEditors() where r.controlsReady do (if history do r.refreshHistory();r.status()))
    fn syncBrushCompatibility = (
        for r in CyrusLayerEditorSections this where r.controlsReady do (
            if isProperty r #syncRelaxAvailability do r.syncRelaxAvailability()
            if isProperty r #syncFinalRelaxAvailability do r.syncFinalRelaxAvailability()
        )
    )
    fn bindNativeUI = (
        if this.mainUI.controlsReady do this.mainUI.bind()
        CyrusBindLayerEditor this
        true
    )
    rollout mainUI "Cyrus Scatter 1.2" width:#cmdPanel height:30 autoLayoutOnResize:true (
        local root=undefined,controlsReady=false,binding=false,roots=#()
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16) tooltip:"Enable calculation and output for this entire Scatter setup."
        timer mountTimer interval:1 active:false
        timer statusTimer interval:1000 active:false
        fn layoutPanels = true
        fn refreshTitles = (CyrusBindLayerEditor root;true)
        fn refreshStats = (
            if not controlsReady do return false
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.refreshStats()
            if root.surfaceUI!=undefined and root.surfaceUI.controlsReady do root.surfaceUI.refreshStats()
            root.syncBrushCompatibility();true
        )
        fn bind = (
            if binding or not controlsReady do return false
            binding=true
            try (
                enabledCheck.checked=root.cyrusEnabled
                for r in root.nativeEditors() where r.controlsReady do r.bind undefined
                binding=false;refreshStats();true
            )catch(binding=false;throw())
        )
        fn rebuild = (bind();CyrusBindLayerEditor root)
        fn rebuildLayers = rebuild()
        fn selectLayerView layer expand:false = (
            if layer==undefined do return false
            local parent=root.logicalParent layer
            if root.selectedLayer()!=parent do undo off root.selectLayer (findItem root.layerObjects parent)
            if expand or (CyrusLayerEditor!=undefined and CyrusLayerEditor.root==root) do CyrusOpenLayerEditor root parent
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.bind undefined
            true
        )
        on mainUI open do (root=this;controlsReady=false;mountTimer.active=true)
        on mountTimer tick do (
            mountTimer.active=false
            if cyrusSetRolloutVisible==undefined do throw "Load the matching Cyrus 0.7.1 native plugin and restart Max."
            root.syncLayerIdentity()
            roots=#(root.flow_updateUI,root.flow_surfaceUI,root.flow_layersUI,root.flow_previewUI)
            root.updateUI=roots[1];root.surfaceUI=roots[2];root.layersUI=roots[3];root.previewUI=roots[4]
            for i=1 to roots.count do (
                roots[i].open=if i<=root.uiRootState.count then root.uiRootState[i] else (i==3 or (i==2 and (root.validSurfaces()).count==0))
                if not (cyrusSetRolloutVisible roots[i].hwnd true (i*10)) do throw "Cannot arrange Cyrus setup controls."
            )
            cyrusSetRolloutVisible mainUI.hwnd true 0
            controlsReady=true;bind()
        )
        on mainUI close do (
            root.uiRootState=for r in roots collect r.open
            controlsReady=false;statusTimer.active=false;mountTimer.active=false;roots=#()
            root.updateUI=root.surfaceUI=root.previewUI=root.layersUI=undefined
            -- The modeless editor keeps its explicitly bound owner when scene
            -- selection changes. Command-panel lifetime does not own it.
        )
        on statusTimer tick do (
            statusTimer.active=false
            if CyrusInteractionHeld() do (statusTimer.active=true;return false)
            local sourceChanges=false
            for leaf in root.layerObjects where leaf.containerUIChanged do (leaf.containerUIChanged=false;sourceChanges=true)
            if sourceChanges then root.bindNativeUI() else refreshStats()
        )
        on enabledCheck changed value do if not binding do (undo "Cyrus enabled" on root.cyrusEnabled=value;root.invalidateGroups();bind())
    )
