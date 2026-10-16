(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-export-start-"+(timeStamp() as string)+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        check (not theHold.Holding()) "Start outside an enclosing hold" log
        CyrusPerfHeadless=true
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Original painted border fixture opens read-only" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject;root.refreshAll()
        global GalleryExportRoot,GalleryExportCounters,GalleryExportRecipe,GalleryExportOutput,GalleryExportJob,GalleryExportDocument,GalleryExportNodes
        GalleryExportRoot=root;GalleryExportCounters=#(root.procEpoch,root.groupBuilds);GalleryExportNodes=objects as array
        GalleryExportDocument=CyrusRecipeCapture root (root.logicalLayers()) "Portable painted borders"
        GalleryExportRecipe=MCPFixtureDir+"portable-"+CyrusNewLayerID()+".csrecipe.json"
        local metadata=CyrusRecipeObject #(#("category","Package fixture"),#("tags",#("paint")),#("description","Owned portable export witness"))
        local digest=cyrusRecipeEntryWrite GalleryExportRecipe GalleryExportDocument metadata "" undefined "" false
        undo "Preceding user action" on node.name="Portable export Undo sentinel"
        CyrusOpenAssetExport root GalleryExportRecipe digest
        local editor=CyrusAssetExportEditor
        editor.matchNames.pressed()
        check (editor.bindings.count>0) "Actual export dialog lists source roles" log
        for pair in editor.bindings do check (isValidNode pair[2]) "Unique source-name suggestion binds an explicit source" log
        editor.destination=MCPFixtureDir;editor.folderName.text="portable-output-"+CyrusNewLayerID();editor.permitted.checked=true
        GalleryExportOutput=pathConfig.appendPath MCPFixtureDir editor.folderName.text
        editor.exportPackage.pressed()
        format "Export status: %\n" editor.status.text to:log;flush log
        check (editor.job>0 and editor.progress.active) "Actual Export starts the file worker and returns" log
        GalleryExportJob=editor.job
        check (not theHold.Holding()) "Export adds no scene hold" log
        format "PASS: waiting for file worker\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
