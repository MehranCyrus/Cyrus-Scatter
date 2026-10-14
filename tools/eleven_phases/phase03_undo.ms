-- Native generated control Undo, persistent typed fields and ownership.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P03 host required"
    local log=createFile (MCPFixtureDir+"phase03-undo.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log
        if not value do throw label
    )
    fn physicalSettings leaf = (
        local values=leaf.surfaceFilterPayload(),meters=units.decodeValue "1m"
        for i=7 to 10 do values[i]/=meters
        values
    )
    fn sameSettings a b = (
        local equal=true
        for i=1 to 10 do if i==1 or i==6 then (if a[i]!=b[i] do equal=false) else if abs(a[i]-b[i])>0.0001 do equal=false
        equal
    )
    try (
        verify (not theHold.Holding()) "Starts outside an enclosing transaction" log
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        units.SystemType=#meters;units.SystemScale=1
        local node=AminScatterObject name:"P03 lifecycle",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane name:"P03 lifecycle receiver" length:30 width:30 lengthsegs:1 widthsegs:1 pos:[0,0,10]
        root.newLayer();local leaf=root.selectedLayer()
        root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=70
        leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        root.refreshAll();CyrusPointSync()
        CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.areasUI.open=true;root.mainUI.bindSection root.areasUI
        clearUndoBuffer();root.areasUI.areaUI_altitudeCheck.changed true
        verify (leaf.altitudeEnabled and not theHold.Holding()) "Actual enable callback is one completed transaction" log
        max undo
        verify (not leaf.altitudeEnabled) "One Undo restores enable flag" log
        max redo
        verify (leaf.altitudeEnabled) "One Redo restores enable flag" log
        clearUndoBuffer();root.areasUI.areaUI_altitudeMinSpin.changed 20
        verify (leaf.altitudeMinimum==20 and leaf.generatedCount==70) "Actual height callback keeps Manual result" log
        max undo
        verify (leaf.altitudeMinimum==0 and leaf.generatedCount==70) "One Undo restores typed world height" log
        max redo
        root.mainUI.updateNow.pressed()
        verify (leaf.generatedCount==0 and (leaf.surfaceFilterStats())[2]==70) "Explicit Update publishes the rejected pool" log
        undo "P03 complete settings" on (
            leaf.slopeEnabled=true;leaf.slopeMinimum=0;leaf.slopeMaximum=80;leaf.slopeLowerFade=0;leaf.slopeUpperFade=10
            leaf.altitudeMinimum=0;leaf.altitudeMaximum=30;leaf.altitudeLowerFade=2;leaf.altitudeUpperFade=3
        )
        root.refreshAll()
        verify (leaf.generatedCount==70) "Recovering the interval restores placements" log
        local expected=physicalSettings leaf,originalID=leaf.layerID
        local duplicate=root.copyLogicalLayer leaf
        verify (sameSettings (physicalSettings duplicate) expected and duplicate.layerID!=originalID) "Layer copy retains all filter settings with independent identity" log
        duplicate.altitudeMaximum=11
        verify (leaf.altitudeMaximum==30) "Copied layer filter edit is independent" log
        local scene=MCPFixtureDir+"P03_lifecycle.max"
        saveMaxFile scene quiet:true
        resetMaxFile #noPrompt;loadMaxFile scene quiet:true
        node=getNodeByName "P03 lifecycle";root=node.baseObject;leaf=root.layerObjects[1]
        verify (sameSettings (physicalSettings leaf) expected) "Reopen retains every filter field" log
        root.refreshAll()
        verify (leaf.generatedCount==70) "Reopen reconstructs filtered result" log
        resetMaxFile #noPrompt
        mergeMAXFile scene #select #autoRenameDups #useMergedMtlDups quiet:true
        node=getNodeByName "P03 lifecycle";root=node.baseObject;leaf=root.layerObjects[1]
        verify (sameSettings (physicalSettings leaf) expected) "Merge retains every filter field" log
        root.refreshAll()
        verify (leaf.generatedCount==70) "Merged filter owner resolves its receiver and result" log
        -- World-unit param storage, not raw floats, participates in scene rescale.
        local before=leaf.altitudeMaximum
        rescaleWorldUnits 100
        verify (abs(leaf.altitudeMaximum-before*100)<0.01 and leaf.slopeMaximum==80) "Scene rescale changes physical heights and leaves degrees unchanged" log
        verify (not theHold.Holding()) "Lifecycle finishes without stranded holds" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
