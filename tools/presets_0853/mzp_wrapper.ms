(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-presets0853-recipient-*/" do throw "Owned installed recipient required"
 local paths=dotNetClass "System.IO.Path",prefix=toLower (paths.GetFullPath MCPFixtureDir)
 for path in #((getDir #userScripts),(getDir #userStartupScripts),(getDir #userMacros),(getFilenamePath (getMAXIniFile()))) do (
  if not matchPattern (toLower (paths.GetFullPath path)) pattern:(prefix+"*") do throw "Installer destination escaped owned recipient"
 )
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/presets-0853-20261016-01/package-04/payload/install.ms"
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"mzp-wrapper-passed.txt") "Exact packaged install.ms completed in owned installed profile; notice dismissed through Computer Use."
)
