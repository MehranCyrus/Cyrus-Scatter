-- Load the script adjacent to the native module actually loaded by this host.
(
 local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),nativePath="",found=0
 for i=0 to process.Modules.Count-1 do (
  local module=process.Modules.Item[i]
  if toLower module.ModuleName=="cyrussurfaceanalyzer.dlx" do (nativePath=module.FileName;found+=1)
 )
 if found==1 then (
  local paths=dotNetClass "System.IO.Path",bin=paths.GetDirectoryName nativePath
  local script=pathConfig.appendPath (paths.GetDirectoryName bin) "CyrusSurfaceAnalyzer.ms"
  if doesFileExist script then fileIn script
  else messageBox "Analyzer could not find the script paired with its loaded native module. Install the complete package and restart Max." title:"Surface Analyzer"
 ) else if found>1 do messageBox "Multiple Analyzer native modules are loaded. Correct duplicate plugin registrations and restart Max." title:"Surface Analyzer"
)
