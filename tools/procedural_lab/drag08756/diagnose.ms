(
    local out=createFile (GardenRun+"diagnose.txt")
    format "enabled:% dirty:% error:% state:% epoch:%\n" WFRoot.cyrusEnabled WFRoot.dirty WFRoot.interactionError WFRoot.interactionState WFRoot.procEpoch to:out
    for leaf in WFRoot.layerObjects do format "LAYER % err:% count:% react:% collider:%\n" leaf.layerID leaf.previewError leaf.generatedCount leaf.interactionReact leaf.interactionCollider to:out
    format "PUBLISHED % rows:%\n" WFRoot.procPublishedOwners.count WFRoot.groupSnapshotRows to:out
    format "native readiness:%\n" (cyrusRetainedRequestReady!=undefined) to:out
    try(format "STAT %\n" (WFRoot.interactionsStatistics()) to:out)catch(format "STATERROR %\n" (getCurrentException()) to:out)
    close out
)
