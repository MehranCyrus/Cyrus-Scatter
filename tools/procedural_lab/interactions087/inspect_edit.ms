global TOwner,TRoot,TEdit,TRocks,PRead
local f=createFile (GardenRun+"edit-state.txt")
format "rootError=% pointError=% viewport=% epoch=%\n" TRoot.interactionError CyrusPointLastError TRoot.viewportMode TRoot.procEpoch to:f
for leaf in TRoot.layerObjects do format "key=% amount=% generated=% error=%\n" leaf.editLayerKey leaf.amount leaf.generatedCount leaf.previewError to:f
format "Edit:%\n" (cyrusEditInspect TEdit 0 20) to:f
format "Topology tree=% rock=%\n" (cyrusEditTopology TEdit 5) (cyrusEditTopology TEdit 6) to:f
format "Tail: %\n" (cyrusEditInspect TEdit 281000 20) to:f
format "Held=% busy=% suspended=% enabled=% available=%\n" (CyrusInteractionHeld()) CyrusPointBusy CyrusPointSuspended CyrusPointEnabled CyrusPointAvailable to:f
close f
