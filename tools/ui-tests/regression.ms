-- Invocation-only regression recipe. Run after setup.ms in its private fixture.
(
    RIAssert (matchPattern RIDir pattern:"*ui-layer-status-*/") "Wrong fixture directory"
    UIChecks=#()
    local ui=UILayerNode.mainUI
    UIAssert ui.controlsReady "Modify UI is mounted"
    UIAssert (ui.roots[4].layerList.width>190) "Initial controls use the fitted panel width"
    UILayerNode.refreshAll()
    local baseline=for l in UILayerNode.layerObjects collect l.previewStats()
    for i=1 to 10 do (
        local p=ui.layerPanels[i]
        p.open=true
        UIAssert (p.children.count==6) ("Slot "+i as string+": first expansion mounts six sections")
        UIAssert (UILayerNode.activeLayer==i) ("Slot "+i as string+": header selects its own layer")
        local children=p.children as array
        p.open=false;p.open=true
        UIAssert (p.children[1]==children[1] and p.children.count==6) ("Slot "+i as string+": reopen reuses controls")
        p.open=false
    )
    ui.selectLayerView UILayerNode.layerObjects[3] expand:true
    UIAssert (ui.layerPanels[3].open and UILayerNode.activeLayer==3) "Manager navigation opens the requested layer"
    UIAssert (ui.roots[4].layerList.SelectedIndices.Item[0]==2) "Manager selection follows the open header"
    ui.selectLayerView UILayerNode.layerObjects[3] expand:true
    UIAssert (ui.layerPanels[3].children.count==6) "Selecting the active row again does not duplicate controls"
    ui.layerPanels[3].children[1].open=true
    ui.layerPanels[3].children[3].open=true
    ui.layerPanels[3].open=false
    ui.rebuildWidth()
    UIAssert (ui.layerPanels[3].children.count==0) "Collapsed parent remains lazy after width rebuild"
    ui.layerPanels[3].open=true
    UIAssert (ui.layerPanels[3].children[1].open and ui.layerPanels[3].children[3].open) "Collapsed parent restores pending nested expansion"
    ui.rebuildWidth()
    UIAssert (ui.layerPanels[3].open and ui.layerPanels[3].children[1].open and ui.layerPanels[3].children[3].open) "Expanded parent restores nested expansion"
    UIAssert (not ui.building and not ui.layingOut and not ui.selecting) "Lifecycle guards return to idle"
    for i=1 to 10 do (
        UIAssert ((UILayerNode.layerObjects[i].previewStats())[1]==baseline[i][1] and not UILayerNode.layerObjects[i].dirty) ("Slot "+i as string+": browsing and resize do not rebuild or dirty preview")
    )
    local manager=ui.roots[4],selected=manager.layerList.SelectedIndices.Item[0]
    local timings=#()
    for k=1 to 100 do (
        local started=RIStamp()
        manager.refreshStats()
        append timings (RIStamp()-started)
    )
    sort timings
    UIAssert (manager.layerList.SelectedIndices.Item[0]==selected) "Passive statistics preserve selection"
    for i=1 to 10 do UIAssert ((UILayerNode.layerObjects[i].previewStats())[1]==baseline[i][1] and not UILayerNode.layerObjects[i].dirty) ("Slot "+i as string+": 100 statistics reads have no build side effect")
    UIAssert (CyrusUICount 1234567=="1,234,567" and CyrusUICount 24600 compact:true=="24.6k") "Exact and abbreviated counts are formatted"
    local layer=UILayerNode.layerObjects[3],oldAmount=UILayerNode.layerObjects[3].amount
    UIAssert ((layer.uiLayerStats()).mode==1) "Completed point-cloud cache records its mode"
    layer.amount=oldAmount+11;manager.refreshStats()
    UIAssert (manager.layerList.Items.Item[2].SubItems.Item[2].Text=="Stale" and (layer.uiLayerStats()).placements==oldAmount) "Manual edit keeps the cached count and marks it stale"
    layer.forcePreviewUpdate();manager.refreshStats()
    UIAssert ((layer.uiLayerStats()).hasResult and (layer.previewStats())[1]==0) "Force-update invalidation retains the cached statistic without rebuilding"
    layer.amount=oldAmount;layer.refreshPreview();manager.refreshStats()
    UIAssert (manager.layerList.Items.Item[2].SubItems.Item[2].Text=="OK") "Successful explicit update returns to cached state"
    layer.viewportMode=2;manager.refreshStats()
    UIAssert ((layer.uiLayerStats()).mode==1 and findString manager.statsDetail.text "Preview dots"!=undefined) "Pending mode change keeps the old cache's count label"
    layer.refreshPreview();manager.refreshStats()
    UIAssert ((layer.uiLayerStats()).mode==2 and findString manager.statsDetail.text "Proxy shown"!=undefined) "Proxy cache is labelled in shown instances"
    layer.viewportMode=3;layer.refreshPreview();manager.refreshStats()
    UIAssert ((layer.uiLayerStats()).mode==3 and findString manager.statsDetail.text "Mesh shown"!=undefined) "Mesh cache is labelled in shown instances"
    layer.viewportMode=1;layer.showPoints=false;layer.showCenters=false;layer.refreshPreview();manager.refreshStats()
    UIAssert (manager.layerList.Items.Item[2].SubItems.Item[2].Text=="Hidden") "Hidden preview has an explicit state"
    layer.showPoints=true;layer.sourceEmpty=#(true);layer.refreshPreview();manager.refreshStats()
    UIAssert ((layer.uiLayerStats()).hasResult and (layer.uiLayerStats()).placements==0 and manager.layerList.Items.Item[2].SubItems.Item[2].Text=="Empty") "Successful empty output is a valid zero"
    layer.sourceEmpty=#();layer.surfaceNodes=#();layer.surface=undefined;layer.refreshPreview();manager.refreshStats()
    UIAssert ((layer.uiLayerStats()).errorText!="" and manager.layerList.Items.Item[2].SubItems.Item[1].Text=="--" and manager.layerList.Items.Item[2].SubItems.Item[2].Text=="Error") "Failed generation shows Error rather than a misleading count"
    UIAssert (not layer.dirty) "Error state remains visible even when the engine clears dirty"
    UILayerNode.syncLayerSurface layer;layer.refreshPreview()
    UILayerNode.layerEnabled[3]=false;manager.refreshStats()
    UIAssert (manager.layerList.Items.Item[2].SubItems.Item[2].Text=="Off" and findString manager.statsTotal.text "9 enabled"==1) "Disabled layer keeps its count and is excluded from enabled total"
    UILayerNode.layerEnabled[3]=true;UILayerNode.cyrusEnabled=false;manager.refreshStats()
    UIAssert (findString manager.statsTotal.text "0 enabled | 0 placed"==1) "Disabled controller contributes zero to enabled total"
    UILayerNode.cyrusEnabled=true
    local emptyLayer=createInstance AminScatterObject
    local unbuilt=emptyLayer.uiLayerStats()
    UIAssert (not unbuilt.hasResult and (CyrusUILayerState unbuilt true true true)[1]=="--") "New layer distinguishes Not built from zero"
    UIAssert ((layer.cacheSnapshot()).count==9) "Existing cache snapshot contract is unchanged"
    UILayerNode.refreshAll()
    ui.roots[4].refresh()
    for p in ui.layerPanels do p.open=false
    ui.roots[4].open=true;ui.layoutPanels()
    CSPWriteText (RIDir+"ui-regression.json") (CSPObject #(#("passed",true),#("checks",UIChecks),#("refresh_median_ms",(timings[50]+timings[51])/2),#("refresh_p95_ms",timings[95]),#("summary",ui.roots[4].statsTotal.text)))
)
