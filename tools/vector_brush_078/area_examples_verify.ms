(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global QA_AreaPhase="verify"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/vector_brush_078/area_examples_finalize.py"
)
