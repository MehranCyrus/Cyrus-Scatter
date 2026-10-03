-- Invocation-only transport in a separate Max process, never artist startup.
global BLCommandTimer,BLLastRequest="",BLCommandTick
global CyrusPerfHeadless=true
fileIn (BLRoot+"tools/performance/CyrusPerformanceMonitor.ms")
-- The shared monitor predates Integer64 counters. Keep lab evidence valid JSON.
fn CSPNumber value = (
    if classof value==Integer64 then substituteString (value as string) "L" ""
    else if classof value==Float or classof value==Double then formattedPrint value format:".17g"
    else value as string
)
fn BLCommandTick sender args = (
    BLCommandTimer.Stop()
    try (
        local request=BLDir+"request.txt"
        if doesFileExist request do (
            local command=(dotNetClass "System.IO.File").ReadAllText request
            if command!=BLLastRequest do (
                BLLastRequest=command
                if not matchPattern command pattern:(BLDir+"*.ms") do throw "Request outside Brush fixture"
                CSPWriteText (BLDir+"response.txt") ("RUNNING "+command)
                try(fileIn command;CSPWriteText (BLDir+"response.txt") ("SUCCESS "+command))
                catch(CSPWriteText (BLDir+"response.txt") ("ERROR "+command+"\n"+getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
            )
        )
    )catch(CSPWriteText (BLDir+"bridge-error.txt") (getCurrentException()))
    if BLCommandTimer!=undefined do BLCommandTimer.Start()
)
BLCommandTimer=dotNetObject "System.Windows.Forms.Timer"
BLCommandTimer.Interval=500
dotNet.addEventHandler BLCommandTimer "Tick" BLCommandTick
BLCommandTimer.Start()
CSPWriteText (BLDir+"transport-ready.txt") "Ready"
try(fileIn (BLRoot+"tools/brush_lab/bootstrap.ms"))
catch(CSPWriteText (BLDir+"startup-error.txt") (getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
if BLReopenScene!=undefined do try(fileIn (BLRoot+"tools/brush_lab/reopen.ms"))catch(CSPWriteText (BLDir+"reopen-error.txt") (getCurrentException()))
