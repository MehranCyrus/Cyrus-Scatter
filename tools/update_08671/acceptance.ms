(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned acceptance host required"
 local folder=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\update_08671\"
 fileIn (folder+"texture_acceptance.ms")
 fileIn (folder+"preview.ms")
 fileIn (folder+"source_controls.ms")
 fileIn (folder+"panel_acceptance.ms")
 fileIn (folder+"gallery_host.ms")
 fileIn (folder+"library_binding.ms")
 fileIn (folder+"installer_host.ms")
 if (maxVersion())[1]==29000 do (
  fileIn (folder+"leaf_probe.ms")
  fileIn (folder+"leaf_acceptance.ms")
 )
)
