(
    local result=stringStream ""
    try (
        local cache=WFGrass.cachedPoints
        format "snapshot=% owner=% freshness=% holding=%\n" cache (CyrusPointOwner WFOwner) (cyrusInteractionSourcesFresh WFRoot.interactionState) (theHold.Holding()) to:result
        local limits=#(WFRoot.previewBudget,WFRoot.viewportNavigationPoints,WFRoot.viewportInstances,WFRoot.viewportNavigationInstances,WFRoot.viewportFaces,WFRoot.viewportNavigationFaces)
        local style=join #(WFGrass.pointColorMode==1,WFGrass.solidPointColor) limits
        local published=cyrusInteractionRetainedPublish (CyrusPointOwner WFOwner) WFOwner WFRoot.interactionState #(cache) #(style) #(1)
        format "publication=%" published to:result
        format "\nBEFORE STAGE\n" to:result
        (dotNetClass "System.IO.File").WriteAllText (GardenRun+"diagnose.txt") (result as string)
        local state=WFRoot.interactionsStage WFRoot.groupSnapshotRows WFRoot.procPublishedOwners WFRoot.procPublishedSources previous:WFRoot.interactionState retargetEdits:false
        format "AFTER STAGE %\nBEFORE OUTPUT\n" (cyrusInteractionInfo state) to:result
        (dotNetClass "System.IO.File").WriteAllText (GardenRun+"diagnose.txt") (result as string)
        local outputs=cyrusInteractionRenderNodes state WFRoot.interactionOutputNodes
        format "AFTER OUTPUT %\n" outputs to:result
        format "\nfull sync error=% holding=%\n" CyrusPointLastError (theHold.Holding()) to:result
    )catch(format "ERROR=%\nSTACK=%" (getCurrentException()) (getCurrentExceptionStackTrace()) to:result)
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"diagnose.txt") (result as string)
)
