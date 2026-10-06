    local updateUI,surfaceUI,previewUI,layersUI,uiRootState=#()
    fn nativeEditors = (for r in #(updateUI,surfaceUI,previewUI,layersUI) where r!=undefined collect r)
    fn brushEditors = (
        local editors=CyrusLayerEditorSections this method:#refreshHistory
        if this.mainUI.controlsReady do for r in this.mainUI.editors where isProperty r #refreshHistory and r.controlsReady do appendIfUnique editors r
        editors
    )
    fn refreshBrushEditors history:false = (for r in this.brushEditors() where r.controlsReady do (if history do r.refreshHistory();r.status()))
    fn syncBrushCompatibility = (
        local editors=CyrusLayerEditorSections this
        if this.mainUI.controlsReady do join editors this.mainUI.editors
        for r in editors where r.controlsReady do (
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
        local root=undefined,controlsReady=false,binding=false,layerBinding=false,roots=#(),editors=#(),owner=undefined,layerPagesVisible=false
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16) tooltip:"Enable calculation and output for this entire Scatter setup."
        timer mountTimer interval:1 active:false
        timer statusTimer interval:1000 active:false
        fn layoutPanels = true
        fn refreshTitles = (
            if owner!=undefined and root.selected_setsUI!=undefined do root.selected_setsUI.title="Paint sets | "+(root.layerCaption owner)
            CyrusBindLayerEditor root;true
        )
        fn refreshStats = (
            if not controlsReady do return false
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.refreshStats()
            if root.surfaceUI!=undefined and root.surfaceUI.controlsReady do root.surfaceUI.refreshStats()
            root.syncBrushCompatibility();true
        )
        fn bindSection section = (
            if not controlsReady or owner==undefined or findItem root.layerObjects owner==0 do return false
            section.root=root;section.owner=owner;section.panel=mainUI
            if section.open then section.bind (if isProperty section #setSpecific and section.setSpecific then root.selectedPaintSet owner else owner)
            else section.controlsReady=false
            true
        )
        fn bindEditors = (
            if not controlsReady or layerBinding do return false
            layerBinding=true
            try (
            local leaf=root.selectedLayer(),nextOwner=if leaf==undefined then undefined else root.logicalParent leaf
            if nextOwner!=owner do (
                if CyrusBrushSessionRoot==root do CyrusStopBrush()
                max select
                owner=nextOwner
                for r in editors do (
                    r.root=root;r.owner=owner;r.panel=mainUI;r.controlsReady=false
                    if isProperty r #obj do r.obj=undefined
                )
            )
            local showPages=owner!=undefined
            if layerPagesVisible!=showPages do (
                for i=1 to editors.count do if not (cyrusSetRolloutVisible editors[i].hwnd showPages (40+i*10)) do throw "Cannot arrange selected-layer controls."
                layerPagesVisible=showPages
            )
            if owner!=undefined do for r in editors do bindSection r
            refreshTitles();layerBinding=false;true
            )catch(layerBinding=false;throw())
        )
        fn bind = (
            if binding or not controlsReady do return false
            binding=true
            try (
                enabledCheck.checked=root.cyrusEnabled
                for r in root.nativeEditors() where r.controlsReady do r.bind undefined
                bindEditors();binding=false;refreshStats();true
            )catch(binding=false;throw())
        )
        fn rebuild = (bind();CyrusBindLayerEditor root)
        fn rebuildLayers = rebuild()
        fn selectLayerView layer expand:false = (
            if layer==undefined do return false
            local parent=root.logicalParent layer
            if root.selectedLayer()!=parent do undo off root.selectLayer (findItem root.layerObjects parent)
            bindEditors()
            if expand then CyrusOpenLayerEditor root parent
            else if CyrusLayerEditor!=undefined and CyrusLayerEditor.root==root do CyrusLayerEditor.retarget root parent
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.bind undefined
            true
        )
        on mainUI open do (root=this;controlsReady=false;mountTimer.active=true)
        on mountTimer tick do (
            mountTimer.active=false
            if cyrusSetRolloutVisible==undefined do throw "Load the matching Cyrus 0.7.1 native plugin and restart Max."
            root.syncLayerIdentity()
            roots=#(root.flow_updateUI,root.flow_surfaceUI,root.flow_previewUI,root.flow_layersUI)
            root.updateUI=roots[1];root.surfaceUI=roots[2];root.previewUI=roots[3];root.layersUI=roots[4]
            editors=#(__SELECTED_PAGES__)
            owner=undefined;layerPagesVisible=false
            for r in editors do (r.root=root;r.owner=undefined;r.panel=mainUI;r.controlsReady=false;r.open=false)
            for i=1 to editors.count do if not (cyrusSetRolloutVisible editors[i].hwnd false (40+i*10)) do throw "Cannot arrange selected-layer controls."
            root.diagnosticsUI.root=root;root.diagnosticsUI.open=false
            if not (cyrusSetRolloutVisible root.diagnosticsUI.hwnd true 220) do throw "Cannot arrange diagnostic controls."
            for i=1 to roots.count do (
                roots[i].open=if i<=root.uiRootState.count then root.uiRootState[i] else (i==4 or (i==2 and (root.validSurfaces()).count==0))
                if not (cyrusSetRolloutVisible roots[i].hwnd true (i*10)) do throw "Cannot arrange Cyrus setup controls."
            )
            cyrusSetRolloutVisible mainUI.hwnd true 0
            controlsReady=true;bind()
        )
        on mainUI close do (
            root.uiRootState=for r in roots collect r.open
            controlsReady=false;statusTimer.active=false;mountTimer.active=false;roots=#();editors=#();owner=undefined;layerPagesVisible=false
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
