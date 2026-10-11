(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/area_examples_extra.py"
if doesFileExist (MCPFixtureDir+"area-examples-extra-error.txt") do throw ((dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"area-examples-extra-error.txt"))
)
