(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-compat-max2024-installer01/" do throw "Owned Max 2024 profile required"
 local f=createFile (MCPFixtureDir+"old-path-reproduction.txt")
 try (
  local package=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/compatibility-0862-20261019/package01/payload2024"
  dotNet.loadAssembly (package+"/CyrusInstaller.dll")
  local io=dotNetClass "System.IO.File",sha=dotNetClass "System.Security.Cryptography.SHA256"
  local algorithm=sha.Create(),bytes=algorithm.ComputeHash (io.ReadAllBytes (package+"/InstallInventory.txt"))
  local digest=toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
  algorithm.Dispose()
  local engine=dotNetObject "Cyrus.Setup.InstallEngine" package digest
  format "Unexpected: old deep payload admitted\n" to:f
 ) catch (format "REPRODUCED: %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:f)
 close f
)
