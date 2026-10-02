(
    local results=#()
    fn pass results label = (append results label;CSPWriteText (RIDir+"lifecycle-progress.json") (CSPJson results))
    fn settle = (CyrusPointSync();completeRedraw();windows.processPostedMessages();completeRedraw())
    local layer=RINode.layerObjects[1]
    settle()
    local initial=RIStats RINode
    RIAssert (initial[1]==500000 and initial[12]==1) "Initial point count/readiness"
    pass results "500000 visible cached points ready"
    local builds=(layer.previewStats())[1]
    for i=1 to 90 do (viewport.setTM ((rotateZMatrix (5.0*sin(i*7.0)))*RIBaseTM);completeRedraw())
    local after=RIStats RINode
    RIAssert (after[3]==initial[3] and after[6]==initial[6] and after[13]==initial[13]) "Camera movement rebuilt point buffers"
    RIAssert (after[8]-initial[8]>=90) "Native point drawing did not execute"
    RIAssert ((layer.previewStats())[1]==builds) "Camera movement rebuilt placement cache"
    pass results "90 camera steps: native drawing, unchanged cache/generation/uploads"
    viewport.setTM RIBaseTM

    local cache=(layer.cacheSnapshot())[1]
    RINode.updateMode=1;CyrusPointSync()
    layer.amount=3200;settle()
    RIAssert ((layer.cacheSnapshot())[1]==cache and (RIStats RINode)[1]==500000) "Manual mode rebuilt without refresh"
    RINode.refreshAll();settle()
    RIAssert ((RIStats RINode)[1]==320000) "Manual refresh did not publish"
    RINode.updateMode=2;layer.amount=5000;settle()
    RIAssert ((RIStats RINode)[1]==500000) "Automatic update did not publish"
    pass results "Manual hold/explicit refresh and automatic publication"

    local exact=cyrusEditFingerprint (layer.placements (layer.validSources()) previewOnly:true) "placements"
    for mode in #(2,3,1) do (
        RINode.viewportMode=mode;RINode.refreshDisplay();settle()
        RIAssert ((RIStats RINode)[1]==(if mode==1 then 500000 else 0)) "Mode switch left stale native points"
        RIAssert ((cyrusEditFingerprint (layer.placements (layer.validSources()) previewOnly:true) "placements")==exact) "Display mode changed placements"
    )
    pass results "Point Cloud / Proxy / Mesh: no stale points, placement fingerprint preserved"
    RINode.showPoints=false;settle();RIAssert ((RIStats RINode)[1]==0) "Show preview off"
    RINode.showPoints=true;settle();RIAssert ((RIStats RINode)[1]==500000) "Show preview on"
    RINode.layerEnabled[1]=false;settle();RIAssert ((RIStats RINode)[1]==0) "Disabled layer remained visible"
    RINode.layerEnabled[1]=true;settle()
    hide RINode;settle();RIAssert ((RIStats RINode)[1]==0) "Hidden controller remained visible"
    unhide RINode;settle();RIAssert ((RIStats RINode)[1]==500000) "Unhidden controller did not recover"
    pass results "Preview visibility, layer disable and controller hide/show"

    RINode.pointColorMode=1;RINode.solidPointColor=red;settle();RICapture "solid-red"
    RINode.pointColorMode=2;settle();RICapture "source-color"
    RIAssert ((RIStats RINode)[12]==1) "Color change failed"
    pass results "Solid/source color publication"

    local copyNode=copy RINode
    copyNode.name="RI_Clone";settle()
    RIAssert (CyrusPointOwner copyNode!=CyrusPointOwner RINode) "Clone shared a display owner"
    RIAssert ((RIStats copyNode)[1]==500000) "Clone preview missing"
    undo off delete copyNode
    settle()
    RIAssert (CyrusPointOwners.count==1) "Deleted controller leaked registry owner"
    pass results "Clone owns separate display; deletion releases owner"

    local oldAmount=layer.amount
    undo "RI change count" on layer.amount=2000
    settle();RIAssert ((RIStats RINode)[1]==200000) "Undo setup"
    max undo
    settle();RIAssert (layer.amount==oldAmount and (RIStats RINode)[1]==500000) "Undo preview"
    max redo
    settle();RIAssert (layer.amount==2000 and (RIStats RINode)[1]==200000) "Redo preview"
    layer.amount=5000;settle()
    pass results "Parameter undo/redo publishes matching generations"

    viewport.setLayout #layout_4
    completeRedraw();windows.processPostedMessages();completeRedraw()
    local multi=RIStats RINode
    completeRedraw();completeRedraw()
    RIAssert ((RIStats RINode)[6]==multi[6]) "Multiple viewports reinitialized buffers"
    viewport.setLayout #layout_1;viewport.setType #view_persp_user;viewport.setTM RIBaseTM
    pass results "Multiple viewports reuse native buffers"

    local scene=RIDir+"lifecycle-copy.max"
    saveMaxFile scene quiet:true
    RIAssert (not CyrusPointSuspended) "Save left display suspended"
    RIAssert (CyrusPointOwners.count==0) "Display nodes were not stripped for save"
    settle();RIAssert (not getSaveRequired()) "Rebuilding disposable preview dirtied saved scene"
    loadMaxFile scene quiet:true
    RINode=getNodeByName "RI_Controller";RISurface=getNodeByName "RI_Surface";RISource=getNodeByName "RI_Source"
    settle()
    RIAssert ((RIStats RINode)[1]==500000) "Open failed to rebuild preview"
    RIAssert (CyrusPointOwners.count==1) "Open restored duplicate native owners"
    pass results "Save strips transient nodes; open rebuilds; no dirty-flag regression"
    gc light:true;settle()
    RIAssert ((RIStats RINode)[12]==1) "GC released a live shared snapshot"
    pass results "GC preserves live snapshot"
    CSPWriteText (RIDir+"lifecycle.json") (CSPObject #(#("passed",results),#("stats",RIStats RINode),#("error",CyrusPointLastError)))
)
