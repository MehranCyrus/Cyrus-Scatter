-- Keep real Undo/Redo outside Python's enclosing execution hold.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P01 host required"
    local log=createFile (MCPFixtureDir+"phase01-undo-native.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log
        flush log
        if not value do throw label
    )
    try (
        verify (not theHold.Holding()) "Native fixture starts outside an enclosing hold" log
        CyrusPerfHeadless=true
        resetMaxFile #noPrompt
        local node=AminScatterObject name:"P01 native Undo",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:1000 width:1000 lengthsegs:1 widthsegs:1
        root.newLayer();local leaf=root.selectedLayer()
        root.setLayerSurfaces leaf #(receiver);leaf.addPointSource()
        leaf.amount=50;leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        root.refreshAll();CyrusPointSync()
        CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.statisticsUI.open=true;root.mainUI.bindSection root.statisticsUI
        local initial=cyrusEditFingerprint root.groupSnapshotRows[1] "p01undo",epoch=root.procEpoch
        verify (leaf.generatedCount==50) "Publishes 50 Points" log
        verify (not theHold.Holding()) "Setup leaves no enclosing hold" log
        undo "P01 Amount" on leaf.amount=55
        root.statisticsUI.detailsUI_refreshButton.pressed()
        verify (leaf.amount==55 and leaf.generatedCount==50) "Manual edit keeps accepted result" log
        max undo
        verify (leaf.amount==50 and leaf.generatedCount==50) "Undo restores authored Amount" log
        verify (root.procEpoch==epoch and cyrusEditFingerprint root.groupSnapshotRows[1] "p01undo"==initial) "Undo retains complete Manual publication" log
        max redo
        verify (leaf.amount==55 and leaf.generatedCount==50) "Redo remains pending in Manual" log
        verify (root.procEpoch==epoch and cyrusEditFingerprint root.groupSnapshotRows[1] "p01undo"==initial) "Redo retains complete Manual publication" log
        root.statisticsUI.detailsUI_refreshButton.pressed()
        verify (findString root.statisticsUI.detailsUI_info.text "Manual: press Update scatter"!=undefined) "Read button reports pending Redo" log
        root.mainUI.updateNow.pressed();CyrusPointSync()
        verify (leaf.generatedCount==55) "Explicit Update accepts Redo settings" log
        format "COMPLETE\n" to:log;close log
    )catch(
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
