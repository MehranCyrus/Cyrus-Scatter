-- Recovery of this disposable qualification scene after failed nested-hold tests.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p02-*/" do throw "Owned P02 host required"
 local count=0
 if CyrusPresetBrowser!=undefined do destroyDialog CyrusPresetBrowser
 if CyrusFalloffGraph!=undefined do (CyrusFalloffGraph.loading=true;destroyDialog CyrusFalloffGraph)
 while theHold.Holding() and count<16 do (theHold.Cancel();count+=1)
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"hold-recovery.txt") ((count as string)+" cancelled holds; holding="+(theHold.Holding() as string))
 if theHold.Holding() do throw "Cannot recover disposable host hold"
 resetMaxFile #noPrompt
)
