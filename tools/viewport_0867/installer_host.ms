(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test6-202*/" do throw "Owned final host required"
 local output=createFile (MCPFixtureDir+"installer-host.txt")
 try(
  local year=((maxVersion())[1]/1000+1998) as string
  local payload=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\viewport-0867-20261020\payload"+year
  dotNet.loadAssembly (payload+"/CyrusInstaller.dll")
  local file=dotNetClass "System.IO.File",inventory=file.ReadAllBytes (payload+"/InstallInventory.txt")
  local hash=(dotNetClass "Cyrus.Setup.InstallEngine").Hash inventory
  local engine=dotNetObject "Cyrus.Setup.InstallEngine" payload hash
  engine.SetContentDirectory @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020"
  local base=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\v867\"+year
  local paths=dotNetObject "Cyrus.Setup.InstallPaths" (base+"/s") (base+"/st") (base+"/m") (base+"/p") (base+"/r")
  paths.SharedContentRoot=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\v867\c"
  local release=engine.Install paths
  if engine.Version!="0.86.7" or engine.Year!=year do throw "Installer identity differs"
  if not doesFileExist (release+"/Library-0.86.7/model-catalog.json") do throw "Installed catalog absent"
  format "PASS: exact MZP managed installer installs/repairs real content in Max %\nRelease %\nSUCCESS\n" year release to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
