-- Owned Max 2027 witnesses: unsupported authored input, pixels, colour and rollback.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-bitmap-boundaries-"+(timeStamp() as string)+".txt"),stage=undefined,savedApply=CyrusRecipeApplySettings
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn rejectMap value expected log = (
        local stage=CyrusAssetOwnStage(),failed=false,reason=""
        try(CyrusAssetMap (CyrusAssetCaptureContext directory:stage[1]) value)catch(failed=true;reason=getCurrentException())
        CyrusAssetRemoveStage stage
        format "Rejection: %\n" reason to:log
        check (failed and matchPattern reason pattern:expected) ("Map rejects: "+expected) log
        check (not doesDirectoryExist stage[1]) "Owned capture staging is removable after rejection" log
    )
    fn settle editor = (
        local started=timeStamp()
        while editor.progress.active and (timeStamp()-started)<30000 do ((dotNetClass "System.Threading.Thread").Sleep 10;if editor.progress.active do editor.progress.tick())
        if editor.progress.active do throw "Owned preparation timeout."
    )
    try (
        CyrusPerfHeadless=true
        local source=GalleryBitmapSourcePNG
        check (doesFileExist source) "Owned source PNG exists" log
        rejectMap (noise()) "*supported static Bitmap*" log
        local texture=bitmaptexture filename:source
        texture.coords.U_Angle=15
        rejectMap texture "*Unsupported non-default asset setting*" log
        texture=bitmaptexture filename:source;texture.output.enableColorMap=true
        rejectMap texture "*Unsupported non-default asset setting*" log
        texture=bitmaptexture filename:source
        animate on (at time 0 texture.coords.U_Offset=0;at time 10 texture.coords.U_Offset=0.25)
        rejectMap texture "*supported static*" log
        texture=bitmaptexture filename:source
        animate on (at time 0 texture.output.RGB_Level=1;at time 10 texture.output.RGB_Level=0.5)
        rejectMap texture "*supported static*" log
        texture=bitmaptexture filename:source
        setPropertyController texture.coords #U_Offset (float_script())
        rejectMap texture "*supported static*" log
        texture=bitmaptexture filename:source
        setPixels texture.bitmap [0,0] #((color 255 0 255))
        rejectMap texture "*in-memory bitmap differs*" log
        -- Reopen from disk after the intentionally unsaved edit; the file is untouched.
        local bitmapValue=openBitmap source
        texture=bitmaptexture bitmap:bitmapValue
        stage=CyrusAssetOwnStage()
        local material=standardMaterial();material.bumpMap=noise();material.bumpMapEnable=false
        local failed=false,reason=""
        try(CyrusAssetMaterial (CyrusAssetCaptureContext directory:stage[1]) material)catch(failed=true;reason=getCurrentException())
        check (failed and matchPattern reason pattern:"*Unsupported non-default asset setting*") "Dormant unsupported material slot is rejected, not discarded" log
        CyrusAssetRemoveStage stage;stage=undefined
        local current=CyrusAssetColorContext bitmapValue.colorSpace,wrong=deepCopy current
        CyrusRecipePut wrong "renderingSpace" "Owned incompatible space"
        failed=false;try(CyrusAssetCheckColor wrong current)catch(failed=true)
        check failed "Mismatched colour pipeline rejects without changing scene settings" log
        close bitmapValue
        -- Actual Load: inject failure after map/material/source creation and first settings.
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Independent rollback destination opens" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject;root.refreshAll()
        local directory=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        CyrusOpenAssetImport root directory;local editor=CyrusAssetImportEditor;settle editor
        editor.suggest.pressed();editor.review.pressed();check editor.commit.enabled "Textured rollback review is ready" log
        local before=objects as array,owners=root.layerObjects as array,epoch=root.procEpoch,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows
        undo "Prior textured import sentinel" on node.name="Textured rollback sentinel"
        global GalleryBitmapSavedApply,GalleryBitmapFailureReached;GalleryBitmapSavedApply=CyrusRecipeApplySettings;GalleryBitmapFailureReached=false
        fn CyrusRecipeApplySettings owner settings bindings variation:#new = (
            GalleryBitmapSavedApply owner settings bindings variation:variation
            GalleryBitmapFailureReached=true
            throw "Owned failure after textured asset staging and first layer setters."
        )
        editor.commit.pressed();settle editor;CyrusRecipeApplySettings=savedApply
        check GalleryBitmapFailureReached "Failure is after textured assets and actual owner setters" log
        check (CyrusPresetSameValues before (objects as array) and CyrusPresetSameValues owners (root.layerObjects as array)) "Rollback restores node inventory and ordered owners" log
        check (root.procEpoch==epoch and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows and not theHold.Holding()) "Rollback retains complete publication and closes transaction" log
        check (not editor.progress.active) "Failed Load stops progress polling" log
        max undo;check (node.name!="Textured rollback sentinel") "Failure preserves the preceding Undo" log
        max redo;check (node.name=="Textured rollback sentinel") "Failure preserves the preceding Redo" log
        destroyDialog editor
        format "PASS: complete\n" to:log;close log
    )catch(
        CyrusRecipeApplySettings=savedApply
        if stage!=undefined do try(CyrusAssetRemoveStage stage)catch()
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
