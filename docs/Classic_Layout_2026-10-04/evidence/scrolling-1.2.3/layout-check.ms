-- Real native bounds and cache checks in the disposable Max profile.
if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
(
    fn require value message = if not value do throw message
    local root=CFRoot,records=#(),checks=0,toggles=0
    require (root.uiVersion()=="1.2.3") "Wrong script revision"
    root.mainUI.open=true
    for r in root.nativeEditors() do r.open=false
    for p in root.layerPanels do (p.open=true;p.mount();for r in p.editors do r.open=false)
    windows.processPostedMessages();completeRedraw()
    local before=for leaf in root.layerObjects collect leaf.cacheSnapshot()
    local paint=for leaf in root.layerObjects collect leaf.paintCacheStats()
    local display=CyrusPointOwner CFNode
    local retained=if isValidNode display then cyrusRetainedStats display else undefined
    local rect=windows.getWindowPos root.mainUI.hwnd
    local frame=windows.getWindowPos (windows.getParentHWND root.mainUI.hwnd)
    require (abs(rect.w-(frame.w-2))<=2) "Main body does not fill its native frame"
    require (abs(root.mainUI.panels.width-root.mainUI.width)<=1) "Flow host is narrower than the panel"
    local handles=for p in root.layerPanels collect #(p.hwnd,for r in p.editors collect r.hwnd)
    local sizes=#()
    for p in root.layerPanels do (
        p.open=false;windows.processPostedMessages()
        p.open=true;windows.processPostedMessages();toggles+=2
    )
    for r in root.nativeEditors() do (
        local initial=root.mainUI.height
        r.open=true;windows.processPostedMessages()
        require (root.mainUI.height>initial) ("Opening root did not grow the host: "+r.title)
        r.open=false;windows.processPostedMessages()
        require (root.mainUI.height==initial) ("Closing root did not restore the host: "+r.title)
        toggles+=2
    )
    for p in root.layerPanels do (
        require (p.width>=root.mainUI.width-4) "Named layer has a narrow fixed width"
        require (p.sections.width>=p.width-4) "Layer sections are too narrow"
        for r in p.editors do (
            local initial=root.mainUI.height,layerInitial=p.height
            r.open=true;windows.processPostedMessages();toggles+=1
            require (root.mainUI.height>initial and p.height>layerInitial) ("Opening a section did not extend its layer: "+r.title)

            local content=windows.getWindowPos r.hwnd
            for c in r.controls where c.visible do (
                for handle in c.hwnd where handle!=0 do (
                    local bounds=windows.getWindowPos handle
                    require (bounds.x>=content.x and bounds.x+bounds.w<=content.x+content.w+1) ("Horizontal control clipping: "+r.title+" / "+(c as string)+" / "+(bounds as string)+" in "+(content as string))
                    require (bounds.y>=content.y-1 and bounds.y+bounds.h<=content.y+content.h+1) ("Vertical control clipping: "+r.title+" / "+(c as string))
                    checks+=1
                )
            )
            append sizes #(p.title,r.title,r.width,r.height,root.mainUI.height)
            r.open=false;windows.processPostedMessages();toggles+=1
            require (root.mainUI.height==initial and p.height==layerInitial) ("Closing section left empty height: "+r.title)
            require ((windows.getWindowPos root.mainUI.hwnd).w==rect.w) "Section toggle changed the host width"
        )
    )
    require ((for p in root.layerPanels collect #(p.hwnd,for r in p.editors collect r.hwnd)) as string==handles as string) "UI navigation remounted controls"
    for i=1 to root.layerObjects.count do (
        require (before[i][6]==(root.layerObjects[i].cacheSnapshot())[6]) "UI navigation regenerated placements"
        require (paint[i][1]==(root.layerObjects[i].paintCacheStats())[1]) "UI navigation evaluated paint"
    )
    if retained!=undefined do (
        local now=cyrusRetainedStats display
        for k in #(3,4,5,6,7) do require (retained[k]==now[k]) "UI navigation uploaded display buffers"
    )
    for p in root.layerPanels do p.open=false
    root.layerPanels[1].open=true
    root.mainUI.scrollPos=0
    append records #("version",root.uiVersion())
    append records #("native_frame_width",frame.w)
    append records #("main_body_width",rect.w)
    append records #("layer_width",root.layerPanels[1].width)
    append records #("section_width",root.layerPanels[1].editors[1].width)
    append records #("control_bounds_checks",checks)
    append records #("rollout_toggles",toggles)
    append records #("retained_controls_and_caches",true)
    append records #("section_sizes",sizes)
    CSPWriteText (BLDir+"classic-layout-acceptance.json") (CSPObject records)
)

