-- Width/layout regression only: leave generation settings and scenes unchanged.
(
    if not matchPattern BLDir pattern:"*/hosts/layers-width*/*" do throw "Private width fixture only"
    fn require value message = if not value do throw message
    local root=LWRoot,records=#(),checks=0,toggles=0
    require (root.uiVersion()=="1.2.1") "Wrong UI revision loaded"
    root.mainUI.open=false;root.layersUI.open=true
    for p in root.layerPanels do (p.open=true;p.mount())
    windows.processPostedMessages();completeRedraw()
    local before=for leaf in root.layerObjects collect leaf.cacheSnapshot()
    local paint=for leaf in root.layerObjects collect leaf.paintCacheStats()
    local display=CyrusPointOwner LWNode
    local retained=if isValidNode display then cyrusRetainedStats display else undefined
    local rect=windows.getWindowPos root.layersUI.hwnd
    local frame=windows.getWindowPos (windows.getParentHWND root.layersUI.hwnd)
    require (abs(rect.w-(frame.w-2))<=2) "Layers body does not fill its native frame"
    require (abs(root.layersUI.layers.width-root.layersUI.width)<=1) "Layer list is narrower than its host"
    local handles=for p in root.layerPanels collect #(p.hwnd,for r in p.editors collect r.hwnd)
    for p in root.layerPanels do (
        require (abs(p.sections.width-p.width)<=1) "Sections are narrower than their layer"
        for r in p.editors do (
            r.open=true;windows.processPostedMessages();toggles+=1
            local content=windows.getWindowPos r.hwnd
            for c in r.controls where c.visible do (
                for handle in c.hwnd where handle!=0 do (
                    local bounds=windows.getWindowPos handle
                    require (bounds.x>=content.x and bounds.x+bounds.w<=content.x+content.w+1) ("Control clipped: "+r.title+" / "+(c as string)+" / "+(bounds as string)+" in "+(content as string))
                    checks+=1
                )
            )
            r.open=false;windows.processPostedMessages();toggles+=1
            local now=windows.getWindowPos root.layersUI.hwnd
            require (now.w==rect.w and now.h==rect.h) "Section toggle resized the outer host"
        )
    )
    require ((for p in root.layerPanels collect #(p.hwnd,for r in p.editors collect r.hwnd)) as string==handles as string) "Controls were remounted"
    for i=1 to root.layerObjects.count do (
        local after=root.layerObjects[i].cacheSnapshot()
        require (before[i][6]==after[6]) "Opening a section regenerated placements"
        require (paint[i][1]==(root.layerObjects[i].paintCacheStats())[1]) "Opening a section evaluated paint"
    )
    if retained!=undefined do (
        local now=cyrusRetainedStats display
        for k in #(3,4,5,6,7) do require (retained[k]==now[k]) "Opening a section uploaded display buffers"
    )
    for p in root.layerPanels do p.open=false
    root.layerPanels[1].open=true
    root.layersUI.scrollPos=0
    for p in root.layerPanels do p.scrollPos=0
    for p in root.layerPanels where p.mounted do p.editors[1].scrollPos=0
    append records #("version",root.uiVersion())
    append records #("native_frame_width",frame.w)
    append records #("layers_body_width",rect.w)
    append records #("layer_width",root.layerPanels[1].width)
    append records #("section_width",root.layerPanels[1].editors[1].width)
    append records #("control_bounds_checks",checks)
    append records #("section_toggles",toggles)
    append records #("retained_controls_and_caches",true)
    CSPWriteText (BLDir+"width-acceptance-"+(rect.w as string)+".json") (CSPObject records)
)
