(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/area_examples.py"
if doesFileExist (MCPFixtureDir+"area-examples-error.txt") do throw ((dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"area-examples-error.txt"))
if not doesFileExist (MCPFixtureDir+"area-examples-results.json") do throw "Point area examples did not complete"
)
