-- Ready-to-use library actions reuse the bounded package worker/transaction.
-- Catalog selection never calls these scene/asset functions.
global CyrusOpenReadyPreset,CyrusReadyPresetEditor,CyrusReadyPresetOpenData
global CyrusPresetPackageDirectory,CyrusPresetPlan,CyrusPresetSaveReady,CyrusPresetSaveEditor,CyrusPresetSaveOpenData,CyrusPresetReviseReady,CyrusPresetReviseEditor,CyrusPresetReviseOpenData
global CyrusRecipeGet,CyrusRecipeObject,CyrusRecipeResolve,CyrusRecipeCheckRoot,CyrusRecipeOwnerNode,CyrusRecipeRestorePaint,CyrusRecipeValidateBindings,CyrusRecipeBrowser
global CyrusAssetRoleIsReceiver,CyrusAssetRoleIsPath,CyrusAssetImportPlan,CyrusAssetImport,CyrusAssetCapture,CyrusAssetOwnStage,CyrusAssetWatch,CyrusAssetRemoveStage,CyrusAssetBitmapDirectory
global CyrusRequireAuthor,CyrusViewportRedraw,CyrusPresetSameValues
global CyrusPointSuspended
global CyrusLibraryCheckSurface,CyrusLibraryDestination,CyrusRecipeErrorText
global CyrusAssetBoundNode
fn CyrusPresetPackageDirectory path digest = (
    local parent=getFilenamePath path
    if filenameFromPath path=="entry.csrecipe.json" and doesFileExist (pathConfig.appendPath parent "cyrus.package.json") do return parent
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
                status.text=if state[1]=="complete" then "Preset details and ready assets saved. Load onto surface remains available." else "Settings details saved; ready revision did not finish. "+state[4]
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
fn CyrusPresetPlan root directory package document surface:undefined preparedToken:0L = (
    CyrusLibraryCheckSurface surface
    if root!=undefined do CyrusRecipeCheckRoot root (CyrusRecipeOwnerNode root)
    local graph=CyrusRecipeGet package "graph",roles=CyrusRecipeGet document "roles",bindings=#(),receiverRoles=#(),receiverData=#(),pathTransform=undefined
    if (CyrusRecipeGet document "layers").count+(if root==undefined then 0 else root.layerObjects.count)>10 do throw "This preset would exceed 10 populations. Existing planting is preserved."
    if (CyrusRecipeGet graph "externalRoles").count>0 do throw "This preset has unpackaged dependencies. Save it with Save Everything before loading onto terrain."
    for role in roles where CyrusAssetRoleIsReceiver role do (append receiverRoles role;append bindings #((CyrusRecipeGet role "id"),surface))
    if receiverRoles.count==0 do throw "This preset has no receiving surface. Save a complete planting setup first."
    -- Aliases of one saved terrain bind together; distinct saved terrains need an explicit future adapter.
    for data in (CyrusRecipeGet graph "nodes") do (
        local receiver=false
        for role in receiverRoles where findItem (CyrusRecipeGet data "roles") (CyrusRecipeGet role "id")>0 do receiver=true
        if receiver do (
            if (CyrusAssetBoundNode data bindings)!=surface do throw "A saved terrain also has a model role. Save terrain and source models as separate objects."
            append receiverData data
        )
    )
    if receiverData.count!=1 do throw "Direct loading requires one saved terrain. Save each terrain as its own preset."
    local hasPaint=false,hasPaths=(CyrusRecipeGet graph "version")>=2 and (CyrusRecipeGet graph "splines").count>0,sourceBounds=undefined
    for record in (CyrusRecipeGet document "layers") do (
        if (CyrusRecipeGet record "paint")!=undefined do hasPaint=true
        for area in (CyrusRecipeGet record "areas") where (CyrusRecipeGet area "paint")!=undefined do hasPaint=true
    )
    if hasPaint or hasPaths do (
        if preparedToken<=0 do throw "Prepare this complete preset before transferring its Paint or paths. Nothing was added."
        local receiverMeshID=CyrusRecipeGet receiverData[1] "mesh",receiverMeshFile=undefined
        for meshData in (CyrusRecipeGet graph "meshes") where (CyrusRecipeGet meshData "id")==receiverMeshID do receiverMeshFile=CyrusRecipeGet meshData "file"
        if receiverMeshFile==undefined do throw "The preset is missing its saved receiver mesh. Nothing was added."
        sourceBounds=cyrusAssetPreparedMeshBounds preparedToken receiverMeshFile
    )
    -- Validate required channels and receiver-bound Paint before staging any models or layers.
    for record in (CyrusRecipeGet document "layers") do (
        local records=#(CyrusRecipeGet record "settings")
        for area in (CyrusRecipeGet record "areas") do append records (CyrusRecipeGet area "settings")
        for settings in records do (
        if root!=undefined and (CyrusRecipeGet settings "densityCoordinateMode")==2 do (
            local frame=(CyrusRecipeOwnerNode root).objectTransform
            if abs(dot frame.row1 (cross frame.row2 frame.row3))<1e-12 do throw "Cannot load a local image frame into a singular Scatter transform. Nothing was added."
        )
        if CyrusRecipeGet settings "meshMaskEnabled" do (
            local curve=CyrusRecipeGet settings "meshMaskSamples"
            if curve.count==0 do curve=#(0.0,1.0)
            local channelError=""
            try(cyrusMeshDensityKey surface #(true,(CyrusRecipeGet settings "meshMaskChannel"),(CyrusRecipeGet settings "meshMaskComponent"),(CyrusRecipeGet settings "meshMaskMinimum"),(CyrusRecipeGet settings "meshMaskMaximum"),(CyrusRecipeGet settings "meshMaskInvert"),curve,(CyrusRecipeGet settings "meshMaskSource")))
            catch(channelError=CyrusRecipeErrorText (getCurrentException()))
            if channelError!="" do throw ("Cannot load layer '"+(CyrusRecipeGet record "name")+"'. "+channelError+" No preset layers were added.")
        )
        if (CyrusRecipeGet settings "distributionMode")==3 and (CyrusRecipeGet settings "densityCoordinateMode")==0 do (
            -- Texture UVs and numeric data channels are independent requirements.
            -- Capture here, before the asset/layer transaction, not at final Update.
            local uvError=""
            try(cyrusProceduralSurfaceKey #(surface) true (CyrusRecipeGet settings "densityUVChannel"))
            catch(uvError=CyrusRecipeErrorText (getCurrentException()))
            if uvError!="" do throw ("Cannot load layer '"+(CyrusRecipeGet record "name")+"'. "+uvError+" No preset layers were added.")
        )
        )
        local paintError=""
        try (
            local paint=CyrusRecipeGet record "paint"
            if paint!=undefined do CyrusRecipeRestorePaint paint surface document footprint:sourceBounds
            for area in (CyrusRecipeGet record "areas") do (
                local data=CyrusRecipeGet area "paint"
                if data!=undefined do CyrusRecipeRestorePaint data surface document footprint:sourceBounds
            )
        )catch(paintError=CyrusRecipeErrorText (getCurrentException()))
        if paintError!="" do throw ("Cannot transfer Paint in layer '"+(CyrusRecipeGet record "name")+"' onto this terrain. "+paintError+" Nothing was added.")
    )
    if hasPaths do (
        local values=CyrusRecipeGet receiverData[1] "transform",metres=(units.decodeValue "1m") as double
        local saved=matrix3 [values[1],values[2],values[3]] [values[4],values[5],values[6]] [values[7],values[8],values[9]] [values[10]*metres,values[11]*metres,values[12]*metres]
        if abs(dot saved.row1 (cross saved.row2 saved.row3))<1e-12 do throw "Saved terrain has a singular frame; its paths cannot be transferred."
        -- Match the same local XY footprint as Paint. Path heights and band
        -- widths remain physical; the receiving mesh supplies final placement Z.
        local destinationBounds=cyrusAssetReceiverBounds surface
        local sx=(destinationBounds[3]-destinationBounds[1])/((sourceBounds[3]-sourceBounds[1])*metres)
        local sy=(destinationBounds[4]-destinationBounds[2])/((sourceBounds[4]-sourceBounds[2])*metres)
        local fit=matrix3 [sx,0,0] [0,sy,0] [0,0,1] [destinationBounds[1]-sourceBounds[1]*metres*sx,destinationBounds[2]-sourceBounds[2]*metres*sy,0]
        pathTransform=(inverse saved)*fit*surface.objectTransform
    )
    CyrusRecipeValidateBindings root (CyrusRecipeObject #(#("roles",receiverRoles))) bindings
    local manifest=CyrusRecipeGet package "manifest",descriptor=CyrusRecipeGet manifest "recipe"
    #(CyrusAssetImportPlan root:root node:(if root==undefined then undefined else CyrusRecipeOwnerNode root) inputKey:(if root==undefined then undefined else root.procInputKey()) directory:directory package:package recipeHash:(CyrusRecipeGet descriptor "sha256") bindings:bindings newSetup:(root==undefined) variation:#new assets:#clone preset:true pathTransform:pathTransform paintFootprint:sourceBounds,"Selected terrain: "+surface.name+(if hasPaint or hasPaths then " / saved layout fitted to terrain footprint" else ""))
)
fn CyrusOpenReadyPreset root directory expected:"" surface:undefined = (
    CyrusRequireAuthor();CyrusLibraryCheckSurface surface
    local node=if root==undefined then undefined else CyrusRecipeOwnerNode root
    if root!=undefined do CyrusRecipeCheckRoot root node
    if CyrusReadyPresetEditor!=undefined do try(destroyDialog CyrusReadyPresetEditor)catch()
    local job=cyrusAssetPackagePrepare directory (CyrusAssetBitmapDirectory())
    rollout editor "Load planting preset" width:500 height:206 (
        local root,node,surface,launchBrowser,launchSession="",directory,expected="",job=0L,finished=false,plan=undefined,result=undefined,terrainNote="",displayHeld=false,previousSuspended=false,updateReadyAt=0.0
        label title "Loading models, materials and planting settings..." pos:[12,12] width:476 height:38
        label status "Adds new layers and updates scatter once. Existing planting settings are kept." pos:[12,54] width:476 height:96
        button closeButton "Cancel" pos:[12,166] width:476
        timer progress interval:100 active:false
        fn resumeDisplay = (
            if displayHeld do (CyrusPointSuspended=previousSuspended;displayHeld=false)
        )
        fn loadPrepared = (
            CyrusLibraryCheckSurface surface
            if root!=undefined do CyrusRecipeCheckRoot root node
            local package=cyrusAssetPackagePrepared job false,document=cyrusAssetPackagePrepared job true
            if expected!="" and (CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet package "manifest") "recipe") "sha256")!=expected do throw "The ready preset does not match this gallery entry. Refresh the library."
            local proposed=CyrusPresetPlan root directory package document surface:surface preparedToken:job
            plan=proposed[1];terrainNote=proposed[2]
            status.text="Adding preset layers. "+terrainNote
            -- Import owns assets, authored changes and the initial calculation
            -- in one Undo hold. No open hold survives this modeless callback.
            previousSuspended=CyrusPointSuspended;CyrusPointSuspended=true;displayHeld=true
            result=CyrusAssetImport plan preparedToken:job
            root=result[1];node=result[3]
            -- MAXScript can reuse a rollout value after close/reopen. Its open
            -- session token, not rollout equality alone, identifies this view.
            if launchBrowser!=undefined and CyrusRecipeBrowser==launchBrowser and launchSession==launchBrowser.sessionID do (launchBrowser.bindDestination root node;launchBrowser.showSelected())
            local clock=dotNetClass "System.Diagnostics.Stopwatch"
            updateReadyAt=(clock.GetTimestamp() as double)+clock.Frequency*0.3
            status.text="Preset calculated. Finishing library view...\n"+terrainNote
            closeButton.text="Close (layers added)"
            progress.active=true
        )
        fn finishUpdate = (
            -- The initial result already succeeded before import committed.
            resumeDisplay()
            local document=cyrusAssetPackagePrepared job true
            title.text="Loaded: "+(CyrusRecipeGet document "name")
            status.text=((result[2].count) as string)+" new layers added.\n"+terrainNote+"\nExisting layers and their settings were kept. "+(if root.updateMode==1 then "Manual mode is still enabled." else "Live mode is still enabled.")
            finished=true;closeButton.text="Close";CyrusViewportRedraw()
        )
        on editor open do (
            root=CyrusReadyPresetOpenData[1];node=CyrusReadyPresetOpenData[2];directory=CyrusReadyPresetOpenData[3];job=CyrusReadyPresetOpenData[4];expected=CyrusReadyPresetOpenData[5];surface=CyrusReadyPresetOpenData[6];launchBrowser=CyrusReadyPresetOpenData[7];launchSession=CyrusReadyPresetOpenData[8]
            progress.active=true
        )
        on progress tick do try (
            CyrusLibraryCheckSurface surface
            if root!=undefined do CyrusRecipeCheckRoot root node
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
            status.text=(if result==undefined then "Preset was not added. " else "Preset layers were added, but Update failed. The last complete preview is retained; Undo removes the added preset. ")+(CyrusRecipeErrorText (getCurrentException()))
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
    CyrusReadyPresetOpenData=#(root,node,directory,job,expected,surface,CyrusRecipeBrowser,(if CyrusRecipeBrowser==undefined then "" else CyrusRecipeBrowser.sessionID));CyrusReadyPresetEditor=editor
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
                status.text=if value[1]=="complete" then "Ready preset saved with its models, materials, terrain, paths and Paint. Select it in the library and use Load onto surface." else "Settings recipe saved; ready package did not finish. "+value[4]
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
