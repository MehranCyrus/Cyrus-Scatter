global TRoot
if TRoot.procEpoch!=1 or TRoot.layerObjects[1].amount!=10011 or TRoot.layerObjects[1].generatedCount!=10000 do throw "UI preparation or Apply consumed a pending Manual population edit."
if TRoot.layerObjects[10].interactionReview!=undefined or TRoot.layerObjects[10].interactionGuides.count!=0 do throw "Accept left transient review objects active."
if TRoot.interactionError!="" do throw TRoot.interactionError
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"ui-source-workflow.json") "{\"status\":\"pass\",\"checks\":[\"Native panel teardown after ready-frame posts\",\"Sky-opened Interactions panel\",\"Sky Analyze model\",\"Sky Accept reviewed guides\",\"Sky Apply interactions\",\"No Manual population consumption or placement epoch rebuild\",\"Review objects cleaned after acceptance\"]}"
