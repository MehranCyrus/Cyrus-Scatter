-- Native-only capacity; no legacy warmup or raised saved heap preference.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native host required"
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NKNode,NKRoot,NKLeaf,NKTerrain,NKModel,NKHashes,NKBefore,NKCount,NKHeap
 fn NKcheck yes message=(if not yes do throw ("Native capacity: "+message))
 fn NKhash=(cyrusPlacementPublicationFingerprint NKRoot.groupSnapshotRows NKRoot.procPublishedRadii #("native-capacity") (for leaf in NKRoot.layerObjects collect #(leaf.procLastStats,leaf.procLastRounds,leaf.procLastSurfaceStats)))
 fn NKapply=(NKRoot.procExplicitUpdate=true;try(NKRoot.refreshAll())catch(NKRoot.procExplicitUpdate=false;throw());NKRoot.procExplicitUpdate=false;NKcheck (NKLeaf.previewError=="") NKLeaf.previewError)
 case command[1] of (
  "setup": (
   NKHeap=heapSize;NKHashes=#();with undo off (
    resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    NKTerrain=plane width:100 length:100 widthsegs:64 lengthsegs:64
    NKModel=pyramid width:0.3 depth:0.3 height:1 pos:[75,0,0]
    NKNode=AminScatterObject name:"Native capacity";NKRoot=NKNode.baseObject;if isProperty NKRoot #procNativeRoute do NKRoot.procNativeRoute=true;NKRoot.updateMode=1;NKRoot.autoRender=false
    NKRoot.newLayer();NKLeaf=NKRoot.selectedLayer();NKRoot.setLayerSurfaces NKLeaf #(NKTerrain);NKLeaf.sources=#(NKModel)
    NKLeaf.procSelfOverride=true;NKLeaf.procSelfEnabled=false;NKLeaf.sourceRadiiWU=#(0.0);NKLeaf.showCenters=true;NKLeaf.amount=0;NKapply()
   )
   undo "Native capacity preceding marker" on box name:"Capacity sentinel" pos:[-75,0,0]
   cyrusPlacementTransportStats true
  )
  "count": (
   NKCount=command[2] as integer;local before=cyrusPlacementTransportStats(),clock=dotNetClass "System.Diagnostics.Stopwatch"
   NKBefore=NKhash();undo "Native capacity Count" on NKLeaf.amount=NKCount
   local start=clock.GetTimestamp();NKapply();local elapsed=(clock.GetTimestamp()-start)*1000.0/clock.Frequency
   NKcheck (NKLeaf.generatedCount==NKCount) "Every requested candidate is accepted"
   NKcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "No population script rows/matrices/strings"
   NKcheck (findItem (theHold.GetUndoNames()) "Native capacity preceding marker">0) "Preceding history remains available"
   local hash=NKhash(),expected=undefined
   for pair in NKHashes where pair[1]==NKCount do expected=pair[2]
   if expected==undefined then append NKHashes #(NKCount,hash) else NKcheck (hash==expected) "Repeated Count has exact ordered fields/radii/statistics"
   local f=openFile(MCPFixtureDir+"native-capacity.tsv") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-capacity.tsv")
   format "%\t%\t%\t%\t%\t%\t%\t%\n" NKCount elapsed NKHeap heapSize heapFree (cyrusPlacementMemoryStats()) (cyrusScriptBufferStats()) hash to:f;close f
  )
  "undo": (max undo)
  "verifyUndo": (NKapply();NKcheck (NKhash()==NKBefore) "Count Undo restores full publication";max redo)
  "verifyRedo": (NKapply();NKcheck (NKLeaf.generatedCount==NKCount) "Count Redo restores full population")
  "over": (
   local frame=NKRoot.procNativePublication,hash=NKhash(),epoch=NKRoot.procEpoch
   NKLeaf.amount=1000001;NKRoot.refreshAll()
   NKcheck (NKLeaf.previewError!="" and NKRoot.procNativePublication==frame and NKRoot.procEpoch==epoch and NKhash()==hash) "Above-cap request retains complete epoch"
   NKLeaf.amount=NKCount;NKapply();NKcheck (NKhash()==hash) "Recovery after bounded admission rejection"
  )
  "release": (
   NKNode=undefined;NKRoot=undefined;NKLeaf=undefined;NKTerrain=undefined;NKModel=undefined
   with undo off resetMaxFile #noPrompt;gc light:true
   NKcheck ((cyrusPlacementMemoryStats())[1]==0 and (cyrusScriptBufferStats())[2]==0 and (cyrusScriptBufferStats())[4]==0) "All tracked native capacity releases at scene departure"
  )
  default:throw "Unknown capacity command"
 )
)
