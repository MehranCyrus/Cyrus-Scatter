(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-preparation-"+(timeStamp() as string)+".txt"),moved="",directory=""
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn waitJob token = (
        local started=timeStamp(),state=cyrusAssetPackagePoll token
        while state[1]=="preparing" and (timeStamp()-started)<30000 do ((dotNetClass "System.Threading.Thread").Sleep 10;state=cyrusAssetPackagePoll token)
        if state[1]=="preparing" do throw "Owned preparation timeout."
        state
    )
    try (
        CyrusPerfHeadless=true
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Painted-border scene opens" log
        directory=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        check (matchPattern directory pattern:"*build*mcp-qualification*foundation-roadmap-gallery0851-*") "Owned package directory" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject;root.refreshAll()
        local before=objects as array,counters=#(root.procEpoch,root.groupBuilds),rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows
        local started=timeStamp(),job=cyrusAssetPackagePrepare directory (CyrusAssetBitmapDirectory()),returned=timeStamp()-started,state=waitJob job
        format "Worker start returned in % ms; prepared payload bytes: %\n" returned state[3] to:log
        check (state[1]=="ready") "File worker prepares a verified snapshot" log
        local package=cyrusAssetPackagePrepared job false,document=CyrusRecipeGet package "recipe",external=CyrusRecipeGet (CyrusRecipeGet package "graph") "externalRoles",all=CyrusRecipeSuggestBindings root document
        local bindings=for pair in all where findItem external pair[1]>0 collect pair,plan=CyrusAssetReview root directory bindings variation:#same verifiedPackage:package
        check (CyrusPresetSameValues before (objects as array) and CyrusPresetSameValues counters #(root.procEpoch,root.groupBuilds) and rows==(cyrusRecipePublicationFingerprint root.groupSnapshotRows)) "Preparation and Review perform no scene or placement mutation" log
        -- Prepared geometry and Paint are detached from files. The final UI Load
        -- prepares a fresh snapshot first; the host commit consumes only that copy.
        moved=directory+"-temporarily-unavailable";(dotNetClass "System.IO.Directory").Move directory moved
        local imported=CyrusAssetImport plan preparedToken:job
        check (imported[2].count==(CyrusRecipeGet document "layers").count) "Host commit consumes prepared meshes/Paint without file I/O" log
        max undo;check (CyrusPresetSameValues before (objects as array)) "Prepared import Undo removes owned sources" log
        (dotNetClass "System.IO.Directory").Move moved directory;moved=""
        cyrusAssetPackageRelease job
        local failed=false;try(cyrusAssetPackagePrepared job false)catch(failed=true)
        check failed "Released snapshot cannot be reused" log
        job=cyrusAssetPackagePrepare directory (CyrusAssetBitmapDirectory());cyrusAssetPackageCancel job;state=waitJob job
        check (findItem #("cancelled","ready") state[1]>0) "Cancellation reaches a safe terminal boundary, including a completed race" log
        cyrusAssetPackageRelease job
        check (CyrusPresetSameValues before (objects as array) and not theHold.Holding()) "Cancelled preparation leaves scene and hold state intact" log
        CyrusOpenAssetImport root directory
        local editor=CyrusAssetImportEditor
        destroyDialog editor
        state=waitJob editor.job
        check (not editor.progress.active and CyrusAssetImportEditor==undefined) "Closing Load cancels preparation and stops polling" log
        check (findItem #("cancelled","released") state[1]>0) "Closed dialog retains no prepared snapshot" log
        format "PASS: complete\n" to:log;close log
    )catch(
        if moved!="" and doesDirectoryExist moved and not doesDirectoryExist directory do (dotNetClass "System.IO.Directory").Move moved directory
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
