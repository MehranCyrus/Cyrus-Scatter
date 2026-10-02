global CVDir="F:/Cursor/_Cyrus_Apps/CyrusScatter/build/viewport-round2-2026-10-01/"
global CVCommandTimer,CVLastRequest="",CVCommandTick
global CSPObject,CSPWriteText,CVBControllers,CVBAnalyzers,CVBBaseTM,CVBCounts
global CyrusPerfHeadless=true
try (
 fileIn "F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms"
 fileIn "F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/scripts/AminScatterObject.ms"
 fileIn "F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/performance/CyrusPerformanceMonitor.ms"
 if cyrusPreviewDrawStats==undefined do throw "0.61 native module was not loaded"
 if not (loadMaxFile "F:/Cursor/_Cyrus_Apps/CyrusScatter/build/viewport-round2-2026-10-01/round2-test.max" quiet:true useFileUnits:true) do throw "Scene failed to load"
 if cyrusProbeBuild==undefined do throw "Experiment native module was not loaded"
 global CVControllers=for n in objects where classof n.baseObject==AminScatterObject collect n
 global CVAnalyzers=for n in objects where classof n.baseObject==CyrusSurfaceAnalyzer collect n
 global CVOriginalView=viewport.getTM()
 global CVViewSettings=NitrousGraphicsManager.GetActiveViewportSetting()
 global CVNeverDegrade
 if CVNeverDegrade==undefined do CVNeverDegrade=CVViewSettings.AdaptiveDegradeNeverDegradeGeometry
 CVViewSettings.AdaptiveDegradeNeverDegradeGeometry=true
 fileIn "F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/performance/CyrusViewportBenchmark.ms"
 CVBControllers=CVControllers;CVBAnalyzers=CVAnalyzers;CVBBaseTM=CVOriginalView
 for n in CVControllers do n.refreshDisplay()
 redrawViews()
 CSPWriteText (CVDir+"desktop-ready.json") (CSPObject #(#("scene",maxFilePath+maxFileName),#("version",maxVersion()),#("renderer",classof renderers.current as string),#("viewport_size",#(gw.getWinSizeX(),gw.getWinSizeY())),#("counts",CVBCounts()),#("draw_stats",for n in CVControllers collect (for l in n.layerObjects collect (for v in cyrusPreviewDrawStats ((l.cacheSnapshot())[1]) collect (v as integer))))))
 fn CVCommandTick sender args = (
  CVCommandTimer.Stop()
  try (
   local request=CVDir+"request.txt"
   if doesFileExist request do (
    local command=(dotNetClass "System.IO.File").ReadAllText request
    if command!=CVLastRequest do (
     CVLastRequest=command
     if not matchPattern command pattern:(CVDir+"*.ms") do throw "Command outside candidate folder"
     CSPWriteText (CVDir+"response.txt") ("RUNNING "+command)
     try(fileIn command;CSPWriteText (CVDir+"response.txt") ("SUCCESS "+command))
     catch(CSPWriteText (CVDir+"response.txt") ("ERROR "+command+"\n"+getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
    )
   )
  )catch(CSPWriteText (CVDir+"bridge-error.txt") (getCurrentException()))
  CVCommandTimer.Start()
 )
 CVCommandTimer=dotNetObject "System.Windows.Forms.Timer";CVCommandTimer.Interval=500
 dotNet.addEventHandler CVCommandTimer "Tick" CVCommandTick;CVCommandTimer.Start()
)catch(
 local f=createFile (CVDir+"desktop-error.txt")
 format "%\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:f;close f
)
