(
    local results=#()
    fn settle = (CyrusPointSync();completeRedraw();windows.processPostedMessages();completeRedraw())
    local layer=RINode.layerObjects[1]
    settle()
    RIAssert CyrusPointAvailable "Retained path unavailable"
    -- No renderer resources may depend on the lifetime of a MAXScript wrapper.
    local cache=(layer.cacheSnapshot())[1],old=RIStats RINode
    local owner=CyrusPointOwner RINode
    local preserved=cyrusEditFingerprint (layer.placements (layer.validSources())) "render"
    local markerExport=aminScatterPreviewPoints cache
    RIAssert (markerExport.count==old[1]) "Native/GW point count mismatch"
    local first=markerExport[1],last=markerExport[markerExport.count]
    markerExport=undefined;gc light:true;settle()
    RIAssert ((RIStats RINode)[13]==old[13]) "GC changed snapshot"
    append results "Native and marker paths share 500000 points; diagnostic export and GC agree"

    -- Explicit global memory pressure without changing the original CPU cache.
    local memoryOwners=#(),manyCaches=for i=1 to 10 collect cache,manyStyles=for i=1 to 10 collect #(false,white)
    local accepted=0,rejected=0
    for i=1 to 3 do (
        local item=cyrusRetainedCreate();append memoryOwners item
        local ok=cyrusRetainedPublish item RINode manyCaches manyStyles
        if ok then accepted+=1 else rejected+=1
        RIAssert ((cyrusRetainedStats item)[11]<=134217728) "Process buffer reservation exceeded cap"
        if not ok do RIAssert ((cyrusRetainedStats item)[12]==2) "Failure not observable"
    )
    RIAssert (accepted==2 and rejected==1) "Expected bounded memory fallback"
    for item in memoryOwners do cyrusRetainedPublish item RINode #() #()
    CyrusPointDelete memoryOwners;completeRedraw();gc light:true
    RIAssert ((RIStats RINode)[11]==6000000) "Memory reservations not released"
    RIAssert ((aminScatterPreviewCount cache)==500000) "Fallback changed source cache"
    append results "128 MiB process cap rejects allocation, preserves cache, releases reservations"

    -- A missing mesh must be visible as an error instead of an apparently fast
    -- empty layer. Restore it afterward and verify normal preview recovers.
    local empty=mesh name:"RI_EmptySource" vertices:#() faces:#()
    layer.sources=#(empty);RINode.refreshAll();settle()
    RIAssert (findString (layer.statusText()) "RI_EmptySource"!=undefined) "Missing source name in diagnostic"
    RIAssert (findString (RINode.allStatus()) "preview error"!=undefined) "Layer error missing from aggregate status"
    RIAssert ((RIStats RINode)[1]==0) "Failed source kept stale points"
    layer.sources=#(RISource);undo off delete empty
    RINode.refreshAll();settle()
    RIAssert ((RIStats RINode)[1]==500000) "Source recovery failed"
    append results "Unsupported source diagnostic identifies source, clears stale output, recovers"

    RINode.showPoints=false;settle();CyrusPointPending=false
    for i=1 to 5 do completeRedraw()
    RIAssert (not CyrusPointPending) "Hidden preview caused idle redraw requests"
    RINode.showPoints=true;settle()
    RIAssert (not canConvertTo (CyrusPointOwner RINode) Editable_Mesh) "Display owner exposes render geometry"
    append results "Disabled preview does not schedule redraw loop; helper cannot convert to mesh"

    local before=RIStats RINode
    RISource.height=230
    local until=RIStamp()+500
    while RIStamp()<until do windows.processPostedMessages()
    settle()
    RIAssert ((RIStats RINode)[13]!=before[13]) "Live source geometry did not update cloud"
    RISource.height=180;RINode.refreshAll();settle()
    RIAssert ((cyrusEditFingerprint (layer.placements (layer.validSources())) "render")==preserved) "Display work changed final placement fingerprint"
    append results "Live source geometry updates; exact final-placement fingerprint preserved"

    -- Exercise the unchanged final-render transport with the display owner live.
    RINode.autoRender=true
    RIAssert (CyrusPFBuild()) "PFlow build failed"
    local particles=0
    for node in CyrusPFNodes where classof node==PF_Source do (node.updateParticles node currentTime;particles+=node.numParticles())
    RIAssert (particles==5000) "Render transport instance count changed"
    CyrusPFClear();RINode.autoRender=false;settle()
    RIAssert ((RIStats RINode)[1]==500000) "Render transport damaged point preview"
    append results "PFlow render transport evaluates all 5000 instances and leaves preview intact"
    CSPWriteText (RIDir+"hardening.json") (CSPObject #(#("passed",results),#("stats",RIStats RINode),#("first_exported_point",first),#("last_exported_point",last),#("final_placement_fingerprint",preserved)))
)
