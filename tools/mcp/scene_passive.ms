-- Owned qualification only: establish an observable clean flag before read tools.
global MCPScenePassiveRun
fn MCPScenePassiveRun scenario = (
    if scenario != "clean" do throw "Unsupported passive scene scenario"
    local destination=MCPFixtureDir+"scene-passive-clean-"+QRequestID+".max"
    if doesFileExist destination do throw "Owned clean-scene checkpoint already exists"
    if not saveMaxFile destination quiet:true do throw "Owned clean-scene checkpoint could not be saved"
    QAssert (not getSaveRequired()) "clean_before_reads" "Owned scene has an explicitly clean flag before public reads"
)
