(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"capture-import-"+(timeStamp() as string)+".txt")
    local recipePath=trimRight (trimLeft ((dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"capture-recipe-path.txt")))
    fn check condition message log = (format "%: %\n" (if condition then "PASS" else "FAIL") message to:log;flush log;if not condition do throw message)
    try (
        -- Cancel only the disposable Python preparation's surrounding hold, then
        -- reload its recorded scene. This is not a bypass of product Undo checks.
        format "TRACE hold before cancel: %\n" (theHold.Holding()) to:log
        if theHold.Holding() do theHold.Cancel()
        format "TRACE hold after cancel: %\n" (theHold.Holding()) to:log
        check (loadMaxFile (MCPFixtureDir+"capture-source.max") quiet:true useFileUnits:true) "Owned preparation opens" log
        format "TRACE hold after load: %\n" (theHold.Holding()) to:log
        local nodes=for n in objects where classof n.baseObject==AminScatterObject collect n
        local root=nodes[1].baseObject,count=(root.logicalLayers()).count
        root.refreshAll();local epoch=root.procEpoch
        check (not theHold.Holding()) "Native command starts outside a hold" log
        CyrusOpenRecipeLoad root recipePath (cyrusRecipeInfo recipePath)[11]
        local editor=CyrusRecipeLoadEditor
        editor.suggestButton.pressed()
        check ((for pair in editor.bindings where pair[2]==undefined collect pair).count==0) "All roles bind to the matching scene" log
        editor.importVariation.selection=2;editor.importButton.pressed()
        format "STATUS: %\n" editor.status.text to:log
        check ((root.logicalLayers()).count==count*2) "Load Review imports revision-5 layers" log
        check (root.procEpoch==epoch) "Manual import retains previous publication" log
        max undo
        check ((root.logicalLayers()).count==count) "One Undo removes imported graph" log
        max redo
        check ((root.logicalLayers()).count==count*2) "Redo restores the graph" log
        check (not theHold.Holding()) "No stranded hold" log
        destroyDialog editor;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
