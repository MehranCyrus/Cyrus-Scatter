-- Sustained authored Count/copy/Edit/ready-preset history. No reset between cycles.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native soak host required"
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NSNode,NSRoot,NSLeaf,NSEdit,NSBaseHash,NSLoadedHash,NSBaseLayers,NSIdle,NSStarted,NSBaseUndo,NSCycle,NSMemoryBaseline
 fn NScheck yes text=(if not yes do throw ("Native soak: "+text))
 fn NShash=(
  local nativeInfo=cyrusPlacementPublicationInfo NSRoot.procNativePublication
  NScheck (nativeInfo[1]==NSRoot.procPublishedInfo[1] and nativeInfo[2]==NSRoot.procEpoch and nativeInfo[5]==NSRoot.procPublishedInfo[5]) "Native and scripted publication restored together"
  cyrusRecipePublicationFingerprint NSRoot.groupSnapshotRows
 )
 fn NSapply=(NSRoot.procExplicitUpdate=true;try(NSRoot.refreshAll())catch(NSRoot.procExplicitUpdate=false;throw());NSRoot.procExplicitUpdate=false;for leaf in NSRoot.layerObjects do NScheck (leaf.previewError=="") leaf.previewError)
 fn NSstats=(#(NSRoot.procEpoch,NSRoot.groupBuilds,for leaf in NSRoot.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount)))
 case command[1] of (
  "setup": (
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    local terrain=plane width:100 length:100 widthsegs:32 lengthsegs:32,model=pyramid width:0.3 depth:0.3 height:1 pos:[75,0,0]
    NSNode=AminScatterObject name:"Native 0.86 sustained test";NSRoot=NSNode.baseObject
    if isProperty NSRoot #procNativeRoute do NSRoot.procNativeRoute=true
    NSRoot.updateMode=1;NSRoot.autoRender=false
    for i=1 to 2 do (NSRoot.newLayer();local leaf=NSRoot.selectedLayer();NSRoot.setLayerSurfaces leaf #(terrain);leaf.sources=#(model);leaf.amount=30000;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.sourceRadiiWU=#(0.0);leaf.showCenters=true)
    NSLeaf=NSRoot.layerObjects[1];NSRoot.selectLayer 1;NSEdit=CyrusScatterEdit();addModifier NSNode NSEdit;NSapply()
   )
   undo "Native soak preceding sentinel" on box pos:[-75,0,0]
   NSBaseHash=NShash();NSBaseLayers=NSRoot.layerObjects as array;NSBaseUndo=theHold.GetUndoNames();NSStarted=timeStamp();NSCycle=0;NSMemoryBaseline=undefined
  )
  "count": (
   NSCycle+=1;NScheck (NShash()==NSBaseHash and CyrusPresetSameValues NSBaseLayers (NSRoot.layerObjects as array)) "Cycle begins with exact baseline"
   undo "Native soak Count" on NSLeaf.amount=50000;NSapply();NSLoadedHash=NShash();NScheck (NSLeaf.generatedCount==50000) "Count change"
   max undo
  )
  "countUndo": (NSapply();NScheck (NShash()==NSBaseHash) "Count Undo";max redo)
  "countRedo": (NSapply();NScheck (NShash()==NSLoadedHash) "Count Redo";max undo)
  "copy": (
   NSapply();NScheck (NShash()==NSBaseHash) "Count returned to baseline"
   NSRoot.copySelectedLayer();NSapply();NScheck (NSRoot.layerObjects.count==3 and CyrusPresetSameValues (for rows in NSRoot.groupSnapshotRows collect rows.count) #(30000,30000,30000)) "Copy grows 60k to 90k"
   NSLoadedHash=NShash();max undo
  )
  "copyUndo": (NSapply();NScheck (NShash()==NSBaseHash and CyrusPresetSameValues NSBaseLayers (NSRoot.layerObjects as array)) "Copy Undo retains existing layers";max redo)
  "copyRedo": (NSapply();NScheck (NShash()==NSLoadedHash) "Copy Redo";max undo)
  "edit": (
   NSapply();undo "Native soak Edit" on (cyrusEditSelect NSEdit (for i=1 to 100 collect i);cyrusEditCommand NSEdit 4 (transMatrix [0.1,0.2,0]))
   NSapply();NSLoadedHash=NShash();NScheck (NSLoadedHash!=NSBaseHash) "Sparse Edit changed output";max undo
  )
  "editUndo": (NSapply();NScheck (NShash()==NSBaseHash) "Edit Undo";max redo)
  "editRedo": (NSapply();NScheck (NShash()==NSLoadedHash) "Edit Redo";max undo)
  "preset": (
   NSapply();NScheck (NShash()==NSBaseHash) "Before preset exact baseline"
   CyrusOpenReadyPreset NSRoot ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"soak-preset-path.txt"))
  )
  "presetReady": (
   NScheck (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") CyrusReadyPresetEditor.status.text
   NSLoadedHash=NShash();NScheck (NSRoot.layerObjects.count>2 and NSRoot.procNativePublication!=undefined) "Ready preset added native populations"
   destroyDialog CyrusReadyPresetEditor;max undo
  )
  "presetUndo": (NScheck (NShash()==NSBaseHash and CyrusPresetSameValues NSBaseLayers (NSRoot.layerObjects as array)) "Preset Undo without solve";max redo)
  "presetRedo": (NScheck (NShash()==NSLoadedHash) "Preset Redo without solve";max undo)
  "finishCycle": (
   NScheck (NShash()==NSBaseHash and CyrusPresetSameValues NSBaseUndo (theHold.GetUndoNames()) and not theHold.Holding()) "Cycle retains earlier history and exact baseline"
   -- Fixed-state observation outside measured artist commands. History/Redo
   -- roots remain intact; this is not a destructive full collection.
   gc light:true
   local f=openFile(MCPFixtureDir+"native-soak.tsv") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-soak.tsv")
   local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
   format "%\t%\t%\t%\t%\t%\t%\n" NSCycle (timeStamp()-NSStarted) (cyrusPlacementMemoryStats()) (cyrusEditMemoryStats()) (cyrusScriptBufferStats()) heapSize process.PrivateMemorySize64 to:f;close f
   local live=#((cyrusPlacementMemoryStats())[1],(cyrusEditMemoryStats())[1],(cyrusScriptBufferStats())[2]+(cyrusScriptBufferStats())[4])
   if NSCycle==2 do NSMemoryBaseline=live
   if NSCycle>2 do for i=1 to live.count do NScheck (live[i]<=NSMemoryBaseline[i]+2097152L) "Equal-history tracked memory does not accumulate abandoned layer generations"
   NSIdle=NSstats()
  )
  "idle": (NScheck (CyrusPresetSameValues NSIdle (NSstats())) "Idle interval has no calculation/preparation/preview work")
  "release": (
   NSNode=undefined;NSRoot=undefined;NSLeaf=undefined;NSEdit=undefined;NSBaseLayers=undefined
   with undo off resetMaxFile #noPrompt;gc light:true
   NScheck ((cyrusPlacementMemoryStats())[1]==0 and (cyrusEditMemoryStats())[1]==0) "Soak last-owner release"
  )
  default:throw "Unknown soak phase"
 )
)
