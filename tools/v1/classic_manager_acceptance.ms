if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
fileIn (BLRoot+"tools/v1/layers_first_load.ms")
(
    fn require value message = if not value do throw message
    local root=LFRoot.baseObject,grass=root.layerObjects[1],flowers=root.layerObjects[2]
    root.layersUI.open=true;root.surfaceUI.open=true
    root.layerPanels[1].editors[7].open=true
    root.mainUI.selectLayerView grass
    require (root.layersUI.currentLayer()==grass and root.layersUI.layerList.selection==1) "Manager selection did not follow the header"
    root.mainUI.selectLayerView flowers expand:true
    require (root.layersUI.currentLayer()==flowers and root.layersUI.nameEdit.text=="Flowers") "Manager did not bind the selected owner"
    local index=root.newLayer(),added=root.layerObjects[index]
    root.bindNativeUI()
    require (root.selectedLayer()==added) "Restoring old expanded layers stole Add selection"
    root.mainUI.selectLayerView added expand:true
    require (root.layerPanels.count==3 and root.layersUI.members.count==3) "Added layer missing from flow or manager"
    require (root.layerPanels[1].editors[7].open) "Add lost an existing section's expansion state"
    root.removeLogicalLayer added
    require (root.layerPanels.count==2 and root.layersUI.members.count==2) "Remove left a stale panel or manager row"
    root.mainUI.selectLayerView grass
    clearSelection();select LFSource;windows.processPostedMessages()
    select LFRoot;max modify mode;modPanel.setCurrentObject root;windows.processPostedMessages()
    require (root.layersUI.open and root.surfaceUI.open and root.layerPanels[1].open and root.layerPanels[1].editors[7].open) "Switching selection lost open UI state"
    require (root.layersUI.currentLayer()==grass) "Switching selection lost the selected layer"
    require (root.layerPanels[1].editors[7].obj==grass and root.layerPanels[2].editors[3].obj==flowers) "Restored controls changed owners"
    root.layerPanels[1].open=false
    clearSelection();select LFSource;windows.processPostedMessages()
    select LFRoot;max modify mode;modPanel.setCurrentObject root;windows.processPostedMessages()
    require (not root.layerPanels[1].open) "A closed layer unexpectedly reopened"
    root.layerPanels[1].open=true;root.layerPanels[1].mount()
    require (root.layerPanels[1].editors[7].open) "A closed layer lost its remembered child section"
    require (root.updateUI.obj==root and root.previewUI.obj==root and root.surfaceUI.root==root and root.layersUI.root==root) "A general editor bound to a leaf"
    root.mainUI.refreshStats()
    require (findString root.layersUI.countInfo.text "Placed:"!=undefined) "Manager cached statistics missing"
    CSPWriteText (BLDir+"classic-manager-acceptance.json") (CSPObject #(#("version",root.uiVersion()),#("selection_and_add_remove",true),#("expansion_restore",true),#("closed_layer_child_restore",true),#("general_and_feature_ownership",true),#("cached_statistics",true)))
)
