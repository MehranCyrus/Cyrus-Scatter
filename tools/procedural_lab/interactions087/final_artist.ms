-- Separate owned final scene production; preserves the user's current window.
fn FRun name = (
    local path=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/interactions087/"+name
    execute ("(\n"+(dotNetClass "System.IO.File").ReadAllText path+"\n)")
)
FRun "physical_boot.ms"
MCPFixtureTimer.Stop()
FRun "final_commands.ms"
FRun "other_stones.ms"
FRun "save_trials.ms"
FRun "reopen_trial.ms"
FRun "capture_trial_audit.ms"
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"completed.json") "{\"status\":\"pass\",\"host\":2027,\"scope\":\"Separate owned final command/Undo/Redo, all three independent stone rows, pending Manual preservation, two saved trials and detailed trial reopen. Independent full audit follows separately.\"}"
MCPFixtureTimer.Start()
