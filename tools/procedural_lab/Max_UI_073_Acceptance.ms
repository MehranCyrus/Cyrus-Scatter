-- Real owner/control/lifecycle assertions in a disposable, hidden Max host.
-- No pointer automation or artist scene. Browsing must not solve or upload.
(
    if findString MCPFixtureDir "/build/mcp-qualification/"==undefined do throw "Private 0.73 fixture required"
    P07Case="0.73 integrated UI"
    fn UI073Stage text = CSPWriteText (MCPFixtureDir+"ui073-stage.txt") text
    UI073Stage "new fixture"
    P07New count:240
    local root=P07Root,a=P07Layer,node=P07Node,source=P07Source
    UI073Stage "add paint set"
    local b=root.addPaintSet a label:"Flowers"
    UI073Stage "add second layer"
    root.newLayer();local second=root.selectedLayer();second.amount=70
    for leaf in root.layerObjects do (leaf.sources=#(source);leaf.sourceWeights=#(1.0);leaf.paintEnabled=false)
    a.uiPaintSetID=a.layerID;root.refreshAll()
    UI073Stage "mount native pages"
    select node;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.mainUI.selectLayerView a
    P07Assert (root.uiVersion()=="0.73" and root.mainUI.editors.count==16) "Wrong UI version or duplicated layer pages"
    P07Assert (CyrusLayerEditor==undefined) "Selecting a layer opened the optional popup"
    local pages=root.mainUI.editors,handles=for r in pages collect r.hwnd
    local epoch=root.procEpoch,key=root.procInputKey(),builds=for leaf in root.layerObjects collect leaf.procPreparedBuilds
    UI073Stage "browse native pages"
    for cycle=1 to 3 do for r in pages do (
        r.open=true;root.mainUI.bindSection r
        P07Assert (r.controlsReady and r.root==root and r.owner==a) "Modify section bound to the wrong layer"
        updateRolloutLayout r forceUpdate:true
        r.open=false
    )
    P07Assert ((for r in pages collect r.hwnd) as string==handles as string) "Browsing replaced native layer controls"
    P07Assert (root.procEpoch==epoch and root.procInputKey()==key) "Modify browsing changed the calculation"
    P07Assert ((for leaf in root.layerObjects collect leaf.procPreparedBuilds) as string==builds as string) "Modify browsing regenerated candidates"
    local pop=root.selected_distributionUI,assets=root.selected_sourceUI,spacing=root.selected_proceduralUI,sets=root.selected_setsUI
    pop.open=true;assets.open=true;sets.open=true;spacing.open=true;root.mainUI.bindEditors()
    P07Assert (pop.obj==a and assets.obj==a) "Initial Modify owners differ"
    UI073Stage "retarget native pages"
    root.mainUI.selectLayerView second
    P07Assert (pop.obj==second and assets.obj==second and spacing.owner==second) "Warm Modify retarget retained old owners"
    local oldA=a.amount
    pop.countSpin.value=83;pop.countSpin.changed 83
    P07Assert (second.amount==83 and a.amount==oldA) "Modify population edited the previous layer"
    root.mainUI.selectLayerView a
    sets.setList.selection=2;sets.selectSet 2
    P07Assert (assets.obj==b and pop.obj==a) "Modify paint-set and layer ownership crossed"
    spacing.scopeList.selection=1;spacing.bindRule resetPeer:true
    spacing.gapSpin.value=9;spacing.gapSpin.changed 9
    P07Assert (b.procSelfOverride and b.procSelfGap==9 and not second.procSelfOverride) "Modify automatic spacing targeted the wrong set"
    -- Same warm topic across two roots is the independently found P1 case.
    UI073Stage "popup retarget"
    root.mainUI.selectLayerView a expand:true
    local editor=CyrusLayerEditor
    editor.showTopic 2
    local popupPop=undefined
    for r in editor.editors where isProperty r #countSpin do popupPop=r
    editor.retarget root second;editor.showTopic 2
    P07Assert (popupPop.obj==second and popupPop.owner==second) "Warm popup topic retained previous owner"
    popupPop.countSpin.value=91;popupPop.countSpin.changed 91
    P07Assert (second.amount==91 and a.amount==oldA) "Warm popup edit crossed layer owners"
    local node2=AminScatterObject name:"UI073_Second_Controller",root2=node2.baseObject
    root2.updateMode=1;root2.newLayer();local layer2=root2.selectedLayer();layer2.amount=19
    editor.retarget root2 layer2;editor.showTopic 2
    P07Assert (popupPop.obj==layer2 and popupPop.root==root2) "Warm popup crossed Scatter roots"
    popupPop.countSpin.value=27;popupPop.countSpin.changed 27
    P07Assert (layer2.amount==27 and second.amount==91) "Warm root switch edited previous Scatter"
    editor.retarget root a;editor.showTopic 1;editor.selectSet 2
    P07Assert (assets.obj==b) "Popup paint-set selection did not refresh open Modify fields"
    CyrusCloseLayerEditor()
    -- Direct logging shares the native recorder with MCP but requires no MCP.
    UI073Stage "direct diagnostics"
    local diag=root.diagnosticsUI
    diag.refresh()
    P07Assert (not cyrusDiagnosticActive()) "Recording started automatically"
    local session=diag.startRecording()
    P07Assert (cyrusDiagnosticActive()) "Direct Start did not start diagnostics"
    P07Assert (not diag.saveReport undefined and cyrusDiagnosticActive()) "Cancelled Save stopped recording"
    for i=1 to 620 do cyrusDiagnosticEvent "ui073.fixture" "private_test" a.layerID root.procEpoch ("event_"+i as string)
    local path=MCPFixtureDir+"direct-diagnostics.json"
    P07Assert (diag.saveReport path and not cyrusDiagnosticActive()) "Direct export failed or left recording active"
    P07Assert (diag.saveReport path) "Replacing an existing report failed"
    local failed=false
    try(diag.saveReport (MCPFixtureDir+"absent-directory/report.json"))catch(failed=true)
    P07Assert (failed and doesFileExist path) "Failed export damaged the previous report"
    local profileKey=root.procInputKey(),profileEpoch=root.procEpoch
    diag.refresh()
    P07Assert (root.procInputKey()==profileKey and root.procEpoch==profileEpoch) "Diagnostics evaluated the scene"
    -- Undo, deletion and switching to a model must leave no stale editor owner.
    clearUndoBuffer()
    pop.countSpin.value=oldA+11;pop.countSpin.changed (oldA+11)
    max undo
    P07Assert (a.amount==oldA and pop.countSpin.value==oldA) "Undo failed to rebind Modify fields"
    select source;windows.processPostedMessages()
    P07Assert (not root.mainUI.controlsReady and root.mainUI.editors.count==0) "Closed Modify panel retained its UI references"
    select node;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    P07Assert (root.mainUI.editors.count==16) "Reopening Modify duplicated or lost sections"
    root.mainUI.selectLayerView a
    root.removeLogicalLayer a
    P07Assert (root.mainUI.owner==second) "Removing selected layer retained its old owner"
    root.removeLogicalLayer second
    P07Assert (root.mainUI.owner==undefined and (for r in root.mainUI.editors where r.controlsReady collect r).count==0) "Empty Scatter retained editable layer fields"
    CSPWriteText (MCPFixtureDir+"ui073-acceptance.json") (CSPObject #(#("passed",true),#("native_sections",16),#("controls_reused",true),#("browsing_regeneration",false),#("popup_warm_retarget",true),#("direct_diagnostics",true),#("pointer_test",false)))
    resetMaxFile #noPrompt
)
