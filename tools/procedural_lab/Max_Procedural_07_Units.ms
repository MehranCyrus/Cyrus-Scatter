-- Document the supported reopen path and the guarded automatic-rescale limit.
-- Run after the acceptance fixture has saved Procedural07-Curved.max.
(
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private profile required"
    local path=MCPFixtureDir+"Procedural07-Curved.max"
    loadMaxFile path quiet:true useFileUnits:true
    local node=getNodeByName "P07_Controller",root=node.baseObject,leaf=root.layerObjects[1]
    local original=cyrusEditFingerprint (root.evaluateGroups())[1] "units"
    local history=(cyrusBrushHistory leaf.paintDocument).count
    units.SystemType=#Meters;units.SystemScale=1
    loadMaxFile path quiet:true useFileUnits:false
    node=getNodeByName "P07_Controller";root=node.baseObject;leaf=root.layerObjects[1]
    local error=""
    try(root.evaluateGroups())catch(error=getCurrentException())
    if error=="" do throw "Automatic rescale unexpectedly accepted unconverted Brush data"
    if (cyrusBrushHistory leaf.paintDocument).count!=history do throw "Rescale guard lost Brush history"
    loadMaxFile path quiet:true useFileUnits:true
    node=getNodeByName "P07_Controller";root=node.baseObject;leaf=root.layerObjects[1]
    local restored=cyrusEditFingerprint (root.evaluateGroups())[1] "units"
    if restored!=original do throw "Adopting saved units did not recover exact placements"
    CSPWriteText (MCPFixtureDir+"units-acceptance.json") (CSPObject #(#("automatic_rescale_supported",false),#("guard",error),#("history_preserved",true),#("adopt_file_units_exact",true),#("file_system_units",units.SystemType as string)))
)
