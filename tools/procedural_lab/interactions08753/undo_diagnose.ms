-- Isolate native MaxScript history from the Python wrapper in the owned host.
(
    -- One-time cleanup for the failed journal preflight's test-only selection
    -- and command-panel bind, before any source action ran. Keep this explicit
    -- and separate; qualification must fail if subsequent authored actions leak.
    if CVProfileCase=="undo-harness-cancel" and theHold.Holding() do theHold.Cancel()
    if CVProfileCase=="undo-control-create" do undo "Owned native Undo control" on (box name:"Owned native Undo control")
    local doc=stringStream ""
    format "holding=% suspended=% super=% undo=% redo=%" (theHold.Holding()) (theHold.IsSuspended()) (theHold.SuperLevel()) (theHold.getUndoNames()) (theHold.getRedoNames()) to:doc
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+CVProfileCase+".txt") (doc as string)
)
