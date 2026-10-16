(
 local log=createFile (MCPFixtureDir+"soak-node-probe.txt")
 for n in objects do (
  format "% | % | % | %\n" n.name (classof n.baseObject) (getHandleByAnim n) (if classof n.baseObject==AminScatterObject then (for owner in n.baseObject.layerObjects collect (for s in owner.sources collect #(s.name,getHandleByAnim s))) else #()) to:log
  if classof n.baseObject==AminScatterObject do for owner in n.baseObject.layerObjects do format "  ERROR %\n" owner.previewError to:log
 )
 format "heapSize % heapFree %\n" heapSize heapFree to:log
 format "Undo % Redo %\n" (theHold.GetUndoNames()) (theHold.GetRedoNames()) to:log
 close log
)
