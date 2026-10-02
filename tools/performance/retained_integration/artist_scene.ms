(
    RIAssert (matchPattern RIDir pattern:"*retained-integration-2026-10-02/run*/") "Not a private test process"
    loadMaxFile (RIRoot+"Test Scene/SaveSelect 2.max") quiet:true
    CyrusPFTimer.Stop()
    local controllers=for n in objects where classof n.baseObject==AminScatterObject collect n
    local report=#(),sources=#(),sourceReport=#()
    for n in controllers do (
        n.updateMode=1;n.viewportMode=1;n.pointsPerPlant=1000;n.previewBudget=500000
        n.refreshDisplay()
        for entry in n.layerEntries includeDisabled:true do (
            local layer=entry[2]
            append report #(n.name,entry[1],n.layerNames[entry[1]],layer.statusText(),layer.previewStats())
            for source in layer.validSources() where classof source!=Integer do appendIfUnique sources source
        )
    )
    CyrusPointSync();completeRedraw();windows.processPostedMessages();completeRedraw()
    for source in sources do (
        local sampled=try((aminScatterSourcePoints source 16 42).count)catch(getCurrentException())
        local bbox=try(nodeGetBoundingBox source source.transform)catch(getCurrentException())
        local geometry=try(local m=snapshotAsMesh source;local r=#(m.numverts,m.numfaces);delete m;r)catch(getCurrentException())
        append sourceReport #(source.name,classof source as string,sampled,bbox,geometry)
    )
    CSPWriteText (RIDir+"artist-sources.json") (CSPObject #(#("controllers",report),#("sources",sourceReport),#("error",CyrusPointLastError),#("owners",for n in controllers where isValidNode (CyrusPointOwner n) collect #(n.name,RIStats n))))
    RICapture "artist-original-view"
)
