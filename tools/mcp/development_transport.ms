-- Qualification fixture only, in a separately launched Max process.
-- Not part of the shipped product or reachable through MCP.
global MCPFixtureTimer,MCPFixtureLast=""
fn MCPFixtureTick sender args = (
    MCPFixtureTimer.Stop()
    try (
        local request=MCPFixtureDir+"dev-request.txt"
        if doesFileExist request do (
            local path=(dotNetClass "System.IO.File").ReadAllText request
            if path!=MCPFixtureLast do (
                MCPFixtureLast=path
                if not matchPattern path pattern:(MCPFixtureDir+"*.ms") do throw "Outside private fixture directory"
                try (fileIn path; (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"dev-result.txt") ("SUCCESS "+path))
                catch ((dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"dev-result.txt") ("ERROR "+getCurrentException()+"\nREQUEST: "+path+"\nSOURCE: "+(getErrorSourceFileName() as string)+" LINE: "+(getErrorSourceFileLine() as string)+"\n"+getCurrentExceptionStackTrace()))
            )
        )
    ) catch ()
    MCPFixtureTimer.Start()
)
MCPFixtureTimer=dotNetObject "System.Windows.Forms.Timer"
MCPFixtureTimer.Interval=200
dotNet.addEventHandler MCPFixtureTimer "Tick" MCPFixtureTick
MCPFixtureTimer.Start()
