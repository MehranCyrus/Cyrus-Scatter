    rollout mainUI "Cyrus Scatter 0.74" width:#cmdPanel height:112 autoLayoutOnResize:true (
        local view=undefined,root=undefined,controlsReady=false,binding=false,layerBinding=false,roots=#(),editors=#(),owner=undefined,layerPagesVisible=false,pagesArranged=false
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16) tooltip:"Enable calculation and output for the entire setup."
        radiobuttons updateRadio "Viewport update" labels:#("Manual","Live") columns:2 pos:[8,26] width:(mainUI.width-16) tooltip:"Manual waits for Update. Live calculates after relevant edits."
        button updateNow "Update now" pos:[8,64] width:(mainUI.width-16) height:22 tooltip:"Calculate enabled layers and paint sets in their visible evaluation order."
        label updateHint "" pos:[8,90] width:(mainUI.width-16) height:18
        timer mountTimer interval:1 active:false
        timer statusTimer interval:1000 active:false
        fn layoutPanels = (for r in editors where r.controlsReady and r.open do r.layout();true)
        fn rememberViews = (
            if not controlsReady or binding or layerBinding or view==undefined do return false
            view.uiPresentationState=for r in editors collect r.captureView()
            true
        )
        fn refreshTitles = (CyrusContainerRefreshLabels root;CyrusBindLayerEditor root;true)
        fn refreshStats = (
            if not controlsReady do return false
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.refreshStats()
            if root.surfaceUI!=undefined and root.surfaceUI.controlsReady do root.surfaceUI.refreshStats()
            root.syncBrushCompatibility();true
        )
        fn bindSection section = (
            if not controlsReady or root==undefined do return false
            section.root=root;section.owner=owner;section.panel=mainUI
            if section.open then section.bind owner else section.controlsReady=false
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
                    for r in editors do (r.root=root;r.owner=owner;r.panel=mainUI;r.controlsReady=false;r.obj=undefined)
                )
                local showPages=owner!=undefined
                for i=1 to editors.count do (
                    local visible=not editors[i].layerPage or showPages
                    if not pagesArranged or layerPagesVisible!=showPages do if not (cyrusSetRolloutVisible editors[i].hwnd visible (i*10)) do throw "Cannot arrange Cyrus settings."
                    if visible do bindSection editors[i]
                )
                pagesArranged=true;layerPagesVisible=showPages;refreshTitles();layerBinding=false;true
            )catch(layerBinding=false;throw())
        )
        fn bind = (
            if binding or not controlsReady or root==undefined do return false
            binding=true
            try (
                enabledCheck.checked=root.cyrusEnabled;updateRadio.state=root.updateMode
                updateHint.text=if root.updateMode==1 then "Pending edits wait for Update." else "Updates after relevant edits."
                bindEditors();binding=false;refreshStats()
                if mainUI.isDisplayed do cyrusSetRolloutVisible mainUI.hwnd true 0
                true
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
            true
        )
        on mainUI open do (view=this;controlsReady=false;mountTimer.active=true)
        on mountTimer tick do (
            if not mainUI.isDisplayed do return false
            mountTimer.active=false
            if cyrusSetRolloutVisible==undefined do throw "Load the matching Cyrus 0.74 native plugin and restart Max."
            local context=if classof view==CyrusSourceContainer then CyrusContainerResolve view else undefined
            root=if classof view==CyrusSourceContainer then (if context==undefined then undefined else context[1]) else view
            editors=#(view.managerUI,view.surfacesUI,view.modelsUI,view.populationUI,view.coverageUI,view.areasUI,view.transformsUI,view.spacingUI,view.displayUI,view.statisticsUI)
            if root==undefined do (
                for r in editors do (r.controlsReady=false;cyrusSetRolloutVisible r.hwnd false 0)
                if isProperty view #containerUI do view.containerUI.bind()
                return false
            )
            if context!=undefined and context[2]!=undefined do undo off (root.selectLayer (findItem root.layerObjects (root.logicalParent context[2]));(root.logicalParent context[2]).uiPaintSetID=context[2].layerID)
            root.syncLayerIdentity()
            roots=#(view.surfacesUI,view.displayUI,view.managerUI)
            root.updateUI=undefined;root.surfaceUI=roots[1];root.previewUI=roots[2];root.layersUI=roots[3]
            owner=undefined;pagesArranged=false
            for r in editors do (r.root=root;r.owner=undefined;r.panel=mainUI;r.controlsReady=false)
            if view.uiPresentationState.count==editors.count then (
                for i=1 to editors.count do editors[i].restoreView view.uiPresentationState[i]
            ) else (
                for r in editors do r.open=false
                roots[1].open=(root.validSurfaces()).count==0;roots[3].open=true
            )
            cyrusSetRolloutVisible mainUI.hwnd true 0
            controlsReady=true;bind();rememberViews()
            if isProperty view #containerUI do view.containerUI.bind()
            -- Max measured these pages before bind assigned their final heights.
            -- Reflow once after all bodies, including the container, are ready.
            cyrusSetRolloutVisible mainUI.hwnd true 0
        )
        on mainUI close do (
            controlsReady=false;statusTimer.active=false;mountTimer.active=false
            for r in editors do (r.controlsReady=false;r.root=undefined;r.owner=undefined;r.obj=undefined)
            roots=#();editors=#();owner=undefined;layerPagesVisible=false
            if root!=undefined do root.updateUI=root.surfaceUI=root.previewUI=root.layersUI=undefined
            root=undefined
        )
        on statusTimer tick do (
            statusTimer.active=false
            if not controlsReady or root==undefined do return false
            if CyrusInteractionHeld() do (statusTimer.active=true;return false)
            local sourceChanges=false
            for leaf in root.layerObjects where leaf.containerUIChanged do (leaf.containerUIChanged=false;sourceChanges=true)
            if isProperty view #containerUI do view.containerUI.bind()
            if sourceChanges then root.bindNativeUI() else refreshStats()
        )
        on enabledCheck changed value do if controlsReady and root!=undefined and not binding do (undo "Cyrus enabled" on root.cyrusEnabled=value;root.invalidateGroups();bind())
        on updateNow pressed do if controlsReady and root!=undefined and not binding do (root.refreshAll();CyrusViewportRedraw())
        on updateRadio changed value do if controlsReady and root!=undefined and not binding do (root.updateMode=value;root.markInputDirty();bind();CyrusViewportRedraw())
    )
