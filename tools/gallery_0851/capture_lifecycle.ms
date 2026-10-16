-- Explicit thumbnail capture must not become a background calculation path.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local log=createFile (MCPFixtureDir+"capture-lifecycle-"+(timeStamp() as string)+".txt")
    fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Owned painted fixture opens" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject;root.updateMode=1;root.refreshAll()
        undo "Capture preceding action" on node.name="Capture preceding action"
        local inventory=objects as array,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows,epoch=root.procEpoch,builds=root.groupBuilds,history=theHold.GetUndoNames()
        format "BEFORE inventory=% history=%\n" (for n in inventory collect #(n.name,getHandleByAnim n)) history to:log;flush log
        local directory=MCPFixtureDir+"capture-lifecycle-"+CyrusNewLayerID();makeDir directory
        for cycle=1 to 60 do (
            CyrusOpenRecipeSave root directory;local editor=CyrusRecipeSaveEditor
            editor.capturePreview false
            local captured=editor.ownedCapture
            check (captured!="" and doesFileExist captured and editor.thumbnailCapture!=undefined) "Explicit capture produces its owned preview and provenance" log
            if cycle==1 or cycle==60 do copyFile captured (MCPFixtureDir+"capture-lifecycle-"+(cycle as string)+".png")
            destroyDialog editor
            check (not doesFileExist captured and CyrusRecipeSaveEditor==undefined) "Closing releases the owned temporary preview" log
            if mod cycle 10==0 do (local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess();format "METRICS cycle=% heapFree=% heapSize=% privateBytes=%\n" cycle heapFree heapSize process.PrivateMemorySize64 to:log)
        )
        format "AFTER inventory=% history=%\n" (for n in objects collect #(n.name,getHandleByAnim n)) (theHold.GetUndoNames()) to:log;flush log
        check (CyrusPresetSameValues inventory (objects as array) and CyrusPresetSameValues history (theHold.GetUndoNames())) "Capture lifecycle preserves scene inventory and history" log
        check (root.procEpoch==epoch and root.groupBuilds==builds and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows) "Sixty captures preserve complete placements and calculation counters" log
        max undo;check (node.name!="Capture preceding action") "Preceding Undo survives" log
        max redo;check (node.name=="Capture preceding action") "Preceding Redo survives" log
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
