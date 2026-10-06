global AminScatterObject,CyrusSurfaceAnalyzer,CyrusLoadedScriptFingerprint,CyrusOpenLayerEditor,CyrusLayerEditor
(
 try (
  (dotNetClass "System.IO.File").WriteAllText @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/restart03-entered.txt" "Entered startup verification"
  if AminScatterObject==undefined or CyrusSurfaceAnalyzer==undefined do throw "Installed startup scripts did not register their scene classes"
  if CyrusLoadedScriptFingerprint!="708ba32fbbebe62530d4168a81fd0b761471e843976926b87d07de42f9be5561" do throw "A different script was loaded at startup"
  local probe=createInstance AminScatterObject
  if probe.uiVersion()!="0.7.1" do throw "Installed script has the wrong UI version"
  local expected=#(#(@"AminScatter.dlx",@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/scripts/CyrusScatter/bin-max2027-01e8f6e316b7/AminScatter.dlx"),#(@"CyrusBrush.dlx",@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/scripts/CyrusScatter/bin-max2027-01e8f6e316b7/CyrusBrush.dlx"),#(@"CyrusBrushStorage.dlh",@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/scripts/CyrusScatter/bin-max2027-01e8f6e316b7/CyrusBrushStorage.dlh"),#(@"CyrusScatterEdit.dlm",@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/scripts/CyrusScatter/bin-max2027-01e8f6e316b7/CyrusScatterEdit.dlm"),#(@"CyrusSurfaceAnalyzer.dlx",@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/scripts/CyrusSurfaceAnalyzer/bin-max2027-737c50438892/CyrusSurfaceAnalyzer.dlx")),process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),log=createFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/restarted03-loaded.tsv"
  for spec in expected do (
   local found=false
   for i=0 to process.Modules.Count-1 do (
    local m=process.Modules.Item[i]
    if toLower m.ModuleName==toLower spec[1] do (
     if toLower (substituteString m.FileName "\\" "/")!=toLower spec[2] do throw ("Wrong installed module path: "+m.FileName)
     found=true;format "%\t%\n" m.ModuleName m.FileName to:log
    )
   )
   if not found do throw ("Missing installed module: "+spec[1])
  )
  close log
  loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/project/scenes/COURTYARD_PACKAGE_TEST.max" quiet:true useFileUnits:true
  local nodes=for n in objects where classof n.baseObject==AminScatterObject collect n
  if nodes.count!=1 do throw "Expected one courtyard controller"
  local root=nodes[1].baseObject,layers=root.logicalLayers()
  if root.uiVersion()!="0.7.1" or layers.count!=5 or root.layerObjects.count!=8 do throw "Courtyard layer/version mismatch"
  select nodes[1];max modify mode
  if not CyrusOpenLayerEditor root layers[1] or CyrusLayerEditor==undefined do throw "Installed floating editor did not open"
  CyrusLayerEditor.showTopic 5
  local report=createFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/restart03-passed.txt"
  format "PASS\nversion=%\nlayers=%\npopulations=%\nfingerprint=%\n" (root.uiVersion()) layers.count root.layerObjects.count CyrusLoadedScriptFingerprint to:report
  close report
  quitMAX #noPrompt
 )catch(
  (dotNetClass "System.IO.File").WriteAllText @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/procedural07-package-071-install01/restart03-error.txt" (getCurrentException()+"\n"+getCurrentExceptionStackTrace())
  quitMAX #noPrompt
 )
)
