(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local io=dotNetClass "System.IO.File",log=createFile (MCPFixtureDir+"preflight-probe.txt")
 local package=cyrusAssetPackageRead (io.ReadAllText (MCPFixtureDir+"mask-package.txt")),document=CyrusRecipeGet package "recipe"
 try(CyrusPresetPlan LRoot "" package document surface:LT;format "PLAN SUCCESS\n" to:log)catch(format "PLAN ERROR: %\n" (getCurrentException()) to:log)
 try(format "CHANNEL=%\n" (cyrusMeshDensityKey LT #(true,2,1,0.,1.,false,#(0.,1.))) to:log)catch(format "CHANNEL ERROR: %\n" (getCurrentException()) to:log)
 close log
)
