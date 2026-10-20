if not (matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" or matchPattern MCPFixtureDir pattern:"*/update08671-content-2027/") do throw "Owned campaign host required"
global VQuitTimer=dotNetObject "System.Windows.Forms.Timer"
fn VQuitOwned sender event=(sender.Stop();quitMAX #noPrompt)
dotNet.addEventHandler VQuitTimer "Tick" VQuitOwned
VQuitTimer.Interval=1200
VQuitTimer.Start()
