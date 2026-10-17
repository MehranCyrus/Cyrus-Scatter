-- Private, repeatable N01 fixtures. Never part of an installer payload.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeobserve-*/" do throw "Owned N01 observation host required."
 local io=dotNetClass "System.IO.File",clock=dotNetClass "System.Diagnostics.Stopwatch"
 local args=filterString (io.ReadAllText (MCPFixtureDir+"native-baseline-command.txt")) " "
 global NPNode,NPRoot,NPLeaf,NPKind,NPHashes,NPIdleState,NPIdleStart
 fn check value text=(if not value do throw ("N01: "+text))
 fn ownerRoots root = (
  local result=#(root.groupSnapshotRows,root.groupPrepareRows)
  for leaf in root.layerObjects do join result #(leaf.procReceiverCache,leaf.paintBaseRows,leaf.procPreparedRows)
  result
 )
 fn currentState root = (
  local display=cyrusRetainedStats (CyrusPointOwner NPNode),streams=cyrusRetainedStreamStats()
  #(root.procEpoch,root.groupBuilds,
    for leaf in root.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount),
    display[4],display[6],display[7],streams[2],streams[3],streams[4],streams[5])
 )
 fn writeLine path line=(local f=openFile path mode:"a";if f==undefined do f=createFile path;format "%\n" line to:f;close f)
 case args[1] of (
  "observer": (
   local tm=matrix3 1,anchor=[0,0,0],row=#(tm,1,1L,1,anchor,0L,false,2),rows=#(row,row)
   local a=cyrusObservePlacementValues #(rows,rows)
   check (a[1]==2 and a[4]==1 and a[5]==1 and a[6]==1) "Unique shared arrays/matrices/anchors counted once"
   append rows rows
   local b=cyrusObservePlacementValues #(rows)
   check (b[1]==2 and b[4]==1 and b[5]==1) "Cycle traversal is bounded and deduplicated"
   check (a[14]>0 and a[15]>=10*8) "Known payload and array capacity recorded"
   io.WriteAllText (MCPFixtureDir+"native-observer-check.txt") "PASS: shared aliases, cycle, known payload; no scene mutation"
  )
  "setup": (
   check (args.count==2 and findItem #("plane","mountain") args[2]>0) "Known fixture kind"
   NPKind=args[2];CyrusPerfHeadless=false;CyrusPointSuspended=true
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    local terrain=plane name:("N01 "+NPKind) length:100 width:100 lengthsegs:64 widthsegs:64
    convertToMesh terrain
    if NPKind=="mountain" do (
     for i=1 to terrain.numverts do (
      local p=getVert terrain i
      p.z=18.0*(exp(-((p.x/20.0)^2+(p.y/24.0)^2)))+3.0*(sin(p.x*5.0))*(cos(p.y*4.0))
      setVert terrain i p
     );update terrain
    )
    local model=pyramid name:"N01 pyramid" width:0.3 depth:0.3 height:1 pos:[75,0,0]
    NPNode=AminScatterObject name:("N01 "+NPKind+" controller");NPRoot=NPNode.baseObject;NPRoot.updateMode=1;NPRoot.autoRender=false
    NPRoot.newLayer();NPLeaf=NPRoot.selectedLayer();NPRoot.setLayerSurfaces NPLeaf #(terrain)
    NPLeaf.sources=#(model);NPLeaf.sourceWeights=#(1.0);NPLeaf.randomSeed=42;NPLeaf.amount=5000
    NPLeaf.sourceRadiiWU=#(0.0);NPLeaf.procSelfOverride=true;NPLeaf.procSelfEnabled=false;NPLeaf.procLayerSelfEnabled=false
    NPLeaf.scaleMinimum=1;NPLeaf.scaleMaximum=1;NPLeaf.yawMinimum=0;NPLeaf.yawMaximum=0;NPLeaf.tiltDegrees=0
    NPRoot.viewportMode=1;NPRoot.pointsPerPlant=1
    NPRoot.refreshAll();CyrusPointSuspended=false
   )
   check (NPLeaf.previewError=="" and NPLeaf.generatedCount==5000) "Fixture publishes all 5k placements"
   saveMaxFile (MCPFixtureDir+"n01-"+NPKind+".max") quiet:true
   NPHashes=#();select NPNode;max modify mode;modPanel.setCurrentObject NPNode
   if not NPRoot.mainUI.controlsReady do NPRoot.mainUI.mountTimer.tick()
   -- Establish an unrelated artist-like operation, retained through Count edits.
   undo "N01 unrelated scene marker" on (box name:"N01 unrelated marker" pos:[-75,0,0])
   check ((theHold.GetUndoNames()).count==1) "Unrelated history starts intact"
   writeLine (MCPFixtureDir+"native-baseline.txt") ("SETUP "+NPKind+" units=meters source=pyramid viewport=PointCloud pointsPerPlant=1")
  )
  "sample": (
   local amount=args[2] as integer,iteration=args[3] as integer
   check (findItem #(5000,50000,90000,200000) amount>0) "Known Count"
   undo "N01 Count" on (NPLeaf.amount=amount)
   local heapBefore=heapSize,freeBefore=heapFree,start=clock.GetTimestamp()
   NPRoot.refreshAll()
   local finish=clock.GetTimestamp(),heapAfter=heapSize,freeAfter=heapFree
   check (NPLeaf.previewError=="" and NPLeaf.generatedCount==amount and NPLeaf.requestedCount==amount) "Complete Count publication"
   check (findItem (theHold.GetUndoNames()) "N01 unrelated scene marker">0) "Unrelated history retained"
   -- Hashing, alias traversal and file I/O are outside the Update window.
   local hashStart=clock.GetTimestamp(),digest=cyrusRecipePublicationFingerprint NPRoot.groupSnapshotRows,hashFinish=clock.GetTimestamp()
   local previous=for pair in NPHashes where pair[1]==amount collect pair[2]
   if previous.count==0 then append NPHashes #(amount,digest) else check (previous[1]==digest) "Repeated complete ordered row fingerprint"
   local f=openFile (MCPFixtureDir+"native-baseline.tsv") mode:"a"
   if f==undefined do f=createFile (MCPFixtureDir+"native-baseline.tsv")
   format "%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\n" NPKind iteration amount start finish clock.Frequency heapBefore freeBefore heapAfter freeAfter NPRoot.procEpoch NPRoot.groupBuilds NPLeaf.procPreparedBuilds NPLeaf.procReceiverBuilds ((theHold.GetUndoNames()).count) digest hashStart hashFinish NPLeaf.cachedPointCount to:f
   close f
  )
  "observe": (
   gc light:true
   local a=cyrusObservePlacementValues (ownerRoots NPRoot),f=openFile (MCPFixtureDir+"native-observation.txt") mode:"a"
   if f==undefined do f=createFile (MCPFixtureDir+"native-observation.txt")
   format "% Count=% values=% buffers=% state=%\n" NPKind NPLeaf.amount a (cyrusScriptBufferStats()) (currentState NPRoot) to:f;close f
  )
  "idleStart": (NPIdleState=currentState NPRoot;NPIdleStart=clock.GetTimestamp())
  "idleEnd": (
   check ((clock.GetTimestamp()-NPIdleStart)/(clock.Frequency as double)>=120) "At least 120 seconds idle"
   check (CyrusPresetSameValues NPIdleState (currentState NPRoot)) "Idle has zero solve, receiver/preparation and upload changes"
   io.WriteAllText (MCPFixtureDir+"native-idle.txt") "PASS: 120 seconds, unchanged solve/preparation/receiver/upload counters"
  )
  default: throw "Unknown N01 command"
 )
)
