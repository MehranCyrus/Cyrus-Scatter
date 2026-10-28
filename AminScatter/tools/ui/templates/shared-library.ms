-- Shared library orchestration. File workers own bytes; host commands own scene changes.
global CyrusSharedStore,CyrusSharedLibraryInstance,CyrusSharedLibraryRootOverride,CyrusSharedBeginSave,CyrusSharedPollSave,CyrusSharedCancelSave,CyrusSharedWatchSave
global CyrusSharedSaveJobs,CyrusSharedSaveTimer,CyrusSharedSaveTick,CyrusSharedProgressEditor,CyrusSharedProgressData
global CyrusSharedQueue
global CyrusRecipeScriptDirectory,CyrusRecipeObject,CyrusRecipeGet,CyrusRecipePut,CyrusRecipeCapture,CyrusAssetCapture,CyrusAssetOwnStage,CyrusAssetRemoveStage
global CyrusRecipeBrowser,cyrusSharedLibraryVersion
global CyrusSharedConfigureRoot,CyrusSharedModelImport,CyrusSharedImportModel,CyrusSharedModels
global CyrusSharedOpenStorage,CyrusSharedSaveModels,CyrusSharedWatchOperation,CyrusSharedAskName
global CyrusSharedRelinkScene,CyrusSharedRelinkEditor,CyrusSharedRelinkData,CyrusSharedJsonQuote
global AminScatterObject,CyrusRequireAuthor,CyrusViewportRedraw,CyrusRecipeOwnerNode,CyrusRecipeCheckRoot,CyrusAssetBitmapDirectory,CyrusAssetStage
global CyrusSharedProvenance
global CyrusSharedUseRoot,cyrusAssetModelPrepare,cyrusAssetOpenStaticImage,cyrusAssetOpenImage,cyrusAssetImageAdmission
global CoronaBitmap
fn CyrusSharedProvenance directory = (
    dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")
    (dotNetClass "Cyrus.Content.SharedLibrary").SourceProvenance directory
)
if CyrusSharedSaveJobs==undefined do CyrusSharedSaveJobs=#()

fn CyrusSharedStore = (
    if cyrusSharedLibraryVersion==undefined or cyrusSharedLibraryVersion()!=1 or cyrusAssetModelPrepare==undefined or cyrusAssetOpenStaticImage==undefined do throw "Install the complete CyrusScatter 0.87.6 package and restart Max."
    if CyrusSharedLibraryInstance!=undefined do return CyrusSharedLibraryInstance
    local assembly=dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")
    if assembly==undefined do throw "The Cyrus shared library assembly could not load."
    local identity=assembly.GetName()
    if identity.Version.ToString()!="0.87.6.0" do throw "Load the matching CyrusScatter 0.87.6 gallery."
    local io=dotNetClass "System.IO.File",root=CyrusSharedLibraryRootOverride
    if root==undefined or root=="" do (
        local config=pathConfig.appendPath ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") "CyrusScatter\\personal-library.txt"
        if io.Exists config then root=trimRight (trimLeft (io.ReadAllText config)) else (
            local registration=(dotNetClass "Cyrus.Content.LibraryLocation").Resolve CyrusRecipeScriptDirectory ((maxVersion())[1]/1000+1998)
            local documents=(dotNetClass "System.Environment").GetFolderPath ((dotNetClass "System.Environment+SpecialFolder").MyDocuments)
            root=if registration!=undefined and registration.ManagedRoot!="" then registration.ManagedRoot else pathConfig.appendPath documents "CyrusScatter\\SharedLibrary"
        )
    )
    CyrusSharedLibraryInstance=dotNetObject "Cyrus.Content.SharedLibrary" root
    CyrusSharedLibraryInstance
)
fn CyrusSharedConfigureRoot = (
    local initial=if CyrusSharedLibraryInstance!=undefined then CyrusSharedLibraryInstance.Root else getDir #userScripts
    local chosen=getSavePath caption:"Open or create a shared library in a short local NTFS folder" initialDir:initial
    if chosen==undefined do return false
    CyrusSharedUseRoot chosen
    if CyrusRecipeBrowser!=undefined do (CyrusRecipeBrowser.panel.SetNavigation 1 "" false;CyrusRecipeBrowser.refresh())
    true
)
fn CyrusSharedUseRoot root = (
    dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")
    local next=dotNetObject "Cyrus.Content.SharedLibrary" root
    if CyrusSharedLibraryRootOverride!=undefined then CyrusSharedLibraryRootOverride=next.Root else (
        local config=pathConfig.appendPath ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") "CyrusScatter\\personal-library.txt"
        (dotNetClass "Cyrus.Content.SharedLibrary").RegisterRoot config next.Root
    )
    CyrusSharedLibraryInstance=next;true
)
struct CyrusSharedSaveJob (store,ticket,stage=undefined,packageJob=0L,managed=undefined,packageDirectory="",path="",digest="",state="working",error="",result="",modelsOnly=false)
fn CyrusSharedPollSave job = (
    if job.state!="working" do return job.state
    try (
        if job.managed==undefined do (
            local progress=undefined
            try(progress=cyrusAssetPackagePoll job.packageJob)catch(
                if doesFileExist (pathConfig.appendPath job.packageDirectory "cyrus.package.json") then progress=#("complete") else throw()
            )
            if progress[1]=="exporting" do return "working"
            if progress[1]!="complete" do throw (if progress.count>=4 then progress[4] else "Ready package was cancelled.")
            job.managed=if job.modelsOnly then job.store.PublishModels job.ticket job.packageDirectory else job.store.Publish job.ticket job.packageDirectory
        )
        if not job.managed.Terminal do return "working"
        job.state=job.managed.State;job.error=job.managed.Error;job.result=job.managed.Result
    )catch(job.state="failed";job.error=getCurrentException())
    if job.state!="working" do (
        if job.stage!=undefined do try(CyrusAssetRemoveStage job.stage;job.stage=undefined)catch(format "Cyrus library staging: %\n" (getCurrentException()))
        if job.state!="complete" do try(job.store.Discard job.ticket)catch(format "Cyrus save staging retained for recovery: %\n" (getCurrentException()))
    )
    job.state
)
fn CyrusSharedSaveTick sender args = (
    for i=CyrusSharedSaveJobs.count to 1 by -1 do if (CyrusSharedPollSave CyrusSharedSaveJobs[i])!="working" do deleteItem CyrusSharedSaveJobs i
    if CyrusSharedSaveJobs.count==0 and CyrusSharedSaveTimer!=undefined do CyrusSharedSaveTimer.Stop()
)
fn CyrusSharedQueue job = (
    append CyrusSharedSaveJobs job
    if CyrusSharedSaveTimer==undefined do (
        CyrusSharedSaveTimer=dotNetObject "System.Windows.Forms.Timer";CyrusSharedSaveTimer.Interval=100
        dotNet.addEventHandler CyrusSharedSaveTimer "Tick" CyrusSharedSaveTick
    )
    CyrusSharedSaveTimer.Start();job
)
fn CyrusSharedBeginSave root data metadata image capture original expected ready bindings modelsOnly:false = (
    CyrusSharedSaveTick undefined undefined
    if CyrusSharedSaveJobs.count>0 do throw "Wait for the current library save to finish or cancel it."
    local store=CyrusSharedStore(),ticket=store.BeginSave original expected ((CyrusRecipeGet data "id")+".csrecipe.json")
    local job=CyrusSharedSaveJob store:store ticket:ticket path:ticket.RecipePath modelsOnly:modelsOnly
    try (
        job.digest=cyrusRecipeEntryWrite ticket.RecipePath data metadata image capture expected false
        if ready then (
            job.stage=CyrusAssetOwnStage()
            -- Use the exact bindings from the same authored capture.
            local graph=CyrusAssetCapture root ticket.RecipePath job.digest bindings job.stage[1] includeContext:true sharedMode:true
            if (CyrusRecipeGet graph[1] "externalRoles").count>0 do throw "A dependency has no portable adapter. No library entry was changed."
            job.packageDirectory=pathConfig.appendPath ticket.Directory "ready"
            (dotNetClass "System.IO.Directory").CreateDirectory (getFilenamePath job.packageDirectory)
            job.packageJob=cyrusAssetPackageStart job.packageDirectory ticket.RecipePath job.digest graph[1] graph[2] "User-created library content; redistribution requires permission for its source assets." 1
        ) else job.managed=store.Publish ticket ""
        CyrusSharedQueue job
    )catch(
        if job.stage!=undefined do CyrusAssetRemoveStage job.stage
        store.Discard ticket;throw()
    )
)
fn CyrusSharedCancelSave job = (
    if job.managed!=undefined then job.managed.Cancel() else cyrusAssetPackageCancel job.packageJob
    true
)
fn CyrusSharedWatchSave job = (
    if CyrusSharedProgressEditor!=undefined do try(destroyDialog CyrusSharedProgressEditor)catch()
    rollout progress "Save to shared library" width:520 height:180 (
        local operation=undefined
        label description "Saving the recipe and its reusable models and textures..." pos:[12,12] width:496 height:44
        label result "" pos:[12,62] width:496 height:64
        button closeButton "Cancel" pos:[12,136] width:496
        timer pulse interval:100 active:false
        on progress open do (operation=CyrusSharedProgressData;pulse.active=true)
        on pulse tick do (
            local state=CyrusSharedPollSave operation
            if state!="working" do (
                pulse.active=false;closeButton.text="Close"
                result.text=if state=="complete" then "Saved. Models and textures are stored once and reused by other recipes." else operation.error
                if state=="complete" and CyrusRecipeBrowser!=undefined do try(CyrusRecipeBrowser.refresh())catch(result.text+=" Refresh the library to see the new revision.")
            )
        )
        on closeButton pressed do if pulse.active then (CyrusSharedCancelSave operation;result.text="Cancelling; the previous complete library remains available.") else destroyDialog progress
        on progress close do (pulse.active=false;CyrusSharedProgressEditor=undefined)
    )
    CyrusSharedProgressData=job;CyrusSharedProgressEditor=progress
    createDialog progress style:#(#style_titlebar,#style_sysmenu,#style_toolwindow);true
)
global CyrusSharedOperationEditor,CyrusSharedOperationData,CyrusSharedWatchOperation,CyrusSharedStorageEditor,CyrusSharedStorageOpenData,CyrusSharedOpenStorage
global CyrusSharedAskName,CyrusSharedNameResult,CyrusSharedNameData
fn CyrusSharedAskName initial:"My collection" caption:"Collection:" = (
    CyrusSharedNameResult=undefined
    rollout prompt "Choose a name" width:400 height:120 (
        editText nameField "Collection:" text:"My collection" pos:[12,12] width:376
        button accept "Save" pos:[12,64] width:180
        button cancelButton "Cancel" pos:[208,64] width:180
        on accept pressed do (CyrusSharedNameResult=trimRight (trimLeft nameField.text);destroyDialog prompt)
        on cancelButton pressed do destroyDialog prompt
        on prompt open do (nameField.caption=CyrusSharedNameData[1];nameField.text=CyrusSharedNameData[2])
    )
    CyrusSharedNameData=#(caption,initial);createDialog prompt modal:true style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    CyrusSharedNameResult
)
fn CyrusSharedWatchOperation operation title:"Shared library" relocated:false = (
    if CyrusSharedOperationEditor!=undefined do throw "Wait for the current library operation window to finish."
    rollout editor "Shared library" width:560 height:240 (
        local operation=undefined,relocated=false,finished=false
        label status "Working..." pos:[12,12] width:536 height:178
        button closeButton "Cancel" pos:[12,200] width:536
        timer pulse interval:100 active:false
        on editor open do (operation=CyrusSharedOperationData[1];relocated=CyrusSharedOperationData[2];pulse.active=true)
        on pulse tick do if operation.Terminal do (
            pulse.active=false;finished=true;closeButton.text="Close"
            if operation.State=="complete" then (
                if relocated do (
                    try(CyrusSharedUseRoot operation.Result)catch(CyrusSharedLibraryInstance=undefined;format "Library relocated; registration could not be updated: %\n" (getCurrentException()))
                    if CyrusSharedStorageEditor!=undefined do destroyDialog CyrusSharedStorageEditor
                )
                status.text=if relocated then "Library relocated. Existing scenes can keep their old texture paths. New imports use the new location." else operation.Result
                if CyrusRecipeBrowser!=undefined do try(CyrusRecipeBrowser.refresh())catch(status.text+="\nRefresh the library to see the completed operation.")
            ) else status.text=if operation.State=="cancelled" then "Cancelled. The previous complete library is retained." else operation.Error
        )
        on closeButton pressed do if finished then destroyDialog editor else (operation.Cancel();status.text="Cancelling...")
        on editor close do (pulse.active=false;CyrusSharedOperationEditor=undefined)
    )
    CyrusSharedOperationData=#(operation,relocated);CyrusSharedOperationEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow);true
)
fn CyrusSharedOpenStorage = (
    local store=CyrusSharedStore()
    if CyrusSharedStorageEditor!=undefined do try(destroyDialog CyrusSharedStorageEditor)catch()
    rollout manager "Shared library storage" width:560 height:408 (
        local store=undefined
        label location "" pos:[12,12] width:536 height:50
        label explanation "Models and textures are stored once. Collections share them. Removing cards retains published data and saved-scene paths." pos:[12,68] width:536 height:54
        button report "Storage usage" pos:[12,130] width:260
        button migrate "Import older recipe folder..." pos:[284,130] width:264
        button relocate "Relocate library..." pos:[12,168] width:260
        button recover "Recover abandoned staging" pos:[284,168] width:264
        button repair "Repair assets from backup..." pos:[12,208] width:260
        button history "Restore previous catalog" pos:[284,208] width:264
        button relink "Relink current scene and save a copy..." pos:[12,246] width:536
        button consolidate "Consolidate verified migration originals..." pos:[12,284] width:536
        label status "" pos:[12,328] width:536 height:68
        on manager open do (store=CyrusSharedStorageOpenData;location.text=store.Root)
        on report pressed do try(CyrusSharedWatchOperation (store.StorageReport()))catch(status.text=getCurrentException())
        on migrate pressed do try(local folder=getSavePath caption:"Choose an older Cyrus recipe folder";if folder!=undefined do CyrusSharedWatchOperation (store.Migrate folder))catch(status.text=getCurrentException())
        on relocate pressed do try(local folder=getSavePath caption:"Choose an empty local NTFS folder (80 characters maximum)";if folder!=undefined do CyrusSharedWatchOperation (store.Relocate folder) relocated:true)catch(status.text=getCurrentException())
        on recover pressed do try(CyrusSharedWatchOperation (store.RecoverStaging()))catch(status.text=getCurrentException())
        on repair pressed do try(local archive=getOpenFileName caption:"Choose a verified shared library backup" types:"Cyrus shared library (*.cyruslib)|*.cyruslib|";if archive!=undefined do CyrusSharedWatchOperation (store.RepairFromArchive archive))catch(status.text=getCurrentException())
        on history pressed do try(if queryBox "Restore the previous catalog? Current cards will remain in history and all published data is retained." title:"Shared library" do CyrusSharedWatchOperation (store.RestorePrevious()))catch(status.text=getCurrentException())
        on relink pressed do try(CyrusSharedRelinkScene())catch(status.text=getCurrentException())
        on consolidate pressed do try(local folder=getSavePath caption:"Choose a previously migrated recipe folder on the same NTFS volume";if folder!=undefined do CyrusSharedWatchOperation (store.ConsolidateMigrated folder))catch(status.text=getCurrentException())
        on manager close do CyrusSharedStorageEditor=undefined
    )
    CyrusSharedStorageOpenData=store;CyrusSharedStorageEditor=manager
    createDialog manager style:#(#style_titlebar,#style_sysmenu,#style_toolwindow);true
)
global CyrusSharedModelImportEditor,CyrusSharedModelImportData
fn CyrusSharedImportModel entry owner:undefined root:undefined = (
    CyrusRequireAuthor()
    if owner!=undefined and (classof owner!=AminScatterObject or owner.containerProvider()!=undefined) do throw "Choose a layer with individual model sources."
    local ownerNode=undefined,ownerID=""
    if owner!=undefined do (
        if root==undefined do throw "Capture the destination Scatter setup before importing a model."
        ownerNode=CyrusRecipeOwnerNode root;CyrusRecipeCheckRoot root ownerNode
        if findItem root.layerObjects owner==0 do throw "The destination layer is no longer in this setup."
        ownerID=owner.layerID
    )
    if CyrusSharedModelImportEditor!=undefined do throw "Wait for the current model import."
    local job=cyrusAssetModelPrepare entry.Package (CyrusAssetBitmapDirectory())
    rollout editor "Import shared model" width:520 height:180 (
        local entry,owner,root,ownerNode,ownerID="",job=0L,finished=false,modelResult=undefined
        label status "Preparing the saved model and materials..." pos:[12,12] width:496 height:112
        button closeButton "Cancel" pos:[12,136] width:496
        timer pulse interval:100 active:false
        fn stageModel = (
            if theHold.Holding() do throw "Finish the current scene operation first."
            if owner!=undefined do (
                CyrusRecipeCheckRoot root ownerNode
                if findItem root.layerObjects owner==0 or owner.layerID!=ownerID or owner.containerProvider()!=undefined do throw "The destination layer changed. Import again."
            )
            local package=cyrusAssetPackagePrepared job false,graph=CyrusRecipeGet package "graph",chosen=undefined
            if (CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet package "manifest") "definition") "sha256")!=entry.Revision do throw "The model package differs from the selected revision. Refresh the library."
            for node in (CyrusRecipeGet graph "nodes") where (CyrusRecipeGet node "id")==entry.Node do chosen=node
            if chosen==undefined do throw "The saved model node is unavailable."
            CyrusRecipePut graph "nodes" #(chosen);CyrusRecipePut graph "splines" #()
            local created=#(),previousSelection=selection as array
            theHold.Begin()
            try (
                CyrusAssetStage #(graph,entry.Package,job) #() createdNodes:created
                if created.count!=1 do throw "The model import created an unexpected node count."
                modelResult=created[1];modelResult.name=uniqueName (entry.Name+" ")
                setUserProp modelResult "CyrusLibraryModelID" entry.Id
                setUserProp modelResult "CyrusLibraryModelRevision" entry.Revision
                setUserProp modelResult "CyrusLibraryStoreID" entry.StoreID
                if owner==undefined then (unhide modelResult;select modelResult) else (
                    if not owner.addModelSource modelResult do throw "The destination layer could not accept the model."
                    modelResult.renderable=false;hide modelResult
                    if previousSelection.count>0 do select previousSelection
                )
                theHold.Accept "Cyrus import shared model"
            )catch(theHold.Cancel();for node in created where isValidNode node do delete node;modelResult=undefined;throw())
            CyrusViewportRedraw()
            if root!=undefined do root.bindNativeUI()
        )
        on editor open do (entry=CyrusSharedModelImportData[1];owner=CyrusSharedModelImportData[2];job=CyrusSharedModelImportData[3];root=CyrusSharedModelImportData[4];ownerNode=CyrusSharedModelImportData[5];ownerID=CyrusSharedModelImportData[6];pulse.active=true)
        on pulse tick do try (
            local state=cyrusAssetPackagePoll job
            if state[1]=="ready" then (
                pulse.active=false;stageModel();finished=true;closeButton.text="Close";status.text="Imported. Models and textures use the shared library. Undo removes this import."
                cyrusAssetPackageRelease job;job=0L
            ) else if state[1]=="failed" or state[1]=="cancelled" do (
                pulse.active=false;finished=true;closeButton.text="Close";status.text=state[4];cyrusAssetPackageRelease job;job=0L
            )
        )catch(pulse.active=false;finished=true;closeButton.text="Close";status.text=getCurrentException();if job!=0L do (cyrusAssetPackageRelease job;job=0L))
        on closeButton pressed do destroyDialog editor
        on editor close do (pulse.active=false;if job!=0L do (cyrusAssetPackageCancel job;cyrusAssetPackageRelease job);CyrusSharedModelImportEditor=undefined)
    )
    CyrusSharedModelImportData=#(entry,owner,job,root,ownerNode,ownerID);CyrusSharedModelImportEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow);true
)
fn CyrusSharedSaveModels = (
    CyrusRequireAuthor()
    if theHold.Holding() do throw "Finish the current scene operation first."
    local models=selection as array
    if models.count<1 or models.count>10 do throw "Select between one and ten static geometry models to save."
    for node in models where superclassof node!=GeometryClass or classof node.baseObject==AminScatterObject do throw "Select only static geometry models."
    local previous=selection as array,temporary=undefined,job=undefined
    theHold.Begin()
    try (
        temporary=AminScatterObject name:"Cyrus temporary model capture"
        local root=temporary.baseObject;root.updateMode=1;root.autoRender=false
        local receiver=plane name:"Cyrus temporary model receiver" width:1 length:1 widthsegs:1 lengthsegs:1
        for node in models do (
            root.newLayer();local layer=root.layerObjects[root.layerObjects.count]
            if not layer.addModelSource node do throw "A selected model could not be captured."
            root.setLayerSurfaces layer #(receiver)
        )
        local bindings=#(),data=CyrusRecipeCapture root root.layerObjects "Saved models" bindingResult:bindings
        local metadata=CyrusRecipeObject #(#("category","Models"),#("tags",#()),#("description","Saved model sources"))
        job=CyrusSharedBeginSave root data metadata "" undefined "" "" true bindings modelsOnly:true
        -- Capture owns copied bytes before cancelling the temporary authored
        -- setup. The artist's geometry, selection and prior history survive.
        theHold.Cancel()
    )catch(theHold.Cancel();if previous.count>0 do select previous;throw())
    if previous.count>0 do select previous
    CyrusSharedWatchSave job;job
)
fn CyrusSharedJsonQuote value = ("\""+(substituteString (substituteString value "\\" "\\\\") "\"" "\\\"")+"\"")
fn CyrusSharedRelinkScene path:undefined = (
    CyrusRequireAuthor()
    if CyrusSharedRelinkEditor!=undefined do throw "Wait for the current scene relink."
    if path==undefined do path=getSaveFileName caption:"Save relinked scene as a new file" types:"3ds Max scene (*.max)|*.max|"
    if path==undefined do return false
    if doesFileExist path do throw "Choose a new scene filename. The original scene is preserved."
    local maps=getClassInstances Bitmaptexture target:rootNode
    if (try(CoronaBitmap!=undefined)catch(false)) do join maps (getClassInstances CoronaBitmap target:rootNode)
    if maps.count>4096 do throw "Scene relink exceeds 4,096 image-map instances."
    local records=#(),json="[",first=true
    for map in maps where isProperty map #filename do (
        local filename=map.filename as string
        if classof map==Bitmaptexture then (
            local image=map.bitmap
            if image==undefined do throw "Restore or repair the original shared images before relinking this scene; their current colour interpretation is unavailable."
            append records #(map,filename,image.colorSpace,image.inputGamma,image.gamma,image.width,image.height)
        ) else append records #(map,filename,map.colorSpace,map.colorSpaceStr,map.gamma,map.useLegacyGamma,map.showLegacyGamma)
        if not first do json+=",";first=false;json+=CyrusSharedJsonQuote filename
    )
    json+="]"
    local operation=(CyrusSharedStore()).PrepareRelink json
    rollout editor "Relink shared scene" width:560 height:220 (
        local operation,records,path,finished=false,applied=false
        label status "Verifying shared image bytes before changing paths..." pos:[12,12] width:536 height:150
        button closeButton "Cancel" pos:[12,176] width:536
        timer pulse interval:100 active:false
        on editor open do (operation=CyrusSharedRelinkData[1];records=CyrusSharedRelinkData[2];path=CyrusSharedRelinkData[3];pulse.active=true)
        on pulse tick do if operation.Terminal do try (
            pulse.active=false;finished=true;closeButton.text="Close"
            if operation.State!="complete" do throw (if operation.State=="cancelled" then "Scene relink cancelled." else operation.Error)
            local changes=#(),helper=dotNetClass "Cyrus.Content.SharedLibrary",pixels=0L,currentMaps=getClassInstances Bitmaptexture target:rootNode
            if (try(CoronaBitmap!=undefined)catch(false)) do join currentMaps (getClassInstances CoronaBitmap target:rootNode)
            for row in records do (
                if not isValidObj row[1] or findItem currentMaps row[1]==0 or (row[1].filename as string)!=row[2] do throw "A scene image changed while preparing relink. Retry with the current scene."
                local target=helper.RelinkTarget operation.Result row[2]
                if target!="" and toLower target!=toLower row[2] do (
                    if classof row[1]==Bitmaptexture do (
                        local image=row[1].bitmap
                        if image==undefined or image.colorSpace!=row[3] or image.inputGamma!=row[4] or abs(image.gamma-row[5])>0.000002 do throw "A bitmap interpretation changed during relink. Retry with the current scene."
                        pixels+=(row[6] as Integer64)*row[7]
                    )
                    append changes #(row,target)
                )
            )
            if changes.count==0 do throw "No shared library image paths need relinking."
            if doesFileExist path do throw "The scene-copy destination now exists. Choose a new filename; scene paths were retained."
            cyrusAssetImageAdmission pixels
            if theHold.Holding() do throw "Finish the current scene operation, then relink again."
            theHold.Begin()
            try(
                for change in changes do (
                    local row=change[1],target=change[2]
                    if classof row[1]==Bitmaptexture then (
                        local gamma=if classof row[4]==Name then "auto" else row[4]
                        local image=if row[6]<=4096 and row[7]<=4096 then cyrusAssetOpenStaticImage target row[3] gamma else cyrusAssetOpenImage target row[3] gamma
                        if abs(image.gamma-row[5])>0.000002 do (close image;throw "The relocated image changed its effective gamma; scene paths were retained.")
                        row[1].bitmap=image
                    ) else (
                        row[1].filename=target;cyrusAssetRefreshCoronaBitmap row[1]
                        if row[1].colorSpace!=row[3] or row[1].colorSpaceStr!=row[4] or row[1].gamma!=row[5] or row[1].useLegacyGamma!=row[6] or row[1].showLegacyGamma!=row[7] do throw "The Corona bitmap interpretation changed while relinking."
                    )
                )
                theHold.Accept "Cyrus relink shared scene"
            )catch(theHold.Cancel();throw())
            applied=true
            if not saveMaxFile path quiet:true do throw "The relinked scene copy could not be saved."
            status.text="Saved the relinked scene copy. Image interpretation is unchanged. Undo restores the previous paths in the open scene."
        )catch(status.text=(if applied then "Paths were relinked; saving the copy failed. Undo restores the previous paths.\n" else "Scene paths were retained.\n")+getCurrentException())
        on closeButton pressed do if finished then destroyDialog editor else operation.Cancel()
        on editor close do (pulse.active=false;CyrusSharedRelinkEditor=undefined)
    )
    CyrusSharedRelinkData=#(operation,records,path);CyrusSharedRelinkEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow);true
)
