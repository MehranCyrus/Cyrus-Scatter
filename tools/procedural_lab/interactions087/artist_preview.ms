global TOwner,TRoot,PSettle
local epoch=TRoot.procEpoch
TRoot.viewportFaces=20000000;TRoot.viewportNavigationFaces=5000000
TRoot.refreshDisplay();CyrusPointSync();completeRedraw();PSettle 700
if TRoot.procEpoch!=epoch do throw "Changing display face limits must not rebuild static placements."
local image=gw.getViewportDib();image.filename=GardenRun+"artist-preview-budget.png";save image;close image
saveMaxFile (GardenRun+"Terraces_087_Artist_Stage.max") quiet:true
PSettle 500
