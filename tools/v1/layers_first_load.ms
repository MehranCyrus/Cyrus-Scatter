resetMaxFile #noPrompt
global LFRoot=AminScatterObject name:"Cyrus layers first"
global LFSurface=plane width:240 length:240 widthsegs:8 lengthsegs:8
global LFSource=sphere radius:2 segs:8 pos:[150,0,2]
LFRoot.surfaceNodes=#(LFSurface)
LFRoot.newLayer();LFRoot.layerNames[1]="Grass"
LFRoot.layerObjects[1].sources=#(LFSource);LFRoot.layerObjects[1].amount=100
LFRoot.newLayer();LFRoot.layerNames[2]="Flowers"
LFRoot.layerObjects[2].sources=#(LFSource);LFRoot.layerObjects[2].amount=90
LFRoot.refreshAll()
select LFRoot
max modify mode
modPanel.setCurrentObject LFRoot
windows.processPostedMessages()
for p in LFRoot.layerPanels do (p.open=true;p.mount())
windows.processPostedMessages()
CSPWriteText (BLDir+"layers-first-loaded.txt") ("Version: "+LFRoot.uiVersion()+" | panels: "+(LFRoot.layerPanels.count as string)+" | "+LFRoot.allStatus())
