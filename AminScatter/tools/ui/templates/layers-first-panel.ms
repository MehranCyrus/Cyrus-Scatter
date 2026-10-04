    rollout layerPanel "Layer" width:150 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,slot=CyrusLayerUISlot
        local editors=#(),sectionOpenState=#(),mounted=false,binding=false,controlsReady=false
        subrollout sections "" pos:[2,0] width:(layerPanel.width-4) height:1 scrollBar:#off autoLayoutOnResize:true
        fn fitHeight = (
            local height=0
            for r in editors do height+=CyrusFlowRolloutExtent r
            height=amax 1 height
            if sections.height!=height do sections.height=height
            if layerPanel.height!=height+4 do layerPanel.height=height+4
        )
        fn refreshStats = (
            if not controlsReady or findItem root.layerObjects owner==0 do return false
            local summary=CyrusFlowLayerSummary root owner
            local caption=(root.layerCaption owner)+" | "+(CyrusUICount summary[1] compact:true)
            if summary[3]!="Cached" do caption+=" | "+summary[3]
            if layerPanel.title!=caption do layerPanel.title=caption
        )
        fn bindEditors = (
            if mounted do for r in editors where r.controlsReady do r.bind (if isProperty r #setSpecific and r.setSpecific then root.selectedPaintSet owner else owner)
        )
        fn mount = (
            if mounted do return false
            root.mainUI.layoutHold+=1
            try (
                editors=CyrusCreateLayerEditors slot root owner layerPanel
                mounted=true
                for r in editors do addSubRollout sections r rolledUp:true
                for i=1 to (amin editors.count sectionOpenState.count) do editors[i].open=sectionOpenState[i]
                bindEditors();fitHeight()
                root.mainUI.layoutHold-=1;root.mainUI.layoutPanels();root.mainUI.bindScrolling();true
            )catch(root.mainUI.layoutHold-=1;throw())
        )
        fn bind = (
            if findItem root.layerObjects owner==0 do return false
            controlsReady=true;refreshStats();bindEditors()
        )
        on layerPanel open do bind()
        on layerPanel rolledUp state do (
            if layerPanel.open do (
                mount()
                -- Restoring headers during binding/Undo is layout work, not
                -- an artist selection. It must not mutate persisted parameters.
                if root.mainUI.controlsReady and root.mainUI.layoutHold==0 and not root.mainUI.binding do root.mainUI.selectLayerView owner
            )
            root.mainUI.layoutPanels()
        )
        on layerPanel close do (
            if mounted do sectionOpenState=for r in editors collect r.open
            controlsReady=false;mounted=false;editors=#()
        )
    )
