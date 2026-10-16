-- One authored transaction owns source meshes/materials and imported recipe layers.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-import-"+(timeStamp() as string)+".txt"),moved="",packageDirectory=""
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn paintBytes owner = #(if owner.paintDocument==undefined then undefined else (cyrusBrushRecipeExport owner.paintDocument)[1],for area in owner.paintAreas collect (if area.paintDocument==undefined then undefined else (cyrusBrushRecipeExport area.paintDocument)[1]))
    fn settle editor log = (
        local started=timeStamp()
        while editor.progress.active and (timeStamp()-started)<30000 do ((dotNetClass "System.Threading.Thread").Sleep 10;if editor.progress.active do editor.progress.tick())
        check (not editor.progress.active) "Background preparation reaches a terminal state" log
    )
    try (
        check (not theHold.Holding()) "Start without a surrounding hold" log
        CyrusPerfHeadless=true
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Original painted-border scene opens" log
        packageDirectory=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        check (matchPattern packageDirectory pattern:"*build*mcp-qualification*foundation-roadmap-gallery0851-*") "Package is owned disposable fixture data" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject;root.refreshAll()
        local beforeNodes=objects as array,beforeLayers=root.layerObjects as array,beforeEpoch=root.procEpoch,beforeRows=cyrusRecipePublicationFingerprint root.groupSnapshotRows
        CyrusOpenAssetImport root packageDirectory
        local editor=CyrusAssetImportEditor;settle editor log;editor.suggest.pressed();editor.variation.selection=2
        for pair in editor.bindings do check (pair[2]!=undefined) "External roles have explicit valid suggestions" log
        editor.review.pressed();format "Review: %\n" editor.status.text to:log;flush log
        check editor.commit.enabled "Actual package Review succeeds" log
        editor.commit.pressed();settle editor log;format "Commit: %\n" editor.status.text to:log;flush log
        check (matchPattern editor.status.text pattern:"Loaded*") "Actual Load package handler commits" log
        local imported=for owner in root.layerObjects where findItem beforeLayers owner==0 collect owner,newNodes=for n in objects where findItem beforeNodes n==0 collect n
        check (imported.count==beforeLayers.count and newNodes.count>0) "Layers and independent source nodes are added" log
        check (root.procEpoch==beforeEpoch and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==beforeRows) "Manual import retains the previous complete publication" log
        for n in newNodes do check (n.isHidden and superclassof n==GeometryClass) "Imported reusable source is hidden geometry" log
        local allSources=#();for owner in imported do for source in owner.sources do appendIfUnique allSources source
        check (allSources.count==newNodes.count) "Imported layers bind only transaction-owned source nodes" log
        for i=1 to imported.count do (
            check (CyrusPresetSameValues (paintBytes beforeLayers[i]) (paintBytes imported[i])) "Complete Paint payloads and empty coverage both survive" log
            for field in #(#areaNodes,#patternPaths,#pathIDs,#strokeIDs,#strokePathIDs,#strokeWidths) where isProperty beforeLayers[i] field do check (CyrusPresetSameValues ((getProperty beforeLayers[i] field) as array) ((getProperty imported[i] field) as array)) ("Border field retained: "+field as string) log
        )
        local layerIDs=for owner in imported collect owner.layerID,sourceHandles=for n in newNodes collect getHandleByAnim n
        -- Temporarily remove the owned package, proving Undo/Redo uses scene state.
        moved=packageDirectory+"-temporarily-unavailable"
        (dotNetClass "System.IO.Directory").Move packageDirectory moved
        max undo
        check (CyrusPresetSameValues beforeLayers (root.layerObjects as array) and CyrusPresetSameValues beforeNodes (objects as array)) "One Undo removes all imported layers and sources" log
        max redo
        check (root.layerObjects.count==beforeLayers.count+imported.count) "Redo restores all layers without source package files" log
        for i=1 to newNodes.count do check (isValidNode newNodes[i] and (getHandleByAnim newNodes[i])==sourceHandles[i]) "Redo restores the same source ownership" log
        for i=1 to imported.count do check (imported[i].layerID==layerIDs[i] and findItem root.layerObjects imported[i]>0) "Redo retains recorded layer IDs" log
        (dotNetClass "System.IO.Directory").Move moved packageDirectory;moved=""
        destroyDialog editor
        root.refreshAll();check (root.procEpoch>beforeEpoch and root.groupSnapshotRows.count>0) "Explicit Update can publish imported hidden sources" log
        check (saveMaxFile (MCPFixtureDir+"portable-import-scene.max") quiet:true) "Imported source ownership saves into the scene" log
        global GalleryImportedRoot;GalleryImportedRoot=root
        check (not theHold.Holding()) "No import hold remains" log
        format "PASS: complete\n" to:log;close log
    )catch(
        if moved!="" and doesDirectoryExist moved and not doesDirectoryExist packageDirectory do (dotNetClass "System.IO.Directory").Move moved packageDirectory
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
