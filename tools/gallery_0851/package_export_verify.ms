(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-export-verify-"+(timeStamp() as string)+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        local result=cyrusAssetPackagePoll GalleryExportJob
        format "Result: %\n" result to:log;flush log
        check (result[1]=="complete") "Portable package publishes completely" log
        local exported=cyrusAssetPackageRead GalleryExportOutput,graph=CyrusRecipeGet exported "graph"
        check ((CyrusRecipeGet graph "nodes").count>0 and (CyrusRecipeGet graph "materials").count>0) "Package verifies declared meshes and materials" log
        local hydrated=cyrusRecipeRead (pathConfig.appendPath GalleryExportOutput "entry.csrecipe.json")
        check ((cyrusRecipeContentFingerprint hydrated)==(cyrusRecipeContentFingerprint GalleryExportDocument)) "Exact authored settings and complete Paint survive export" log
        check (CyrusPresetSameValues GalleryExportNodes (objects as array)) "Export creates or removes no scene objects" log
        check (CyrusPresetSameValues GalleryExportCounters #(GalleryExportRoot.procEpoch,GalleryExportRoot.groupBuilds)) "Export does not calculate placements" log
        check (CyrusAssetJobs.count==0 and not CyrusAssetCleanupTimer.Enabled) "File worker staging is cleaned and cleanup polling stops" log
        check (not CyrusAssetExportEditor.progress.active) "Export dialog progress timer stops" log
        local node=CyrusRecipeOwnerNode GalleryExportRoot
        max undo;check (node.name!="Portable export Undo sentinel") "Export preserves preceding scene Undo" log
        max redo;check (node.name=="Portable export Undo sentinel") "Preceding scene Redo survives" log
        (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"portable-package-path.txt") GalleryExportOutput
        destroyDialog CyrusAssetExportEditor
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
