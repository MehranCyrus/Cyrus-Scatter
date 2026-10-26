global PTrace,PRead,PInspectOffset,TEdit,TRoot,TRocks
local f=createFile (GardenRun+"pointer-debug.txt")
format "first:%\nlast:%\ncurrent:%\n" PTrace[1] PTrace[PTrace.count] (PRead()) to:f
format "row:%\n" ((cyrusEditInspect TEdit PInspectOffset 1)[4][1]) to:f
format "stats:%\n" (TRoot.interactionsStatistics()) to:f
format "undo:%\nredo:%\nEdit memory:%\n" (theHold.GetUndoNames()) (theHold.GetRedoNames()) (cyrusEditMemoryStats TEdit) to:f
close f
