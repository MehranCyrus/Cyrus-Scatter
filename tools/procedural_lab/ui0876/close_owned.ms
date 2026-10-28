-- Cleanup only: never close an artist session or a different campaign profile.
global UI76CloseOwnedTimer,UI76CloseOwnedTick
(
    if not matchPattern GardenRun pattern:"*/build/ui0876-20261028-01/host-*/" do throw "Owned callback profile required."
    if not doesFileExist (GardenRun+"launch.json") or not doesFileExist (GardenRun+"loaded-identity.json") do throw "Owned identity receipts are missing."
    if theHold.Holding() or theHold.IsSuspended() do throw "An authored operation is still active; do not close it."
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"completed.json") "{\"status\":\"scoped_campaign_complete\",\"cleanup\":\"private Max quit requested without saving disposable state\"}"
    fn UI76CloseOwnedTick sender args = (
        UI76CloseOwnedTimer.Stop();UI76CloseOwnedTimer.Dispose()
        quitMax #noPrompt
    )
    UI76CloseOwnedTimer=dotNetObject "System.Windows.Forms.Timer"
    UI76CloseOwnedTimer.Interval=750
    dotNet.addEventHandler UI76CloseOwnedTimer "Tick" UI76CloseOwnedTick
    UI76CloseOwnedTimer.Start()
)
