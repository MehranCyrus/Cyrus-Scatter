(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-cold-2027/" do throw "Owned cold-start host required"
 local output=createFile (MCPFixtureDir+"cold-surface-08672.txt")
 try(
  loadMaxFile @"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\mcp-qualification\update08671-test-final4-2027\surface-visibility.max" quiet:true
  if not cyrusSurfaceHidden $Plane001 or not $Plane001.isHidden do throw "Saved viewport preference did not apply on cold host startup"
  format "PASS: newly launched Max applies saved surface visibility before any visibility command\n" to:output
  cyrusBrushBegin (cyrusBrushCreate $Plane001)
  cyrusBrushStop()
  format "PASS: saved hidden receiver remains paintable after a process restart\nSUCCESS\n" to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
