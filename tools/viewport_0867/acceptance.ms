(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test*-202*/" do throw "Owned acceptance host required"
 local folder=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\viewport_0867\"
 fileIn (folder+"texture_acceptance.ms")
 fileIn (folder+"preview.ms")
 fileIn (folder+"source_controls.ms")
 fileIn (folder+"gallery_host.ms")
)
