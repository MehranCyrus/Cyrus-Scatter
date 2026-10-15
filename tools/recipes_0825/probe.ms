(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
    local log=createFile (MCPFixtureDir+"recipe-probe.txt")
    try (
        local root=RecipeTestRoot
        format "schema: %\n" (cyrusRecipeSchema()).count to:log
        cyrusRecipeCheckStatic root
        format "root static passed\n" to:log
        format "logical layers: %\n" (root.logicalLayers()).count to:log;flush log
        format "modifiers: %\n" (root.procModifiers()).count to:log;flush log
        format "validate function: %\n" cyrusRecipeValidate to:log;flush log
        CyrusRequireAuthor();format "author passed\n" to:log;flush log
        local node=CyrusRecipeOwnerNode root
        CyrusRecipeCheckRoot root node;format "owner passed: %\n" node to:log;flush log
        local context=CyrusRecipeCaptureContext root:root node:node owners:(root.layerObjects as array) metres:1.0
        format "context passed: %\n" context.metres to:log;flush log
        local settings=CyrusRecipeCaptureSettings context root
        format "settings passed: %\n" settings.count to:log;flush log
        for leaf in root.layerObjects do (
            local settings=CyrusRecipeCaptureSettings context leaf
            format "layer passed: %\n" leaf.layerID to:log;flush log
            for area in leaf.paintAreas do (
                local settings=CyrusRecipeCaptureSettings context area
                format "area settings passed: %\n" area.layerID to:log;flush log
                local paint=CyrusRecipeCapturePaint context area
                format "paint passed: %\n" area.paintSetName to:log;flush log
            )
        )
        local data=CyrusRecipeCapture root (root.layerObjects as array) "Probe"
        format "capture passed: %\n" (CyrusRecipeGet data "name") to:log
    )catch(format "%\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
    close log
)
