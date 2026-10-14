(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P02 host required"
 global P02LiveReadyTimer,P02LiveReadyTick,P02LiveStarted
 try(P02LiveReadyTimer.Stop();P02LiveReadyTimer.Dispose())catch()
 fn P02LiveReadyTick sender args = (
  if P02LiveLeaf.generatedCount==75 do (
   P02LiveReadyTimer.Stop()
   (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase02-live-ready.txt") ((timeStamp()-P02LiveStarted) as string)
  )
 )
 P02LiveReadyTimer=dotNetObject "System.Windows.Forms.Timer";P02LiveReadyTimer.Interval=100
 dotNet.addEventHandler P02LiveReadyTimer "Tick" P02LiveReadyTick
 P02LiveEpoch=P02LiveRoot.procEpoch
 P02LiveBefore=cyrusEditFingerprint P02LiveRoot.groupSnapshotRows[1] "live"
 P02LiveStarted=timeStamp()
 CyrusPresetApply P02LiveTarget P02LiveProposal
 P02LiveReadyTimer.Start()
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase02-live-start.txt") ((P02LiveEpoch as string)+" / "+(P02LiveRoot.procEpoch as string))
)
