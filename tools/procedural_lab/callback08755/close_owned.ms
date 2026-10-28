-- Cleanup only: never close an artist session or a different campaign profile.
global CB55CloseOwnedTimer,CB55CloseOwnedTick
(
    if not matchPattern GardenRun pattern:"*/build/callback08755-20261028-01/host-*/" do throw "Owned callback profile required."
    if not doesFileExist (GardenRun+"launch.json") or not doesFileExist (GardenRun+"loaded-identity.json") do throw "Owned identity receipts are missing."
    if theHold.Holding() or theHold.IsSuspended() do throw "An authored operation is still active; do not close it."
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"completed.json") "{\"status\":\"scoped_campaign_complete\",\"cleanup\":\"private Max quit requested without saving disposable state\"}"
    fn CB55CloseOwnedTick sender args = (
        CB55CloseOwnedTimer.Stop();CB55CloseOwnedTimer.Dispose()
        quitMax #noPrompt
    )
    CB55CloseOwnedTimer=dotNetObject "System.Windows.Forms.Timer"
    CB55CloseOwnedTimer.Interval=750
    dotNet.addEventHandler CB55CloseOwnedTimer "Tick" CB55CloseOwnedTick
    CB55CloseOwnedTimer.Start()
)
