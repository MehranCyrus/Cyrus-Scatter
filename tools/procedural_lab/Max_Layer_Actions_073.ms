-- Exercise the actual user button handlers in an owned disposable Max host.
global LayerActions073Node,LayerActions073Root,LayerActions073Setup,LayerActions073FirstAdd
global LayerActions073OldBind,LayerActions073Reenter=false,LayerActions073Other,LayerActions073ReentrantAdd
global LayerActions073Assert,LayerActions073Steps=#(),LayerActions073Exercise,LayerActions073Container
global LayerActions073SelectContainer,LayerActions073ContainerAdd,LayerActions073Popup,LayerActions073Finish
fn LayerActions073Assert value message = (if not value do throw ("[layer action] "+message);true)
fn LayerActions073Setup live:false = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private fixture required"
    resetMaxFile #noPrompt
    LayerActions073Node=AminScatterObject name:"Layer_Actions_073"
    LayerActions073Root=LayerActions073Node.baseObject
    LayerActions073Root.updateMode=if live then 2 else 1;LayerActions073Root.autoRender=false
    select LayerActions073Node;max modify mode
    true
)
fn LayerActions073ReentrantAdd = (
    LayerActions073Other=box name:"Unrelated_selection" pos:[1000,0,0]
    LayerActions073OldBind=CyrusBindLayerEditor
    LayerActions073Reenter=true
    fn CyrusBindLayerEditor controller = (
        LayerActions073OldBind controller
        if LayerActions073Reenter do (
            LayerActions073Reenter=false
            -- A host-driven selection change closes the active page while
            -- its original button stack is still returning from bind.
            select LayerActions073Other
        )
        true
    )
    local errorText=""
    try(LayerActions073FirstAdd())catch(errorText=getCurrentException())
    CyrusBindLayerEditor=LayerActions073OldBind
    if errorText!="" do throw errorText
    LayerActions073Assert (not LayerActions073Reenter and not LayerActions073Root.mainUI.controlsReady and selection[1]==LayerActions073Other) "Interrupted action reopened or changed the selected view"
    local countBefore=LayerActions073Root.layerObjects.count
    LayerActions073Root.managerUI.flow_layersUI_addButton.pressed()
    LayerActions073Assert (LayerActions073Root.layerObjects.count==countBefore) "Closed stale button still edited the scene"
    append LayerActions073Steps #("reentrant Add",2,"one layer committed, closed UI stays closed, stale event ignored",true)
    true
)
fn LayerActions073Exercise = (
    local controller=LayerActions073Root,page=controller.managerUI,first=controller.selectedLayer()
    LayerActions073Assert (page.controlsReady and page.root==controller) "Layer controls lost their owner"
    first.amount=137;first.randomSeed=917
    local identity=first.layerID
    clearUndoBuffer()
    page.flow_layersUI_addButton.pressed()
    local second=controller.selectedLayer()
    LayerActions073Assert (controller.layerObjects.count==2 and second!=first and controller.mainUI.owner==second) "Second Add did not select the new layer"
    max undo
    LayerActions073Assert (controller.layerObjects.count==1 and controller.layerObjects[1]==first) "Add Undo did not restore the existing layer"
    max redo
    LayerActions073Assert (controller.layerObjects.count==2) "Add Redo did not restore exactly one layer"
    controller.mainUI.selectLayerView first
    page.flow_layersUI_copyButton.pressed()
    local copied=controller.selectedLayer()
    LayerActions073Assert (controller.layerObjects.count==3 and copied!=first and copied.layerID!=identity and copied.amount==137 and copied.randomSeed==917) "Copy changed identity or missed settings"
    page.flow_layersUI_removeButton.pressed()
    LayerActions073Assert (controller.layerObjects.count==2 and first.layerID==identity and first.amount==137) "Remove changed the original layer"
    controller.mainUI.selectLayerView first
    page.advancedToggle.checked=true;page.advancedToggle.changed true
    page.setsUI_addButton.pressed()
    local painted=controller.selectedPaintSet first
    LayerActions073Assert ((controller.layerSets first).count==2 and painted!=first and painted.logicalParentID==identity) "Native Add set missed ownership"
    page.setsUI_upButton.pressed();page.setsUI_downButton.pressed()
    LayerActions073Assert ((controller.selectedPaintSet first)==painted) "Paint-set ordering changed the selection"
    page.setsUI_removeButton.pressed()
    LayerActions073Assert ((controller.layerSets first).count==1 and first.amount==137 and first.randomSeed==917) "Native set removal changed layer settings"
    append LayerActions073Steps #("native actions",controller.updateMode,"repeat Add, Undo/Redo, Copy, Remove, set Add/order/Remove",true)
    true
)
fn LayerActions073SelectContainer = (
    local controller=LayerActions073Root
    controller.mainUI.selectLayerView controller.layerObjects[1]
    LayerActions073Container=controller.layerObjects[1].containerCreate()
    select LayerActions073Container
    true
)
fn LayerActions073ContainerAdd = (
    local controller=LayerActions073Root,view=LayerActions073Container.baseObject,page=LayerActions073Container.baseObject.managerUI
    LayerActions073Assert (view.mainUI.controlsReady and page.root==controller) "Natural container panel did not mount"
    local before=controller.layerObjects.count
    page.flow_layersUI_addButton.pressed()
    LayerActions073Assert (controller.layerObjects.count==before+1 and view.mainUI.owner==controller.selectedLayer()) "Container Add targeted the wrong setup/layer"
    page.flow_layersUI_copyButton.pressed()
    LayerActions073Assert (controller.layerObjects.count==before+2) "Container Copy failed"
    page.flow_layersUI_removeButton.pressed()
    LayerActions073Assert (controller.layerObjects.count==before+1) "Container Remove failed"
    append LayerActions073Steps #("container actions",controller.updateMode,"Add, Copy, Remove",true)
    true
)
fn LayerActions073Popup = (
    local controller=LayerActions073Root,parent=(controller.logicalLayers())[1]
    CyrusOpenLayerEditor controller parent
    CyrusLayerEditor.showTopic 1
    local page=undefined
    for candidate in CyrusLayerEditor.activeEditors() where isProperty candidate #setsUI_addButton do page=candidate
    LayerActions073Assert (page!=undefined and page.controlsReady) "Popup paint-set controls did not mount"
    local before=(controller.layerSets parent).count
    page.advancedToggle.checked=true;page.advancedToggle.changed true
    page.setsUI_addButton.pressed()
    local added=controller.selectedPaintSet parent
    LayerActions073Assert ((controller.layerSets parent).count==before+1 and page.setsUI_currentSet()==added) "Popup Add set did not refresh the selected set"
    page.setsUI_upButton.pressed();page.setsUI_downButton.pressed()
    page.setsUI_removeButton.pressed()
    LayerActions073Assert ((controller.layerSets parent).count==before) "Popup Remove set did not refresh"
    CyrusCloseLayerEditor()
    append LayerActions073Steps #("popup actions",controller.updateMode,"set Add/order/Remove",true)
    true
)
fn LayerActions073Finish = (
    CSPWriteText (MCPFixtureDir+"layer-actions073.json") (CSPObject #(#("passed",true),#("checks",LayerActions073Steps),#("script",CyrusLoadedScriptFingerprint),#("computer_use",false)))
    true
)
fn LayerActions073FirstAdd = (
    local controller=LayerActions073Root,page=LayerActions073Root.managerUI,errorText=""
    if not controller.mainUI.controlsReady or not page.controlsReady do throw "Natural Modify mount did not finish"
    local before=controller.layerObjects.count
    try(page.flow_layersUI_addButton.pressed())catch(errorText=getCurrentException())
    local result=CSPObject #(
        #("error",errorText),#("before",before),#("after",controller.layerObjects.count),
        #("component_root_cleared",page.flow_layersUI_root==undefined),#("page_root_cleared",page.root==undefined),
        #("main_ready",controller.mainUI.controlsReady),#("script",CyrusLoadedScriptFingerprint))
    CSPWriteText (MCPFixtureDir+"layer-first-add.json") result
    if errorText!="" do throw errorText
    if controller.layerObjects.count!=before+1 do throw "Add must create exactly one layer"
    true
)
