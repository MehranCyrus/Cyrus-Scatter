(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-baseline-2027/" do throw "Owned baseline required"
 saveMaxFile (MCPFixtureDir+"schema58.max") quiet:true
 local f=createFile (MCPFixtureDir+"schema58-save.txt")
 format "schema=58\nfingerprint=%\nlayers=%\n" CyrusLoadedScriptFingerprint VRoot.layerObjects.count to:f
 close f
)
