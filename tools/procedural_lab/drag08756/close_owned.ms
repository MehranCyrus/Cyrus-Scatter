-- Cleanup only: never close an artist session or a different campaign profile.
global DG56CloseOwnedTimer,DG56CloseOwnedTick
(
    if not matchPattern GardenRun pattern:"*/build/drag08756-20261028-01/host-*/" do throw "Owned callback profile required."
    if not doesFileExist (GardenRun+"launch.json") or not doesFileExist (GardenRun+"loaded-identity.json") do throw "Owned identity receipts are missing."
    if theHold.Holding() or theHold.IsSuspended() do throw "An authored operation is still active; do not close it."
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"completed.json") "{\"status\":\"scoped_campaign_complete\",\"cleanup\":\"private Max quit requested without saving disposable state\"}"
    fn DG56CloseOwnedTick sender args = (
        DG56CloseOwnedTimer.Stop();DG56CloseOwnedTimer.Dispose()
        quitMax #noPrompt
    )
    DG56CloseOwnedTimer=dotNetObject "System.Windows.Forms.Timer"
    DG56CloseOwnedTimer.Interval=750
    dotNet.addEventHandler DG56CloseOwnedTimer "Tick" DG56CloseOwnedTick
    DG56CloseOwnedTimer.Start()
)
