(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-surface0866-*/" do throw "Owned 0.86.6 host required"
 local log=createFile (MCPFixtureDir+"installer-core-host.txt")
 try (
  local file=dotNetClass "System.IO.File",directory=file.ReadAllText (MCPFixtureDir+"installer-payload.txt")
  local inventory=file.ReadAllBytes (pathConfig.appendPath directory "InstallInventory.txt")
  dotNet.loadAssembly (pathConfig.appendPath directory "CyrusInstaller.dll")
  local hash=(dotNetClass "Cyrus.Setup.InstallEngine").Hash inventory
  local root="D:/CyrusScatterBuilds/if0866/maxhost03",paths=dotNetObject "Cyrus.Setup.InstallPaths" (root+"/scripts") (root+"/startup") (root+"/macros") (root+"/profile") (root+"/r")
  local engine=dotNetObject "Cyrus.Setup.InstallEngine" directory hash
  if engine.Version!="0.86.6" or engine.Year!="2027" do throw "Installer version/host mismatch"
  local release=engine.Install paths
  if not doesFileExist (release+"/bin/AminScatter.dlx") or not doesDirectoryExist (release+"/Library-0.86.6") do throw "Installed native/library payload missing"
  if not doesFileExist (release+"/SurfaceGeodesic-LICENSE.txt") or not doesFileExist (release+"/SurfaceGeodesic-NOTICE.txt") do throw "Surface dependency notices missing"
  if engine.Install paths!=release do throw "Identical repair changed release identity"
  format "PASS: exact MZP installer core loads in Max 2027 and installs/repairs native, library and dependency notices in owned destinations.\nRelease: %\n" release to:log
  close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
