-- Called only in the disposable hidden host, after P07 acceptance definitions.
global Approved073Run
fn Approved073Run = (
    if findString MCPFixtureDir "/build/mcp-qualification/"==undefined do throw "Private fixture required"
    P07Checks=#();P07Case="approved native workflow layout";P07New count:180
    local root=P07Root,a=P07Layer,node=P07Node,source=P07Source
    local b=root.addPaintSet a label:"Flowers"
    root.newLayer();local second=root.selectedLayer();second.amount=70
    for leaf in root.layerObjects do (leaf.sources=#(source);leaf.sourceWeights=#(1.0);leaf.paintEnabled=false)
    a.uiPaintSetID=a.layerID;root.refreshAll()
    select node;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.mainUI.selectLayerView a
    local pages=root.mainUI.editors
    P07Assert (pages.count==10 and root.mainUI.controlsReady) "Native workflow must have ten pages"
    P07Assert (CyrusLayerEditor==undefined) "Layer selection opened a popup"
    local names=for r in pages collect r.title
    CSPWriteText (MCPFixtureDir+"approved-page-order.json") (CSPJson names)
    P07Assert (names as string==#("Receiving surfaces","Layers & paint sets","Models & source containers","Population","Coverage & painting","Include / exclude areas","Transforms","Spacing & cleanup","Viewport & render","Statistics & diagnostics") as string) "Approved page order differs"
    for r in pages do (r.open=true;root.mainUI.bindSection r)
    root.refreshDisplay();CyrusViewportRedraw()
    local epoch=root.procEpoch,key=root.procInputKey(),fingerprint=P07Fingerprint root
    local builds=for leaf in root.layerObjects collect leaf.procPreparedBuilds,handles=for r in pages collect r.hwnd
    for cycle=1 to 3 do for r in pages do (
        P07Assert (r.controlsReady and r.root==root and r.owner==a) "Wrong page owner"
        P07Assert (not r.advancedToggle.checked) "Advanced did not start folded"
        local closedHeight=r.height
        r.advancedToggle.checked=true;r.advancedToggle.changed true
        P07Assert (r.height>closedHeight) "Advanced did not expand"
        r.advancedToggle.checked=false;r.advancedToggle.changed false
        P07Assert (r.height==closedHeight) "Advanced did not restore page height"
        r.open=false;r.open=true;root.mainUI.bindSection r
    )
    P07Assert ((for r in pages collect r.hwnd) as string==handles as string) "Browsing rebuilt controls"
    P07Assert (root.procEpoch==epoch and root.procInputKey()==key and (P07Fingerprint root) as string==fingerprint as string) "Browsing changed calculation/publication"
    P07Assert ((for leaf in root.layerObjects collect leaf.procPreparedBuilds) as string==builds as string) "Browsing regenerated candidates"
    local pop=root.populationUI,assets=root.modelsUI,spacing=root.spacingUI,sets=root.managerUI
    P07Assert (pop.distributionUI_obj==a and assets.sourceUI_obj==a) "Initial model owners differ"
    root.mainUI.selectLayerView second
    P07Assert (pop.distributionUI_obj==second and assets.sourceUI_obj==second) "Warm retarget retained old model owners"
    local oldA=a.amount
    pop.distributionUI_countSpin.value=83;pop.distributionUI_countSpin.changed 83
    P07Assert (second.amount==83 and a.amount==oldA) "Population changed previous layer"
    root.mainUI.selectLayerView a
    sets.setsUI_setList.selection=2;sets.setsUI_selectSet 2
    P07Assert (assets.sourceUI_obj==b and pop.distributionUI_obj==a) "Paint-set and parent-layer ownership crossed"
    spacing.proceduralUI_scopeList.selection=1;spacing.proceduralUI_bindRule resetPeer:true
    spacing.proceduralUI_gapSpin.value=9;spacing.proceduralUI_gapSpin.changed 9
    P07Assert (b.procSelfOverride and b.procSelfGap==9 and not second.procSelfOverride) "Automatic spacing changed another owner"
    pop.advancedToggle.checked=false;pop.layout()
    P07Assert (not pop.populationPolicyUI_roundSpin.visible) "Retry limits escaped Advanced"
    assets.advancedToggle.checked=false;assets.layout()
    P07Assert (not assets.diversityUI_diversityRadio.visible and not assets.sourceUI_forwardAxis.visible) "Source details escaped Advanced"
    root.mainUI.selectLayerView a expand:true
    local editor=CyrusLayerEditor
    editor.showTopic 2
    local popupPop=undefined
    for r in editor.editors where isProperty r #distributionUI_countSpin do popupPop=r
    P07Assert (popupPop!=undefined) "Grouped popup population page missing"
    editor.retarget root second;editor.showTopic 2
    P07Assert (popupPop.distributionUI_obj==second) "Popup warm retarget kept old layer"
    popupPop.distributionUI_countSpin.value=91;popupPop.distributionUI_countSpin.changed 91
    P07Assert (second.amount==91 and a.amount==oldA) "Popup changed previous owner"
    editor.showTopic 3
    P07Assert ((editor.activeEditors()).count==1) "Coverage was split into old pages"
    editor.showTopic 5
    P07Assert ((editor.activeEditors()).count==1) "Spacing was split into old pages"
    CyrusCloseLayerEditor()
    clearUndoBuffer()
    pop.distributionUI_countSpin.value=oldA+11;pop.distributionUI_countSpin.changed (oldA+11)
    max undo
    P07Assert (a.amount==oldA and pop.distributionUI_countSpin.value==oldA) "Undo failed to rebind fields"
    local container=a.containerCreate()
    select container;max modify mode;modPanel.setCurrentObject container.baseObject
    if not container.baseObject.mainUI.controlsReady do container.baseObject.mainUI.mountTimer.tick()
    local view=container.baseObject.mainUI
    P07Assert (view.controlsReady and view.root==root and view.editors.count==10) "Container failed to mount matching workflow"
    for r in view.editors do (r.open=true;view.bindSection r;r.advancedToggle.checked=true;r.advancedToggle.changed true)
    select source;windows.processPostedMessages()
    P07Assert (not view.controlsReady and view.editors.count==0) "Closed container retained editable references"
    view.mountTimer.tick()
    P07Assert (not view.controlsReady and view.editors.count==0) "Late closed timer mounted stale controls"
    select node;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.mainUI.selectLayerView second
    root.removeLogicalLayer a;root.removeLogicalLayer second
    P07Assert (root.mainUI.owner==undefined) "Empty setup retained layer owner"
    P07Assert (root.managerUI.controlsReady and root.statisticsUI.open==false) "Setup controls disappeared with last layer"
    root.statisticsUI.open=true;root.mainUI.bindSection root.statisticsUI
    P07Assert (root.statisticsUI.diagnosticsUI_controlsReady and not root.statisticsUI.detailsUI_controlsReady) "Diagnostics require a layer or stale statistics remain editable"
    CSPWriteText (MCPFixtureDir+"approved-layout073.json") (CSPObject #(#("passed",true),#("native_sections",10),#("advanced_cycles",30),#("retained_controls",true),#("browsing_regeneration",false),#("warm_ownership",true),#("container_mount",true),#("computer_use",false)))
    "approved workflow layout passed"
)
