-- Actual product apply/Undo witnesses in an owned Max 2027 host only.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery qualification host required."
    if (maxVersion())[1]!=29000 do throw "Max 2027 required."
    local log=createFile (MCPFixtureDir+"preset-noop-"+(timeStamp() as string)+".txt")
    fn verify condition label log = (format "%: %\n" (if condition then "PASS" else "FAIL") label to:log;flush log;if not condition do throw label)
    fn counters root leaf = #((leaf.receiverCacheStats())[1],leaf.procPreparedBuilds,leaf.procDensityBakes,root.procEpoch)
    try (
        if theHold.Holding() do throw "Previous fixture has an active Undo hold."
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node,root,leaf,peer,surface,source
        undo off (
            units.SystemType=#centimeters;units.SystemScale=1
            surface=plane width:1000 length:1000 widthsegs:4 lengthsegs:4
            source=pyramid width:10 depth:20 height:40 pos:[2000,0,0]
            node=AminScatterObject name:"Gallery preset witness";root=node.baseObject
            root.updateMode=1;root.autoRender=false;root.newLayer();leaf=root.selectedLayer()
            root.setLayerSurfaces leaf #(surface);leaf.sources=#(source);leaf.ensureSourceRows()
            leaf.amount=1200;leaf.procPopulation=1;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
            leaf.wholeScaleMin=0.65;leaf.wholeScaleMax=1.15
            root.newLayer();peer=root.selectedLayer();root.setLayerSurfaces peer #(surface)
            root.refreshAll()
        )
        verify (root.uiVersion()=="0.85.1") "Matched 0.85.1 script" log
        local target=CyrusPresetMakeBinding root leaf "population"
        local document=#("population","Same settings",CyrusPresetCapture target),before=counters root leaf
        local rows=deepCopy root.groupSnapshotRows
        undo "Existing user edit" on (node.name="User edit must survive no-op")
        local sentinel=node.name
        verify (not (CyrusPresetApply target document)) "Identical Amount apply returns no-change" log
        verify (CyrusPresetSameValues before (counters root leaf)) "No-op preserves solve/preparation/publication counters" log
        max undo
        verify (node.name!=sentinel) "One Undo reaches the preceding user action" log
        max redo
        verify (node.name==sentinel) "Redo preserves the preceding action" log
        document[3][1]=1300
        verify (CyrusPresetApply target document) "Real Amount edit commits" log
        verify (leaf.amount==1300 and root.procEpoch==before[4]) "Manual edit waits for Update" log
        verify (not (CyrusPresetApply target document)) "Repeat of pending Manual settings is passive" log
        max undo
        verify (leaf.amount==1200) "No-op did not consume real edit Undo" log
        max redo
        verify (leaf.amount==1300) "Real edit Redo restores settings" log
        document=#("population","Keep seed",CyrusPresetCapture target)
        local fields=cyrusPresetSchema "population",seedIndex=findItem (for f in fields collect f[1]) "randomSeed"
        document[3][seedIndex]=leaf.randomSeed+1
        verify (not (CyrusPresetApply target document seedPolicy:#current)) "Keep Current compares effective seed" log
        local oldSeed=leaf.randomSeed
        verify (CyrusPresetApply target document seedPolicy:#new) "New seed is an authored change" log
        local newSeed=leaf.randomSeed
        verify (newSeed!=oldSeed) "New seed differs" log
        max undo;verify (leaf.randomSeed==oldSeed) "New seed Undo" log
        max redo;verify (leaf.randomSeed==newSeed) "New seed Redo does not reroll" log

        target=CyrusPresetMakeBinding root leaf "transforms"
        document=#("transforms","Transforms",CyrusPresetCapture target)
        local original=getPropertyController leaf #wholeScaleMin
        if original==undefined do (undo off (setPropertyController leaf #wholeScaleMin (bezier_float()));leaf.wholeScaleMin=0.65;original=getPropertyController leaf #wholeScaleMin;document[3]=CyrusPresetCapture target)
        undo off (setPropertyController peer #wholeScaleMin original)
        verify (not (CyrusPresetApply target document)) "Identical Transform apply is passive" log
        verify ((getPropertyController leaf #wholeScaleMin)==original and (getPropertyController peer #wholeScaleMin)==original) "No-op preserves shared static controller identity" log
        local rejected=false
        undo off (setPropertyController leaf #wholeScaleMin (float_expression()))
        try(CyrusPresetApply target document)catch(rejected=true)
        verify rejected "Unsupported controller still rejects even when numbers match" log
        undo off (setPropertyController leaf #wholeScaleMin original)

        target=CyrusPresetMakeBinding root leaf "spacing"
        document=#("spacing","Self rule",CyrusPresetCapture target)
        verify (not (CyrusPresetApply target document)) "Explicit same self-spacing is passive" log
        undo off (leaf.procSelfOverride=false)
        document[3]=CyrusPresetCapture target
        verify (CyrusPresetApply target document) "Inherited to explicit spacing is authored even at equal numbers" log
        max undo;verify (not leaf.procSelfOverride) "Spacing ownership Undo" log
        max redo;verify leaf.procSelfOverride "Spacing ownership Redo" log
        target=CyrusPresetMakeBinding root leaf "spacing" peer:peer
        document=#("spacing","Pair rule",CyrusPresetCapture target)
        verify (CyrusPresetApply target document) "Missing explicit pair becomes authored" log
        verify (not (CyrusPresetApply target document)) "Same explicit pair is passive" log
        max undo;verify ((root.procPair 2 leaf peer)==0) "Pair no-op preserves one-Undo removal" log
        max redo;verify ((root.procPair 2 leaf peer)>0) "Pair Redo" log
        format "PASS: complete numeric no-op, ownership and Undo fixture\n" to:log
    )catch(format "ERROR: %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
    close log
)
