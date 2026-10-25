-- Owned fixture only. Python runs after this request releases Max's busy context.
global MCPFoundationRun
fn MCPFoundationRun scenario = (
    if scenario != "start" do throw "Unsupported foundation scenario"
    python.ExecuteFile (MCPFixtureDir+"../boot.py")
    QAssert true "boot_scheduled" "Owned MCP bootstrap scheduled on the Qt host thread"
)
