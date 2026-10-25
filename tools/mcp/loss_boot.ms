-- Owned process-loss fixture only; never shipped as an MCP tool.
global MCPLossRun
fn MCPLossRun scenario = (
    if findItem #("before","after") scenario==0 do throw "Unknown loss bootstrap"
    python.ExecuteFile (MCPFixtureDir+"../boot-"+scenario+".py")
    QAssert true "boot_scheduled" "Owned loss bootstrap scheduled on the host thread"
)
