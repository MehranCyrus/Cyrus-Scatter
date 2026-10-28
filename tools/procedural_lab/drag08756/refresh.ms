(
    local out=createFile (GardenRun+"refresh.txt"),failure="",start=timeStamp()
    try(WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync();completeRedraw())catch(failure=getCurrentException())
    format "elapsed_ms:%\nerror:%\nroot:%\n" (timeStamp()-start) failure WFRoot.interactionError to:out
    try(format "%\n" (WFRoot.interactionsStatistics()) to:out)catch()
    close out
)
