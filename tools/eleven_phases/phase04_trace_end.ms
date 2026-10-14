(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p04-*/" do throw "Owned P04 host required"
    cyrusDiagnosticStop()
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase04-preset-trace.json") (cyrusDiagnosticSnapshot 0 500)
)
