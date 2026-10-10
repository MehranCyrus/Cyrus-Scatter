(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global PTDir=(MCPFixtureDir+"playback/"),PTNativeExpected=#("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm")
makeDir PTDir
local source=(dotNetClass "System.IO.File").ReadAllText @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/Max_Playback_073_Regression.ms"
source=substituteString source "/build/mcp-qualification/" "/build/vector-brush-078/"
local launch=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"launch.json")
local expected=if findString launch "\"max_year\": 2026"!=undefined then 28000 else 29000
if (maxVersion())[1]!=expected do throw "Playback host differs from launch receipt"
source=substituteString source "((maxVersion())[1]==29000)" ("((maxVersion())[1]=="+(expected as string)+")")
execute source
)
