-- Native command fixture invokes the actual graph preset dialog handlers.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"curve-presets-"+(timeStamp() as string)+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        check (not theHold.Holding()) "No surrounding hold" log
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node,root,leaf,surface,source
        undo off (
            surface=plane width:500 length:500 widthsegs:2 lengthsegs:2;source=pyramid width:10 depth:10 height:20 pos:[1000,0,0]
            node=AminScatterObject name:"Curve preset witness";root=node.baseObject;root.updateMode=1;root.autoRender=false
            root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces leaf #(surface);leaf.sources=#(source);leaf.ensureSourceRows()
            leaf.amount=300;leaf.procPopulation=1;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
            leaf.fallDensity=true;leaf.fallDensityCurve=#(0.0,1.0);root.refreshAll()
        )
        local epoch=root.procEpoch
        CyrusOpenFalloffGraph leaf undefined true
        local editor=CyrusFalloffGraph,target=CyrusPresetMakeBinding root leaf "density_curve" editor:editor
        local values=CyrusPresetCapture target,original=leaf.fallDensityCurve as array,oldGraph=leaf.fallDensityGraph
        local path=MCPFixtureDir+"curve-"+CyrusNewLayerID()+".cspreset.json"
        CyrusPresetWrite path #("density_curve","Owned curve",values)
        CyrusOpenPresets root leaf "density_curve" editor:editor
        CyrusPresetBrowser.directory=MCPFixtureDir;CyrusPresetBrowser.refresh selectPath:path
        undo "Preceding user action" on node.name="No-op curve sentinel"
        CyrusPresetBrowser.applyPreset.pressed()
        check (matchPattern CyrusPresetBrowser.status.text pattern:"Already applied*") "Actual curve Apply handler detects no-op" log
        check (leaf.fallDensityGraph==oldGraph and CyrusPresetSameValues original (leaf.fallDensityCurve as array)) "No-op retains sampled and editable representations" log
        max undo;check (node.name!="No-op curve sentinel") "Curve no-op retains preceding Undo" log
        max redo
        CyrusPresetWrite path #("density_curve","Changed curve",#(#(1.0,0.0),#(),false)) replace:true
        CyrusPresetBrowser.applyPreset.pressed()
        check (matchPattern CyrusPresetBrowser.status.text pattern:"Applied*") "Actual curve change handler commits" log
        check (leaf.fallDensityCurve[1]==1.0 and leaf.fallDensityCurve[leaf.fallDensityCurve.count]==0.0) "Changed curve is stored" log
        check (root.procEpoch==epoch and leaf.fallDensity) "Manual curve waits for Update and keeps enable state" log
        -- Save the current editor's canonical representation, then repeat it.
        CyrusPresetWrite path #("density_curve","Canonical current",CyrusPresetCapture target) replace:true
        CyrusPresetBrowser.applyPreset.pressed()
        check (matchPattern CyrusPresetBrowser.status.text pattern:"Already applied*") "Repeat canonical graph Apply is passive" log
        max undo;check (CyrusPresetSameValues original (leaf.fallDensityCurve as array) and leaf.fallDensityGraph==oldGraph) "One Undo restores full curve representation" log
        max redo;check (leaf.fallDensityCurve[1]==1.0) "Curve Redo" log
        destroyDialog CyrusPresetBrowser;destroyDialog editor
        check (not theHold.Holding()) "No curve hold remains" log
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
