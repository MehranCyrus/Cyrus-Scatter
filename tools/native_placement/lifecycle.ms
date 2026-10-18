-- Structural Edit ownership, receiver restoration and New Setup history.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native lifecycle host required"
 local command=(dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")
 global NLNode,NLRoot,NLLeaves,NLEdit,NLTerrain,NLExpected,NLSubset,NLClone,NLDocument,NLBindings,NLImported,NLImportHash
 fn NLcheck yes text=(if not yes do throw ("Native lifecycle: "+text))
 fn NLhash root=(cyrusRecipePublicationFingerprint root.groupSnapshotRows)
 fn NLapply root=(root.refreshAll();for leaf in root.layerObjects do NLcheck (leaf.previewError=="") leaf.previewError)
 case command of (
  "setup": (
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    NLTerrain=plane width:100 length:100 widthsegs:16 lengthsegs:16
    local model=pyramid width:.3 depth:.3 height:1 pos:[75,0,0]
    NLNode=AminScatterObject name:"Native lifecycle";NLRoot=NLNode.baseObject;NLRoot.updateMode=1;NLRoot.autoRender=false
    for i=1 to 2 do (
     NLRoot.newLayer();local leaf=NLRoot.selectedLayer();NLRoot.setLayerSurfaces leaf #(NLTerrain)
     leaf.sources=#(model);leaf.amount=5000;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.sourceRadiiWU=#(0.0)
    )
    NLapply NLRoot;NLLeaves=NLRoot.layerObjects as array
    NLBindings=#();NLDocument=CyrusRecipeCapture NLRoot NLLeaves "Native new setup test" bindingResult:NLBindings
    NLEdit=CyrusScatterEdit();addModifier NLNode NLEdit;NLapply NLRoot
   )
   undo "Native lifecycle sentinel" on box pos:[-75,0,0]
   undo "Native lifecycle authored edit" on (cyrusEditSelect NLEdit (for i=1 to 100 collect i);cyrusEditCommand NLEdit 4 (transMatrix [1,0,0]))
   NLapply NLRoot;NLExpected=NLhash NLRoot
   NLRoot.selectLayer 1;NLRoot.removePopulation();NLapply NLRoot
   NLcheck (NLRoot.layerObjects.count==1) "Remove edited layer";NLSubset=NLhash NLRoot;max undo
  )
  "removeUndo": (NLapply NLRoot;NLcheck (NLhash NLRoot==NLExpected and CyrusPresetSameValues NLLeaves (NLRoot.layerObjects as array)) "Remove Undo restores authored native layer";max redo)
  "removeRedo": (NLapply NLRoot;NLcheck (NLhash NLRoot==NLSubset) "Remove Redo";max undo)
  "clone": (
   NLapply NLRoot;NLcheck (NLhash NLRoot==NLExpected) "Repeated remove Undo"
   NLClone=copy NLNode;NLapply NLClone.baseObject
   NLcheck (NLhash NLClone.baseObject==NLExpected and NLClone.modifiers[1]!=NLEdit) "Clone owns independent Edit with exact authored output"
   undo "Native lifecycle clone move" on cyrusEditCommand NLClone.modifiers[1] 4 (transMatrix [2,0,0])
   NLapply NLClone.baseObject;NLapply NLRoot
   NLcheck (NLhash NLClone.baseObject!=NLExpected and NLhash NLRoot==NLExpected) "Clone edit leaves original intact"
   max undo
  )
  "receiver": (
   NLapply NLClone.baseObject;NLcheck (NLhash NLClone.baseObject==NLExpected) "Clone Undo"
   local previous=NLRoot.procNativePublication
   undo "Native lifecycle receiver topology" on NLTerrain.widthsegs=17
   NLRoot.refreshAll()
   NLcheck (NLLeaves[1].previewError!="" and NLRoot.procNativePublication==previous and NLhash NLRoot==NLExpected) "Incompatible receiver topology retains complete prior result"
   max undo
  )
  "receiverUndo": (NLapply NLRoot;NLcheck (NLhash NLRoot==NLExpected) "Restoring topology restores authored Edit without Reset")
  "newSetup": (
   NLImported=CyrusRecipeImport undefined NLDocument NLBindings newSetup:true variation:#same
   NLapply NLImported[1];NLImportHash=NLhash NLImported[1]
   NLcheck (NLImported[1]!=NLRoot and NLImported[1].procNativeOwner!=NLRoot.procNativeOwner) "Recipe New Setup has independent native owner"
   max undo
  )
  "newUndo": (NLcheck (not isValidNode NLImported[3] and NLhash NLRoot==NLExpected) "New Setup Undo preserves original";max redo)
  "newRedo": (NLcheck (isValidNode NLImported[3]) "New Setup Redo node";NLapply NLImported[1];NLcheck (NLhash NLImported[1]==NLImportHash) "New Setup Redo full output";max undo)
  "abandon": (
   undo "Native lifecycle abandon new setup" on box pos:[-70,0,0]
   NLImported=undefined;gc light:true
   NLcheck ((theHold.GetRedoNames()).count==0 and findItem (theHold.GetUndoNames()) "Native lifecycle sentinel">0) "Abandoned New Setup retains unrelated Undo"
   NLNode=undefined;NLRoot=undefined;NLLeaves=undefined;NLEdit=undefined;NLTerrain=undefined;NLClone=undefined;NLBindings=undefined;NLDocument=undefined
   with undo off resetMaxFile #noPrompt;gc light:true
   NLcheck ((cyrusPlacementMemoryStats())[1]==0 and (cyrusEditMemoryStats())[1]==0) "Last-owner release after structural history"
  )
  default:throw "Unknown native lifecycle phase"
 )
 local log=openFile(MCPFixtureDir+"native-lifecycle.txt") mode:"a";if log==undefined do log=createFile(MCPFixtureDir+"native-lifecycle.txt")
 format "PASS %\n" command to:log;close log
)
