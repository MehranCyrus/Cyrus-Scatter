fileIn (BLRoot+"tools/v1/layers_first_load.ms")
LFRoot.updateMode=1
modPanel.setCurrentObject LFSurface
windows.processPostedMessages()
select LFRoot
modPanel.setCurrentObject LFRoot
windows.processPostedMessages()
LFRoot.mainUI.open=false
LFRoot.layersUI.open=true
for p in LFRoot.layerPanels do p.open=false
global LFClickBefore=windows.getWindowPos LFRoot.layersUI.hwnd
CSPWriteText (BLDir+"ui-click-before.txt") ((for p in LFRoot.layerPanels collect #(p.owner.layerID,p.open,p.mounted)) as string)
