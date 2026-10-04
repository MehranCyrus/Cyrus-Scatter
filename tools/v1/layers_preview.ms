-- Reopen the untouched demo after the mouse qualification; show paint-set ownership.
if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
CyrusStopBrush()
loadMaxFile (BLDir+"Cyrus_Scatter_1.2_Layers_Demo.max") useFileUnits:true quiet:true
(
    local node=getNodeByName "Cyrus_Scatter_1_Demo",root=node.baseObject
    select node;max modify mode;root.bindNativeUI()
    root.mainUI.open=false;root.layersUI.open=true
    for p in root.layerPanels do p.open=false
    local flowers=root.layerPanels[2]
    flowers.open=true;flowers.mount();flowers.editors[1].open=true
    viewport.setRenderLevel #smoothhighlights
    completeRedraw()
)
