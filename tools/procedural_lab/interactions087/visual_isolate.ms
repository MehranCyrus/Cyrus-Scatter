global TOwner,TRoot,PSettle
TRoot.identificationMode=4;TRoot.refreshIdentification();CyrusPointSync();completeRedraw();PSettle 500
local image=gw.getViewportDib();image.filename=GardenRun+"textured-before-isolation.png";save image;close image
local old=for node in geometry where not node.isHidden and node!=TOwner and not matchPattern node.name pattern:"Cyrus*" collect node
hide old;completeRedraw();PSettle 500
image=gw.getViewportDib();image.filename=GardenRun+"textured-isolated.png";save image;close image
unhide old;completeRedraw();PSettle 300
