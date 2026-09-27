(
 if (maxVersion())[1]!=28000 then messageBox "Requires 3ds Max 2026." else (
 local packageDir=getFilenamePath(getSourceFileName())
 local dest=(getDir #userScripts)+"\\CyrusSurfaceAnalyzer"
 local bins=dest+"\\bin05"
 local io=dotNetClass "System.IO.File"
 try (
 makeDir bins all:true
 local dll=bins+"\\CyrusSurfaceAnalyzer.dlx"
 if not doesFileExist dll then (if not copyFile (packageDir+"CyrusSurfaceAnalyzer.dlx") dll do throw "Native copy failed.")
 else (
 local convert=dotNetClass "System.Convert"
 if (convert.ToBase64String(io.ReadAllBytes dll))!=(convert.ToBase64String(io.ReadAllBytes(packageDir+"CyrusSurfaceAnalyzer.dlx"))) do throw "Different DLL installed; restart and install to a new version folder."
 )
 io.Copy (packageDir+"CyrusSurfaceAnalyzer.ms") (dest+"\\CyrusSurfaceAnalyzer.ms") true
 io.Copy (packageDir+"CyrusSurfaceAnalyzerStartup.ms") ((getDir #userStartupScripts)+"\\CyrusSurfaceAnalyzerStartup.ms") true
 local ini=(getFilenamePath(getMAXIniFile()))+"Plugin.UserSettings.ini"
 if not setINISetting ini "Directories" "CyrusSurfaceAnalyzer2026" bins do throw "Plugin registration failed."
 messageBox "Surface Analyzer 0.14 installed. Restart Max.\nCreate > Geometry > Cyrus > Surface Analyzer." title:"Cyrus Surface Analyzer"
 )catch(messageBox(getCurrentException()) title:"Analyzer installation")
 )
)









