global TOwner,TRoot,TEdit,TRocks,PTrace,PRead,PSettle
local before=PTrace[1][3],after=(PRead())[3],epoch=TRoot.procEpoch,builds=TRoot.groupBuilds
max undo;PSettle 600
if distance (PRead())[3] before>0.01 do throw "Physical gesture Undo did not restore the original stone."
max redo;PSettle 600
if distance (PRead())[3] after>0.01 do throw "Physical gesture Redo did not restore the moved stone."
if TRoot.procEpoch!=epoch or TRoot.groupBuilds!=builds or TRoot.interactionError!="" do throw "Physical Undo/Redo changed placements or rejected contacts."
-- Leave an authored Manual population change pending for the next real drag.
TRoot.layerObjects[1].amount+=11
viewport.setType #view_top
local frame=plane name:"087 temporary view frame" width:320 length:320 pos:after
select frame;max zoomext sel all;delete frame
select TOwner;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 400
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"physical-undo-redo.json") "{\"status\":\"pass\",\"scope\":\"Native pointer gesture Undo/Redo restores the same stone and contact result without placement rebuild. A Manual population edit is pending for the second gesture.\"}"
