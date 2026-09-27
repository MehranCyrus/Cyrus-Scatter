    rollout mainUI "Cyrus Scatter" width:#cmdPanel (
        local controlsReady=false,building=false,controller
        local roots=#(),layerPanels=#(),dpiScale=1.0
        subrollout panels "" pos:[0,0] width:162 height:200
        timer widthTimer interval:300 active:true
        fn fitWidth = (
            local h=mainUI.hwnd,p=windows.getParentHWND h
            if h==0 or p==0 do return false
            local b=windows.getWindowPos h,pb=windows.getWindowPos p
            local desired=amax 160 (pb.w-8),changed=abs(b.w-desired)>1
            if changed or abs(b.x-pb.x-4)>1 do windows.setWindowPos h 4 (b.y-pb.y) desired b.h true
            if panels.width!=desired do panels.width=desired
            changed
        )
        fn layoutPanels = (
            if controlsReady and not building do (
                local h=0
                dpiScale=mainUI.height as float / (amax 1 (windows.getWindowPos mainUI.hwnd).h)
                local header=floor(23.333*dpiScale+0.5)
                for r in layerPanels do r.fitHeight()
                for r in roots do h+=(if r.open then r.height+header else header)
                for r in layerPanels do h+=(if r.open then r.height+header else header)
                panels.pos=[0,0];panels.height=h;mainUI.height=h;fitWidth()
                -- Nested rollout resizing can leave stale child paint regions in Max.
                for panel in layerPanels where panel.open do for section in panel.children where section.open and section.title=="Collision / Relax" do (
                    for c in section.controls do c.visible=false
                    for c in section.controls do c.visible=true
                )
            )
        )
        fn refreshTitles = (
            for i=1 to layerPanels.count do layerPanels[i].title=controller.layerNames[i]
        )
        fn rebuildLayers = (
            building=true
            local states=for r in layerPanels collect #(r.obj,r.open,(for c in r.children collect c.open))
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
            building=false;layoutPanels()
        )
        fn rebuild = (
            if controlsReady do (rebuildLayers();roots[4].refresh())
        )
        fn rebuildWidth = (
            local states=for r in roots collect r.open
            building=true
            for r in roots do removeSubRollout panels r
            roots=#(CyrusMake_updateUI controller mainUI,CyrusMake_surfaceUI controller mainUI,CyrusMake_previewUI controller mainUI,CyrusMakeManager controller mainUI)
            for i=1 to roots.count do CyrusMount panels roots[i] (not states[i])
            building=false;rebuildLayers()
        )
        on widthTimer tick do if controlsReady and not building do (if fitWidth() do rebuildWidth())
        on mainUI open do (
            controller=this
            building=true
            fitWidth()
            roots=#(CyrusMake_updateUI controller mainUI,CyrusMake_surfaceUI controller mainUI,CyrusMake_previewUI controller mainUI,CyrusMakeManager controller mainUI)
            for r in roots do CyrusMount panels r true
            controlsReady=true;building=false;rebuildLayers()
        )
        on mainUI close do (controlsReady=false;roots=#();layerPanels=#())
    )







