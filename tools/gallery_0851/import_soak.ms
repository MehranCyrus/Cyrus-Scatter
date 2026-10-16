-- One bounded import/reuse cycle, with actual asynchronous dialog handlers.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local file=dotNetClass "System.IO.File",cycle=(file.ReadAllText (MCPFixtureDir+"soak-cycle.txt")) as integer
    local run=file.ReadAllText (MCPFixtureDir+"soak-run.txt")
    local phase=file.ReadAllText (MCPFixtureDir+"soak-phase.txt")
    local log=openFile (MCPFixtureDir+"import-soak-"+run+"-cycle-"+(cycle as string)+".txt") mode:(if phase=="begin" then "w" else "a")
    fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn settle editor=(local start=timeStamp();while editor.progress.active and timeStamp()-start<30000 do ((dotNetClass "System.Threading.Thread").Sleep 10;if editor.progress.active do editor.progress.tick());if editor.progress.active do throw "Preparation timeout.")
    try (
        global GallerySoakRetiredRoot,GallerySoakRetiredOwners,GallerySoakState
        if phase=="begin" then (
        if cycle==1 do (GallerySoakRetiredRoot=undefined;GallerySoakRetiredOwners=#())
        local root=GalleryExportRoot,node=CyrusRecipeOwnerNode root,directory=file.ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        if cycle==1 do undo "Soak preceding sentinel" on node.name="Soak preceding sentinel"
        local before=objects as array,owners=root.layerObjects as array,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows,epoch=root.procEpoch,builds=root.groupBuilds
        local oldUndo=theHold.GetUndoNames(),oldHeap=heapSize,start=timeStamp(),shared=(mod cycle 2)==0
        CyrusOpenAssetImport root directory;local editor=CyrusAssetImportEditor;settle editor
        editor.mode.selection=2;editor.variation.selection=2
        if shared do (editor.assets.selection=2;editor.readyPackage editor.package)
        editor.suggest.pressed();editor.review.pressed();check editor.commit.enabled ("Review: "+editor.status.text) log
        editor.commit.pressed();settle editor;check (matchPattern editor.status.text pattern:"Loaded*") ("Import: "+editor.status.text) log
        if GallerySoakRetiredRoot!=undefined do (
            check (GallerySoakRetiredRoot.groupSnapshotRows.count==0 and GallerySoakRetiredRoot.procPublishedOwners.count==0) "Discarded Redo creation releases its root publication caches" log
            for owner in GallerySoakRetiredOwners do check (owner.procPreparedRows.count==0 and (owner.paintBaseRows==undefined or owner.paintBaseRows.count==0)) "Discarded Redo creation releases its layer calculation caches" log
        )
        local added=for n in objects where findItem before n==0 collect n,controllers=for n in added where classof n.baseObject==AminScatterObject collect n
        check (controllers.count==1) "Exactly one new setup" log
        local newRoot=controllers[1].baseObject
        if shared do (
            for owner in newRoot.layerObjects do for source in owner.sources do check (findItem before source>0) "Reuse binds only pre-existing models" log
            for n in added where findItem controllers n==0 do check ((classof n.baseObject as string)=="Cyrus_Point_Display") "Only the setup's ordinary display helper is additionally created" log
        )
        newRoot.refreshAll();check ((for v in newRoot.groupSnapshotRows where v.count>0 collect v).count==newRoot.layerObjects.count) "Imported layers publish on explicit Update" log
        local newRows=cyrusRecipePublicationFingerprint newRoot.groupSnapshotRows
        destroyDialog editor
        GallerySoakState=#(root,before,owners,rows,epoch,builds,oldUndo,oldHeap,start,shared,controllers[1],newRoot,newRows)
        max undo
        ) else (
        local state=GallerySoakState,root=state[1],before=state[2],owners=state[3],rows=state[4],epoch=state[5],builds=state[6],oldUndo=state[7],oldHeap=state[8],start=state[9],shared=state[10],controller=state[11],newRoot=state[12],newRows=state[13]
        if phase=="undo" then (
        format "INVENTORY before=% after=% undo=% redo=%\n" (for n in before collect #(n.name,getHandleByAnim n)) (for n in objects collect #(n.name,getHandleByAnim n)) (theHold.GetUndoNames()) (theHold.GetRedoNames()) to:log;flush log
        check (CyrusPresetSameValues before (objects as array)) "Undo removes only new owned content" log
        max redo
        ) else if phase=="redo" then (
        check (isValidNode controller and (cyrusRecipePublicationFingerprint newRoot.groupSnapshotRows)==newRows) "Redo preserves imported identity and complete publication" log
        max undo
        ) else if phase=="finish" then (
        check (CyrusPresetSameValues before (objects as array) and CyrusPresetSameValues oldUndo (theHold.GetUndoNames())) "Cycle preserves prior scene inventory and Undo history" log
        GallerySoakRetiredRoot=newRoot;GallerySoakRetiredOwners=newRoot.procPublishedOwners as array
        check (root.procEpoch==epoch and root.groupBuilds==builds and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows) "Independent original publication/work remains unchanged" log
        check (CyrusPresetSameValues owners (root.layerObjects as array) and not theHold.Holding()) "Owners and hold state remain intact" log
        local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        format "METRICS cycle=% shared=% ms=% heapBefore=% heapAfter=% heapFree=% privateBytes=%\nPASS: complete\n" cycle shared (timeStamp()-start) oldHeap heapSize heapFree process.PrivateMemorySize64 to:log
        GallerySoakState=undefined
        ) else throw "Unknown soak phase."
        )
        close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
