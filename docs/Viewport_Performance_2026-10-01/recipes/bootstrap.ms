global CVDir="F:/Cursor/_Cyrus_Apps/CyrusScatter/build/viewport-investigation-2026-10-01/"
global CVCommandTimer,CVLastRequest="",CVCommandTick
global CyrusPerfHeadless=true
fileIn "F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/performance/CyrusPerformanceMonitor.ms"
fn CVCommandTick sender args = (
 CVCommandTimer.Stop()
 try (
  local request=CVDir+"request.txt"
  if doesFileExist request do (
   local command=(dotNetClass "System.IO.File").ReadAllText request
   if command!=CVLastRequest do (
    CVLastRequest=command
    if not matchPattern command pattern:(CVDir+"*.ms") do throw "Command outside investigation folder"
    CSPWriteText (CVDir+"response.txt") ("RUNNING "+command)
    try(fileIn command;CSPWriteText (CVDir+"response.txt") ("SUCCESS "+command))
    catch(CSPWriteText (CVDir+"response.txt") ("ERROR "+command+"\n"+getCurrentException()))
   )
  )
 )catch(CSPWriteText (CVDir+"bridge-error.txt") (getCurrentException()))
 CVCommandTimer.Start()
)
CVCommandTimer=dotNetObject "System.Windows.Forms.Timer"
CVCommandTimer.Interval=500
dotNet.addEventHandler CVCommandTimer "Tick" CVCommandTick
CVCommandTimer.Start()
CSPWriteText (CVDir+"ready.txt") "Local investigation command timer ready; stop it at completion."
