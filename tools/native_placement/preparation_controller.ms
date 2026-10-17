-- Whole Scale + mesh-field integration, using the ordinary controller fixture.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned preparation controller required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global PCBefore,PCExpected,PCFrame,PCKey,PCGeometry,PCIdle,PCStarted,PCDataChannel
 fn PCcheck yes message=(if not yes do throw ("Preparation controller: "+message))
 fn PClog message=NPWrite ("CONTROLLER "+NCKind+" "+message)
 fn PChash=(cyrusPlacementPublicationFingerprint NCRoot.groupSnapshotRows NCRoot.procPublishedRadii #("optional") #(NCLeaf.procLastStats,NCLeaf.procLastRounds,NCLeaf.procLastSurfaceStats))
 fn PCapply=(NCRoot.refreshAll();PCcheck (NCLeaf.previewError=="") NCLeaf.previewError)
 fn PCcounters=(#(NCRoot.procEpoch,NCLeaf.procReceiverBuilds,NCLeaf.procPreparedBuilds,NCLeaf.previewBuildCount,cyrusMeshDensityStats(),cyrusRetainedStats (CyrusPointOwner NCNode)))
 case command[1] of (
  "cases": (
   NCRoot.updateMode=1
   NPMap NCTerrain 2 2
   with undo off (NCLeaf.meshMaskEnabled=true;NCLeaf.meshMaskChannel=2;NCLeaf.wholeScaleMin=0.5;NCLeaf.wholeScaleMax=1.7)
   local clock=dotNetClass "System.Diagnostics.Stopwatch"
   for amount in #(5000,50000,200000,0,5000) do (
    with undo off NCLeaf.amount=amount
    NCRoot.procNativeRoute=false;local start=clock.GetTimestamp();PCapply();local oldMs=(clock.GetTimestamp()-start)*1000.0/clock.Frequency,expected=PChash()
    NCRoot.procNativeRoute=true;local before=cyrusPlacementTransportStats();start=clock.GetTimestamp();PCapply();local newMs=(clock.GetTimestamp()-start)*1000.0/clock.Frequency
    PCcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Integrated mask/scale creates no placement-sized script values"
    PCcheck (expected==PChash()) "Complete ordered accepted rows/radii/statistics match existing controller"
    if amount>0 do PCcheck (NCLeaf.generatedCount>0 and NCLeaf.generatedCount<amount) "Ramp mask thins the population"
    PCcheck (findString NCLeaf.procPreparedKey "ReceiverFields:"!=undefined) "Sealed preparation identifies its evaluated numeric field"
    PClog ("PARITY Count="+(amount as string)+" accepted="+(NCLeaf.generatedCount as string)+" oldMs="+(oldMs as string)+" nativeMs="+(newMs as string))
   )
   local unspaced=NCLeaf.generatedCount
   with undo off (NCLeaf.sourceRadiiWU=#(0.4);NCLeaf.sourceFollowScale=#(true);NCLeaf.procSelfEnabled=true)
   NCRoot.procNativeRoute=false;PCapply();local spaced=PChash()
   NCRoot.procNativeRoute=true;local before=cyrusPlacementTransportStats();PCapply()
   PCcheck (spaced==PChash() and NCLeaf.generatedCount<unspaced) "Whole Scale feeds final effective radii and spacing without changing winner order"
   PCcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Optional preparation plus radii/acceptance stays native"
   with undo off (NCLeaf.sourceRadiiWU=#(0.0);NCLeaf.sourceFollowScale=#(false);NCLeaf.procSelfEnabled=false)
   NPMap NCTerrain 2 1;PCapply();PCExpected=PChash()
   NCRoot.updateMode=2
   PClog "PASS integrated preparation"
  )
  "mapBlack": (
   PCBefore=PCcounters();PCKey=NCLeaf.procPreparedKey;PCGeometry=cyrusProceduralSurfaceKey #(NCTerrain) false
   NPMap NCTerrain 2 0
  )
  "checkBlack": (
   PCcheck (NCLeaf.previewError=="" and NCLeaf.generatedCount==0 and NCRoot.procEpoch>PCBefore[1]) "Actual same-frame mapping notification publishes black field"
   PCcheck (PCGeometry==cyrusProceduralSurfaceKey #(NCTerrain) false and PCKey!=NCLeaf.procPreparedKey) "Numeric field changes without geometry change and changes preparation proof"
   NCRoot.updateMode=1;PCBefore=PCcounters();NPMap NCTerrain 2 1
   PClog "PASS actual mapping Live callback"
  )
  "checkManual": (
   PCcheck (NCLeaf.generatedCount==0 and NCRoot.procEpoch==PCBefore[1]) "Manual channel change waits for explicit Update"
   PCapply();PCcheck (PChash()==PCExpected) "Explicit Update restores complete white-field result"
   NCRoot.updateMode=2;PCBefore=PChash()
   NCRoot.populationUI.distributionUI_countSpin.value=50000;NCRoot.populationUI.distributionUI_countSpin.changed 50000
  )
  "checkCount": (
   local deadline=timeStamp()+15000
   while NCLeaf.previewError=="" and NCLeaf.generatedCount!=50000 and timeStamp()<deadline do (windows.processPostedMessages();sleep 0.02)
   PCcheck (NCLeaf.amount==50000 and NCLeaf.generatedCount==50000 and NCLeaf.previewError=="") "Ordinary Count control updates native mask/scale";PCExpected=PChash();max undo
  )
  "checkUndo": (PCcheck (NCLeaf.amount==5000 and PChash()==PCBefore) "Ordinary Count Undo restores every field with mask/scale";max redo)
  "checkRedo": (PCcheck (NCLeaf.amount==50000 and PChash()==PCExpected) "Ordinary Count Redo restores every field with mask/scale";PClog "PASS Count Undo/Redo";PCBefore=PCcounters();PCFrame=NCRoot.procNativePublication;NCLeaf.meshMaskChannel=98)
  "checkFailure": (
   PCcheck (NCLeaf.previewError!="" and NCRoot.procEpoch==PCBefore[1] and NCRoot.procNativePublication==PCFrame and PChash()==PCExpected) "Missing Live channel retains exact complete publication"
   PCFrame=undefined;NCLeaf.meshMaskChannel=2
  )
  "checkRecovery": (
   PCcheck (NCLeaf.previewError=="" and PChash()==PCExpected) "Valid field recovers after failed successor"
   PClog "PASS missing-channel retention/recovery"
   NCRoot.updateMode=1
   PCDataChannel=DataChannelModifier();PCDataChannel.AddOperator 236108612L 0L 0;PCDataChannel.AddOperator 2882382387L 0L 1
   PCcheck (PCDataChannel.operators.count==2) "Actual Data Channel operators created from full-width Class IDs"
   local curvature=PCDataChannel.operators[1],output=PCDataChannel.operators[2]
   curvature.convex=1;curvature.flat=1;curvature.concave=1;curvature.scale=3;curvature.hardEdgesOnly=false
   output.output=2;output.channelNum=7;output.xyz=0;output.replace=0
   addModifier NCTerrain PCDataChannel;NCLeaf.meshMaskChannel=7;PCapply()
   PCcheck (NCLeaf.generatedCount==50000) "Actual Data Channel Curvature/Vertex Output drives the native route"
   NCRoot.updateMode=2;PCBefore=PCcounters();curvature.convex=0;curvature.flat=0;curvature.concave=0
  )
  "checkDataChannel": (
   PCcheck (NCLeaf.previewError=="" and NCLeaf.generatedCount==0 and NCRoot.procEpoch>PCBefore[1]) "Same-frame real Data Channel operator change drives Live result"
   PClog "PASS actual Data Channel Live"
   NCRoot.updateMode=1;local curvature=PCDataChannel.operators[1]
   curvature.convex=0;curvature.flat=0.5;curvature.concave=1;PCapply()
   PCExpected=PChash();saveMaxFile (MCPFixtureDir+"optional-preparation.max") quiet:true
   loadMaxFile (MCPFixtureDir+"optional-preparation.max") quiet:true useFileUnits:true
   NCNode=getNodeByName "Native controller";NCRoot=NCNode.baseObject;NCLeaf=NCRoot.layerObjects[1];NCTerrain=(NCLeaf.validSurfaces())[1]
   PCcheck (NCRoot.procNativePublication==undefined) "Native publication remains session-only"
   NCRoot.procNativeRoute=true;NCRoot.procExplicitUpdate=true;try(PCapply())catch(NCRoot.procExplicitUpdate=false;throw());NCRoot.procExplicitUpdate=false
   PCcheck (PChash()==PCExpected) "Scale/channel/Data Channel scene round-trip preserves complete output"
   select NCNode;max modify mode;modPanel.setCurrentObject NCNode
   if not NCRoot.mainUI.controlsReady do NCRoot.mainUI.mountTimer.tick()
   NCRoot.updateMode=2
   PClog "PASS save/reopen"
  )
  "idleStart": (
   PCIdle=PCcounters();PCStarted=timeStamp()
   for cycle=1 to 2 do for slot in NCRoot.mainUI.slots do (slot.open=true;slot.rolledUp false;slot.open=false;slot.rolledUp true)
  )
  "idleEnd": (
   local after=PCcounters()
   PCcheck (timeStamp()-PCStarted>=60000) "At least sixty seconds actual idle"
   for i=1 to 5 do PCcheck (CyrusPresetSameValues PCIdle[i] after[i]) "Idle/panel browsing performs zero mesh reads/preparation/solve/preview work"
   for i in #(4,6,7) do PCcheck (PCIdle[6][i]==after[6][i]) "Idle/panels perform zero retained uploads"
   PCIdle=undefined;PCDataChannel=undefined;PCBefore=undefined
   PClog "PASS 65s idle and passive panels"
  )
  default:throw "Unknown optional controller phase"
 )
)
