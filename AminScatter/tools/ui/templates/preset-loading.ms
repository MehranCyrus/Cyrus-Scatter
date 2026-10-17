-- Ready-to-use library actions reuse the bounded package worker/transaction.
-- Catalog selection never calls these scene/asset functions.
global CyrusOpenReadyPreset,CyrusReadyPresetEditor,CyrusReadyPresetOpenData
global CyrusPresetPackageDirectory,CyrusPresetPlan,CyrusPresetSaveReady,CyrusPresetSaveEditor,CyrusPresetSaveOpenData,CyrusPresetReviseReady,CyrusPresetReviseEditor,CyrusPresetReviseOpenData
global CyrusRecipeGet,CyrusRecipeObject,CyrusRecipeResolve,CyrusRecipeCheckRoot,CyrusRecipeOwnerNode,CyrusRecipeRestorePaint,CyrusRecipeValidateBindings,CyrusRecipeBrowser
global CyrusAssetRoleIsReceiver,CyrusAssetRoleIsPath,CyrusAssetImportPlan,CyrusAssetImport,CyrusAssetCapture,CyrusAssetOwnStage,CyrusAssetWatch,CyrusAssetRemoveStage,CyrusAssetBitmapDirectory
global CyrusRequireAuthor,CyrusViewportRedraw,CyrusPresetSameValues
global CyrusPointSuspended
fn CyrusPresetPackageDirectory path digest = (
    -- Keep native file paths short while retaining the full content identity.
    pathConfig.appendPath (getFilenamePath path) ("Presets\\"+digest)
)
fn CyrusPresetReviseReady path previous digest = (
    local source=CyrusPresetPackageDirectory path previous,destination=CyrusPresetPackageDirectory path digest
    if not doesFileExist (pathConfig.appendPath source "cyrus.package.json") or previous==digest do return true
    if CyrusPresetReviseEditor!=undefined do throw "A preset revision is still being saved. Wait for it to finish."
    local job=cyrusAssetPackagePrepare source (CyrusAssetBitmapDirectory())
    rollout editor "Save preset details" width:500 height:150 (
        local path="",source="",destination="",digest="",job=0L,preparing=true,finished=false
        label status "Updating the ready preset without reading or changing scene objects..." pos:[12,12] width:476 height:84
        button closeButton "Cancel" pos:[12,110] width:476
        timer progress interval:100 active:false
        on editor open do (
            path=CyrusPresetReviseOpenData[1];source=CyrusPresetReviseOpenData[2];destination=CyrusPresetReviseOpenData[3];digest=CyrusPresetReviseOpenData[4];job=CyrusPresetReviseOpenData[5];progress.active=true
        )
        on progress tick do try (
            local state=cyrusAssetPackagePoll job
            if preparing and state[1]=="ready" then (
                local package=cyrusAssetPackagePrepared job false,graph=CyrusRecipeGet package "graph",files=#()
                for file in (CyrusRecipeGet graph "files") do append files #((CyrusRecipeGet file "id"),(pathConfig.appendPath source ("assets\\"+(CyrusRecipeGet file "sha256")+"."+(CyrusRecipeGet file "suffix"))))
                local replacement=cyrusAssetPackageStart destination path digest graph files (CyrusRecipeGet (CyrusRecipeGet package "manifest") "redistribution") 1
                cyrusAssetPackageRelease job;job=replacement;preparing=false;status.text="Saving revised preset files..."
            ) else if (preparing and (state[1]=="failed" or state[1]=="cancelled")) or (not preparing and state[1]!="exporting") do (
                progress.active=false;finished=true;closeButton.text="Close"
                status.text=if state[1]=="complete" then "Preset details and ready assets saved. Load + Update remains available." else "Settings details saved; ready revision did not finish. "+state[4]
                if preparing do (cyrusAssetPackageRelease job;job=0L)
                if CyrusRecipeBrowser!=undefined do CyrusRecipeBrowser.refreshEntry path
            )
        )catch(progress.active=false;finished=true;closeButton.text="Close";status.text="Settings details saved; ready revision failed. "+getCurrentException())
        on closeButton pressed do destroyDialog editor
        on editor close do (
            progress.active=false
            if job!=0L do (if not finished do cyrusAssetPackageCancel job;if preparing do cyrusAssetPackageRelease job)
            CyrusPresetReviseEditor=undefined
        )
    )
    CyrusPresetReviseOpenData=#(path,source,destination,digest,job);CyrusPresetReviseEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow);true
)
fn CyrusPresetPlan root directory package document = (
    CyrusRecipeCheckRoot root (CyrusRecipeOwnerNode root)
    local graph=CyrusRecipeGet package "graph",roles=CyrusRecipeGet document "roles",bindings=#(),terrain=#(),receiverRoles=#(),reason="Included terrain",compatible=true
    if (CyrusRecipeGet document "layers").count+root.layerObjects.count>10 do throw "This preset would exceed 10 populations. Use a new Scatter setup or remove unneeded layers first. Existing planting is preserved."
    if (CyrusRecipeGet graph "externalRoles").count>0 do throw "This package still needs external dependencies. Use Recipe actions > Review bindings, or save a ready preset including its terrain and paths."
    local selected=root.selectedLayer()
    if selected!=undefined do terrain=selected.validSurfaces()
    if terrain.count==0 do for layer in root.logicalLayers() do for node in layer.validSurfaces() do appendIfUnique terrain node
    for role in roles where CyrusAssetRoleIsReceiver role do append receiverRoles role
    if terrain.count==1 and receiverRoles.count==1 then (
        bindings=#(#((CyrusRecipeGet receiverRoles[1] "id"),terrain[1]))
        -- A required field must exist; valid zero is different from missing.
        try (
            for record in (CyrusRecipeGet document "layers") do (
                local settings=CyrusRecipeGet record "settings"
                if CyrusRecipeGet settings "meshMaskEnabled" do (
                    local curve=CyrusRecipeGet settings "meshMaskSamples"
                    if curve.count==0 do curve=#(0.0,1.0)
                    cyrusMeshDensityKey terrain[1] #(true,(CyrusRecipeGet settings "meshMaskChannel"),(CyrusRecipeGet settings "meshMaskComponent"),(CyrusRecipeGet settings "meshMaskMinimum"),(CyrusRecipeGet settings "meshMaskMaximum"),(CyrusRecipeGet settings "meshMaskInvert"),curve)
                )
                local paint=CyrusRecipeGet record "paint"
                if paint!=undefined do CyrusRecipeRestorePaint paint terrain[1] document
                for area in (CyrusRecipeGet record "areas") do (
                    local data=CyrusRecipeGet area "paint"
                    if data!=undefined do CyrusRecipeRestorePaint data terrain[1] document
                )
            )
        )catch(compatible=false)
        if compatible then reason="Current terrain: "+terrain[1].name
        else (bindings=#();reason="Included terrain: saved Paint or mesh-channel data")
    ) else reason=if terrain.count>1 then "Included terrain: destination has multiple receivers" else "Included terrain: no destination terrain"
    -- A saved path belongs to its saved receiver frame. Never move a path to an
    -- unrelated destination implicitly; use included context for path presets.
    if (CyrusRecipeGet graph "version")==2 and (CyrusRecipeGet graph "splines").count>0 do (bindings=#();reason="Included terrain and spline paths")
    if bindings.count>0 do CyrusRecipeValidateBindings root (CyrusRecipeObject #(#("roles",receiverRoles))) bindings
    local manifest=CyrusRecipeGet package "manifest",descriptor=CyrusRecipeGet manifest "recipe"
    #(CyrusAssetImportPlan root:root node:(CyrusRecipeOwnerNode root) inputKey:(root.procInputKey()) directory:directory package:package recipeHash:(CyrusRecipeGet descriptor "sha256") bindings:bindings newSetup:false variation:#new assets:#clone preset:true,reason)
)
fn CyrusOpenReadyPreset root directory expected:"" = (
    CyrusRequireAuthor();local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if CyrusReadyPresetEditor!=undefined do try(destroyDialog CyrusReadyPresetEditor)catch()
    local job=cyrusAssetPackagePrepare directory (CyrusAssetBitmapDirectory())
    rollout editor "Load planting preset" width:500 height:206 (
        local root,node,directory,expected="",job=0L,finished=false,plan=undefined,result=undefined,terrainNote="",displayHeld=false,previousSuspended=false,updateReadyAt=0.0
        label title "Loading models, materials and planting settings..." pos:[12,12] width:476 height:38
        label status "Adds new layers and updates scatter once. Existing planting settings are kept." pos:[12,54] width:476 height:96
        button closeButton "Cancel" pos:[12,166] width:476
        timer progress interval:100 active:false
        fn resumeDisplay = (
            if displayHeld do (CyrusPointSuspended=previousSuspended;displayHeld=false)
        )
        fn loadPrepared = (
            CyrusRecipeCheckRoot root node
            local package=cyrusAssetPackagePrepared job false,document=cyrusAssetPackagePrepared job true
            if expected!="" and (CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet package "manifest") "recipe") "sha256")!=expected do throw "The ready preset does not match this gallery entry. Refresh the library."
            local proposed=CyrusPresetPlan root directory package document
            plan=proposed[1];terrainNote=proposed[2]
            status.text="Adding preset layers. "+terrainNote
            -- Keep import's normal Live redraw from solving before the explicit
            -- Update. Max batches node notifications with a 150 ms delay; let
            -- that batch invalidate the newly created inputs before calculating.
            previousSuspended=CyrusPointSuspended;CyrusPointSuspended=true;displayHeld=true
            result=CyrusAssetImport plan preparedToken:job
            local clock=dotNetClass "System.Diagnostics.Stopwatch"
            updateReadyAt=(clock.GetTimestamp() as double)+clock.Frequency*0.3
            status.text="Layers added. Finishing Update...\n"+terrainNote
            closeButton.text="Close (layers added)"
            progress.active=true
        )
        fn finishUpdate = (
            -- This button is explicitly Load + Update, a calculation boundary.
            -- Authored import and subsequent complete publication stay separate.
            root.refreshAll()
            resumeDisplay()
            local document=cyrusAssetPackagePrepared job true
            title.text="Loaded: "+(CyrusRecipeGet document "name")
            status.text=((result[2].count) as string)+" new layers added.\n"+terrainNote+"\nExisting layers and their settings were kept. "+(if root.updateMode==1 then "Manual mode is still enabled." else "Live mode is still enabled.")
            finished=true;closeButton.text="Close";CyrusViewportRedraw()
        )
        on editor open do (
            root=CyrusReadyPresetOpenData[1];node=CyrusReadyPresetOpenData[2];directory=CyrusReadyPresetOpenData[3];job=CyrusReadyPresetOpenData[4];expected=CyrusReadyPresetOpenData[5]
            progress.active=true
        )
        on progress tick do try (
            CyrusRecipeCheckRoot root node
            local value=cyrusAssetPackagePoll job
            if result!=undefined then (
                local clock=dotNetClass "System.Diagnostics.Stopwatch"
                if (clock.GetTimestamp() as double)>=updateReadyAt do (
                    progress.active=false;finishUpdate();cyrusAssetPackageRelease job;job=0L
                )
            ) else if value[1]=="ready" then (
                progress.active=false;loadPrepared()
            ) else if value[1]=="failed" or value[1]=="cancelled" then (
                progress.active=false;finished=true;closeButton.text="Close";status.text=value[4]
                cyrusAssetPackageRelease job;job=0L
            ) else status.text="Preparing preset: "+value[2]+"\nExisting layers remain unchanged."
        )catch(
            resumeDisplay()
            progress.active=false;finished=true;closeButton.text="Close"
            status.text=(if result==undefined then "Preset was not added. " else "Preset layers were added, but Update failed. The last complete preview is retained; Undo removes the added preset. ")+getCurrentException()
            if job!=0L do (cyrusAssetPackageRelease job;job=0L)
        )
        on closeButton pressed do destroyDialog editor
        on editor close do (
            progress.active=false
            resumeDisplay()
            if job!=0L do (if not finished do cyrusAssetPackageCancel job;cyrusAssetPackageRelease job)
            CyrusReadyPresetEditor=undefined
        )
    )
    CyrusReadyPresetOpenData=#(root,node,directory,job,expected);CyrusReadyPresetEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)
fn CyrusPresetSaveReady root path digest bindings = (
    CyrusRecipeCheckRoot root (CyrusRecipeOwnerNode root)
    local directory=CyrusPresetPackageDirectory path digest
    if doesFileExist (pathConfig.appendPath directory "cyrus.package.json") do return true
    if CyrusPresetSaveEditor!=undefined do try(destroyDialog CyrusPresetSaveEditor)catch()
    local stage=CyrusAssetOwnStage(),job=0L
    try (
        local capture=CyrusAssetCapture root path digest bindings stage[1] includeContext:true
        if (CyrusRecipeGet capture[1] "externalRoles").count>0 do throw "Ready preset needs a supported adapter for all dependencies. The settings recipe is saved; it is not a complete ready preset."
        (dotNetClass "System.IO.Directory").CreateDirectory (getFilenamePath directory)
        job=cyrusAssetPackageStart directory path digest capture[1] capture[2] "User-created preset; redistribution remains subject to the user's source-asset licenses." 1
        CyrusAssetWatch job stage;stage=undefined
    )catch(if stage!=undefined do CyrusAssetRemoveStage stage;throw())
    rollout editor "Save ready-to-use preset" width:500 height:150 (
        local job=0L,path="",finished=false
        label status "Saving models, materials, terrain, paths and complete Paint..." pos:[12,12] width:476 height:84
        button closeButton "Cancel" pos:[12,110] width:476
        timer progress interval:100 active:false
        on editor open do (job=CyrusPresetSaveOpenData[1];path=CyrusPresetSaveOpenData[2];progress.active=true)
        on progress tick do try (
            local value=cyrusAssetPackagePoll job
            if value[1]!="exporting" do (
                progress.active=false;finished=true;closeButton.text="Close"
                status.text=if value[1]=="complete" then "Ready preset saved with its models, materials, terrain, paths and Paint. Select it in the library and use Load + Update." else "Settings recipe saved; ready package did not finish. "+value[4]
                if CyrusRecipeBrowser!=undefined do CyrusRecipeBrowser.refreshEntry path
            )
        )catch(progress.active=false;finished=true;closeButton.text="Close";status.text=getCurrentException())
        on closeButton pressed do destroyDialog editor
        on editor close do (progress.active=false;if not finished do cyrusAssetPackageCancel job;CyrusPresetSaveEditor=undefined)
    )
    CyrusPresetSaveOpenData=#(job,path);CyrusPresetSaveEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)
