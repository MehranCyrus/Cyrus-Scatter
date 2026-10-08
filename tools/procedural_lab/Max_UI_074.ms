-- Load after Max_Procedural_07_Acceptance.ms, only in an owned private host.
global UI074Run,UI074Views
fn UI074Run = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private host required"
    P07Case="0.74 UI refinements";P07New count:120
    local r=P07Root,a=P07Layer,node=P07Node,source=P07Source
    P07Assert (r.uiVersion()=="0.74") "Wrong UI version"
    r.refreshAll();select node;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    for page in r.mainUI.editors do (page.open=true;r.mainUI.bindSection page)
    local manager=r.managerUI,models=r.modelsUI,epoch=r.procEpoch,key=r.procInputKey(),displayKey=r.procDisplayInputKey(),originalName=source.name
    local prepared=a.procPreparedBuilds,originalRows=(for rows in r.groupSnapshotRows collect cyrusEditFingerprint rows "ui074"),originalGroups=a.sourceColors as array
    for control in #(manager.flow_layersUI_copyButton,manager.flow_layersUI_removeButton,manager.flow_layersUI_upButton,manager.flow_layersUI_downButton) do P07Assert (control.pos.y==manager.flow_layersUI_addButton.pos.y) "Layer icons are not on one row"
    P07Assert (manager.flow_layersUI_nameEdit.pos.y>manager.flow_layersUI_addButton.pos.y) "Name is not below actions"
    P07Assert (models.sourceUI_plantList_colored.visible and not models.sourceUI_plantList.visible) "Color list not presented"
    P07Assert (models.sourceUI_plantList_colored.Items.Count==a.sources.count) "Visible source rows differ"
    models.propertiesToggle.checked=true;models.propertiesToggle.changed true
    local expanded=models.height
    models.propertiesToggle.checked=false;models.propertiesToggle.changed false
    P07Assert (models.height<expanded and models.sourceUI_plantList_colored.visible and models.sourceUI_addPlant.visible) "Properties fold hid list/actions or retained space"
    P07Assert (not models.sourceUI_weightSpin.visible) "Properties did not fold"
    local height=models.sourceUI_plantList.height,y=models.sourceUI_addPlant.pos.y
    models.sourceUI_plantList.height=height+80;models.layout()
    P07Assert (models.sourceUI_addPlant.pos.y>=y+70 and models.sourceUI_plantList_colored.height==models.sourceUI_plantList.height) "Resized list did not reflow"
    P07Assert (r.procEpoch==epoch and r.procInputKey()==key and a.procPreparedBuilds==prepared) "View operations changed placement"

    models.sourceUI_sourceName.entered "Artist label"
    P07Assert (a.sourceLabel 1=="Artist label" and source.name==originalName) "Rename affected scene source"
    P07Assert (r.procDisplayInputKey()==displayKey) "Label edit changed display input"
    a.setSourceIDColor #{1} (color 249 48 17)
    P07Assert (a.sourceIDColor 1==(color 249 48 17) and (a.sourceColors as array) as string==originalGroups as string) "ID color changed cluster grouping"
    P07Assert (r.procEpoch==epoch and r.procInputKey()==key and a.procPreparedBuilds==prepared) "ID color changed placements"
    local copyLayer=r.copyLogicalLayer a
    P07Assert (copyLayer.sourceLabel 1=="Artist label" and copyLayer.sourceIDColor 1==(color 249 48 17)) "Copy lost source metadata"
    r.removeLogicalLayer copyLayer
    r.mainUI.selectLayerView a
    r.refreshAll();epoch=r.procEpoch;originalRows=for rows in r.groupSnapshotRows collect cyrusEditFingerprint rows "ui074"
    a.amount=177;a.markInputDirty()
    a.setSourceIDColor #{1} (color 32 160 250)
    P07Assert (r.procEpoch==epoch and (for rows in r.groupSnapshotRows collect cyrusEditFingerprint rows "ui074") as string==originalRows as string) "Recolor published pending Manual edits"
    r.refreshAll();P07Assert (r.groupSnapshotRows[1].count==177) "Explicit Update lost pending edit"
    epoch=r.procEpoch;key=r.procInputKey();prepared=a.procPreparedBuilds
    r.managerUI.flow_layersUI_layerColor.changed (color 200 70 240)
    r.displayUI.flow_previewUI_selectIdentification 2
    P07Assert (r.identificationMode==2 and a.layerIDColor==(color 200 70 240)) "Layer ID color not assigned"
    P07Assert (r.procEpoch==epoch and r.procInputKey()==key and a.procPreparedBuilds==prepared) "Layer ID color regenerated placements"
    r.displayUI.flow_previewUI_selectIdentification 1

    local b=plane name:"UI074_Receiver2" width:100 length:100 pos:[2000,0,0]
    local c=plane name:"UI074_Receiver3" width:100 length:100 pos:[2300,0,0]
    r.surfacesUI.flow_surfaceUI_addSurfaces #(b,b,c)
    P07Assert ((r.validSurfaces()).count==3 and r.surfacesUI.flow_surfaceUI_receiversList.items.count==3) "Additive selection/dedup failed"
    b.name="Renamed receiver";r.mainUI.bindSection r.surfacesUI
    P07Assert (findItem r.surfacesUI.flow_surfaceUI_receiversList.items b.name>0) "Receiver name stale after bind"
    r.surfacesUI.flow_surfaceUI_receiversList.selection=#{2,3};r.surfacesUI.flow_surfaceUI_removeSurfaces.pressed()
    P07Assert ((r.validSurfaces()).count==1 and isValidNode b and isValidNode c) "Multi-remove changed scene objects"
    max undo
    P07Assert ((r.validSurfaces()).count==3) "Receiver removal Undo failed"
    max redo
    P07Assert ((r.validSurfaces()).count==1) "Receiver removal Redo failed"
    r.refreshAll();epoch=r.procEpoch;key=r.procInputKey()

    for i=1 to r.mainUI.editors.count do r.mainUI.editors[i].open=(mod i 2)==0
    r.managerUI.advancedToggle.checked=true;r.managerUI.advancedToggle.changed true
    r.managerUI.propertiesToggle.checked=true;r.managerUI.propertiesToggle.changed true
    r.managerUI.flow_layersUI_layerList.height=205;r.managerUI.layout();r.mainUI.rememberViews()
    local before=deepCopy r.uiPresentationState
    select b;select node;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    P07Assert ((for page in r.mainUI.editors collect page.captureView()) as string==before as string) "Mixed view state did not survive reselection"
    P07Assert (r.procEpoch==epoch and r.procInputKey()==key) "Reselection rebuilt placements"
    for page in r.mainUI.editors do page.open=true
    r.mainUI.rememberViews();before=deepCopy r.uiPresentationState
    select b;select node;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    P07Assert ((for page in r.mainUI.editors collect page.open) as string==(for value in before collect value[1]) as string) "All-open state was lost"
    for page in r.mainUI.editors do page.open=false
    r.mainUI.rememberViews();select b;select node;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    P07Assert ((for page in r.mainUI.editors where page.open collect page).count==0) "All-closed state was lost"

    saveMaxFile (MCPFixtureDir+"ui074-owned.max") quiet:true
    resetMaxFile #noPrompt;loadMaxFile (MCPFixtureDir+"ui074-owned.max") quiet:true
    node=getNodeByName "P07_Controller";r=node.baseObject;a=(r.logicalLayers())[1]
    P07Assert (a.sourceLabel 1=="Artist label" and a.sourceIDColor 1==(color 32 160 250)) "Metadata did not survive save/reopen"
    P07Assert (a.sources[1].name==originalName and (r.validSurfaces()).count==1) "Save/reopen changed scene identities"
    local receipt=createFile (MCPFixtureDir+"ui074-checks.txt")
    format "PASS: compact actions; named properties; list height/reflow; source labels; visual colors; copy; pending Manual isolation; additive receivers; multi-remove; Undo/Redo; mixed/all-open/all-closed reselection; metadata save/reopen.\nPointer dragging and visual/DPI appearance are separate acceptance gates.\n" to:receipt
    close receipt;true
)
fn UI074Views = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private host required"
    P07Case="0.74 shared views";P07New count:100
    local r=P07Root,a=P07Layer,node=P07Node
    local b=box name:"UI074_Model2" pos:[1600,0,0]
    a.sources=#(P07Source,b);a.sourceWeights=#(1.0,1.0);r.refreshAll()
    select node;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    r.modelsUI.open=true;r.mainUI.bindSection r.modelsUI
    local models=r.modelsUI,epoch=r.procEpoch,key=r.procInputKey()
    models.sourceUI_plantList_colored.SetSelected 1 true
    P07Assert (models.sourceUI_focusedRow==2) "Ctrl-add did not focus newly selected source"
    models.sourceUI_plantList_colored.SetSelected 0 false
    P07Assert (models.sourceUI_plantList.selection==#{2} and models.sourceUI_focusedRow==2) "Colored list selection did not reach model"
    models.sourceUI_sourceName.entered "Second model label"
    P07Assert (a.sourceLabel 2=="Second model label" and a.sourceLabel 1==P07Source.name) "Color list edited the wrong source"
    P07Assert (r.procEpoch==epoch and r.procInputKey()==key) "Selection regenerated placement"
    r.managerUI.flow_layersUI_addButton.pressed();local other=r.selectedLayer();other.sources=#(b)
    r.managerUI.flow_layersUI_layerList_colored.SelectedIndex=0
    P07Assert (r.logicalParent (r.selectedLayer())==a and r.modelsUI.sourceUI_obj==a) "Colored layer list retained wrong owner"
    r.managerUI.openColorLayer()
    P07Assert (CyrusLayerEditor!=undefined and CyrusLayerEditor.owner==a) "Layer double-click action lost editor owner"
    CyrusCloseLayerEditor()
    r.modelsUI.sourceUI_plantList.height=143;r.modelsUI.layout();r.mainUI.rememberViews()
    local rootHeight=r.modelsUI.sourceUI_plantList.height,container=a.containerCreate()
    select container;max modify mode;modPanel.setCurrentObject container.baseObject
    if not container.baseObject.mainUI.controlsReady do container.baseObject.mainUI.mountTimer.tick()
    local panel=container.baseObject.mainUI
    container.baseObject.modelsUI.open=true;panel.bindSection container.baseObject.modelsUI
    P07Assert (container.baseObject.modelsUI.sourceUI_obj==a) "Container model owner differs"
    container.baseObject.modelsUI.sourceUI_plantList.height=217;container.baseObject.modelsUI.layout();panel.rememberViews()
    local containerHeight=container.baseObject.modelsUI.sourceUI_plantList.height
    select node;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    P07Assert (r.modelsUI.sourceUI_plantList.height==rootHeight) "Container overwrote setup view state"
    select container;modPanel.setCurrentObject container.baseObject
    if not container.baseObject.mainUI.controlsReady do container.baseObject.mainUI.mountTimer.tick()
    P07Assert (container.baseObject.modelsUI.sourceUI_plantList.height==containerHeight) "Container lost its view state"
    CyrusOpenLayerEditor r a
    local editor=CyrusLayerEditor
    for size in #([920,650],[720,500]) do (
        setDialogSize editor size;windows.processPostedMessages();editor.showTopic 1
        for page in editor.activeEditors() where isProperty page #sourceUI_plantList do (
            P07Assert (page.sourceUI_obj==a and page.sourceUI_plantList_colored.Items.Count==a.sources.count) "Popup source view is not bound"
            page.propertiesToggle.checked=true;page.propertiesToggle.changed true
            page.sourceUI_plantList.height=180;page.layout()
            P07Assert (page.sourceUI_addPlant.pos.y>page.sourceUI_plantList.pos.y+page.sourceUI_plantList.height) "Popup resize overlaps actions"
        )
    )
    destroyDialog editor
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ui074-views.txt") "PASS: colored source/layer selection; Ctrl-add focus; double-click action helper; owner isolation; independent container/setup view state; popup reflow at two sizes."
    true
)
