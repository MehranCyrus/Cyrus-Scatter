(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p04-*/" do throw "Owned P04 host required"
    global P04LiveStage,P04LiveTimer
    try(P04LiveTimer.Stop();P04LiveTimer.Dispose())catch()
    P04LiveStage=0
)
