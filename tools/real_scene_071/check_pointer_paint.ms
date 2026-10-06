(
 CyrusStopBrush()
 local history=cyrusBrushHistory RSPointerLeaf.paintDocument
 RSAssert (history.count==RSPointerHistory.count+1) "Pointer drag did not record one stroke"
 RSAssert (history[history.count][6]>1) "Pointer drag did not sample continuous motion"
 RSAssert (RSEqual RSPointerBaseline (RSRows())) "Manual pointer paint unexpectedly published"
 RSRoot.refreshAll();local painted=RSRows()
 RSAssert (not(RSEqual RSPointerBaseline painted)) "Pointer painting did not affect flower output"
 local samples=history[history.count][6]
 max undo;RSRoot.refreshAll();RSAssert (RSEqual RSPointerBaseline (RSRows())) "Undo pointer paint failed"
 max redo;RSRoot.refreshAll();RSAssert (RSEqual painted (RSRows())) "Redo pointer paint failed"
 max undo;RSRoot.refreshAll();RSAssert (RSEqual RSPointerBaseline (RSRows())) "Final pointer Undo failed"
 CSPWriteText (MCPFixtureDir+"pointer-paint.json") (CSPObject #(#("passed",true),#("pointer_drag_samples",samples),#("flower_count_before_after",#(RSPointerBaseline[7].count,painted[7].count)),#("manual_preserved",true),#("undo_redo_exact",true)))
 RSPointerBrush.refreshHistory();RSPointerBrush.status()
)
