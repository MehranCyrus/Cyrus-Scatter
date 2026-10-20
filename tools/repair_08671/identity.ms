(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned identity fixture required"
 local output=createFile (MCPFixtureDir+"loaded-identity.json")
 local native=VRoot.statisticsUI.diagnosticsUI_nativeIdentity()
 local panel=dotNetObject "CyrusScatter.UI.LibraryPanel",kind=panel.GetType()
 local gallery=(dotNetClass "Cyrus.Content.LibraryLocation").Hash kind.Assembly.Location
 panel.Dispose()
 format "{\"year\":%,\"script\":\"%\",\"gallery\":\"%\",\"native\":%}\n" ((maxVersion())[1]/1000+1998) CyrusLoadedScriptFingerprint gallery native to:output
 close output
)
