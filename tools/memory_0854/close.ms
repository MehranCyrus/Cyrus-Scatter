(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-*/" do throw "Owned memory-fix host required."
 global MFLog
 if MFLog!=undefined do try(close MFLog)catch()
 local io=dotNetClass "System.IO.File",p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),log=createFile (MCPFixtureDir+"final-environment.txt")
 format "MaxVersion=%\nPID=%\nheapSize=%\nreserved=%\n" (maxVersion()) p.Id heapSize CyrusScriptWorkspaceReserved to:log;close log
 io.WriteAllText (MCPFixtureDir+"closed-owned-session.txt") MCPFixtureLast
 quitMAX #noPrompt quiet:true exitCode:0
)
