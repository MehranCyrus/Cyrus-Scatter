(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p04-*/" do throw "Owned P04 host required"
    cyrusDiagnosticStop()
    cyrusDiagnosticStart "P04_preset_notification_audit" 2000 1048576 60000
)
