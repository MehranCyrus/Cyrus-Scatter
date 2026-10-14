-- Native Undo is tested outside Python's enclosing execution hold.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P02 host required"
    local log=createFile (MCPFixtureDir+"phase02-undo-native.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log
        if not value do throw label
    )
    fn encode target = (cyrusPresetEncode target.category "witness" (CyrusPresetCapture target))
    try (
        verify (not theHold.Holding()) "Fixture starts outside an enclosing hold" log
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        units.SystemType=#meters;units.SystemScale=1
        local node=AminScatterObject name:"P02 native transactions",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
        for i=1 to 2 do (
            root.newLayer();local leaf=root.selectedLayer()
            root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=40
            leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        )
        local first=root.layerObjects[1],second=root.layerObjects[2]
        root.refreshAll();CyrusPointSync()
        local published=cyrusEditFingerprint root.groupSnapshotRows[1] "p02undo",epoch=root.procEpoch
        local target=CyrusPresetMakeBinding root first "population",before=encode target
        local proposal=cyrusPresetDecode before
        proposal[3][1]=70;proposal[3][3]=12.5;proposal[3][4]=1234;proposal[3][5]=2;proposal[3][6]=4;proposal[3][7]=3;proposal[3][8]=true
        local wanted=cyrusPresetEncode proposal[1] proposal[2] proposal[3]
        theHold.Begin();second.amount=61
        local nestedRejected=false
        try(CyrusPresetApply target proposal)catch(nestedRejected=true)
        verify (nestedRejected and second.amount==61 and encode target==before and theHold.Holding()) "Nested application is rejected without cancelling the caller's transaction" log
        theHold.Cancel()
        clearUndoBuffer()
        CyrusPresetApply target proposal
        verify (encode target==wanted) "Apply stores every population field" log
        verify (not theHold.Holding() and not first.getLayerTransfer()) "Apply releases native hold and transfer guard" log
        for iteration=1 to 3 do (
            max undo
            verify (encode target==before) ("One Undo restores the complete category " + iteration as string) log
            max redo
            verify (encode target==wanted) ("One Redo restores the complete category " + iteration as string) log
        )
        verify (root.procEpoch==epoch and cyrusEditFingerprint root.groupSnapshotRows[1] "p02undo"==published) "Manual transactions retain complete published placements" log

        local uiDoc=cyrusPresetDecode wanted
        uiDoc[3][1]=88
        local uiDir=pathConfig.appendPath MCPFixtureDir "native-browser"
        local uiFile=pathConfig.appendPath uiDir "population.cspreset.json"
        CyrusPresetWrite uiFile uiDoc replace:(doesFileExist uiFile)
        CyrusOpenPresets root first "population"
        CyrusPresetBrowser.directory=uiDir;CyrusPresetBrowser.refresh()
        clearUndoBuffer();CyrusPresetBrowser.applyPreset.pressed()
        verify (first.amount==88 and not theHold.Holding()) "Native browser Apply invokes a completed transaction" log
        max undo
        verify (encode target==wanted) "One native Undo restores the real browser Apply" log
        destroyDialog CyrusPresetBrowser

        local pairTarget=CyrusPresetMakeBinding root first "spacing" peer:second
        local pairBefore=encode pairTarget
        clearUndoBuffer();CyrusPresetApply pairTarget #("spacing","Pair",#(true,1.5,0.25,true))
        verify (root.procPair 2 first second>0) "Spacing Apply creates the requested pair" log
        local pairWanted=encode pairTarget
        verify (not theHold.Holding()) "Pair Apply releases its hold" log
        max undo
        verify (encode pairTarget==pairBefore and root.procPair 2 first second==0) "One Undo removes newly created pair and its parallel rows" log
        max redo
        verify (encode pairTarget==pairWanted) "One Redo restores the pair rule" log

        local transforms=CyrusPresetMakeBinding root first "transforms"
        local transformDoc=#("transforms","Static",CyrusPresetCapture transforms)
        local shared=bezier_float()
        shared.value=0.8
        setPropertyController first #wholeScaleMin shared;setPropertyController second #wholeScaleMin shared
        transformDoc[3][22]=0.5;transformDoc[3][23]=1.5
        clearUndoBuffer();CyrusPresetApply transforms transformDoc
        verify (abs(first.wholeScaleMin-0.5)<0.0001 and abs(second.wholeScaleMin-0.8)<0.0001) "Static shared controller is detached before assignment" log
        verify (getPropertyController first #wholeScaleMin!=getPropertyController second #wholeScaleMin) "Other owner retains its original controller" log
        max undo
        verify (getPropertyController first #wholeScaleMin==getPropertyController second #wholeScaleMin) "Undo restores shared controller identity" log
        local animated=bezier_float();setPropertyController first #wholeScaleMin animated
        with animate on (at time 0 animated.value=0.8;at time 10 animated.value=0.9)
        local rejected=false,keys=numKeys animated
        try(CyrusPresetApply transforms transformDoc)catch(rejected=true)
        verify (rejected and numKeys animated==keys and getPropertyController first #wholeScaleMin==animated) "Animated target is rejected without removing keys" log
        setPropertyController first #wholeScaleMin (bezier_float());first.wholeScaleMin=0.8
        local wired=float_expression();setPropertyController first #wholeScaleMin wired
        rejected=false;try(CyrusPresetApply transforms transformDoc)catch(rejected=true)
        verify (rejected and getPropertyController first #wholeScaleMin==wired) "Expression target is rejected without replacing its controller" log
        setPropertyController first #wholeScaleMin (bezier_float());first.wholeScaleMin=0.8

        -- Inject a late target-adapter failure after a real authored setter.
        -- No product fault hook or special production binary is used.
        struct P02FailingCurve (leaf,fn presetTargetValid=true,fn presetPrepare values=undefined,fn presetRestore state=true,fn presetApply values=(leaf.amount=999;throw "P02 injected setter failure"))
        local previousEditor=CyrusFalloffGraph,fake=P02FailingCurve leaf:first
        CyrusFalloffGraph=fake
        local failureTarget=CyrusPresetMakeBinding root first "density_curve" editor:fake,oldAmount=first.amount
        rejected=false;try(CyrusPresetApply failureTarget #("density_curve","Rollback",#(#(0.0,1.0),#(),false)))catch(rejected=true)
        CyrusFalloffGraph=previousEditor
        verify (rejected and first.amount==oldAmount and not theHold.Holding() and not first.getLayerTransfer()) "Late apply failure rolls back authored values and releases guards" log
        verify (root.procEpoch==epoch and cyrusEditFingerprint root.groupSnapshotRows[1] "p02undo"==published) "Failed transaction preserves the last complete publication" log

        CyrusPerfHeadless=false
        local editor=CyrusOpenFalloffGraph first undefined true
        local curveTarget=CyrusPresetMakeBinding root first "density_curve" editor:editor
        local oldCurve=first.fallDensityCurve as array
        clearUndoBuffer();CyrusPresetApply curveTarget #("density_curve","Ramp",#(#(0.2,0.8),#(),false))
        local accepted=first.fallDensityCurve as array
        max undo
        verify ((first.fallDensityCurve as string)==(oldCurve as string)) "One Undo restores curve samples" log
        destroyDialog editor
        verify ((first.fallDensityCurve as string)==(oldCurve as string)) "Closing stale graph after Undo does not reapply preset" log
        max redo
        verify ((first.fallDensityCurve as string)==(accepted as string)) "Curve Redo remains available after editor close" log
        root.refreshAll();CyrusPointSync()
        verify (first.generatedCount==70) "Explicit Update uses the applied population" log
        saveMaxFile (MCPFixtureDir+"P02_native_transactions.max") quiet:true
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
