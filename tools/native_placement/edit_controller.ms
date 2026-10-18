-- Native Edit, old saved-state parity, real holds and sparse history accounting.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native Edit host required"
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NEEdit,NEBefore,NEAfter,NESelectBefore,NEBaseMemory,NECase,NEOldHash,NESaved,NEClone
 global NCNode,NCRoot,NCLeaf,NCModels,NCTerrain,NCKind
 fn NEcheck yes text=(if not yes do throw ("Native Edit: "+text))
 fn NEwrite label=(local f=openFile(MCPFixtureDir+"native-edit.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-edit.txt");format "% % editMemory=% placements=%\n" NCKind label (cyrusEditMemoryStats NEEdit) (cyrusPlacementMemoryStats()) to:f;close f)
 fn NEhash=(cyrusRecipePublicationFingerprint NCRoot.groupSnapshotRows)
 fn NEapply=(NCRoot.refreshAll();if NCLeaf.previewError!="" do throw NCLeaf.previewError)
 fn NEparity label=(
  NCRoot.procNativeRoute=false;NEapply();local expected=NEhash()
  NCRoot.procNativeRoute=true;local before=cyrusPlacementTransportStats();NEapply()
  NEcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) (label+" has no bulk script transport")
  NEcheck (NEhash()==expected) (label+" full ordered output matches comparison")
  NEwrite ("PASS "+label)
 )
 case command[1] of (
  "old": (
   NCKind=command[2]
   local dir="F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-20261018-07/"
   local f=openFile(dir+"edit-baseline-"+NCKind+".txt");NEOldHash=readLine f;close f
   loadMaxFile (dir+"edit-baseline-"+NCKind+".max") quiet:true useFileUnits:true
   NCNode=getNodeByName "Native controller";NCRoot=NCNode.baseObject;NCLeaf=NCRoot.layerObjects[1];NCModels=NCLeaf.validSources();NCTerrain=(NCLeaf.validSurfaces())[1]
   NEEdit=NCNode.modifiers[1];NCRoot.updateMode=1;NCRoot.procNativeRoute=true;NEapply()
   NEcheck (NEhash()==NEOldHash) "Old saved multi-modifier move/rotate/scale/copy/delete scene matches full ordered output"
   NEparity "Old authored stack on native and comparison routes"
   NEBefore=NEhash();NESelectBefore=cyrusEditSelectedIDs #(NEEdit) NCLeaf.editLayerKey
   undo "Native Edit move" on cyrusEditCommand NEEdit 4 (transMatrix [1,2,3])
   NEapply();NEAfter=NEhash();NEcheck (NEAfter!=NEBefore) "Move changes output"
   max undo
  )
  "undo": (NEapply();NEcheck (NEhash()==NEBefore and CyrusPresetSameValues NESelectBefore (cyrusEditSelectedIDs #(NEEdit) NCLeaf.editLayerKey)) "Undo restores every field and selection";max redo)
  "redo": (NEapply();NEcheck (NEhash()==NEAfter) "Redo restores every field";max undo)
  "repeated": (NEapply();NEcheck (NEhash()==NEBefore) "Repeated Undo";max redo)
  "gesture": (
   NEapply();NEcheck (NEhash()==NEAfter) "Repeated Redo"
   NEBefore=NEhash();local names=theHold.GetUndoNames(),before=cyrusEditMemoryStats NEEdit
   theHold.Begin()
   try (
    cyrusEditCommand NEEdit 4 (transMatrix [30,0,0]);NEapply()
    NEcheck (NEhash()!=NEBefore) "Gesture changes output"
    theHold.Restore();NEapply();NEcheck (NEhash()==NEBefore) "Restore(false) restores authored edit"
    theHold.Restore();NEapply();NEcheck (NEhash()==NEBefore) "Repeated Restore(false) is idempotent"
    cyrusEditCommand NEEdit 4 (transMatrix [10,0,0]);NEapply();theHold.Cancel()
   )catch(if theHold.Holding() do theHold.Cancel();throw())
   NEapply();NEcheck (NEhash()==NEBefore and CyrusPresetSameValues names (theHold.GetUndoNames())) "Cancel restores output and previous history"
   -- Max does not promise to query Size during Cancel. The separate SDK
   -- qualification build explicitly calls Hold::Size on real Edit restores.
   NEparity "Actual restore/cancel"
   -- Count changes retain authored candidates and copies; no ordinal identity rewrite.
   NCLeaf.amount=100;NEparity "Lower Count with authored protection"
   NCLeaf.amount=5000;NEparity "Raise Count restores dormant ordering"
   local expected=NEhash(),prior=NCRoot.procNativePublication,ids=cyrusEditSelectedIDs #(NEEdit) NCLeaf.editLayerKey
   NCLeaf.procRadiusIDs=#("native-invalid-radius");NCRoot.refreshAll()
   NEcheck (NCLeaf.previewError!="" and NCRoot.procNativePublication==prior and NEhash()==expected and CyrusPresetSameValues ids (cyrusEditSelectedIDs #(NEEdit) NCLeaf.editLayerKey)) "Downstream failure rolls back Edit binding/selection and publication"
   NCLeaf.procRadiusIDs=#();NEapply();NEcheck (NEhash()==expected) "Failed Edit successor recovers"
   NEwrite "PASS history, Count and transaction rollback"
   NESaved=NEhash();saveMaxFile(MCPFixtureDir+"native-edit-"+NCKind+".max") quiet:true
   loadMaxFile(MCPFixtureDir+"native-edit-"+NCKind+".max") quiet:true useFileUnits:true
   NCNode=getNodeByName "Native controller";NCRoot=NCNode.baseObject;NCLeaf=NCRoot.layerObjects[1];NEEdit=NCNode.modifiers[1]
   NCRoot.procNativeRoute=true;NEapply();NEcheck (NEhash()==NESaved) "New representation saves and reopens exact fields"
   NEwrite "PASS save/reopen unchanged native Edit chunk"
  )
  "memory": (
   NEEdit=undefined;with undo off resetMaxFile #noPrompt;gc light:true
   NEcheck ((cyrusEditMemoryStats())[1]==0 and (cyrusEditMemoryStats())[6]==0) "Scene departure releases unique Edit storage and restores"
   with undo off (
    NCTerrain=plane width:100 length:100;NCModels=#(pyramid width:0.2 depth:0.2 height:1 pos:[75,0,0])
    NCNode=AminScatterObject name:"Native Edit memory";NCRoot=NCNode.baseObject;NCRoot.updateMode=1;NCRoot.autoRender=false;NCRoot.procNativeRoute=true
    NCRoot.newLayer();NCLeaf=NCRoot.selectedLayer();NCRoot.setLayerSurfaces NCLeaf #(NCTerrain);NCLeaf.sources=NCModels;NCLeaf.amount=200000
    NCLeaf.procSelfOverride=true;NCLeaf.procSelfEnabled=false;NCLeaf.sourceRadiiWU=#(0.0)
    NEEdit=CyrusScatterEdit();addModifier NCNode NEEdit;NEapply()
   )
   NEwrite "MEMORY 200k initialized"
   undo "Native Edit memory unrelated marker" on box name:"Edit memory marker" pos:[-75,0,0]
   for selected in #(1,100,10000,200000) do (
    local before=cyrusEditMemoryStats NEEdit
    theHold.Begin()
    cyrusEditSelect NEEdit (for i=1 to selected collect i)
    cyrusEditCommand NEEdit 4 (transMatrix [0.01,0,0])
    local after=cyrusEditMemoryStats NEEdit,delta=after[1]-before[1]
    if selected==1 do NEcheck (delta<500000) "One selection/move does not copy all 200k matrices or rows"
    if selected==100 do NEcheck (delta<500000) "100 nearby moves detach bounded blocks"
    theHold.Accept ("Native Edit memory "+(selected as string))
    NEcheck (findItem (theHold.GetUndoNames()) "Native Edit memory unrelated marker">0) "Edit memory admission preserves unrelated history"
    NEcheck (findItem (theHold.GetUndoNames()) ("Native Edit memory "+(selected as string))>0) "Max accepted this native Edit history record"
    NEapply();NEwrite ("MEMORY selected="+(selected as string)+" commandDelta="+(delta as string))
   )
   NEBefore=NEhash();NEwrite "PASS sparse command history measurements"
   max undo
  )
  "memoryUndo": (NEapply();NEcheck (NEhash()!=NEBefore) "Large-selection Undo changes output";max redo)
  "memoryRedo": (NEapply();NEcheck (NEhash()==NEBefore) "Large-selection Redo restores exact result";max undo)
  "abandon": (
   NEapply();local restores=(cyrusEditMemoryStats NEEdit)[6]
   undo "Native Edit abandon redo marker" on box pos:[-75,0,0]
   NEcheck ((cyrusEditMemoryStats NEEdit)[6]<restores and (theHold.GetRedoNames()).count==0) "Abandoned Redo releases native restore ownership"
   NEwrite "PASS abandoned Redo"
   NEEdit=undefined;NCNode=undefined;NCRoot=undefined;NCLeaf=undefined;NCModels=undefined;NCTerrain=undefined
   with undo off resetMaxFile #noPrompt;gc light:true
   NEcheck ((cyrusEditMemoryStats())[1]==0 and (cyrusEditMemoryStats())[6]==0) "All Edit native storage and history release on reset"
  )
  default:throw "Unknown native Edit phase"
 )
)
