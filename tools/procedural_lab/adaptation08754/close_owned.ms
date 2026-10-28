-- Close only the disposable host whose launch receipts authorize this channel.
global ADCloseOwnedTimer,ADCloseOwnedTick
(
    if not matchPattern GardenRun pattern:"*/build/adaptation08754-20261028-01/host-*/" do throw "Owned adaptation host required."
    if not doesFileExist (GardenRun+"launch.json") or not doesFileExist (GardenRun+"loaded-identity.json") do throw "Owned host identity receipts are missing."
    if theHold.Holding() or theHold.IsSuspended() do throw "An authored operation is still active; do not close it."
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"completed.json") "{\"status\":\"scoped_campaign_complete\",\"cleanup\":\"private Max quit requested without saving the final disposable state\"}"
    fn ADCloseOwnedTick sender args = (
        ADCloseOwnedTimer.Stop();ADCloseOwnedTimer.Dispose()
        quitMax #noPrompt
    )
    ADCloseOwnedTimer=dotNetObject "System.Windows.Forms.Timer"
    ADCloseOwnedTimer.Interval=750
    dotNet.addEventHandler ADCloseOwnedTimer "Tick" ADCloseOwnedTick
    ADCloseOwnedTimer.Start()
)
