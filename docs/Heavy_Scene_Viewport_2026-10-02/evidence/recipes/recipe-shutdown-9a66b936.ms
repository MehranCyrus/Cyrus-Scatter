-- Run only after cleanup.ms has returned SUCCESS in the private fixture.
(
    if HVPDir==undefined or HVPCommandTimer==undefined do throw "Private fixture is not active"
    if not matchPattern HVPDir pattern:"*/build/heavy-viewport-2026-10-02/" do throw "Unexpected experiment directory"
    if objects.count!=0 do throw "Refusing shutdown with a nonempty scene"
    if not doesFileExist (HVPDir+"cleanup.json") do throw "Cleanup evidence is missing"
    HVPCommandTimer.Stop()
    dotNet.removeAllEventHandlers HVPCommandTimer
    HVPCommandTimer.Dispose()
    HVPCommandTimer=undefined
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    CSPWriteText (HVPDir+"shutdown-requested.json") (CSPObject #(#("pid",process.Id),#("transport_disposed",true),#("empty_scene",true)))
    CSPWriteText (HVPDir+"response.txt") ("SUCCESS "+HVPLastRequest)
    quitMax #noPrompt
)
