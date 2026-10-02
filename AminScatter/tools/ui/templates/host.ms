    rollout mainUI "Cyrus Scatter" width:#cmdPanel (
        local controlsReady=false,building=false,layingOut=false,selecting=false,controller,lastStatusAt=0
        local roots=#(),layerPanels=#(),dpiScale=1.0,contentWidth=0
        subrollout panels "" pos:[0,0] width:162 height:200 scrollBar:#off
        timer widthTimer interval:300 active:true
        fn fitWidth = (
            local h=mainUI.hwnd,p=windows.getParentHWND h
            if h==0 or p==0 do return false
            local b=windows.getWindowPos h,pb=windows.getWindowPos p
            -- Max can reset the HWND width during a height change. Repair that
            -- without treating it as a new command-panel width or remounting UI.
            local desired=amax 160 (pb.w-8),changed=abs(contentWidth-desired)>1
            -- Repaint the correction; otherwise stale narrow pixels persist until hover.
            if abs(b.w-desired)>1 or abs(b.x-pb.x-4)>1 do windows.setWindowPos h 4 (b.y-pb.y) desired b.h true
            if panels.width!=desired do panels.width=desired
            changed
        )
        fn layoutPanels = (
            if controlsReady and not building and not layingOut and not selecting do (
                layingOut=true
                try (
                local h=0
                dpiScale=mainUI.height as float / (amax 1 (windows.getWindowPos mainUI.hwnd).h)
                local header=floor(23.333*dpiScale+0.5)
                for r in layerPanels do r.fitHeight()
                for r in roots do h+=(if r.open then r.height+header else header)
                for r in layerPanels do h+=(if r.open then r.height+header else header)
                if panels.pos!=[0,0] do panels.pos=[0,0]
                if panels.height!=h do panels.height=h
                if mainUI.height!=h do mainUI.height=h
                fitWidth()
                )catch(layingOut=false;throw())
                layingOut=false
            )
        )
        fn refreshTitles = (
            for i=1 to layerPanels.count do (
                local label=controller.layerNames[i]+(if i==controller.activeLayer then " [active]" else "")
                if layerPanels[i].title!=label do layerPanels[i].title=label
            )
        )
        fn selectLayerView layer expand:false = (
            if selecting or building or not controlsReady do return false
            local i=findItem controller.layerObjects layer
            if i==0 do return false
            selecting=true
            try (
                if controller.activeLayer!=i do controller.selectLayer i
                if expand and i<=layerPanels.count do (
                    local r=layerPanels[i]
                    r.ensureContents();r.open=true
                )
                refreshTitles()
                if roots.count>=4 do roots[4].syncSelection()
            )catch(selecting=false;throw())
            selecting=false
            if expand do layoutPanels()
            true
        )
        fn rebuildLayers = (
            building=true
            local states=for r in layerPanels collect #(r.obj,r.open,r.sectionStates())
            try (
            for r in layerPanels do removeSubRollout panels r
            layerPanels=#()
            for i=1 to controller.layerObjects.count do (
                controller.syncLayerSurface controller.layerObjects[i]
                local r=CyrusMakeLayer controller.layerObjects[i] mainUI i
                append layerPanels r
                r.title=controller.layerNames[i]
                local previous=undefined
                for state in states where state[1]==controller.layerObjects[i] do previous=state
                CyrusMount panels r (if previous==undefined then true else not previous[2])
                r.title=controller.layerNames[i]
                if previous!=undefined do for k=1 to r.children.count do r.children[k].open=previous[3][k]
            )
            )catch(building=false;throw())
            building=false;refreshTitles();layoutPanels()
        )
        fn rebuild = (
            if controlsReady do (rebuildLayers();roots[4].refresh())
        )
        fn rebuildWidth = (
            local scroll=mainUI.scrollPos
            local states=for r in roots collect r.open
            building=true
            try (
            for r in roots do removeSubRollout panels r
            roots=#(CyrusMake_updateUI controller mainUI,CyrusMake_surfaceUI controller mainUI,CyrusMake_previewUI controller mainUI,CyrusMakeManager controller mainUI)
            for i=1 to roots.count do CyrusMount panels roots[i] (not states[i])
            contentWidth=panels.width
            )catch(building=false;throw())
            building=false;rebuildLayers()
            mainUI.scrollPos=scroll
        )
        on widthTimer tick do if controlsReady and mainUI.open and not building do (
            if widthTimer.interval!=300 do widthTimer.interval=300
            if fitWidth() and not CyrusInteractionHeld() do rebuildWidth()
            if roots.count>=4 and roots[4].open and abs(timeStamp()-lastStatusAt)>=500 do (
                lastStatusAt=timeStamp();roots[4].refreshStats()
            )
        )
        on mainUI open do (
            widthTimer.active=true
            controller=this
            building=true
            fitWidth()
            roots=#(CyrusMake_updateUI controller mainUI,CyrusMake_surfaceUI controller mainUI,CyrusMake_previewUI controller mainUI,CyrusMakeManager controller mainUI)
            for r in roots do CyrusMount panels r true
            contentWidth=panels.width
            controlsReady=true;building=false;rebuildLayers()
        )
        -- Max resets the width after rolledUp returns. Use the existing timer
        -- for the next UI turn, then restore its normal polling interval.
        on mainUI rolledUp expanded do widthTimer.interval=if expanded then 1 else 300
        on mainUI close do (controlsReady=false;widthTimer.active=false;roots=#();layerPanels=#())
    )







