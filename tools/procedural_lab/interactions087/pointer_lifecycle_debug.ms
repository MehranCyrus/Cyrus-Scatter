global PRead,PSettle,TEdit
local f=createFile (GardenRun+"undo-stages.txt")
fn stage label f=(format "%\nundo:%\nredo:%\nmemory:%\npose:%\n" label (theHold.GetUndoNames()) (theHold.GetRedoNames()) (cyrusEditMemoryStats TEdit) (PRead()) to:f;flush f)
stage "before" f
max undo;stage "immediate undo" f
PSettle 600;stage "settled undo" f
max redo;stage "immediate redo" f
PSettle 600;stage "settled redo" f
close f
