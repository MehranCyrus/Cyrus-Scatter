-- Expanded only by the matching package builder; never load a loose script.
(
 if (maxVersion())[1]!=__MAX_VERSION__ then
  messageBox "This Surface Analyzer __VERSION__ package requires 3ds Max __MAX_YEAR__." title:"Cyrus Surface Analyzer"
 else (
  local io=dotNetClass "System.IO.File",dirs=dotNetClass "System.IO.Directory"
  local packageDir=getFilenamePath(getSourceFileName())
  local root=pathConfig.appendPath (getDir #userScripts) "CyrusSurfaceAnalyzer"
  local runtime=pathConfig.appendPath root "r\\__RUNTIME_ID__",bins=pathConfig.appendPath runtime "bin"
  local startup=pathConfig.appendPath (getDir #userStartupScripts) "CyrusSurfaceAnalyzerStartup.ms"
  local ini=pathConfig.appendPath (getFilenamePath(getMAXIniFile())) "Plugin.UserSettings.ini"
  local key="CyrusSurfaceAnalyzer__MAX_YEAR__",oldEntry=getINISetting ini "Directories" key
  local oldStartup=if io.Exists startup then io.ReadAllBytes startup else undefined
  local unique=(dotNetClass "System.Guid").NewGuid()
  local backup=startup+".cyrus-previous-"+(unique.ToString "N")
  local switched=false
  fn digest path = (
   local hash=(dotNetClass "System.Security.Cryptography.SHA256").Create()
   local stream=(dotNetClass "System.IO.File").OpenRead path
   local result=""
   try(result=toLower ((dotNetClass "System.BitConverter").ToString(hash.ComputeHash stream));stream.Dispose();hash.Dispose())
   catch(stream.Dispose();hash.Dispose();throw())
   substituteString result "-" ""
  )
  fn copyVerified source destination expected = (
   local files=dotNetClass "System.IO.File"
   if digest source!=expected do throw ("Package hash differs: "+getFilenameFile source)
   if files.Exists destination then (
    if digest destination!=expected do throw "An immutable Analyzer runtime contains different bytes. Preserve it and install a distinct package."
   ) else files.Copy source destination false
   if digest destination!=expected do throw "Installed Analyzer verification failed."
  )
  try (
   dirs.CreateDirectory bins
   copyVerified (pathConfig.appendPath packageDir "CyrusSurfaceAnalyzer.dlx") (pathConfig.appendPath bins "CyrusSurfaceAnalyzer.dlx") "__NATIVE_SHA256__"
   copyVerified (pathConfig.appendPath packageDir "CyrusSurfaceAnalyzer.ms") (pathConfig.appendPath runtime "CyrusSurfaceAnalyzer.ms") "__SCRIPT_SHA256__"
   local nextStartup=io.ReadAllBytes (pathConfig.appendPath packageDir "CyrusSurfaceAnalyzerStartup.ms")
   if digest (pathConfig.appendPath packageDir "CyrusSurfaceAnalyzerStartup.ms")!="__STARTUP_SHA256__" do throw "Analyzer startup payload differs."
   -- Both immutable files verify before either binding is changed.
   switched=true
   if not setINISetting ini "Directories" key bins do throw "Analyzer plugin registration failed."
   io.WriteAllBytes (startup+".cyrus-stage") nextStartup
   -- MAXScript's undefined is not a .NET String null overload argument.
   -- A unique owned backup keeps File.Replace atomic and unambiguous.
   if io.Exists startup then io.Replace (startup+".cyrus-stage") startup backup else io.Move (startup+".cyrus-stage") startup
   if getINISetting ini "Directories" key!=bins or digest startup!="__STARTUP_SHA256__" do throw "Analyzer startup registration verification failed."
   if io.Exists backup do io.Delete backup
   messageBox "Surface Analyzer __VERSION__ installed. Save your work and restart Max.\nThen Analyze / Update Analyzer, followed by Update scatter in Manual mode." title:"Cyrus Surface Analyzer"
  )catch(
   local reason=getCurrentException(),recovery=""
   if switched do try (
    if oldEntry=="" then delINISetting ini "Directories" key else setINISetting ini "Directories" key oldEntry
    if oldStartup==undefined then (if io.Exists startup do io.Delete startup) else io.WriteAllBytes startup oldStartup
   )catch(recovery="\nBinding recovery failed: "+getCurrentException())
   messageBox (reason+recovery) title:"Surface Analyzer installation failed"
  )
 )
)
