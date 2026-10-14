(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 try(P05Timer.Stop();P05Timer.Dispose())catch()
 P05Stage=0
 P05RStage=0
)
