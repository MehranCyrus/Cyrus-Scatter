(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"thumbnail-repro-"+(timeStamp() as string)+".txt"),page=DRoot.mainUI.editors[6]
 local original=DLayer.densityMap
 for mapValue in #(undefined,Noise(),Bitmaptexture()) do (
  with undo off DLayer.densityMap=mapValue
  try(page.distributionUI_syncControls();format "UNEXPECTED SUCCESS: %\n" (classof mapValue) to:log)
  catch(format "REPRODUCED %: %\n" (classof mapValue) (getCurrentException()) to:log)
 )
 with undo off DLayer.densityMap=original
 try(page.distributionUI_syncControls())catch(format "RESTORE %\n" (getCurrentException()) to:log)
 close log
)
