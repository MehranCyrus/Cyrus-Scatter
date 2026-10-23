-- Expanded only by the matching package builder; run the complete MZP.
(
 if (maxVersion())[1]!=__MAX_VERSION__ then
  messageBox "This Surface Analyzer __VERSION__ package requires 3ds Max __MAX_YEAR__." title:"Cyrus Surface Analyzer"
 else try (
  local packageDir=getFilenamePath(getSourceFileName())
  local helper=pathConfig.appendPath packageDir "CyrusInstaller.dll"
  fn digest path = (
   local hash=(dotNetClass "System.Security.Cryptography.SHA256").Create()
   local stream=(dotNetClass "System.IO.File").OpenRead path
   local result=""
   try(result=toLower ((dotNetClass "System.BitConverter").ToString(hash.ComputeHash stream));stream.Dispose();hash.Dispose())
   catch(stream.Dispose();hash.Dispose();throw())
   substituteString result "-" ""
  )
  if digest helper!="__HELPER_SHA256__" do throw "Analyzer installer helper differs. Run the complete matching MZP."
  local loaded=undefined
  local assemblies=(dotNetClass "System.AppDomain").CurrentDomain.GetAssemblies()
  for assembly in assemblies do (
   local assemblyName=assembly.GetName()
   if assemblyName.Name=="CyrusInstaller" do (
    if toLower(assembly.ManifestModule.ModuleVersionId.ToString())!="__HELPER_MVID__" do
     throw "A different Cyrus installer is already loaded. Save your work, restart Max, then run this MZP again."
    if digest assembly.Location!="__HELPER_SHA256__" do throw "The loaded Cyrus installer identity differs. Restart Max and run the complete MZP again."
    loaded=assembly
   )
  )
  if loaded==undefined do loaded=(dotNetClass "System.Reflection.Assembly").LoadFrom helper
  local loadedName=loaded.GetName()
  if loadedName.Name!="CyrusInstaller" or toLower(loaded.ManifestModule.ModuleVersionId.ToString())!="__HELPER_MVID__" or digest loaded.Location!="__HELPER_SHA256__" do
   throw "Max could not load the matching Cyrus installer. Restart Max and run the complete MZP again."
  local entry=(loaded.GetType "Cyrus.Setup.AnalyzerInstallEngine" true).GetMethod "InstallFromHost"
  local arguments=dotNetObject "System.Object[]" 7
  arguments.SetValue packageDir 0
  arguments.SetValue "__DESCRIPTOR_SHA256__" 1
  arguments.SetValue (getDir #userScripts) 2
  arguments.SetValue (getDir #userStartupScripts) 3
  arguments.SetValue (getDir #userMacros) 4
  arguments.SetValue (getFilenamePath(getMAXIniFile())) 5
  arguments.SetValue "__MAX_YEAR__" 6
  entry.Invoke (dotNetObject "System.Object") arguments
  messageBox "Surface Analyzer __VERSION__ installed. Save your work and restart Max.\nThen Analyze / Update Analyzer, followed by Update scatter in Manual mode." title:"Cyrus Surface Analyzer"
 )catch(
  messageBox ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace())) title:"Surface Analyzer installation failed"
 )
)
