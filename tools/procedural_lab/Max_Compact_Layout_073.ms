-- Measured native widget bounds, not just generated positions or screenshots.
-- Run only in an owned disposable Max host after P07 acceptance definitions.
global Compact073Run,Compact073Bounds
fn Compact073Bounds page = (
    local rectangles=#()
    for control in page.controls where control.visible and (classof control==CheckBoxControl or classof control==PickerControl) do (
        P07Assert (control.hwnd.count==1) "Expected a single native checkbox/picker window"
        local rectangle=windows.getWindowPos control.hwnd[1]
        P07Assert (rectangle.w>0 and control.pos.x+rectangle.w<=page.width-5) ("Native control exceeds its column: "+control.name as string+"; page width="+page.width as string+"; local="+control.pos as string+"; native="+rectangle as string)
        append rectangles #(control.name as string,rectangle)
    )
    for i=1 to rectangles.count do for j=i+1 to rectangles.count do (
        local a=rectangles[i][2],b=rectangles[j][2]
        P07Assert (a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y) ("Native controls overlap: "+rectangles[i][1]+" / "+rectangles[j][1])
    )
    #(page.title,page.width,page.height,for item in rectangles collect #(item[1],item[2] as string))
)
fn Compact073Run = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private qualification host required"
    P07Case="compact native layout";P07New count:180
    local root=P07Root,owner=P07Layer,node=P07Node
    root.refreshAll();select node;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.mainUI.selectLayerView owner
    for page in root.mainUI.editors do (page.open=true;root.mainUI.bindSection page)
    windows.processPostedMessages()
    local manager=root.managerUI,models=root.modelsUI
    P07Assert (manager.flow_layersUI_addButton.pos.y==manager.flow_layersUI_copyButton.pos.y and manager.flow_layersUI_addButton.pos.y==manager.flow_layersUI_removeButton.pos.y) "Layer actions were stacked unnecessarily"
    P07Assert (manager.flow_layersUI_upButton.pos.y==manager.flow_layersUI_downButton.pos.y) "Layer ordering actions were stacked"
    P07Assert (abs(manager.setsUI_weightSpin.pos.y-manager.setsUI_weightSpin_caption.pos.y)<=2) "Share weight caption did not fit inline"
    P07Assert (models.sourceContainersUI_createContainer.pos.y==models.sourceContainersUI_pickContainer.pos.y and models.sourceContainersUI_createContainer.pos.y==models.sourceContainersUI_removeContainer.pos.y) "Container actions were stacked unnecessarily"
    P07Assert (models.sourceUI_plantList.height>=80 and models.sourceContainersUI_containersList.height>=50) "Lists lost visible rows"
    CSPWriteText (MCPFixtureDir+"compact-basic-heights.json") (CSPObject #(#("header",root.mainUI.height),#("manager",manager.height),#("models",models.height)))
    P07Assert (root.mainUI.height<=116 and manager.height<400 and models.height<650) "Basic layout still reserves excessive space"
    P07Assert (root.transformsUI.randomUI_wholeMinSpin.pos.y==root.transformsUI.randomUI_wholeMaxSpin.pos.y) "Min/max scale fields did not share their header row"
    local epoch=root.procEpoch,key=root.procInputKey(),prepared=for leaf in root.layerObjects collect leaf.procPreparedBuilds
    local native=#(),popup=#()
    for page in root.mainUI.editors do (
        append native (Compact073Bounds page)
        page.advancedToggle.checked=true;page.advancedToggle.changed true
        append native (Compact073Bounds page)
        page.advancedToggle.checked=false;page.advancedToggle.changed false
    )
    CyrusOpenLayerEditor root owner
    local editor=CyrusLayerEditor
    for size in #([920,650],[1280,720],[720,500],[920,650]) do (
        setDialogSize editor size;windows.processPostedMessages()
        for topic=1 to 6 do (
            editor.showTopic topic;windows.processPostedMessages()
            for page in editor.activeEditors() do (
                append popup #(getDialogSize editor,topic,Compact073Bounds page)
                page.advancedToggle.checked=true;page.advancedToggle.changed true
                append popup #(getDialogSize editor,topic,Compact073Bounds page)
                page.advancedToggle.checked=false;page.advancedToggle.changed false
            )
        )
    )
    CyrusCloseLayerEditor()
    P07Assert (root.procEpoch==epoch and root.procInputKey()==key) "Layout changed calculation/publication"
    P07Assert ((for leaf in root.layerObjects collect leaf.procPreparedBuilds) as string==prepared as string) "Layout regenerated candidates"
    CSPWriteText (MCPFixtureDir+"compact-layout073.json") (CSPObject #(#("passed",true),#("native",native),#("popup",popup),#("native_bounds_checked",true),#("resize_sizes",#(920,1280,720,920)),#("zero_candidate_builds",true),#("zero_publications",true),#("computer_use",false)))
    "compact native bounds and resize passed"
)
