(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    fn solve root = (root.procManualRevision+=1;root.evaluateProcedural())
    fn p05Rows root = (with printAllElements on (root.groupSnapshotRows as string))
    gc light:true
    local log=createFile (MCPFixtureDir+"phase05-undo.txt")
    try (
        if theHold.Holding() do throw "Run outside a Python execution hold"
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        units.SystemType=#meters;units.SystemScale=1
        local node=AminScatterObject name:"P05 lifecycle",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:60 width:60 lengthsegs:1 widthsegs:1
        root.newLayer();local leaf=root.selectedLayer()
        root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=1500
        leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        local area=root.addPaintArea leaf target:receiver,curveNode=circle radius:20
        root.importPaintSpline area curveNode tolerance:0.002;solve root
        local first=p05Rows root,areaID=area.layerID,document=area.paintDocument
        curveNode.radius=10
        clearUndoBuffer();root.importPaintSpline area curveNode tolerance:0.002
        verify ((p05Rows root)==first and not theHold.Holding()) "Import command holds Manual placements and closes its Undo hold" log
        solve root;local smaller=p05Rows root
        verify (first!=smaller) "Explicit Update consumes imported coverage" log
        max undo;solve root
        verify ((p05Rows root)==first and area.layerID==areaID and area.paintDocument==document) "One Undo restores complete coverage and identity" log
        max redo;solve root
        verify ((p05Rows root)==smaller) "One Redo restores imported region" log
        -- Nest inside an existing artist transaction, without ending that hold.
        curveNode.radius=15;clearUndoBuffer()
        undo "P05 outer transaction" on (root.importPaintSpline area curveNode tolerance:0.002;area.paintDensity=0.5)
        solve root;local outer=p05Rows root
        max undo;solve root
        verify ((p05Rows root)==smaller and area.paintDensity==1) "Existing Undo transaction groups import with other authored edits" log
        max redo;solve root
        verify ((p05Rows root)==outer and area.paintDensity==0.5) "Outer transaction Redo restores both edits" log
        clearUndoBuffer();local countBefore=objects.count
        local exported=root.exportPaintSpline area
        verify (isValidNode exported and objects.count==countBefore+1) "Export publishes one spline" log
        max undo
        verify (objects.count==countBefore and (p05Rows root)==outer) "One export Undo removes only the snapshot" log
        max redo
        verify (objects.count==countBefore+1 and (p05Rows root)==outer) "Export Redo restores snapshot without changing Paint" log
        -- Actual generated Export callback loses selection during its command.
        CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.coverageUI.open=true;root.mainUI.bindSection root.coverageUI
        verify (root.coverageUI.brushUI_exportSpline.enabled and root.coverageUI.brushUI_importSpline.enabled) "Conversion controls bind the explicit Paint Area" log
        local epoch=root.procEpoch,revision=(cyrusBrushStats area.paintDocument)[1]
        clearUndoBuffer();root.coverageUI.brushUI_exportSpline.pressed()
        verify (selection.count==1 and superclassof selection[1]==Shape and (cyrusBrushStats area.paintDocument)[1]==revision and root.procEpoch==epoch) "Actual Export callback survives selection change and stays passive" log
        max undo
        select node;max modify mode;modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.coverageUI.open=true;root.mainUI.bindSection root.coverageUI
        local duplicate=root.copyLogicalLayer leaf,other=root.selectedPaintArea duplicate
        verify (other.layerID!=area.layerID and other.paintDocument!=area.paintDocument and other.areaTarget==receiver) "Layer copy owns an independent converted Paint document" log
        root.importPaintSpline other curveNode tolerance:0.002
        verify ((cyrusBrushStats area.paintDocument)[1]==revision) "Editing copied area preserves original document revision" log
        local beforeBrowse=root.procEpoch
        for i=1 to 20 do (
            root.mainUI.selectLayerView duplicate;root.mainUI.bindSection root.coverageUI
            root.mainUI.selectLayerView leaf;root.mainUI.bindSection root.coverageUI
        )
        verify (root.procEpoch==beforeBrowse and (cyrusBrushStats area.paintDocument)[1]==revision) "Repeated conversion control binding is passive" log
        solve root;local saved=p05Rows root,scene=MCPFixtureDir+"P05_lifecycle.max"
        saveMaxFile scene quiet:true
        resetMaxFile #noPrompt;loadMaxFile scene quiet:true useFileUnits:true
        node=getNodeByName "P05 lifecycle";root=node.baseObject;leaf=root.layerObjects[1];area=root.selectedPaintArea leaf
        solve root
        verify (area.layerID==areaID and (p05Rows root)==saved) "Save/reopen preserves converted contours, owner and full placements" log
        resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
        mergeMAXFile scene #select #autoRenameDups #useMergedMtlDups quiet:true
        node=getNodeByName "P05 lifecycle";root=node.baseObject;leaf=root.layerObjects[1];area=root.selectedPaintArea leaf
        solve root
        verify (area.areaTarget==cyrusBrushTarget area.paintDocument and (p05Rows root)==saved) "Merge resolves converted document receiver and preserves placements" log
        verify (not theHold.Holding()) "No stranded conversion transaction" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
