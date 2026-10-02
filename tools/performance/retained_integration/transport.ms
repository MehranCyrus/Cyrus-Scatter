-- Local invocation-only fixture transport. Never install in artist startup.
global RICommandTimer,RILastRequest="",RICommandTick
global CyrusPerfHeadless=true
fileIn (RIRoot+"tools/performance/CyrusPerformanceMonitor.ms")
fn RICommandTick sender args = (
    RICommandTimer.Stop()
    try (
        local request=RIDir+"request.txt"
        if doesFileExist request do (
            local command=(dotNetClass "System.IO.File").ReadAllText request
            if command!=RILastRequest do (
                RILastRequest=command
                if not matchPattern command pattern:(RIDir+"*.ms") do throw "Request outside private fixture directory"
                CSPWriteText (RIDir+"response.txt") ("RUNNING "+command)
                try(fileIn command;CSPWriteText (RIDir+"response.txt") ("SUCCESS "+command))
                catch(CSPWriteText (RIDir+"response.txt") ("ERROR "+command+"\n"+getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
            )
        )
    )catch(CSPWriteText (RIDir+"bridge-error.txt") (getCurrentException()))
    if RICommandTimer!=undefined do RICommandTimer.Start()
)
RICommandTimer=dotNetObject "System.Windows.Forms.Timer"
RICommandTimer.Interval=500
dotNet.addEventHandler RICommandTimer "Tick" RICommandTick
RICommandTimer.Start()
CSPWriteText (RIDir+"transport-ready.txt") "Ready"
try(fileIn (RIRoot+"tools/performance/retained_integration/bootstrap.ms"))
catch(CSPWriteText (RIDir+"startup-error.txt") (getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
