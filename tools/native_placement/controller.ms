-- Controller integration witness. Disposable matching Max 2027 pair only.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native controller host required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NCNode,NCRoot,NCLeaf,NCTerrain,NCModels,NCKind,NCHashes,NCBefore,NCIdle,NCIdleStart
 global NCCopiedRoot,NCCopiedName,NCCopiedHash
 fn NCCheck yes text=(if not yes do throw ("Native controller: "+text))
 fn NCWrite text=(local f=openFile(MCPFixtureDir+"native-controller.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-controller.txt");format "%\n" text to:f;close f)
 fn NCHash=(cyrusPlacementPublicationFingerprint NCRoot.groupSnapshotRows NCRoot.procPublishedRadii #("stable-comparison") (for leaf in NCRoot.layerObjects collect #(leaf.procLastStats,leaf.procLastRounds,leaf.procLastSurfaceStats)))
 fn NCExpected amount=(for pair in NCHashes where pair[1]==amount do return pair[2];throw "Missing comparison Count")
 fn NCApply=(NCRoot.refreshAll();for leaf in NCRoot.layerObjects where leaf.previewError!="" do throw leaf.previewError)
 fn NCCounters=(#(NCRoot.procEpoch,NCRoot.groupBuilds,(for leaf in NCRoot.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount)),(cyrusRetainedStats (CyrusPointOwner NCNode))))
 fn NCCount amount = (
  local before=cyrusPlacementTransportStats(),start=timeStamp()
  NCRoot.populationUI.distributionUI_countSpin.value=amount;NCRoot.populationUI.distributionUI_countSpin.changed amount
  local elapsed=timeStamp()-start
  -- The real handler deliberately defers work while a physical mouse button
  -- is held. Observe its existing release timer; never force an Update here.
  local deadline=timeStamp()+15000
  while NCLeaf.previewError=="" and (NCLeaf.requestedCount!=amount or NCLeaf.generatedCount!=amount) and timeStamp()<deadline do (windows.processPostedMessages();sleep 0.02)
  NCCheck (NCLeaf.previewError=="" and NCLeaf.requestedCount==amount and NCLeaf.generatedCount==amount) "Actual Count UI publishes the complete native successor"
  NCCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Count Update creates no placement-sized script rows/matrices/identities/readback"
  NCCheck ((NCHash())==NCExpected amount) "Every accepted field/radius/statistic equals legacy controller output"
  NCCheck (findItem (theHold.GetUndoNames()) "Native controller unrelated marker">0) "Unrelated artist-like history survives"
  NCWrite ("COUNT "+NCKind+" "+(amount as string)+" handlerMs="+(elapsed as string)+" settledMs="+((timeStamp()-start) as string)+" bytes="+((cyrusPlacementMemoryStats())[1] as string)+" scriptBuffers="+((cyrusScriptBufferStats()) as string))
 )
 case command[1] of (
  "setup": (
   NCKind=command[2];CyrusPerfHeadless=false;CyrusPointSuspended=true
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    NCTerrain=plane name:"Native controller terrain" width:100 length:100 widthsegs:64 lengthsegs:64
    convertToMesh NCTerrain
    if NCKind=="mountain" do (
     for i=1 to NCTerrain.numverts do (local p=getVert NCTerrain i;p.z=18.0*exp(-((p.x/20.0)^2+(p.y/24.0)^2))+3.0*sin(p.x*5.0)*cos(p.y*4.0);setVert NCTerrain i p);update NCTerrain
    )
    NCModels=#(pyramid name:"Native controller pyramid" width:0.3 depth:0.3 height:1 pos:[75,0,0])
    NCNode=AminScatterObject name:"Native controller";NCRoot=NCNode.baseObject;NCRoot.updateMode=1;NCRoot.autoRender=false
    NCRoot.newLayer();NCLeaf=NCRoot.selectedLayer();NCRoot.setLayerSurfaces NCLeaf #(NCTerrain)
    NCLeaf.sources=NCModels;NCLeaf.sourceWeights=#(1.0);NCLeaf.sourceRadiiWU=#(0.0);NCLeaf.sourceAutoRadius=#(false);NCLeaf.sourceShowRadius=#(false)
    NCLeaf.procSelfOverride=true;NCLeaf.procSelfEnabled=false;NCLeaf.procLayerSelfEnabled=false;NCLeaf.autoRender=false
    NCLeaf.randomSeed=42;NCLeaf.scaleMinimum=1;NCLeaf.scaleMaximum=1;NCLeaf.yawMinimum=0;NCLeaf.yawMaximum=0;NCLeaf.tiltDegrees=0
    NCLeaf.viewportMode=1;NCLeaf.pointsPerPlant=1;NCLeaf.showCenters=true
    NCHashes=#()
    for amount in #(5000,50000,200000,0) do (NCLeaf.amount=amount;NCApply();append NCHashes #(amount,NCHash()))
    NCRoot.procNativeRoute=true;NCLeaf.amount=5000;NCApply()
    NCCheck (cyrusPlacementIsNative NCRoot.groupSnapshotRows[1] and cyrusPlacementIsNative NCLeaf.procPreparedRows and cyrusPlacementIsNative NCLeaf.paintBaseRows) "Controller receiver/base/prepared/accepted storage stays native"
    NCCheck (NCRoot.procNativePublication!=undefined and (NCHash())==NCExpected 5000) "Complete controller publishes the coherent native frame"
    CyrusPointSuspended=false
   )
   select NCNode;max modify mode;modPanel.setCurrentObject NCNode
   if not NCRoot.mainUI.controlsReady do NCRoot.mainUI.mountTimer.tick()
   with undo off NCRoot.selectLayer 1
   NCRoot.populationUISlot.open=true;NCRoot.mainUI.bindEditors()
   NCRoot.mainUI.updateRadio.state=2;NCRoot.mainUI.updateRadio.changed 2
   undo "Native controller unrelated marker" on (box name:"Native controller marker" pos:[-75,0,0])
   cyrusPlacementTransportStats true
   NCBefore=NCHash();NCCount 50000
   NCWrite ("SETUP "+NCKind)
  )
  "undo": (max undo)
  "verifyUndo": (NCCheck (NCLeaf.amount==5000 and (NCHash())==NCBefore) "Ordinary Count Undo restores authored value and full native publication";NCWrite "PASS Count Undo")
  "redo": (max redo)
  "verifyRedo": (NCCheck (NCLeaf.amount==50000 and (NCHash())==NCExpected 50000) "Ordinary Count Redo restores full native publication";NCWrite "PASS Count Redo")
  "counts": (for amount in #(200000,0,5000,50000,200000,5000) do NCCount amount)
  "manual": (
   NCRoot.mainUI.updateRadio.state=1;NCRoot.mainUI.updateRadio.changed 1
   local before=NCHash(),epoch=NCRoot.procEpoch
   NCRoot.populationUI.distributionUI_countSpin.value=200000;NCRoot.populationUI.distributionUI_countSpin.changed 200000
   NCCheck (NCRoot.procEpoch==epoch and (NCHash())==before and NCLeaf.requestedCount==5000) "Manual pending Count does no calculation"
   NCRoot.mainUI.updateNow.pressed()
   NCCheck (NCLeaf.previewError=="" and (NCHash())==NCExpected 200000) "Explicit Update publishes the native pending Count"
   NCRoot.mainUI.updateRadio.state=2;NCRoot.mainUI.updateRadio.changed 2
   NCWrite "PASS Manual/Update/Live"
  )
  "failure": (
   local prior=NCRoot.procNativePublication,hash=NCHash(),epoch=NCRoot.procEpoch,cache=NCLeaf.cachedPoints
   with undo off NCLeaf.procRadiusIDs=#("owned-invalid-radius")
   NCRoot.populationUI.distributionUI_countSpin.value=5000;NCRoot.populationUI.distributionUI_countSpin.changed 5000
   with undo off NCLeaf.procRadiusIDs=#()
   NCCheck (NCLeaf.previewError!="" and NCRoot.procNativePublication==prior and NCRoot.procEpoch==epoch and (NCHash())==hash and cyrusPreviewContentEqual cache NCLeaf.cachedPoints) "Post-preparation failure retains the exact native frame and retained display"
   NCApply();NCCheck (NCLeaf.previewError=="" and (NCHash())==NCExpected 5000) "Valid successor recovers after staged failure"
   NCWrite "PASS failure/retention/recovery"
  )
  "display": (
   local before=NCHash(),builds=NCRoot.groupBuilds
   for mode in #(2,3,1) do (
    NCLeaf.viewportMode=mode;NCRoot.procEnsureDisplay()
    NCCheck ((NCHash())==before and NCRoot.groupBuilds==builds and NCLeaf.cachedPoints!=undefined) "Point/proxy/mesh display switching retains the same native placement result"
   )
   for i=1 to 3 do (completeRedraw();windows.processPostedMessages())
   NCWrite "PASS retained display switching"
  )
  "bindings": (
   local prior=NCRoot.procNativePublication,oldContext=NCLeaf.procNativeContext,oldHandle=(cyrusPlacementContextSources oldContext)[1][2]
   local replacement=copy NCModels[1]
   with undo off NCLeaf.sources=#(replacement)
   NCApply()
   local info=NCRoot.procPublicationInfo(),sources=cyrusPlacementContextSources NCLeaf.procNativeContext
   NCCheck (sources[1][2]==getHandleByAnim replacement and sources[1][2]!=oldHandle and info[6][1][10][1][2]==sources[1][2]) "Equal-count asset replacement publishes its actual new source binding"
   NCCheck ((cyrusPlacementContextSources oldContext)[1][2]==oldHandle) "An old pinned frame retains its original asset correspondence"
   with undo off NCLeaf.sources=NCModels
   NCApply();delete replacement
   NCCheck ((NCHash())==NCExpected 5000) "Restoring the asset restores exact complete placement data"
   NCWrite "PASS same-cardinality source binding"
  )
  "panels": (
   local before=NCCounters(),hash=NCHash(),transport=cyrusPlacementTransportStats()
   for cycle=1 to 2 do for slot in NCRoot.mainUI.slots do (slot.open=true;slot.rolledUp false;slot.open=false;slot.rolledUp true)
   local after=NCCounters()
   NCCheck (CyrusPresetSameValues before[1] after[1] and CyrusPresetSameValues before[2] after[2] and CyrusPresetSameValues before[3] after[3] and (NCHash())==hash) "Modify panel browsing does no placement, preparation or preview work"
   NCCheck (NGAllCoveredSame transport (cyrusPlacementTransportStats())) "Modify panel browsing materializes no placements"
   NCWrite "PASS passive panel browsing"
  )
  "copy": (
   local copied=copy NCNode,root=copied.baseObject,leaf=root.layerObjects[1]
   NCCheck (root!=NCRoot and leaf!=NCLeaf) "Copy creates independent authored controller/layer owners"
   root.procNativeRoute=true;root.updateMode=1
   root.procExplicitUpdate=true
   try(root.refreshAll())catch(root.procExplicitUpdate=false;throw())
   root.procExplicitUpdate=false
   NCCheck (leaf.previewError=="" and cyrusPlacementIsNative root.groupSnapshotRows[1]) "Copied setup can calculate a complete native result"
   NCCheck (leaf.procNativeOwner!=NCLeaf.procNativeOwner and root.procNativeOwner!=NCRoot.procNativeOwner) "Copied controller/layer sessions have independent native owners"
   NCCheck ((cyrusRecipePublicationFingerprint root.groupSnapshotRows)==(cyrusRecipePublicationFingerprint NCRoot.groupSnapshotRows)) "Copy preserves every placement field"
   with undo off leaf.amount=50000
   root.procExplicitUpdate=true;root.refreshAll();root.procExplicitUpdate=false
   NCCheck (leaf.generatedCount==50000 and NCLeaf.amount==5000 and NCLeaf.generatedCount==5000) "Copied Count changes leave the original controller intact"
   NCCopiedRoot=root;NCCopiedName=copied.name;NCCopiedHash=cyrusRecipePublicationFingerprint root.groupSnapshotRows
   undo "Native delete copied setup" on delete copied
   windows.processPostedMessages();gc light:true
   NCWrite "PASS native copy independence"
  )
  "undoDelete": (max undo)
  "verifyDeleteUndo": (
   local node=getNodeByName NCCopiedName
   NCCheck (isValidNode node and node.baseObject==NCCopiedRoot) "Undo deletion restores the independent controller owner"
   NCCheck (node.baseObject.procNativePublication!=undefined and (cyrusRecipePublicationFingerprint node.baseObject.groupSnapshotRows)==NCCopiedHash) "Undo deletion preserves the complete native Manual result"
   NCWrite "PASS native deletion Undo"
  )
  "redoDelete": (max redo)
  "verifyDeleteRedo": (
   NCCheck (not isValidNode (getNodeByName NCCopiedName)) "Redo deletion removes the copied controller"
   NCWrite "PASS native deletion Redo"
  )
  "reopen": (
   local expected=NCHash(),path=MCPFixtureDir+"native-controller-"+NCKind+".max"
   saveMaxFile path quiet:true
   loadMaxFile path quiet:true useFileUnits:true
   NCNode=getNodeByName "Native controller";NCRoot=NCNode.baseObject;NCLeaf=NCRoot.layerObjects[1]
   NCModels=NCLeaf.validSources();NCTerrain=(NCLeaf.validSurfaces())[1]
   NCCheck (NCRoot.procNativePublication==undefined) "Native publication/session handles are not serialized as scene data"
   NCRoot.procNativeRoute=true;NCRoot.procExplicitUpdate=true
   try(NCApply())catch(NCRoot.procExplicitUpdate=false;throw())
   NCRoot.procExplicitUpdate=false
   NCCheck ((NCHash())==expected and cyrusPlacementIsNative NCRoot.groupSnapshotRows[1]) "Save/reopen restores authored settings and exact native calculation"
   select NCNode;max modify mode;modPanel.setCurrentObject NCNode
   if not NCRoot.mainUI.controlsReady do NCRoot.mainUI.mountTimer.tick()
   for i=1 to 3 do (completeRedraw();windows.processPostedMessages())
   NCWrite "PASS native save/reopen"
  )
  "idleStart": (NCIdle=NCCounters();NCIdleStart=timeStamp())
  "benchmark": (
   local clock=dotNetClass "System.Diagnostics.Stopwatch"
   for native in #(false,true) do (
    NCRoot.procNativeRoute=native
    for repetition=0 to 10 do for amount in #(5000,50000,200000) do (
     with undo off NCLeaf.amount=amount
     local start=clock.GetTimestamp()
     NCApply()
     local finish=clock.GetTimestamp(),hash=NCHash()
     NCCheck (hash==NCExpected amount) "Matched benchmark keeps complete ordered fields/radii/statistics"
     local f=openFile (MCPFixtureDir+"controller-benchmark.tsv") mode:"a"
     if f==undefined do f=createFile (MCPFixtureDir+"controller-benchmark.tsv")
     format "%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\n" NCKind native repetition amount start finish clock.Frequency heapSize heapFree (cyrusPlacementMemoryStats())[1] hash to:f
     close f
    )
   )
   with undo off NCLeaf.amount=5000
   NCApply()
   NCWrite ("PASS matched controller benchmark "+NCKind)
  )
  "idleEnd": (
   local current=NCCounters()
   NCCheck (timeStamp()-NCIdleStart>=60000) "At least sixty seconds actual idle"
   NCCheck (CyrusPresetSameValues NCIdle[1] current[1] and CyrusPresetSameValues NCIdle[2] current[2] and CyrusPresetSameValues NCIdle[3] current[3]) "Idle performs zero calculation/preparation/preview work"
   for i in #(4,6,7) do NCCheck (NCIdle[4][i]==current[4][i]) "Idle performs no retained buffer preparation or upload"
   NCWrite "PASS 65s idle"
  )
  "release": (
   NCBefore=undefined;NCIdle=undefined;NCRoot=undefined;NCLeaf=undefined;NCNode=undefined;NCTerrain=undefined;NCModels=undefined;NCCopiedRoot=undefined
   resetMaxFile #noPrompt;gc light:true
   local memory=cyrusPlacementMemoryStats(),buffers=cyrusScriptBufferStats()
   NCCheck (memory[1]==0 and memory[6]==0 and memory[7]==0 and buffers[3]==0 and buffers[4]==0) "Scene retirement releases all native controller stores, selections and radii despite transient wrappers"
   NCWrite "PASS controller release"
  )
  default: throw "Unknown native controller phase"
 )
)
