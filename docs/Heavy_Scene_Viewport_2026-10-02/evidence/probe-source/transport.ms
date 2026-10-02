-- Local, invocation-only transport. Stop/dispose the timer at experiment completion.
global HVPCommandTimer, HVPLastRequest="", HVPCommandTick
global CyrusPerfHeadless=true
fileIn (HVPRoot+"tools/performance/CyrusPerformanceMonitor.ms")
fn HVPCommandTick sender args = (
    HVPCommandTimer.Stop()
    try (
        local request=HVPDir+"request.txt"
        if doesFileExist request do (
            local command=(dotNetClass "System.IO.File").ReadAllText request
            if command!=HVPLastRequest do (
                HVPLastRequest=command
                if not matchPattern command pattern:(HVPDir+"*.ms") do throw "Request outside private fixture directory"
                CSPWriteText (HVPDir+"response.txt") ("RUNNING "+command)
                try(fileIn command; CSPWriteText (HVPDir+"response.txt") ("SUCCESS "+command))
                catch(CSPWriteText (HVPDir+"response.txt") ("ERROR "+command+"\n"+getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
            )
        )
    )catch(CSPWriteText (HVPDir+"bridge-error.txt") (getCurrentException()))
    if HVPCommandTimer!=undefined do HVPCommandTimer.Start()
)
HVPCommandTimer=dotNetObject "System.Windows.Forms.Timer"
HVPCommandTimer.Interval=500
dotNet.addEventHandler HVPCommandTimer "Tick" HVPCommandTick
HVPCommandTimer.Start()
CSPWriteText (HVPDir+"transport-ready.txt") "Ready"
try(fileIn (HVPRoot+"tools/performance/native_point_probe/bootstrap.ms"))
catch(CSPWriteText (HVPDir+"startup-error.txt") (getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
