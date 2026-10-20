(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned prototype host required"
 resetMaxFile #noPrompt
 local script=MCPFixtureDir+"scripts/CyrusScatter.ms"
 (dotNetClass "System.IO.File").Copy @"F:\Cursor\_Cyrus_Apps\CyrusScatter\AminScatter\scripts\AminScatterObject.ms" script true
 fileIn script
)
