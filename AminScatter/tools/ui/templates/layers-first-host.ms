    local layerPanels=#(),updateUI,surfaceUI,previewUI,layersUI,uiFlowState=#(),uiRootState=#()
    fn nativeEditors = (for r in #(updateUI,surfaceUI,previewUI,layersUI) where r!=undefined collect r)
    fn brushEditors = (local result=#();for p in layerPanels where p.mounted do for r in p.editors where isProperty r #refreshHistory do append result r;result)
    fn refreshBrushEditors history:false = (for r in this.brushEditors() where r.controlsReady do (if history do r.refreshHistory();r.status()))
    fn syncBrushCompatibility = (
        for p in layerPanels where p.mounted do for r in p.editors where r.controlsReady do (
            if isProperty r #syncRelaxAvailability do r.syncRelaxAvailability()
            if isProperty r #syncFinalRelaxAvailability do r.syncFinalRelaxAvailability()
        )
    )
    fn bindNativeUI = (if this.mainUI.controlsReady do this.mainUI.bind();true)
    rollout mainUI "Cyrus Scatter 1.2" width:#cmdPanel autoLayoutOnResize:true (
        local root=undefined,controlsReady=false,binding=false,layingOut=false,layoutHold=0,dpiScale=1.0,roots=#()
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16)
        subrollout panels "" pos:[0,30] width:(mainUI.width) height:24 scrollBar:#off autoLayoutOnResize:true
        timer statusTimer interval:1000 active:false
        fn bindScrolling = (
            -- Install only after structural mounting. Normal layout and stats
            -- updates retain these native gesture routes without polling.
            if controlsReady and cyrusBindRolloutScroll!=undefined do cyrusBindRolloutScroll mainUI.hwnd
        )
        fn layoutPanels = (
            if not controlsReady or layoutHold>0 or layingOut do return false
            layingOut=true
            try (
                for p in root.layerPanels where p.mounted do p.fitHeight()
                local height=0
                for r in roots do height+=CyrusFlowRolloutExtent r
                for p in root.layerPanels do height+=CyrusFlowRolloutExtent p
                height=amax 1 height
                if panels.height!=height do panels.height=height
                if mainUI.height!=height+36 do mainUI.height=height+36
                layingOut=false;true
            )catch(layingOut=false;throw())
        )
        fn refreshTitles = (for p in root.layerPanels do p.refreshStats())
        fn refreshStats = (
            if not controlsReady do return false
            for p in root.layerPanels do p.refreshStats()
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.refreshStats()
            if root.surfaceUI!=undefined and root.surfaceUI.controlsReady do root.surfaceUI.refreshStats()
            root.syncBrushCompatibility();true
        )
        fn rebuildLayers = (
            local parents=root.logicalLayers(),same=parents.count==root.layerPanels.count
            if same do for i=1 to parents.count where root.layerPanels[i].owner!=parents[i] do same=false
            if same do return false
            layoutHold+=1
            local selected=root.selectedLayer()
            local states=for p in root.layerPanels collect #(p.owner,p.open,if p.mounted then (for r in p.editors collect r.open) else p.sectionOpenState)
            if states.count==0 do states=root.uiFlowState
            try (
                for p in root.layerPanels do removeSubRollout panels p
                root.layerPanels=#()
                for i=1 to parents.count do (
                    local p=CyrusCreateLayerPanel i root parents[i],previous=undefined
                    for state in states where state[1]==parents[i] do previous=state
                    append root.layerPanels p
                    addSubRollout panels p rolledUp:true
                    -- Rollout locals initialize when installed in the host.
                    if previous!=undefined do p.sectionOpenState=previous[3]
                    if previous!=undefined and previous[2] do (
                        p.open=true;p.mount()
                    )
                )
                -- Restoring expanded headers fires selection events. Keep the
                -- user's selection, including a newly added layer.
                if selected!=undefined and findItem root.layerObjects selected>0 and root.selectedLayer()!=selected do undo off root.activeLayer=findItem root.layerObjects selected
                layoutHold-=1;layoutPanels();bindScrolling();true
            )catch(layoutHold-=1;throw())
        )
        fn bind = (
            if binding or not controlsReady do return false
            binding=true;layoutHold+=1
            try (
                enabledCheck.checked=root.cyrusEnabled
                rebuildLayers()
                for r in root.nativeEditors() where r.controlsReady do r.bind undefined
                for p in root.layerPanels do p.bind()
                binding=false;layoutHold-=1;refreshStats();layoutPanels();true
            )catch(binding=false;layoutHold-=1;throw())
        )
        fn rebuild = bind()
        fn selectLayerView layer expand:false = (
            if layer==undefined do return false
            local parent=root.logicalParent layer
            if root.selectedLayer()!=parent do undo off root.selectLayer (findItem root.layerObjects parent)
            for p in root.layerPanels where p.owner==parent do (if expand do (p.open=true;p.mount());p.bind())
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.bind undefined
            layoutPanels();true
        )
        on mainUI open do (
            root=this
            root.syncLayerIdentity();layoutHold=1
            roots=CyrusCreateFlowRoots root
            root.updateUI=roots[1];root.surfaceUI=roots[2];root.previewUI=roots[3];root.layersUI=roots[4]
            for i=1 to roots.count do (
                addSubRollout panels roots[i] rolledUp:true
                if i<=root.uiRootState.count do roots[i].open=root.uiRootState[i]
            )
            controlsReady=true;statusTimer.active=true;layoutHold=0;bind()
        )
        on mainUI close do (
            if cyrusReleaseRolloutScroll!=undefined do cyrusReleaseRolloutScroll mainUI.hwnd
            root.uiRootState=for r in roots collect r.open
            root.uiFlowState=for p in root.layerPanels collect #(p.owner,p.open,if p.mounted then (for r in p.editors collect r.open) else p.sectionOpenState)
            controlsReady=false;statusTimer.active=false;roots=#();root.layerPanels=#()
            root.updateUI=root.surfaceUI=root.previewUI=root.layersUI=undefined
        )
        on statusTimer tick do if not CyrusInteractionHeld() do refreshStats()
        on enabledCheck changed value do if not binding do (undo "Cyrus enabled" on root.cyrusEnabled=value;root.invalidateGroups();bind())
    )
