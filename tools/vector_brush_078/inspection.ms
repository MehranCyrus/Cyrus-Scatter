(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/inspection.py"
if not doesFileExist (MCPFixtureDir+"inspection.json") do throw "Python inspection check did not complete; read Listener errors"
)
