    local layerPanels=#(),updateUI,surfaceUI,previewUI,layersUI,uiFlowState=#(),uiRootState=#()
    fn nativeEditors = (for r in #(updateUI,surfaceUI,previewUI,layersUI) where r!=undefined collect r)
    fn nativeLayerSlots = #(this.layerPanel_1,this.layerPanel_2,this.layerPanel_3,this.layerPanel_4,this.layerPanel_5,this.layerPanel_6,this.layerPanel_7,this.layerPanel_8,this.layerPanel_9,this.layerPanel_10)
    fn brushEditors = (local result=#();for p in layerPanels where p.mounted do for r in p.editors where isProperty r #refreshHistory do append result r;result)
    fn refreshBrushEditors history:false = (for r in this.brushEditors() where r.controlsReady do (if history do r.refreshHistory();r.status()))
    fn syncBrushCompatibility = (
        for p in layerPanels where p.mounted do for r in p.editors where r.controlsReady do (
            if isProperty r #syncRelaxAvailability do r.syncRelaxAvailability()
            if isProperty r #syncFinalRelaxAvailability do r.syncFinalRelaxAvailability()
        )
    )
    fn bindNativeUI = (if this.mainUI.controlsReady do this.mainUI.bind();true)
    rollout mainUI "Cyrus Scatter 1.2" width:#cmdPanel height:30 autoLayoutOnResize:true (
        local root=undefined,controlsReady=false,binding=false,layingOut=false,layoutHold=0,roots=#(),nativeFlow=true
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16)
        timer mountTimer interval:1 active:false
        timer statusTimer interval:1000 active:false
        fn showPage page shown category = (
            if not (cyrusSetRolloutVisible page.hwnd shown category) do throw ("Cannot arrange Cyrus command-panel page: "+page.title)
        )
        fn bindScrolling = (
            if controlsReady and cyrusBindRolloutScroll!=undefined do (
                cyrusBindRolloutScroll mainUI.hwnd
                for r in root.layerPanels do cyrusBindRolloutScroll r.hwnd
            )
        )
        fn layoutPanels = (
            if not controlsReady or layoutHold>0 or layingOut do return false
            layingOut=true
            try (
                for p in root.layerPanels where p.mounted do p.fitHeight()
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
                local slots=root.nativeLayerSlots()
                -- Only structural layer changes remount editors. Resizing and
                -- opening retain controls and never regenerate placements.
                for p in slots do (
                    cyrusReleaseRolloutScroll p.hwnd
                    p.open=false;p.unmount();p.owner=undefined
                    showPage p false (100+p.slot)
                )
                root.layerPanels=#()
                for i=1 to parents.count do (
                    local p=slots[i],previous=undefined
                    p.owner=parents[i];p.controlsReady=true
                    for state in states where state[1]==parents[i] do previous=state
                    append root.layerPanels p
                    if previous!=undefined do p.sectionOpenState=previous[3]
                    p.bind();showPage p true (100+i)
                    if previous!=undefined and previous[2] do (p.open=true;p.mount())
                )
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
            -- Initialize once after Max constructs all plugin pages.
            controlsReady=false;mountTimer.active=true
        )
        on mountTimer tick do (
            mountTimer.active=false
            if cyrusSetRolloutVisible==undefined do throw "Install the matching Cyrus 0.7 native plugin and restart Max."
            root.syncLayerIdentity();layoutHold=1
            roots=#(root.flow_updateUI,root.flow_surfaceUI,root.flow_previewUI,root.flow_layersUI)
            root.updateUI=roots[1];root.surfaceUI=roots[2];root.previewUI=roots[3];root.layersUI=roots[4]
            for i=1 to roots.count where i<=root.uiRootState.count do roots[i].open=root.uiRootState[i]
            showPage mainUI true 0
            for i=1 to roots.count do showPage roots[i] true (i*10)
            for p in root.nativeLayerSlots() do showPage p false (100+p.slot)
            controlsReady=true;statusTimer.active=true;layoutHold=0;bind();bindScrolling()
        )
        on mainUI close do (
            if cyrusReleaseRolloutScroll!=undefined do (
                cyrusReleaseRolloutScroll mainUI.hwnd
                for p in root.layerPanels do cyrusReleaseRolloutScroll p.hwnd
            )
            root.uiRootState=for r in roots collect r.open
            root.uiFlowState=for p in root.layerPanels collect #(p.owner,p.open,if p.mounted then (for r in p.editors collect r.open) else p.sectionOpenState)
            controlsReady=false;statusTimer.active=false;mountTimer.active=false;roots=#();root.layerPanels=#()
            root.updateUI=root.surfaceUI=root.previewUI=root.layersUI=undefined
        )
        on statusTimer tick do if not CyrusInteractionHeld() do (
            local sourceChanges=false
            for leaf in root.layerObjects where leaf.containerUIChanged do (leaf.containerUIChanged=false;sourceChanges=true)
            if sourceChanges then bind() else refreshStats()
        )
        on enabledCheck changed value do if not binding do (undo "Cyrus enabled" on root.cyrusEnabled=value;root.invalidateGroups();bind())
    )
