    rollout mainUI "Cyrus Scatter 0.85.1" width:#cmdPanel height:140 autoLayoutOnResize:true (
        local view=undefined,root=undefined,controlsReady=false,binding=false,layerBinding=false,roots=#(),editors=#(),slots=#(),owner=undefined,layerPagesVisible=false,pagesArranged=false,resizing=false
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16) tooltip:"Enable calculation and output for the entire setup."
        radiobuttons updateRadio "Viewport update" labels:#("Manual","Live") columns:2 pos:[8,26] width:(mainUI.width-16) tooltip:"Manual waits for Update. Live calculates after relevant edits."
        button updateNow "Update scatter" pos:[8,64] width:(mainUI.width-16) height:22 tooltip:"Generate or refresh the enabled layers using their current surfaces, models and amount."
        label updateHint "" pos:[8,90] width:(mainUI.width-16) height:18
        button licenseButton "License / activation..." pos:[8,112] width:(mainUI.width-16) height:22 tooltip:"Import a team license or inspect its expiry. Existing scenes remain available after expiry."
        timer mountTimer interval:1 active:false
        timer statusTimer interval:1000 active:false
        fn layoutPanels = (for i=1 to editors.count where editors[i].controlsReady and slots[i].open do editors[i].layout();true)
        fn resizeSection index = (
            if resizing or index>editors.count do return false
            local section=editors[index],slot=slots[index],target=amax 100 slot.width
            if not section.isDisplayed do return false
            resizing=true
            try (
                if slot.body.width!=target do slot.body.width=target
                -- The subrollout has its own margins. Its child HWND gives the
                -- actual available width in logical UI units at the current DPI.
                local available=amax 100 (amin (slot.width-8) (windows.getWindowPos section.hwnd removeUIScaling:true).w)
                if section.controlsReady and section.lastLayoutWidth!=available do section.layout()
                resizing=false;true
            )catch(resizing=false;throw())
        )
        fn rememberViews = (
            if not controlsReady or binding or layerBinding or view==undefined do return false
            local previous=view.uiPresentationState
            view.uiPresentationState=for i=1 to editors.count collect (
                if editors[i].isDisplayed then editors[i].captureView()
                else if i<=previous.count and previous[i]!=undefined then #(slots[i].open,previous[i][2],previous[i][3])
                else #(slots[i].open,undefined,undefined)
            )
            true
        )
        fn refreshTitles = (CyrusContainerRefreshLabels root;true)
        fn refreshStats = (
            if not controlsReady do return false
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.refreshStats()
            if root.surfaceUI!=undefined and root.surfaceUI.controlsReady do root.surfaceUI.refreshStats()
            if root.statisticsUI.controlsReady and slots[12].open do if root.statisticsUI.detailsUI_refreshStats() do root.statisticsUI.layout()
            root.syncBrushAvailability();true
        )
        fn bindSection section = (
            if not controlsReady or root==undefined do return false
            local index=findItem editors section
            if index==0 do return false
            section.root=root;section.owner=owner;section.panel=mainUI
            if slots[index].open then (
                if not section.isDisplayed do (
                    local measurement=CyrusMeasureBegin 12
                    try (
                        addSubRollout slots[index].body section rolledUp:false
                        -- The outer slot supplies the single visible header. Crop
                        -- the nested header using its measured logical extent;
                        -- Max keeps ownership through addSubRollout throughout.
                        local innerRect=windows.getWindowPos section.hwnd removeUIScaling:true
                        local slotRect=windows.getWindowPos slots[index].hwnd removeUIScaling:true
                        slots[index].headerInset=amax 0 (innerRect.y-slotRect.y)
                        slots[index].body.pos=[0,-slots[index].headerInset]
                    )catch(CyrusMeasureEnd measurement root.layerID root.procEpoch (section.name as string) failed:true;throw())
                    CyrusMeasureEnd measurement root.layerID root.procEpoch (section.name as string)
                    -- addSubRollout initializes body locals. Bind owners only
                    -- afterwards; the first opening must be fully interactive.
                    section.hostPage=slots[index]
                    section.root=root;section.owner=owner;section.panel=mainUI
                    if index<=view.uiPresentationState.count do section.restoreView view.uiPresentationState[index]
                )
                resizeSection index
                section.bind owner
            ) else section.controlsReady=false
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
                    if not pagesArranged or layerPagesVisible!=showPages do if not (cyrusSetRolloutVisible slots[i].hwnd visible (i*10)) do throw "Cannot arrange Cyrus settings."
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
        fn rebuild = bind()
        fn rebuildLayers = rebuild()
        fn selectLayerView layer = (
            if layer==undefined do return false
            local parent=root.logicalParent layer
            local action=CyrusBeginAction root "select_layer";CyrusEndAction action
            if root.selectedLayer()!=parent do undo off root.selectLayer (findItem root.layerObjects parent)
            bindEditors()
            true
        )
        on mainUI open do (view=this;controlsReady=false;mountTimer.active=true)
        on mountTimer tick do (
            if not mainUI.isDisplayed do return false
            mountTimer.active=false
            if cyrusSetRolloutVisible==undefined do throw "Load the matching Cyrus 0.85.1 native plugin and restart Max."
            root=view
            view.managerUI=createmanagerUI();view.surfacesUI=createsurfacesUI();view.modelsUI=createmodelsUI();view.containersUI=createcontainersUI()
            view.layoutUI=createlayoutUI();view.populationUI=createpopulationUI();view.coverageUI=createcoverageUI();view.areasUI=createareasUI()
            view.transformsUI=createtransformsUI();view.spacingUI=createspacingUI();view.displayUI=createdisplayUI();view.statisticsUI=createstatisticsUI()
            editors=#(view.managerUI,view.surfacesUI,view.modelsUI,view.containersUI,view.layoutUI,view.populationUI,view.coverageUI,view.areasUI,view.transformsUI,view.spacingUI,view.displayUI,view.statisticsUI)
            slots=#(view.managerUISlot,view.surfacesUISlot,view.modelsUISlot,view.containersUISlot,view.layoutUISlot,view.populationUISlot,view.coverageUISlot,view.areasUISlot,view.transformsUISlot,view.spacingUISlot,view.displayUISlot,view.statisticsUISlot)
            if root==undefined do (
                for r in slots do cyrusSetRolloutVisible r.hwnd false 0
                return false
            )
            root.syncLayerIdentity()
            roots=#(view.surfacesUI,view.displayUI,view.managerUI)
            root.updateUI=undefined;root.surfaceUI=roots[1];root.previewUI=roots[2];root.layersUI=roots[3]
            owner=undefined;pagesArranged=false
            for r in editors do (r.root=root;r.owner=undefined;r.panel=mainUI;r.controlsReady=false)
            if view.uiPresentationState.count==editors.count then (
                for i=1 to editors.count do slots[i].open=view.uiPresentationState[i][1]
            ) else (
                for r in slots do r.open=false
                slots[2].open=(root.validSurfaces()).count==0;slots[1].open=true
            )
            cyrusSetRolloutVisible mainUI.hwnd true 0
            controlsReady=true;bind();rememberViews()
            -- Max measured these pages before bind assigned their final heights.
            -- Reflow once after all bodies, including the container, are ready.
            cyrusSetRolloutVisible mainUI.hwnd true 0
        )
        on mainUI close do (
            controlsReady=false;statusTimer.active=false;mountTimer.active=false
            for r in editors do (r.controlsReady=false;r.root=undefined;r.owner=undefined;r.obj=undefined)
            roots=#();editors=#();slots=#();owner=undefined;layerPagesVisible=false
            if root!=undefined do root.updateUI=root.surfaceUI=root.previewUI=root.layersUI=undefined
            root=undefined
        )
        on statusTimer tick do (
            statusTimer.active=false
            if not controlsReady or root==undefined do return false
            if CyrusInteractionHeld() do (statusTimer.active=true;return false)
            local sourceChanges=false
            for leaf in root.layerObjects where leaf.containerUIChanged do (leaf.containerUIChanged=false;sourceChanges=true)
            if sourceChanges then root.bindNativeUI() else refreshStats()
        )
        on licenseButton pressed do CyrusOpenLicenseDialog()
        on enabledCheck changed value do if controlsReady and root!=undefined and not binding and CyrusLicenseCanEdit() do (local action=CyrusBeginAction root "setup_enabled";try(undo "Cyrus enabled" on root.cyrusEnabled=value;root.invalidateGroups();bind();CyrusEndAction action)catch(CyrusEndAction action;throw()))
        on updateNow pressed do if controlsReady and root!=undefined and not binding and CyrusLicenseCanEdit() do (local action=CyrusBeginAction root "explicit_update";try(root.refreshAll();CyrusViewportRedraw();CyrusEndAction action)catch(CyrusEndAction action;throw()))
        on updateRadio changed value do if controlsReady and root!=undefined and not binding and CyrusLicenseCanEdit() do (local action=CyrusBeginAction root "update_mode";try(root.updateMode=value;root.markInputDirty();bind();CyrusViewportRedraw();CyrusEndAction action)catch(CyrusEndAction action;throw()))
    )
