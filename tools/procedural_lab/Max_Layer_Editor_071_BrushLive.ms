-- Brush, Areas, source fields, transforms and Live rules through the new editor.
(
    if findString MCPFixtureDir "/procedural07-ui-071-"==undefined do throw "Private 0.7.1 fixture required"
    P07Case="0.7.1 Brush and Live controls"
    P07New count:2000
    local root=P07Root,leaf=P07Layer,node=P07Node,source=P07Source
    CyrusOpenLayerEditor root leaf
    local editor=CyrusLayerEditor
    editor.showTopic 3
    local brush=UI071Section #beginButton
    brush.radiusSpin.value=200;brush.strengthSpin.value=100;brush.softSpin.value=0
    brush.beginButton.pressed()
    P07Assert (CyrusBrushSessionRoot==root and CyrusBrushSessionLayer==leaf) "Start Brush was not bound to the layer"
    P07Assert (cyrusBrushDab leaf.paintDocument [0,0,500] [0,0,-1] true) "Brush missed the private surface"
    brush.stopButton.pressed();root.refreshAll();brush.refreshHistory()
    local painted=leaf.generatedCount
    P07Assert (painted>100 and painted<2000 and brush.history.count==1) "Paint/history missing"
    brush.detailsToggle.checked=true;brush.detailsToggle.changed true
    brush.strokeList.selection=1;brush.showStroke()
    brush.strokeRadius.value=120;brush.strokeRadius.changed 120
    root.refreshAll()
    P07Assert (leaf.generatedCount<painted) "Saved-stroke radius did not affect coverage"
    brush.beginButton.pressed();editor.showTopic 1
    P07Assert (CyrusBrushSessionRoot==undefined) "Navigating away left Brush active"
    local assets=UI071Section #plantList
    assets.plantList.selection=#{1};assets.showSelectedColor()
    assets.weightSpin.value=.7;assets.weightSpin.changed .7
    assets.sourceScaleSpin.value=1.3;assets.sourceScaleSpin.changed 1.3
    assets.radiusSourceSpin.value=6;assets.radiusSourceSpin.changed 6
    P07Assert (abs((leaf.sourceWeight 1)-.7)<.0001 and abs((leaf.sourceScale 1)-1.3)<.0001 and (leaf.sourceRadius 1)==6) "Per-model fields were not saved"
    editor.showTopic 4
    local transforms=UI071Section #wholeMinSpin
    transforms.wholeMinSpin.value=.8;transforms.wholeMinSpin.changed .8
    transforms.wholeMaxSpin.value=1.2;transforms.wholeMaxSpin.changed 1.2
    P07Assert (abs(leaf.wholeScaleMin-.8)<.0001 and abs(leaf.wholeScaleMax-1.2)<.0001) "Layer scale fields failed"
    transforms.resetWholeScale.pressed()
    P07Assert (leaf.wholeScaleMin==1 and leaf.wholeScaleMax==1) "Transform reset failed"
    editor.showTopic 2
    local area=UI071Section #areaList,shape=rectangle width:70 length:70 pos:[0,0,0]
    area.pickArea.picked shape
    area.areaList.selection=#{1};area.areaMode.changed 2
    P07Assert (leaf.areaNodes.count==1 and leaf.areaModes[1]==2) "Area pick / Exclude failed"
    area.detailsToggle.checked=true;area.detailsToggle.changed true
    area.fallTarget.selection=2;area.syncFalloff()
    area.fallDeleteCheck.checked=true;area.fallDeleteCheck.changed true
    area.fallDeleteSpin.value=5;area.fallDeleteSpin.changed 5
    P07Assert ((leaf.getFallConfig shape)[1] and (leaf.getFallConfig shape)[2]==5) "Area-specific falloff failed"
    root.updateMode=2;root.refreshAll()
    local epoch=root.procEpoch
    editor.showTopic 5
    local rules=UI071Section #scopeList
    rules.scopeList.selection=1;rules.bindRule resetPeer:true
    rules.enabledCheck.checked=true;rules.enabledCheck.changed true
    rules.multiplierSpin.value=0;rules.multiplierSpin.changed 0
    rules.gapSpin.value=5000;rules.gapSpin.changed 5000
    completeRedraw();windows.processPostedMessages()
    -- The normal Live exact consumer must see the saved field without Apply.
    local rows=leaf.placements (leaf.outputSources())
    P07Assert (root.procEpoch>epoch and rows.count<=1) "Live spacing field did not publish"
    local cleanup=UI071Section #cleanCheck
    cleanup.cleanCheck.checked=true;cleanup.cleanCheck.changed true
    cleanup.minNeighborSpin.value=2;cleanup.minNeighborSpin.changed 2
    rows=leaf.placements (leaf.outputSources())
    P07Assert (rows.count==0) "Layer cleanup did not affect Live result"
    CSPWriteText (MCPFixtureDir+"layer-editor-071-brush-live.json") (CSPObject #(#("brush_and_saved_stroke",true),#("brush_stops_on_navigation",true),#("source_fields",true),#("transforms_and_reset",true),#("area_and_falloff",true),#("live_spacing_autosave",true),#("cleanup",true)))
    CyrusCloseLayerEditor()
)
