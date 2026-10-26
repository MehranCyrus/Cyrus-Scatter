global TOwner,TRoot,TEdit,TRocks,PSettle
loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.87.0-20261025-r4/Trials/Terraces_087_Detailed.max" quiet:true useFileUnits:true
TOwner=getNodeByName "CyrusScatter 0.87 - Terrace contact study";TRoot=TOwner.baseObject;TEdit=TOwner.modifiers[1];TRocks=TRoot.layerObjects[6]
if TRoot.layerObjects.count!=10 or TRoot.layerObjects[1].amount!=10000 do throw "Saved trial populations did not reopen correctly."
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1)
TRoot.refreshAll();CyrusPointSync();completeRedraw();PSettle 900
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 300
if TRoot.interactionError!="" or not (cyrusInteractionOwner TRoot.interactionState TOwner) do throw "Reopened trial failed to rebuild its own contact generation."
if distance (cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation [-8000,-3100,-988.8409]>0.01 do throw "Saved hero stone transform changed."
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"full-scene-reopen.json") (TRoot.interactionsStatistics())
