(
 local f=createFile (MCPFixtureDir+"surface-inspect.txt")
 format "idle before % after % hash matches %\n" BIdle #(BRoot.procEpoch,(cyrusBrushStats BDoc)[8],(cyrusBrushStats BDoc)[9]) ((cyrusRecipePublicationFingerprint BRoot.groupSnapshotRows)==BHash) to:f
 close f
)
