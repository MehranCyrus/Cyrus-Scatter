-- Repeatable command/Undo/Redo check in a separate owned session.
global TOwner,TRoot,TEdit,TRocks,PSettle
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 1600
local before=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation
local epoch=TRoot.procEpoch,builds=TRoot.groupBuilds
TRoot.layerObjects[1].amount+=11
undo "Final hero stone check" on cyrusEditTransform TEdit 0 [2,0,0] (matrix3 1) false
completeRedraw();PSettle 600
if distance (cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation (before+[2,0,0])>0.01 do throw "Final hero command did not move the stone."
max undo;completeRedraw();PSettle 600
if distance (cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation before>0.01 do throw "Final hero command Undo failed."
max redo;completeRedraw();PSettle 600
if distance (cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation (before+[2,0,0])>0.01 do throw "Final hero command Redo failed."
if TRoot.procEpoch!=epoch or TRoot.groupBuilds!=builds or TRoot.layerObjects[1].generatedCount!=10000 or TRoot.layerObjects[1].amount!=10011 do throw "Final command/Undo/Redo changed placements or consumed Manual inputs."
if TRoot.interactionError!="" do throw TRoot.interactionError
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"final-command-undo-redo.json") "{\"status\":\"pass\",\"scope\":\"Individual hero command, native Undo/Redo, advancing contacts, unchanged placement epoch/build counts and pending 10011 amount with 10000 published placements. Separate owned host, no injected mouse input.\"}"
