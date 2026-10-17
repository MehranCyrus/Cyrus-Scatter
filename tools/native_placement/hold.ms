-- SDK hold/Size observations, never production Undo implementation or UI.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativegenerate-hold-*/" do throw "Owned native hold host required."
 local phase=(dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")
 global NGA,NGB,NGC,NGOwner,NGHoldState,NGHoldBefore,NGHoldAfter
 fn HCheck yes text=(if not yes do throw ("Native hold: "+text))
 fn HMatches buffer=(local state=cyrusOwnedPlacementProbeState(),token=cyrusPlacementToken buffer;state[1]==token[1] and state[2]==token[2] and state[3]==token[3] and state[4]==buffer.count)
 fn HLog label=(local f=openFile(MCPFixtureDir+"hold-observations.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"hold-observations.txt");format "% state=% undo=% redo=% native=%\n" label (cyrusOwnedPlacementProbeState()) (theHold.GetUndoNames()) (theHold.GetRedoNames()) (cyrusPlacementMemoryStats()) to:f;close f)
 case phase of (
  "ordinary": (
   HCheck (cyrusOwnedPlacementProbeVersion()==1) "Qualification-only SDK probe loaded"
   HCheck (HMatches NGA) "Seed is the complete 5k generation"
   NGHoldBefore=cyrusPlacementMemoryStats()
   undo "Native owned ordinary hold" on cyrusOwnedPlacementProbeSet NGB
   HCheck (HMatches NGB) "Accepted ordinary hold publishes 50k immutable generation"
   HCheck (findItem (theHold.GetUndoNames()) "Owned prior scene edit">0) "Prior artist-like history retained"
   HLog "ordinary-accepted"
  )
  "undo": (max undo)
  "redo": (max redo)
  "checkA": (HCheck (HMatches NGA) "Undo restores the original full immutable generation";HLog "undo-A")
  "checkB": (
   HCheck (HMatches NGB) "Redo restores the exact 50k generation"
   local after=cyrusPlacementMemoryStats()
   HCheck (after[1]==NGHoldBefore[1] and after[4]==NGHoldBefore[4]) "Repeated Undo/Redo pins existing native storage without allocating new vector payload"
   HLog "redo-B"
  )
  "cancel": (
   local names=theHold.GetUndoNames()
   cyrusOwnedPlacementProbeHold 1 "begin"
   cyrusOwnedPlacementProbeSet NGC
   HLog "gesture-applied-C"
   local observedSize=cyrusOwnedPlacementProbeHoldSize()
   HCheck (observedSize>50000L*96L) "Hold Size accounts for the retained before generation and restore record"
   cyrusOwnedPlacementProbeHold 4 "restore-preview"
   HCheck (HMatches NGB) "Restore(false) resets gesture to its before generation"
   cyrusOwnedPlacementProbeHold 4 "restore-again"
   HCheck (HMatches NGB) "Repeated Restore(false) is idempotent"
   cyrusOwnedPlacementProbeSet NGC
   cyrusOwnedPlacementProbeHold 3 "cancel"
   HCheck (HMatches NGB and CyrusPresetSameValues names (theHold.GetUndoNames())) "Cancelled gesture restores exact generation and adds no Undo item"
   HLog ("cancelled holdSize="+(observedSize as string))
  )
  "super": (
   local before=(theHold.GetUndoNames()).count
   cyrusOwnedPlacementProbeHold 5 "super-begin"
   cyrusOwnedPlacementProbeHold 1 "child-a"
   cyrusOwnedPlacementProbeSet NGA
   cyrusOwnedPlacementProbeHold 2 "Native child A"
   cyrusOwnedPlacementProbeHold 1 "child-c"
   cyrusOwnedPlacementProbeSet NGC
   cyrusOwnedPlacementProbeHold 2 "Native child C"
   cyrusOwnedPlacementProbeHold 6 "Native grouped states"
   local state=cyrusOwnedPlacementProbeState()
   HCheck (HMatches NGC and state[17]==0 and state[18]==0) "Super hold completes with no stranded hold"
   HCheck ((theHold.GetUndoNames()).count==before+1) "Two child changes become one host history operation"
   HLog "super-accepted-C"
  )
  "checkSuperUndo": (HCheck (HMatches NGB) "Grouped Undo restores the previous 50k generation";HLog "super-undo-B")
  "checkSuperRedo": (HCheck (HMatches NGC) "Grouped Redo restores the final 90k generation";HLog "super-redo-C")
  "abandon": (
   HCheck (HMatches NGA and (theHold.GetRedoNames()).count>=2) "Both native operations undone before abandoning Redo"
   undo "Owned new scene edit" on (box name:"Abandon redo marker")
   local state=cyrusOwnedPlacementProbeState()
   HCheck (state[12]==0 and state[13]==0 and state[5]==state[6]) "Abandoning Redo destroys every native restore record and releases its shared pins"
   HCheck (findItem (theHold.GetUndoNames()) "Owned prior scene edit">0) "Unrelated prior history survives native Undo/Redo and abandonment"
   HLog "abandoned-redo"
  )
  "finish": (
   cyrusOwnedPlacementProbeSeed undefined
   NGA=undefined;NGB=undefined;NGC=undefined
   gc light:true
   local memory=cyrusPlacementMemoryStats(),state=cyrusOwnedPlacementProbeState()
   HCheck (memory[1]==0 and memory[5]==0 and memory[6]==0 and memory[7]==0) "Last current/script/history pins release all native allocations"
   HCheck (state[16]==0 and state[17]==0 and state[18]==0) "Bounded event log complete; no stranded hold or super hold"
   local f=createFile(MCPFixtureDir+"hold-events.txt")
   for event in cyrusOwnedPlacementProbeEvents() do format "% % %\n" event[1] event[2] event[3] to:f
   close f
   HLog "PASS complete"
  )
  default: throw "Unknown owned hold phase"
 )
)
