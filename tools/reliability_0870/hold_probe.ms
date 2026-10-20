(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 local log=createFile (MCPFixtureDir+"hold-probe.txt")
 format "Before owned fixture cleanup: %\n" (theHold.Holding()) to:log
 if theHold.Holding() do theHold.Cancel()
 format "After owned fixture cleanup: %\n" (theHold.Holding()) to:log
 close log
)
