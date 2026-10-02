-- Private fixture only. Compare cold opening, warm reopening and UI remounts.
(
    RIAssert (matchPattern RIDir pattern:"*ui-layer-status-*/") "Wrong fixture directory"
    global UITimingMountOriginal=CyrusMount,UITimingMounts=#(),UITimingCapture=false
    fn CyrusMount host r collapsed = (
        local started=RIStamp()
        UITimingMountOriginal host r collapsed
        if UITimingCapture do append UITimingMounts #(r.title,RIStamp()-started)
    )
    local samples=#()
    try (
        UILayerNode.mainUI.roots[4].open=false
        for p in UILayerNode.mainUI.layerPanels do p.open=false
        UILayerNode.mainUI.rebuildLayers()
        UILayerNode.mainUI.layoutPanels()
        windows.processPostedMessages()
        UITimingCapture=true
        for i=1 to UILayerNode.mainUI.layerPanels.count do (
            local p=UILayerNode.mainUI.layerPanels[i],start=RIStamp()
            UITimingMounts=#()
            p.open=true
            local cold=RIStamp()-start,coldMounts=for entry in UITimingMounts collect entry
            windows.processPostedMessages()
            p.open=false
            start=RIStamp()
            p.open=true
            local warm=RIStamp()-start
            append samples #(#("layer",i),#("cold_ms",cold),#("warm_ms",warm),#("mounts",coldMounts),#("content_width",UILayerNode.mainUI.contentWidth),#("native_width",(windows.getWindowPos UILayerNode.mainUI.hwnd).w))
            p.open=false
        )
        UITimingCapture=false
        CyrusMount=UITimingMountOriginal
        local json="["
        for i=1 to samples.count do (if i>1 do json+=",";json+=CSPObject samples[i])
        CSPWriteText (RIDir+"ui-open-timing.json") (json+"]")
    )catch(UITimingCapture=false;CyrusMount=UITimingMountOriginal;throw())
)
