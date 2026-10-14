(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P04 host required"
    local log=createFile (MCPFixtureDir+"phase04-undo.txt")
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        units.SystemType=#meters;units.SystemScale=1
        local node=AminScatterObject name:"P04 lifecycle",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
        root.newLayer();local leaf=root.selectedLayer()
        root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=70
        leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.distributionMode=3
        leaf.densityMap=checker color1:white color2:white
        root.refreshAll();CyrusPointSync()
        CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.populationUI.open=true;root.mainUI.bindSection root.populationUI
        clearUndoBuffer();root.populationUI.distributionUI_uvChannelSpin.changed 2
        verify (leaf.densityUVChannel==2 and leaf.generatedCount==70 and not theHold.Holding()) "Actual channel callback preserves Manual publication" log
        max undo
        verify (leaf.densityUVChannel==1) "One Undo restores UV channel" log
        max redo
        verify (leaf.densityUVChannel==2) "One Redo restores UV channel" log
        leaf.densityUVChannel=1;root.mainUI.bindSection root.populationUI
        python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/eleven_phases/phase04_ui.py"
        clearUndoBuffer();python.Execute "p04_choose_resolution(4)"
        verify (leaf.densityResolution==512 and leaf.generatedCount==70) "Actual resolution callback preserves Manual publication" log
        max undo
        verify (leaf.densityResolution==128) "One Undo restores map resolution" log
        max redo
        verify (leaf.densityResolution==512) "One Redo restores map resolution" log
        root.mainUI.updateNow.pressed()
        verify (leaf.generatedCount==70 and (leaf.densityCacheStats())[5]==512*512) "Explicit Update samples selected resolution" log
        -- Real Undo notifications on an existing texture must invalidate its cached pixels.
        clearUndoBuffer();undo "P04 map colors" on (leaf.densityMap.color1=black;leaf.densityMap.color2=black)
        root.refreshAll();local bakes=(leaf.densityCacheStats())[1]
        verify (leaf.generatedCount==0) "Edited map becomes empty" log
        max undo;root.refreshAll()
        verify (leaf.generatedCount==70 and (leaf.densityCacheStats())[1]>bakes) "Map Undo rebakes and restores white eligibility" log
        local duplicate=root.copyLogicalLayer leaf
        verify (duplicate.densityUVChannel==1 and duplicate.densityResolution==512 and duplicate.layerID!=leaf.layerID) "Copy retains map options with independent layer identity" log
        local epoch=root.procEpoch,firstBakes=(leaf.densityCacheStats())[1]
        for i=1 to 30 do (
            root.mainUI.selectLayerView duplicate;root.mainUI.bindSection root.populationUI
            root.mainUI.selectLayerView leaf;root.mainUI.bindSection root.populationUI
        )
        verify (root.procEpoch==epoch and (leaf.densityCacheStats())[1]==firstBakes) "Owner switching and control binding do not bake or solve" log
        root.mainUI.selectLayerView duplicate;root.mainUI.bindSection root.populationUI
        python.Execute "p04_choose_resolution(1)"
        verify (duplicate.densityResolution==64 and leaf.densityResolution==512) "Resolution callback changes only the captured selected owner" log
        local scene=MCPFixtureDir+"P04_lifecycle.max"
        saveMaxFile scene quiet:true
        resetMaxFile #noPrompt;loadMaxFile scene quiet:true
        node=getNodeByName "P04 lifecycle";root=node.baseObject;leaf=root.layerObjects[1]
        verify (leaf.densityUVChannel==1 and leaf.densityResolution==512 and root.layerObjects[2].densityResolution==64) "Reopen retains separate layer UV and resolution fields" log
        root.refreshAll()
        verify (leaf.generatedCount==70 and (leaf.densityCacheStats())[1]==1) "Reopen reconstructs one transient bake" log
        resetMaxFile #noPrompt;mergeMAXFile scene #select #autoRenameDups #useMergedMtlDups quiet:true
        node=getNodeByName "P04 lifecycle";root=node.baseObject;leaf=root.layerObjects[1]
        root.refreshAll()
        verify (leaf.generatedCount==70 and leaf.densityResolution==512) "Merge preserves options and resolves map/receiver references" log
        rescaleWorldUnits 100
        verify (leaf.densityUVChannel==1 and leaf.densityResolution==512) "Unit rescale leaves channel and pixel dimensions unchanged" log
        verify (not theHold.Holding()) "Lifecycle ends without a stranded hold" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
