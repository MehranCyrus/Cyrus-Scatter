(
    if RIDir==undefined or not matchPattern RIDir pattern:"*retained-integration-2026-10-02/run*/" do throw "Not a private fixture"
    if CyrusPointClear!=undefined do CyrusPointClear()
    resetMaxFile #noPrompt
    local ownerCount=(for n in objects where classID n.baseObject==#(0x471d60ab,0x67ca238e) collect n).count
    CSPWriteText (RIDir+"shutdown.json") (CSPObject #(#("objects",objects.count),#("owners",ownerCount),#("registry",CyrusPointOwners.count)))
    try(CyrusPFTimer.Stop();CyrusPFTimer.Dispose())catch()
    try(CyrusReleaseTimer.Stop();CyrusReleaseTimer.Dispose())catch()
    RICommandTimer.Stop();RICommandTimer.Dispose();RICommandTimer=undefined
    CSPWriteText (RIDir+"response.txt") ("SUCCESS "+RILastRequest+" (shutdown requested; verify process exit)")
    quitMax #noPrompt
)
