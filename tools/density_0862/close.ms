if matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" then (
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"teardown-request.json") "{\"owned_profile\":true,\"action\":\"quitMAX noPrompt\"}"
 global DCloseTimer=dotNetObject "System.Windows.Forms.Timer"
 DCloseTimer.Interval=250
 fn DCloseTick sender event=(sender.Stop();quitMAX #noPrompt)
 dotNet.addEventHandler DCloseTimer "Tick" DCloseTick
 DCloseTimer.Start()
) else throw "Owned density profile required"
