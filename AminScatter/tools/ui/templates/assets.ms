-- Explicit portable export. This template uses only closed built-in adapters.
-- Catalog browsing never calls these functions or inspects scene dependencies.
global CyrusAssetCapture,CyrusAssetCaptureContext,CyrusAssetMaterial,CyrusAssetMap,CyrusAssetSettingsEqual,CyrusAssetCheckDefaults,CyrusAssetRoleIsSource,CyrusAssetExportEditor,CyrusAssetExportOpenData,CyrusOpenAssetExport
global CyrusRecipeObject,CyrusRecipeGet,CyrusRecipeResolve,CyrusRecipeCheckRoot,CyrusRecipeOwnerNode,CyrusRecipeSuggestBindings,CyrusRequireAuthor,CyrusNewLayerID,CyrusPresetSameValues,CyrusRecipeRestorePaint
global CyrusAssetJobs,CyrusAssetCleanupTimer,CyrusAssetCleanupTick,CyrusAssetOwnStage,CyrusAssetRemoveStage,CyrusAssetWatch
global CyrusAssetCheckController
global CyrusAssetStage,CyrusAssetImport,CyrusAssetImportPlan,CyrusAssetReview,CyrusRecipeImport,CyrusRecipePut
global CyrusOpenAssetImport,CyrusAssetImportEditor,CyrusAssetImportOpenData,CyrusRecipeValidateBindings
global CyrusAssetColorContext,CyrusAssetCheckColor,CyrusAssetBitmapDirectory,CyrusAssetRestoreMap
global CyrusAssetSharedSnapshot,CyrusAssetRoleIsReceiver,CyrusAssetRoleIsPath,CyrusAssetCaptureSpline,CyrusAssetBoundNode
global CyrusAssetShaderKind,CyrusAssetCheckRenderer,CyrusAssetCheckForest,CyrusAssetCaptureShader,CyrusAssetRestoreShader,CyrusAssetAdapterArrayLinks
global cyrusAssetOpenImage,cyrusAssetImageInfo,cyrusAssetImageEqual,cyrusAssetImageAdmission,cyrusAssetRendererModule
global cyrusAssetMeshProfile,cyrusAssetPlantMeshExport,cyrusAssetPlantSceneAdmission
global CyrusAssetCheckImageBuild
global CyrusAssetCaptureCoronaImage,CyrusAssetRestoreCoronaImage
global CyrusAssetUsesRenderer
fn CyrusAssetCheckImageBuild = (
    if cyrusAssetOpenImage==undefined or cyrusAssetImageInfo==undefined or cyrusAssetImageEqual==undefined or cyrusAssetImageAdmission==undefined or cyrusAssetRendererModule==undefined do throw "Load the complete matching plant-image native build."
    true
)
fn CyrusAssetUsesRenderer value depth:0 = (
    if value==undefined do return false
    if depth>8 do throw "Portable shader dependency depth exceeds eight."
    if (CyrusAssetShaderKind value)!=undefined do return true
    -- These are the only map slots admitted by the existing Standard adapter.
    -- Detect their finite nested adapters before any image copy, independent of
    -- role/slot order. Unsupported other slots are still rejected by its guard.
    if classof value==StandardMaterial do for key in #(#ambientMap,#diffuseMap,#opacityMap) do (
        if CyrusAssetUsesRenderer (getProperty value key) depth:(depth+1) do return true
    )
    false
)
struct CyrusAssetImportPlan (root,node,inputKey,directory,package,recipeHash,bindings,newSetup=false,variation=#new,assets=#clone,sharedSnapshot=undefined,preset=false,pathTransform=undefined,paintFootprint=undefined)
if CyrusAssetJobs==undefined do CyrusAssetJobs=#()
struct CyrusAssetCaptureContext (directory,materials=#(),materialValues=#(),maps=#(),mapValues=#(),files=#(),fileBindings=#(),bitmapPixels=0,colorContext=undefined,rendererMode=false,rendererChecked=false,plantMeshes=false,mapVisiting=#(),materialVisiting=#())
fn CyrusAssetBitmapDirectory = (pathConfig.appendPath (getDir #userScripts) "CyrusScatter\\ImportedAssets")
fn CyrusAssetColorContext inputSpace = (
    if ColorPipelineMgr.Mode!=#OCIO_Default or ColorPipelineMgr.Status!=#normal do throw "Portable bitmap maps currently require Max's normal default OCIO colour pipeline."
    local path=ColorPipelineMgr.OCIOConfigPath,info=cyrusAssetFileInfo path false
    if isProperty ColorPipelineMgr #ModifiedOCIOConfigPath do (
        local changed=ColorPipelineMgr.ModifiedOCIOConfigPath
        if changed!=undefined and changed!="" and changed!=path do throw "Modified OCIO configurations require a separate portable adapter."
    )
    local config=(dotNetClass "System.IO.File").ReadAllText path
    if findString (toLower config) "filetransform"!=undefined do throw "External OCIO transform dependencies require a separate portable adapter."
    CyrusRecipeObject #(#("mode","OCIO_Default"),#("configSHA256",info[1]),#("renderingSpace",ColorPipelineMgr.RenderingColorSpace),#("dataSpace",ColorPipelineMgr.DataColorSpace),#("inputSpace",inputSpace))
)
fn CyrusAssetCheckColor data current = (
    for key in #("mode","configSHA256","renderingSpace","dataSpace") where (CyrusRecipeGet data key)!=(CyrusRecipeGet current key) do throw "The bitmap's saved colour pipeline differs from this scene. No scene colour settings were changed."
    true
)
fn CyrusAssetSettingsEqual a b = (
    if classof a==ArrayParameter do a=a as array
    if classof b==ArrayParameter do b=b as array
    if classof a==Color and classof b==Color do return (a.r==b.r and a.g==b.g and a.b==b.b)
    if classof a==Matrix3 and classof b==Matrix3 do (
        for i=1 to 4 do for j=1 to 3 where a[i][j]!=b[i][j] do return false
        return true
    )
    CyrusPresetSameValues a b
)
fn CyrusAssetCheckDefaults value baseline supported = (
    cyrusRecipeCheckStatic value
    for key in getPropNames value do (
        -- StandardUVGen/TextureOutput expose legacy parameter blocks that are
        -- not enumerated by NumParamBlocks(). Inspect their authored properties
        -- as well; comparing the value at this frame can silently flatten keys
        -- or an expression controller even when it currently equals a default.
        CyrusAssetCheckController (getPropertyController value key)
        if findItem supported key==0 and not (CyrusAssetSettingsEqual (getProperty value key) (getProperty baseline key)) do throw ("Unsupported non-default asset setting: "+(key as string))
    )
    true
)
fn CyrusAssetCheckController control depth:0 = (
    if control==undefined do return true
    if depth>8 do throw "Portable source controller depth exceeds its bound."
    if findItem #(PRS,Position_XYZ,Euler_XYZ,Bezier_Position,Linear_Position,TCB_Position,Bezier_Rotation,Linear_Rotation,TCB_Rotation,Bezier_Scale,Linear_Scale,TCB_Scale,Bezier_Float,Linear_Float,TCB_Float) (classof control)==0 do throw ("Portable assets require supported static parameter and transform controllers. Unsupported class: "+(classof control as string)+". Prepare an explicitly named static derivative before packaging; the source is preserved.")
    if (numKeys control)>0 do throw ("Portable assets require supported static parameter and transform controllers. Keyed class: "+(classof control as string)+". Prepare an explicitly named static derivative before packaging; the source is preserved.")
    for i=1 to control.numSubs do (
        local child=(getSubAnim control i).controller
        if child!=undefined do CyrusAssetCheckController child depth:(depth+1)
    )
    true
)
-- CoronaBitmap owns a file-backed image, not an editable MAXBitMap value. Only
-- the measured modern interpretation is admitted. The shader adapter owns all
-- typed controls; this helper owns verified bytes, colour context and lifetime.
fn CyrusAssetCaptureCoronaImage context value = (
    if (CyrusAssetShaderKind value)!="corona-bitmap-v1" do throw "Unsupported Corona image class identity."
    CyrusAssetCheckImageBuild()
    if value.useLegacyGamma or value.showLegacyGamma or value.gamma!=1.0 or value.colorSpace!=4 or findItem #("Raw","Gamma 2.2 / Rec.709") value.colorSpaceStr==0 do throw "Prepare an explicitly authored modern OCIO CoronaBitmap before packaging; the source was preserved."
    local path=value.filename,info=cyrusAssetImageInfo path,pixels=(info[3] as Integer64)*info[4]
    if context.bitmapPixels+pixels>536870912L do throw "Portable bitmap map instances exceed the 512-Mpixel plant profile."
    -- Existing source/staged allocations are reflected in current free memory.
    -- Admit this next image before opening either a BMM or plugin-side copy.
    cyrusAssetImageAdmission pixels
    local colorData=CyrusAssetColorContext value.colorSpaceStr
    if context.colorContext==undefined then context.colorContext=deepCopy colorData else CyrusAssetCheckColor colorData context.colorContext
    local suffix=toLower(getFilenameType path),fileID="corona-bitmap-file-"+((context.maps.count+1) as string)
    local staged=pathConfig.appendPath context.directory (fileID+suffix),opened=undefined
    (dotNetClass "System.IO.File").Copy path staged false
    try (
        if not (CyrusPresetSameValues info (cyrusAssetImageInfo staged)) do throw "Corona image bytes changed during capture."
        opened=cyrusAssetOpenImage staged value.colorSpaceStr 1.0
        if opened==undefined or opened.numframes!=1 or opened.aspect!=1.0 or opened.width!=info[3] or opened.height!=info[4] or opened.colorSpaceStatus!=#normal or opened.colorSpace!=value.colorSpaceStr do throw "The copied Corona image has an unresolved or unsupported colour interpretation."
        close opened;opened=undefined
    )catch(if opened!=undefined do close opened;throw())
    context.bitmapPixels+=pixels
    append context.files (CyrusRecipeObject #(#("id",fileID),#("kind","bitmap"),#("sha256",info[1]),#("bytes",info[2]),#("suffix",substring suffix 2 (suffix.count-1))))
    append context.fileBindings #(fileID,staged)
    #(CyrusRecipeObject #(#("file",fileID),#("size",#(info[3],info[4])),#("color",colorData)),staged)
)
fn CyrusAssetMap context value = (
    if value==undefined do return undefined
    local found=findItem context.mapValues value
    if found>0 do return (CyrusRecipeGet context.maps[found] "id")
    if classof value!=Bitmaptexture do (
        local kind=CyrusAssetShaderKind value
        if kind==undefined do throw ("Unsupported portable map: "+(classof value as string)+". The source is preserved.")
        return CyrusAssetCaptureShader context value kind
    )
    local mapLimit=if context.rendererMode then 256 else 128
    if classof value!=Bitmaptexture or context.maps.count+context.mapVisiting.count>=mapLimit do throw "Portable maps exceed their finite profile count or use an unsupported class."
    if context.mapVisiting.count+context.materialVisiting.count>=8 do throw "Portable shader dependency depth exceeds eight."
    local defaults=bitmaptexture(),coords=value.coords,output=value.output
    if classof coords!=classof defaults.coords or classof output!=classof defaults.output do throw "This bitmap uses an unsupported coordinate/output adapter."
    CyrusAssetCheckDefaults value defaults #(#name,#filename,#bitmap,#coords,#output,#filtering,#monoOutput,#rgbOutput,#alphaSource,#preMultAlpha)
    local uvFields=#(#mapChannel,#U_Offset,#V_Offset,#U_Tiling,#V_Tiling,#W_Angle,#U_Mirror,#V_Mirror,#U_Tile,#V_Tile,#blur,#Blur_Offset)
    for key in uvFields do setProperty defaults.coords key (getProperty coords key)
    -- UVTransform is derived cached renderer state; a detached UVGen can still
    -- expose its identity cache after setters. Compare the authored parameters.
    CyrusAssetCheckDefaults coords defaults.coords #(#UVTransform)
    CyrusAssetCheckDefaults output defaults.output #(#invert,#clamp,#alphaFromRGB,#RGB_Level,#RGB_Offset,#Output_Amount)
    cyrusAssetDefaultCurves output defaults.output
    local path=value.filename,info=(if context.rendererMode then cyrusAssetImageInfo path else cyrusAssetFileInfo path true),pixels=info[3]*info[4]
    local pixelLimit=if context.rendererMode then 536870912 else 16777216
    if context.bitmapPixels+pixels>pixelLimit do throw "Portable bitmap map instances exceed their profile's aggregate pixel bound."
    if context.rendererMode do cyrusAssetImageAdmission pixels
    context.bitmapPixels+=pixels
    local source=value.bitmap
    if source==undefined or source.numframes!=1 or source.width!=info[3] or source.height!=info[4] or source.aspect!=1.0 do throw "Portable bitmap requires a current single-frame image with square pixels."
    if source.colorSpaceStatus!=#normal do throw "This bitmap's input colour space is unresolved."
    if context.colorContext==undefined do context.colorContext=CyrusAssetColorContext source.colorSpace
    local colorData=deepCopy context.colorContext;CyrusRecipePut colorData "inputSpace" source.colorSpace
    local inputGamma=source.inputGamma
    if context.rendererMode do (
        if classof inputGamma==Name then (
            if inputGamma!=#auto do throw "This bitmap input-gamma mode has no portable renderer adapter."
            CyrusRecipePut colorData "inputGamma" "auto"
        )else (
            if not (isKindOf inputGamma Number) do throw "This bitmap input-gamma value has no portable renderer adapter."
            CyrusRecipePut colorData "inputGamma" (inputGamma as double)
        )
        CyrusRecipePut colorData "effectiveGamma" (source.gamma as double)
    )
    local suffix=if context.rendererMode then toLower (getFilenameType path) else ".png"
    local id="bitmap-"+((context.maps.count+1) as string),fileID="bitmap-file-"+((context.maps.count+1) as string),staged=pathConfig.appendPath context.directory (fileID+suffix),opened=undefined
    (dotNetClass "System.IO.File").Copy path staged false
    try (
        local copied=if context.rendererMode then cyrusAssetImageInfo staged else cyrusAssetFileInfo staged true
        if not (CyrusPresetSameValues info copied) do throw "Bitmap changed during capture."
        opened=if context.rendererMode then cyrusAssetOpenImage staged source.colorSpace (CyrusRecipeGet colorData "inputGamma") else openBitmap staged colorSpace:source.colorSpace
        if opened==undefined or opened.colorSpaceStatus!=#normal or opened.colorSpace!=source.colorSpace do throw "The copied bitmap could not retain its input colour interpretation."
        if context.rendererMode and (abs (opened.gamma-source.gamma)>0.000002 or opened.inputGamma!=source.inputGamma) do throw "The copied bitmap changed its saved gamma interpretation."
        if not (if context.rendererMode then cyrusAssetImageEqual source opened else cyrusAssetBitmapEqual source opened) do throw "The in-memory bitmap differs from its file or colour interpretation. Save it before exporting."
        close opened;opened=undefined
    )catch(if opened!=undefined do close opened;throw())
    local sampler=CyrusRecipeObject #(#("filtering",value.filtering),#("monoOutput",value.monoOutput),#("rgbOutput",value.rgbOutput),#("alphaSource",value.alphaSource),#("preMultAlpha",value.preMultAlpha),#("uMirror",coords.U_Mirror),#("vMirror",coords.V_Mirror),#("uTile",coords.U_Tile),#("vTile",coords.V_Tile),#("blur",coords.blur),#("blurOffset",coords.Blur_Offset))
    local outputData=CyrusRecipeObject #(#("invert",output.invert),#("clamp",output.clamp),#("alphaFromRGB",output.alphaFromRGB),#("rgbLevel",output.RGB_Level),#("rgbOffset",output.RGB_Offset),#("outputAmount",output.Output_Amount))
    local data=CyrusRecipeObject #(#("id",id),#("kind","bitmap"),#("name",value.name),#("file",fileID),#("channel",coords.mapChannel),#("uv",#(coords.U_Offset,coords.V_Offset,coords.U_Tiling,coords.V_Tiling,coords.W_Angle)),#("size",#(info[3],info[4])),#("color",colorData),#("sampler",sampler),#("output",outputData),#("roles",#()))
    append context.maps data;append context.mapValues value
    append context.files (CyrusRecipeObject #(#("id",fileID),#("kind","bitmap"),#("sha256",info[1]),#("bytes",info[2]),#("suffix",substring suffix 2 (suffix.count-1))))
    append context.fileBindings #(fileID,staged);id
)
fn CyrusAssetMaterial context value = (
    if value==undefined do return undefined
    local found=findItem context.materialValues value
    if found>0 do return (CyrusRecipeGet context.materials[found] "id")
    if context.materials.count+context.materialVisiting.count>=128 do throw "Package material limit is 128."
    if context.mapVisiting.count+context.materialVisiting.count>=8 do throw "Portable shader dependency depth exceeds eight."
    if classof value!=StandardMaterial do (
        local kind=CyrusAssetShaderKind value
        if kind==undefined do throw ("Unsupported portable material: "+(classof value as string)+". The source is preserved.")
        return CyrusAssetCaptureShader context value kind
    )
    if classof value!=StandardMaterial do throw ("Unsupported portable material: "+(classof value as string)+". The source is preserved.")
    local defaults=standardMaterial(),supported=#(#name,#diffuse,#ambient,#specular,#specularLevel,#glossiness,#soften,#selfIllumAmount,#selfIllumColor,#useSelfIllumColor,#adLock,#dsLock,#adTextureLock,#opacity,#twoSided)
    defaults.adTextureLock=false
    local slots=#()
    for slot in #("ambient","diffuse","opacity") do (
        local key=(slot+"Map") as name,amount=(slot+"MapAmount") as name,enabled=(slot+"MapEnable") as name
        setProperty defaults key (getProperty value key);setProperty defaults amount (getProperty value amount);setProperty defaults enabled (getProperty value enabled)
        append slots (CyrusRecipeObject #(#("slot",slot),#("map",CyrusAssetMap context (getProperty value key)),#("amount",getProperty value amount),#("enabled",getProperty value enabled)))
    )
    -- Compare aliases against the material our closed adapter actually restores.
    -- Older hosts also enumerate Diffuse_Color/Specular_Level; these are derived
    -- from the captured canonical properties, not extra unsupported settings.
    defaults.adLock=false;defaults.dsLock=false
    for key in #(#diffuse,#ambient,#specular,#specularLevel,#glossiness,#soften,#selfIllumAmount,#selfIllumColor,#useSelfIllumColor,#opacity,#twoSided) do setProperty defaults key (getProperty value key)
    defaults.adLock=value.adLock;defaults.dsLock=value.dsLock;defaults.adTextureLock=value.adTextureLock
    CyrusAssetCheckDefaults value defaults supported
    fn colorData colorValue = #(colorValue.r as double,colorValue.g as double,colorValue.b as double)
    local id="material-"+((context.materials.count+1) as string)
    local data=CyrusRecipeObject #(#("id",id),#("kind","standard-blinn"),#("name",value.name),#("diffuse",colorData value.diffuse),#("ambient",colorData value.ambient),#("specular",colorData value.specular),#("specularLevel",value.specularLevel),#("glossiness",value.glossiness),#("soften",value.soften),#("selfIllumAmount",value.selfIllumAmount),#("selfIllumColor",colorData value.selfIllumColor),#("useSelfIllumColor",value.useSelfIllumColor),#("ambientDiffuseLock",value.adLock),#("diffuseSpecularLock",value.dsLock),#("textureLock",value.adTextureLock),#("opacity",value.opacity),#("twoSided",value.twoSided),#("maps",slots))
    append context.materialValues value;append context.materials data;id
)
fn CyrusAssetRoleIsSource role = (
    if (CyrusRecipeGet role "kind")!="node" or (CyrusRecipeGet role "requirements")!=undefined do return false
    local purposes=CyrusRecipeGet role "purposes"
    if purposes.count==0 do return false
    for purpose in purposes where findItem #("sources","procSourceNodes") purpose==0 do return false
    true
)
fn CyrusAssetRoleIsReceiver role = (
    if (CyrusRecipeGet role "kind")!="node" do return false
    local purposes=CyrusRecipeGet role "purposes"
    for purpose in purposes where findItem #("surface","surfaceNodes","procReceiverNodes","areaTarget","paintReceiver") purpose==0 do return false
    purposes.count>0
)
fn CyrusAssetRoleIsPath role = (
    if (CyrusRecipeGet role "kind")!="node" do return false
    local purposes=CyrusRecipeGet role "purposes"
    for purpose in purposes where findItem #("areaNodes","patternLines","patternPaths") purpose==0 do return false
    purposes.count>0
)
fn CyrusAssetCaptureSpline source roleID metres index = (
    if not isValidNode source or superclassof source!=Shape or source.modifiers.count>0 or source.parent!=undefined or source.children.count>0 do throw "Ready presets require independent static spline paths."
    local controllerError=undefined
    try(CyrusAssetCheckController source.transform.controller)catch(controllerError=getCurrentException())
    if controllerError!=undefined do throw ("Source "+source.name+": "+controllerError)
    cyrusRecipeCheckStatic source.baseObject
    local curves=cyrusAssetSplineSnapshot source metres,values=#(),transform=source.objectTransform
    for i=1 to 4 do for j=1 to 3 do append values (transform[i][j]/(if i==4 then metres else 1.0))
    CyrusRecipeObject #(#("id","spline-"+(index as string)),#("name",source.name),#("transform",values),#("wireColor",#(source.wireColor.r as double,source.wireColor.g as double,source.wireColor.b as double)),#("roles",#(roleID)),#("curves",curves))
)
fn CyrusAssetCapture root recipePath digest bindings directory includeContext:false = (
    CyrusRequireAuthor();CyrusRecipeCheckRoot root (CyrusRecipeOwnerNode root)
    if cyrusAssetPackageVersion==undefined or cyrusAssetPackageVersion()!=3 do throw "Load the complete matching package-capable Cyrus build."
    if (cyrusRecipeInfo recipePath)[11]!=digest do throw "Recipe changed. Review it again before export."
    local document=if includeContext then cyrusRecipeRead recipePath else cyrusRecipeReadMetadata recipePath
    local roles=CyrusRecipeGet document "roles",context=CyrusAssetCaptureContext directory:directory,nodes=#(),nodeValues=#(),meshes=#(),splines=#(),external=#(),metres=(units.decodeValue "1m") as double
    if not (doesDirectoryExist directory) do throw "Owned asset staging folder is missing."
    -- Choose the finite profile before copying any bitmap, independent of role
    -- order. A Standard/Bitmap-only graph retains the exact legacy admission.
    for role in roles do (
        local value=CyrusRecipeResolve bindings (CyrusRecipeGet role "id")
        if (CyrusRecipeGet role "kind")=="node" and isValidNode value do value=value.material
        if CyrusAssetUsesRenderer value do context.rendererMode=true
    )
    if context.rendererMode do (CyrusAssetCheckImageBuild();CyrusAssetCheckRenderer();cyrusAssetImageAdmission 0L;context.rendererChecked=true)
    if context.rendererMode do (
        if cyrusAssetMeshProfile==undefined or cyrusAssetPlantMeshExport==undefined do throw "Load the complete matching plant-mesh native build."
        -- Inspect the selected cohort before copying images. Any later evaluated
        -- terrain change is inspected again by the actual exporter.
        local inspected=#()
        for role in roles where (CyrusAssetRoleIsSource role) or (includeContext and (CyrusAssetRoleIsReceiver role)) do (
            local source=CyrusRecipeResolve bindings (CyrusRecipeGet role "id")
            if isValidNode source and findItem inspected source==0 do (
                if (cyrusAssetMeshProfile source)[1]=="plant" do context.plantMeshes=true
                append inspected source
            )
        )
    )
    for role in roles do (
        local roleID=CyrusRecipeGet role "id"
        if (CyrusRecipeGet role "kind")=="texture" then (
            local value=CyrusRecipeResolve bindings roleID,id=CyrusAssetMap context value
            if id==undefined do throw "Bind every texture role before portable export."
            for row in context.maps where (CyrusRecipeGet row "id")==id do (
                if (CyrusRecipeGet row "kind")!="bitmap" do throw "Renderer shader maps are not qualified as density-map roles."
                append (CyrusRecipeGet row "roles") roleID
            )
        ) else if includeContext and (CyrusAssetRoleIsPath role) then append splines (CyrusAssetCaptureSpline (CyrusRecipeResolve bindings roleID) roleID metres (splines.count+1))
        else if not (CyrusAssetRoleIsSource role) and not (includeContext and (CyrusAssetRoleIsReceiver role)) then append external roleID
        else (
            local source=CyrusRecipeResolve bindings roleID
            if not isValidNode source do throw ("Bind the source to package: "+CyrusRecipeGet role "name")
            local index=findItem nodeValues source
            if index>0 then append (CyrusRecipeGet nodes[index] "roles") roleID
            else (
                if nodes.count>=128 do throw "Package source limit is 128."
                if isGroupHead source or isGroupMember source or source.children.count>0 or source.parent!=undefined do throw "Portable sources must be independent objects; groups and hierarchies need their own adapter."
                if source.modifiers.count>0 and not (includeContext and (CyrusAssetRoleIsReceiver role)) do throw "Portable sources currently require static geometry without modifiers. The source is preserved."
                local controllerError=undefined
                try(CyrusAssetCheckController source.transform.controller)catch(controllerError=getCurrentException())
                if controllerError!=undefined do throw ("Source "+source.name+": "+controllerError)
                cyrusRecipeCheckStatic source.baseObject
                if includeContext and (CyrusAssetRoleIsReceiver role) do (
                    -- Terrain is an evaluated snapshot, including produced mesh
                    -- channels, rather than a serialized modifier stack.
                    for record in (CyrusRecipeGet document "layers") do (
                        local paint=CyrusRecipeGet record "paint"
                        if paint!=undefined and (CyrusRecipeGet paint "receiverRole")==roleID do CyrusRecipeRestorePaint paint source document
                        for area in (CyrusRecipeGet record "areas") do (
                            local data=CyrusRecipeGet area "paint"
                            if data!=undefined and (CyrusRecipeGet data "receiverRole")==roleID do CyrusRecipeRestorePaint data source document
                        )
                    )
                    if findItem (CyrusRecipeGet role "purposes") "paintReceiver">0 and source.objectTransform!=source.transform do throw "Ready presets with Paint require receiver object offsets baked before painting. The original Paint and settings recipe are preserved."
                )
                if findItem #(Box,Sphere,Cylinder,Cone,Pyramid,GeoSphere,Editable_Mesh,Editable_Poly,Plane) (classof source.baseObject)==0 do throw "This geometry class has no qualified portable adapter."
                local materialID=CyrusAssetMaterial context source.material,number=(nodes.count+1) as string,meshID="mesh-"+number,fileID="mesh-file-"+number,path=pathConfig.appendPath directory (fileID+".cmesh")
                local meshPlan=if context.rendererMode then cyrusAssetMeshProfile source else undefined
                local needsPlant=if context.rendererMode then meshPlan[1]=="plant" else false
                if needsPlant do (
                    if cyrusAssetPlantSceneAdmission==undefined do throw "Load the complete matching plant-mesh native build."
                    cyrusAssetPlantSceneAdmission (meshPlan[2] as Integer64) 0L
                    context.plantMeshes=true
                )
                local info=if needsPlant then cyrusAssetPlantMeshExport source path metres else cyrusAssetMeshExport source path metres
                local transform=source.transform,values=#()
                for i=1 to 4 do for j=1 to 3 do append values (transform[i][j]/(if i==4 then metres else 1.0))
                append context.files (CyrusRecipeObject #(#("id",fileID),#("kind","mesh"),#("sha256",info[1]),#("bytes",info[2]),#("suffix","cmesh")))
                append context.fileBindings #(fileID,path)
                append meshes (CyrusRecipeObject #(#("id",meshID),#("file",fileID)))
                append nodes (CyrusRecipeObject #(#("id","node-"+number),#("name",source.name),#("mesh",meshID),#("material",materialID),#("transform",values),#("wireColor",#(source.wireColor.r as double,source.wireColor.g as double,source.wireColor.b as double)),#("roles",#(roleID))))
                append nodeValues source
            )
        )
    )
    if (cyrusRecipeInfo recipePath)[11]!=digest do throw "Recipe changed during asset capture. Export was cancelled."
    local graph=CyrusRecipeObject #(#("format","cyrus.library-assets"),#("version",1),#("nodes",nodes),#("meshes",meshes),#("materials",context.materials),#("maps",context.maps),#("files",context.files),#("externalRoles",external))
    if includeContext do (CyrusRecipePut graph "version" 2;CyrusRecipePut graph "splines" splines)
    if context.rendererMode do (
        CyrusRecipePut graph "version" 3;CyrusRecipePut graph "splines" splines
        CyrusRecipePut graph "rendererProfile" (CyrusAssetAdapterProfile())
        CyrusRecipePut graph "resourceProfile" (if context.plantMeshes or context.maps.count>128 then "plant-assets-v1" else "plant-images-v1")
    )
    #(graph,context.fileBindings)
)

fn CyrusAssetOwnStage = (
    local parent=pathConfig.appendPath (getDir #plugcfg) "CyrusScatter\\Export-Staging",token=CyrusNewLayerID(),folder=pathConfig.appendPath parent token
    if doesDirectoryExist folder do throw "Owned export staging path already exists. Retry export."
    (dotNetClass "System.IO.Directory").CreateDirectory folder
    #(folder,token)
)
fn CyrusAssetRemoveStage stage = (
    local paths=dotNetClass "System.IO.Path",files=dotNetClass "System.IO.Directory"
    local parent=paths.GetFullPath (pathConfig.appendPath (getDir #plugcfg) "CyrusScatter\\Export-Staging"),actual=paths.GetFullPath stage[1],expected=paths.GetFullPath (pathConfig.appendPath parent stage[2])
    if actual!=expected or (paths.GetDirectoryName actual)!=parent or (paths.GetFileName actual)!=stage[2] do throw "Owned export staging identity differs. Cleanup stopped."
    if files.Exists actual do files.Delete actual true
    true
)
fn CyrusAssetCleanupTick sender args = (
    for i=CyrusAssetJobs.count to 1 by -1 do (
        local row=CyrusAssetJobs[i],terminal=false
        try(terminal=(cyrusAssetPackagePoll row[1])[1]!="exporting")catch(terminal=true)
        if terminal do (
            try(CyrusAssetRemoveStage row[2])catch(format "Cyrus export staging cleanup: %\n" (getCurrentException()))
            deleteItem CyrusAssetJobs i
        )
    )
    if CyrusAssetJobs.count==0 and CyrusAssetCleanupTimer!=undefined do CyrusAssetCleanupTimer.Stop()
)
fn CyrusAssetWatch token stage = (
    append CyrusAssetJobs #(token,stage)
    if CyrusAssetCleanupTimer==undefined do (
        CyrusAssetCleanupTimer=dotNetObject "System.Windows.Forms.Timer"
        CyrusAssetCleanupTimer.Interval=250
        dotNet.addEventHandler CyrusAssetCleanupTimer "Tick" CyrusAssetCleanupTick
    )
    CyrusAssetCleanupTimer.Start();true
)
fn CyrusOpenAssetExport root path digest = (
    CyrusRequireAuthor();local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if cyrusAssetPackageVersion==undefined or cyrusAssetPackageVersion()!=3 do throw "Load the complete matching package-capable Cyrus build."
    if (cyrusRecipeInfo path)[11]!=digest do throw "Recipe changed. Refresh before export."
    local document=cyrusRecipeReadMetadata path
    if CyrusAssetExportEditor!=undefined do try(destroyDialog CyrusAssetExportEditor)catch()
    rollout editor "Export portable recipe" width:600 height:630 (
        local root,node,path,digest,document,roles=#(),bindings=#(),destination="",job=0L,stage=undefined
        label summary "" pos:[12,12] width:576 height:62
        button matchNames "Match unique scene names" pos:[12,82] width:282
        pickbutton bindSource "Bind selected source..." pos:[306,82] width:282 autoDisplay:false
        mapbutton bindTexture "Bind selected map..." pos:[306,82] width:282 visible:false
        listbox sourceRoles "Sources and maps to package" items:#() pos:[12,118] width:576 height:9
        label retained "Terrain, Paint receivers, splines and external layers remain explicit roles. Complete saved Paint is included." pos:[12,278] width:576 height:44
        edittext folderName "New folder:" text:"Planting package" pos:[12,334] width:576
        button chooseParent "Choose destination folder..." pos:[12,368] width:576
        label folderLabel "Choose an existing parent folder. Export creates a new folder inside it." pos:[12,402] width:576 height:44
        checkbox permitted "I have permission to redistribute these models and materials." pos:[12,458] width:576 checked:false
        button exportPackage "Export package" pos:[12,498] width:282
        button cancelButton "Close" pos:[306,498] width:282
        label status "Static meshes, supported Standard/Blinn materials and PNG maps. Original scene objects remain unchanged." pos:[12,538] width:576 height:80
        timer progress interval:250 active:false
        fn showBindings = (
            local selected=sourceRoles.selection
            sourceRoles.items=for i=1 to roles.count collect ((CyrusRecipeGet roles[i] "name")+" - "+(if bindings[i][2]==undefined then "UNBOUND" else bindings[i][2].name))
            sourceRoles.selection=if selected>0 and selected<=roles.count then selected else if roles.count>0 then 1 else 0
            local i=sourceRoles.selection,isMap=i>0 and (CyrusRecipeGet roles[i] "kind")=="texture"
            bindTexture.visible=isMap;bindSource.visible=not isMap
        )
        fn setBusy busy = (
            matchNames.enabled=not busy;bindSource.enabled=not busy;bindTexture.enabled=not busy;sourceRoles.enabled=not busy;folderName.enabled=not busy;chooseParent.enabled=not busy;permitted.enabled=not busy;exportPackage.enabled=not busy
            cancelButton.text=if busy then "Cancel export" else "Close"
        )
        fn startExport = (
            CyrusRecipeCheckRoot root node
            if not permitted.checked do throw "Confirm redistribution permission before creating the package."
            if destination=="" do throw "Choose a destination parent folder."
            local name=trimRight (trimLeft folderName.text),paths=dotNetClass "System.IO.Path"
            if name=="" or name=="." or name==".." or (paths.GetFileName name)!=name or findString name ":"!=undefined do throw "Enter one new folder name without path separators."
            local output=pathConfig.appendPath destination name
            if doesDirectoryExist output or doesFileExist output do throw "That destination exists. Choose a new package folder."
            stage=CyrusAssetOwnStage()
            try (
                status.text="Capturing supported source meshes..."
                local captured=CyrusAssetCapture root path digest bindings stage[1]
                job=cyrusAssetPackageStart output path digest captured[1] captured[2] "Exporter confirms permission to redistribute the packaged models and materials." 1
                CyrusAssetWatch job stage;stage=undefined;setBusy true;progress.active=true
            )catch(if stage!=undefined do try(CyrusAssetRemoveStage stage)catch();stage=undefined;throw())
            true
        )
        on editor open do (
            root=CyrusAssetExportOpenData[1];node=CyrusAssetExportOpenData[2];path=CyrusAssetExportOpenData[3];digest=CyrusAssetExportOpenData[4];document=CyrusAssetExportOpenData[5]
            for role in (CyrusRecipeGet document "roles") where (CyrusAssetRoleIsSource role) or (CyrusRecipeGet role "kind")=="texture" do (append roles role;append bindings #((CyrusRecipeGet role "id"),undefined))
            summary.text=(CyrusRecipeGet document "name")+"\nSource geometry is captured as static meshes with its pivot, transform, mapping and smoothing. Max scenes or scripts are not embedded."
            showBindings()
        )
        on matchNames pressed do try(
            CyrusRecipeCheckRoot root node;local candidates=CyrusRecipeSuggestBindings root document
            for pair in bindings do pair[2]=CyrusRecipeResolve candidates pair[1]
            showBindings()
        )catch(status.text=getCurrentException())
        on bindSource picked value do (local i=sourceRoles.selection;if i>0 and i<=bindings.count do (bindings[i][2]=value;showBindings()))
        on bindTexture picked value do (local i=sourceRoles.selection;if i>0 and i<=bindings.count do (bindings[i][2]=value;showBindings()))
        on sourceRoles selected i do showBindings()
        on chooseParent pressed do (local selected=getSavePath caption:"Portable package destination";if selected!=undefined do (destination=selected;folderLabel.text=destination))
        on exportPackage pressed do try(startExport())catch(status.text=getCurrentException())
        on progress tick do try(
            local result=cyrusAssetPackagePoll job
            status.text=result[1]+": "+result[2]+(if result[4]!="" then "\n"+result[4] else if result[5]!="" then "\n"+result[5] else "")
            if result[1]!="exporting" do (progress.active=false;setBusy false)
        )catch(progress.active=false;setBusy false;status.text=getCurrentException())
        on cancelButton pressed do (if progress.active then (cyrusAssetPackageCancel job;status.text="Cancelling at the next file checkpoint...") else destroyDialog editor)
        on editor close do (
            if progress.active do try(cyrusAssetPackageCancel job)catch()
            progress.active=false;CyrusAssetExportEditor=undefined
        )
    )
    CyrusAssetExportOpenData=#(root,node,path,digest,document);CyrusAssetExportEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)

fn CyrusAssetSharedSnapshot root directory digest bindings = (
    local stage=CyrusAssetOwnStage(),snapshot=undefined
    try (
        -- Explicit review/commit only: never scan the scene during browsing.
        -- Capture the chosen assets, not a name-based guess of package ownership.
        snapshot=(CyrusAssetCapture root (pathConfig.appendPath directory "entry.csrecipe.json") digest bindings stage[1])[1]
        CyrusAssetRemoveStage stage;snapshot
    )catch(try(CyrusAssetRemoveStage stage)catch();throw())
)
fn CyrusAssetReview root directory bindings newSetup:false variation:#new verifiedPackage:undefined assets:#clone = (
    CyrusRequireAuthor();local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if cyrusAssetMeshCreate==undefined do throw "Load the complete portable-import build."
    local package=if verifiedPackage==undefined then cyrusAssetPackageRead directory else verifiedPackage
    local graph=CyrusRecipeGet package "graph",external=CyrusRecipeGet graph "externalRoles",recipe=CyrusRecipeGet package "recipe"
    if (CyrusRecipeGet graph "maps").count>0 do (
        local currentColor=CyrusAssetColorContext "raw"
        for data in (CyrusRecipeGet graph "maps") do CyrusAssetCheckColor (CyrusRecipeGet data "color") currentColor
    )
    if findItem #(#clone,#share) assets==0 do throw "Choose independent packaged assets or explicitly bound scene assets. XRefs require a separate adapter."
    local required=if assets==#share then (for role in (CyrusRecipeGet recipe "roles") collect CyrusRecipeGet role "id") else external
    if bindings.count!=required.count do throw "Bind every requested dependency exactly once."
    local seen=#()
    for pair in bindings do (
        if findItem required pair[1]==0 or findItem seen pair[1]>0 or pair[2]==undefined do throw "Missing, duplicate or unexpected package binding."
        append seen pair[1]
    )
    local externalRoleData=for role in (CyrusRecipeGet recipe "roles") where findItem required (CyrusRecipeGet role "id")>0 collect role
    CyrusRecipeValidateBindings (if newSetup then undefined else root) (CyrusRecipeObject #(#("roles",externalRoleData))) bindings
    if findItem #(#same,#new) variation==0 do throw "Choose Saved or New variation."
    if (if newSetup then 0 else root.layerObjects.count)+(CyrusRecipeGet recipe "layers").count>10 do throw "Import exceeds the ten-population capacity."
    local manifest=CyrusRecipeGet package "manifest",descriptor=CyrusRecipeGet manifest "recipe",digest=CyrusRecipeGet descriptor "sha256"
    local snapshot=if assets==#share then CyrusAssetSharedSnapshot root directory digest bindings else undefined
    CyrusAssetImportPlan root:root node:node inputKey:(root.procInputKey()) directory:directory package:package recipeHash:digest bindings:(for pair in bindings collect #(pair[1],pair[2])) newSetup:newSetup variation:variation assets:assets sharedSnapshot:snapshot
)
fn CyrusAssetRestoreMap data fileData token currentColor plantImages:false = (
    if token==0 do throw "Bitmap import requires background package preparation. Use Load package."
    local colorData=CyrusRecipeGet data "color"
    CyrusAssetCheckColor colorData currentColor
    local path=cyrusAssetPreparedBitmap token (CyrusRecipeGet data "file"),info=(if plantImages then cyrusAssetImageInfo path else cyrusAssetFileInfo path true),dimensions=CyrusRecipeGet data "size"
    if info[1]!=(CyrusRecipeGet fileData "sha256") or info[2]!=(CyrusRecipeGet fileData "bytes") or info[3]!=dimensions[1] or info[4]!=dimensions[2] do throw "Owned bitmap content changed after preparation."
    local opened=undefined,result=undefined
    try (
        local savedGamma=if plantImages then CyrusRecipeGet colorData "inputGamma" else undefined
        opened=if plantImages then cyrusAssetOpenImage path (CyrusRecipeGet colorData "inputSpace") savedGamma else openBitmap path colorSpace:(CyrusRecipeGet colorData "inputSpace")
        if opened==undefined or opened.colorSpaceStatus!=#normal or opened.colorSpace!=(CyrusRecipeGet colorData "inputSpace") or opened.width!=dimensions[1] or opened.height!=dimensions[2] or opened.numframes!=1 do throw "The bitmap could not be restored in its saved colour space."
        if plantImages and abs (opened.gamma-(CyrusRecipeGet colorData "effectiveGamma"))>0.000002 do throw "The bitmap's resolved gamma differs from its saved interpretation."
        result=bitmaptexture name:(CyrusRecipeGet data "name") bitmap:opened
        local uv=CyrusRecipeGet data "uv",sampler=CyrusRecipeGet data "sampler",output=CyrusRecipeGet data "output"
        result.coords.mapChannel=CyrusRecipeGet data "channel"
        for i=1 to 5 do setProperty result.coords #(#U_Offset,#V_Offset,#U_Tiling,#V_Tiling,#W_Angle)[i] uv[i]
        for pair in #(#("filtering",#filtering),#("monoOutput",#monoOutput),#("rgbOutput",#rgbOutput),#("alphaSource",#alphaSource),#("preMultAlpha",#preMultAlpha)) do setProperty result pair[2] (CyrusRecipeGet sampler pair[1])
        for pair in #(#("uMirror",#U_Mirror),#("vMirror",#V_Mirror),#("uTile",#U_Tile),#("vTile",#V_Tile),#("blur",#blur),#("blurOffset",#Blur_Offset)) do setProperty result.coords pair[2] (CyrusRecipeGet sampler pair[1])
        for pair in #(#("invert",#invert),#("clamp",#clamp),#("alphaFromRGB",#alphaFromRGB),#("rgbLevel",#RGB_Level),#("rgbOffset",#RGB_Offset),#("outputAmount",#Output_Amount)) do setProperty result.output pair[2] (CyrusRecipeGet output pair[1])
        opened=undefined;result
    )catch(if opened!=undefined do close opened;throw())
)
fn CyrusAssetRestoreCoronaImage data fileData token currentColor = (
    if token==0 or fileData==undefined do throw "Corona image import requires a prepared, declared bitmap resource."
    local colorData=CyrusRecipeGet data "color",dimensions=CyrusRecipeGet data "size",properties=CyrusRecipeGet data "properties"
    CyrusAssetCheckColor colorData currentColor
    if (CyrusRecipeGet colorData "inputSpace")!=(CyrusRecipeGet properties "colorSpaceStr") do throw "Corona image colour space disagrees with its shader controls."
    cyrusAssetImageAdmission ((dimensions[1] as Integer64)*dimensions[2])
    local path=cyrusAssetPreparedBitmap token (CyrusRecipeGet data "file"),info=cyrusAssetImageInfo path
    if info[1]!=(CyrusRecipeGet fileData "sha256") or info[2]!=(CyrusRecipeGet fileData "bytes") or info[3]!=dimensions[1] or info[4]!=dimensions[2] do throw "Owned Corona image content changed after preparation."
    CyrusAssetRestoreShader data #() #() imagePath:path
)
fn CyrusAssetBoundNode data bindings = (
    local roles=CyrusRecipeGet data "roles",found=0,node=undefined
    for role in roles do for pair in bindings where pair[1]==role do (
        if pair[2]==undefined or (node!=undefined and pair[2]!=node) do throw "Packaged context bindings disagree."
        node=pair[2];found+=1
    )
    if found>0 and found!=roles.count do throw "Bind every role of a shared packaged context node together."
    node
)
global CyrusAssetStageTrackingVersion
fn CyrusAssetStageTrackingVersion = 1
fn CyrusAssetStage package bindings createdNodes:undefined = (
    if not theHold.Holding() do throw "Portable source staging requires the recipe's authored transaction."
    local graph=package[1],directory=package[2],metres=(units.decodeValue "1m") as double,materials=#(),maps=#(),files=CyrusRecipeGet graph "files",meshes=CyrusRecipeGet graph "meshes",resolved=for pair in bindings collect #(pair[1],pair[2])
    fn colorValue values = (color values[1] values[2] values[3])
    fn hasBinding values identity = (
        if identity==undefined do return true
        for pair in values where pair[1]==identity do return true
        false
    )
    local plantImages=(CyrusRecipeGet graph "version")==3
    if plantImages do (
        CyrusAssetCheckImageBuild()
        CyrusAssetCheckRenderer()
        local expectedProfile=CyrusAssetAdapterProfile(),savedProfile=CyrusRecipeGet graph "rendererProfile"
        for key in #("id","hostYear","pluginVersion") where (CyrusRecipeGet savedProfile key)!=(CyrusRecipeGet expectedProfile key) do throw "The renderer adapter profile differs from this build."
        local forestUsed=false
        for data in (CyrusRecipeGet graph "maps") where findItem #("forest-color-v1","forest-edge-v1") (CyrusRecipeGet data "kind")>0 do forestUsed=true
        if forestUsed do CyrusAssetCheckForest()
        local pixels=0L
        for data in (CyrusRecipeGet graph "maps") where findItem #("bitmap","corona-bitmap-v1") (CyrusRecipeGet data "kind")>0 do (
            local size=CyrusRecipeGet data "size";pixels+=(size[1] as Integer64)*size[2]
        )
        if (CyrusRecipeGet graph "resourceProfile")=="plant-assets-v1" then (
            if cyrusAssetPlantSceneAdmission==undefined do throw "Load the complete matching plant-mesh native build."
            local meshBytes=0L
            for file in files where (CyrusRecipeGet file "kind")=="mesh" do meshBytes+=(CyrusRecipeGet file "bytes") as Integer64
            cyrusAssetPlantSceneAdmission meshBytes pixels
        )else cyrusAssetImageAdmission pixels
    )
    local currentColor=if (CyrusRecipeGet graph "maps").count>0 then CyrusAssetColorContext "raw" else undefined
    for data in (CyrusRecipeGet graph "maps") where findItem #("bitmap","corona-bitmap-v1") (CyrusRecipeGet data "kind")>0 do (
        local fileData=undefined;for row in files where (CyrusRecipeGet row "id")==(CyrusRecipeGet data "file") do fileData=row
        local value=undefined
        if (CyrusRecipeGet data "kind")=="bitmap" then value=CyrusAssetRestoreMap data fileData (if package.count>2 then package[3] else 0L) currentColor plantImages:plantImages else value=CyrusAssetRestoreCoronaImage data fileData (if package.count>2 then package[3] else 0L) currentColor
        append maps #((CyrusRecipeGet data "id"),value)
        for role in (CyrusRecipeGet data "roles") do append resolved #(role,value)
    )
    -- Native validation admits a DAG, independent of serialization order. Create
    -- dependency leaves first and retain each completed graph in these arrays.
    local pending=for data in (CyrusRecipeGet graph "maps") where findItem #("bitmap","corona-bitmap-v1") (CyrusRecipeGet data "kind")==0 collect data
    while pending.count>0 do (
        local progressed=false
        for i=pending.count to 1 by -1 do (
            local data=pending[i],ready=true
            local links=CyrusRecipeGet data "links"
            for field in (CyrusAssetAdapterLinks (CyrusRecipeGet data "kind")) where not (hasBinding maps (CyrusRecipeGet links field)) do ready=false
            for field in (CyrusAssetAdapterArrayLinks (CyrusRecipeGet data "kind")) do (
                for identity in (CyrusRecipeGet links field) where not (hasBinding maps identity) do ready=false
            )
            if ready do (
                append maps #((CyrusRecipeGet data "id"),CyrusAssetRestoreShader data maps materials)
                deleteItem pending i;progressed=true
            )
        )
        if not progressed do throw "Renderer map dependencies could not be restored."
    )
    for data in (CyrusRecipeGet graph "materials") where (CyrusRecipeGet data "kind")!="multi-sub-v1" do (
        local material=undefined
        if (CyrusRecipeGet data "kind")=="standard-blinn" then (
        material=standardMaterial name:(CyrusRecipeGet data "name")
        material.adLock=false;material.dsLock=false;material.adTextureLock=false
        for pair in #(#("ambient",#ambient),#("diffuse",#diffuse),#("specular",#specular),#("selfIllumColor",#selfIllumColor)) do setProperty material pair[2] (colorValue (CyrusRecipeGet data pair[1]))
        for pair in #(#("opacity",#opacity),#("twoSided",#twoSided),#("specularLevel",#specularLevel),#("glossiness",#glossiness),#("soften",#soften),#("selfIllumAmount",#selfIllumAmount),#("useSelfIllumColor",#useSelfIllumColor),#("ambientDiffuseLock",#adLock),#("diffuseSpecularLock",#dsLock)) do setProperty material pair[2] (CyrusRecipeGet data pair[1])
        for slot in (CyrusRecipeGet data "maps") do (
            local key=CyrusRecipeGet slot "slot"
            setProperty material ((key+"Map") as name) (CyrusRecipeResolve maps (CyrusRecipeGet slot "map"))
            setProperty material ((key+"MapAmount") as name) (CyrusRecipeGet slot "amount")
            setProperty material ((key+"MapEnable") as name) (CyrusRecipeGet slot "enabled")
        )
        material.adTextureLock=CyrusRecipeGet data "textureLock"
        ) else material=CyrusAssetRestoreShader data maps materials
        append materials #((CyrusRecipeGet data "id"),material)
    )
    pending=for data in (CyrusRecipeGet graph "materials") where (CyrusRecipeGet data "kind")=="multi-sub-v1" collect data
    while pending.count>0 do (
        local progressed=false
        for i=pending.count to 1 by -1 do (
            local data=pending[i],ready=true
            for slot in (CyrusRecipeGet data "slots") where not (hasBinding materials (CyrusRecipeGet slot "material")) do ready=false
            if ready do (
                append materials #((CyrusRecipeGet data "id"),CyrusAssetRestoreShader data maps materials)
                deleteItem pending i;progressed=true
            )
        )
        if not progressed do throw "Multi/Sub material dependencies could not be restored."
    )
    for data in (CyrusRecipeGet graph "nodes") where (CyrusAssetBoundNode data bindings)==undefined do (
        local meshID=CyrusRecipeGet data "mesh",meshData=undefined,fileData=undefined
        for row in meshes where (CyrusRecipeGet row "id")==meshID do meshData=row
        for row in files where (CyrusRecipeGet row "id")==(CyrusRecipeGet meshData "file") do fileData=row
        local sha=CyrusRecipeGet fileData "sha256",file=pathConfig.appendPath directory ("assets/"+sha+"."+(CyrusRecipeGet fileData "suffix"))
        local node=if package.count>2 and package[3]>0 then cyrusAssetPreparedMeshCreate package[3] (CyrusRecipeGet fileData "id") metres (CyrusRecipeGet data "name") else cyrusAssetMeshCreate file sha metres (CyrusRecipeGet data "name")
        if createdNodes!=undefined do append createdNodes node
        local values=CyrusRecipeGet data "transform"
        node.transform=matrix3 [values[1],values[2],values[3]] [values[4],values[5],values[6]] [values[7],values[8],values[9]] [values[10]*metres,values[11]*metres,values[12]*metres]
        node.wireColor=colorValue (CyrusRecipeGet data "wireColor")
        local materialID=CyrusRecipeGet data "material"
        if materialID!=undefined do node.material=CyrusRecipeResolve materials materialID
        if package.count>4 do for role in package[5] where (CyrusAssetRoleIsReceiver role) and findItem (CyrusRecipeGet data "roles") (CyrusRecipeGet role "id")>0 do (
            node.isHidden=false;appendIfUnique package[4] node
        )
        for role in (CyrusRecipeGet data "roles") do append resolved #(role,node)
    )
    if (CyrusRecipeGet graph "version")>=2 do for data in (CyrusRecipeGet graph "splines") where (CyrusAssetBoundNode data bindings)==undefined do (
        local node=splineShape name:(CyrusRecipeGet data "name"),values=CyrusRecipeGet data "transform",index=0
        if createdNodes!=undefined do append createdNodes node
        fn pointValue value metres = [value[1]*metres,value[2]*metres,value[3]*metres]
        for curve in (CyrusRecipeGet data "curves") do (
            addNewSpline node;index+=1
            for knot in (CyrusRecipeGet curve "knots") do addKnot node index ((CyrusRecipeGet knot "type") as name) ((CyrusRecipeGet knot "line") as name) (pointValue (CyrusRecipeGet knot "point") metres) (pointValue (CyrusRecipeGet knot "in") metres) (pointValue (CyrusRecipeGet knot "out") metres)
            if CyrusRecipeGet curve "closed" do close node index
        )
        updateShape node;node.transform=matrix3 [values[1],values[2],values[3]] [values[4],values[5],values[6]] [values[7],values[8],values[9]] [values[10]*metres,values[11]*metres,values[12]*metres]
        if package.count>5 and package[6]!=undefined do node.transform=node.transform*package[6]
        node.wireColor=colorValue (CyrusRecipeGet data "wireColor");node.isHidden=true
        for role in (CyrusRecipeGet data "roles") do append resolved #(role,node)
    )
    resolved
)
fn CyrusAssetImport plan preparedToken:0L = (
    CyrusRequireAuthor()
    if not plan.newSetup do (
        CyrusRecipeCheckRoot plan.root plan.node
        if plan.root.procInputKey()!=plan.inputKey do throw "The destination changed since review. Review the package again."
    )
    local path=pathConfig.appendPath plan.directory "entry.csrecipe.json"
    if preparedToken==0 and (cyrusRecipeInfo path)[11]!=plan.recipeHash do throw "The packaged recipe changed since review."
    -- Verify the graph/content identity as well; equal recipe IDs are insufficient.
    local current=if preparedToken>0 then cyrusAssetPackagePrepared preparedToken false else cyrusAssetPackageRead plan.directory
    if not (CyrusPresetSameValues current plan.package) do throw "The package changed since review."
    local document=if preparedToken>0 then cyrusAssetPackagePrepared preparedToken true else cyrusRecipeRead path
    if preparedToken==0 and (cyrusRecipeInfo path)[11]!=plan.recipeHash do throw "The recipe changed while preparing Paint."
    if plan.assets==#share then (
        local snapshot=CyrusAssetSharedSnapshot plan.root plan.directory plan.recipeHash plan.bindings
        if not (CyrusPresetSameValues snapshot plan.sharedSnapshot) do throw "A shared source, material or bitmap changed since review. Review again; no assets were replaced."
        -- Borrowed scene references are never deleted/replaced by this import.
        -- Their normal Max reference graph owns lifetime and saved persistence.
        CyrusRecipeImport plan.root document plan.bindings newSetup:plan.newSetup variation:plan.variation
    ) else (
        if plan.assets!=#clone do throw "Unsupported asset reuse policy."
        local packagedReceivers=#()
        CyrusRecipeImport plan.root document plan.bindings newSetup:plan.newSetup variation:plan.variation prepareAssets:#(CyrusAssetStage,#((CyrusRecipeGet plan.package "graph"),plan.directory,preparedToken,packagedReceivers,(CyrusRecipeGet document "roles"),plan.pathTransform)) packagedPaintReceivers:(if plan.preset then packagedReceivers else undefined) paintFootprint:plan.paintFootprint calculate:plan.preset
    )
)

fn CyrusOpenAssetImport root directory = (
    CyrusRequireAuthor();local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if CyrusAssetImportEditor!=undefined do try(destroyDialog CyrusAssetImportEditor)catch()
    local job=cyrusAssetPackagePrepare directory (CyrusAssetBitmapDirectory())
    rollout editor "Load portable recipe" width:640 height:606 (
        local root,node,directory,package,document,roles=#(),bindings=#(),plan=undefined,bindingControls=false,job=0L,loading=false,busy=true
        label summary "" pos:[12,12] width:616 height:66
        dropdownlist mode "Destination:" items:#("Add Layers to this setup","Create New Setup") selection:1 pos:[12,86] width:302
        dropdownlist variation "Variation:" items:#("New variation","Saved variation") selection:1 pos:[326,86] width:302
        dropdownlist assets "Models and materials:" items:#("Import independent packaged models and materials","Reuse chosen scene models and keep their materials") selection:1 pos:[12,144] width:616
        button suggest "Match unique scene names" pos:[12,202] width:616
        listbox roleList "Dependencies to bind" items:#() pos:[12,238] width:616 height:8
        pickbutton bindNode "Bind scene object..." pos:[12,388] width:302 autoDisplay:false enabled:false
        mapbutton bindMap "Bind map..." pos:[326,388] width:302 enabled:false
        dropdownlist bindLayer "Spacing partner:" items:#() pos:[12,424] width:616 enabled:false
        button review "Review import" pos:[12,484] width:196
        button commit "Load package" pos:[222,484] width:196 enabled:false
        button closeButton "Close" pos:[432,484] width:196
        label status "Adds hidden, independent source meshes and new layers as one Undo. Existing materials and models are preserved." pos:[12,526] width:616 height:68
        timer progress interval:100 active:false
        fn clearPlan = (plan=undefined;commit.enabled=false)
        fn setBusy value = (
            busy=value;mode.enabled=not value;variation.enabled=not value;assets.enabled=not value;suggest.enabled=not value;roleList.enabled=not value;review.enabled=not value
            bindNode.enabled=false;bindMap.enabled=false;bindLayer.enabled=false;commit.enabled=not value and plan!=undefined
            closeButton.text=if value then "Cancel" else "Close"
        )
        fn showControls = (
            bindingControls=true;local i=roleList.selection,kind=if i<1 or i>roles.count then "" else CyrusRecipeGet roles[i] "kind"
            bindNode.enabled=not busy and kind=="node";bindMap.enabled=not busy and kind=="texture";bindLayer.enabled=not busy and kind=="layer" and mode.selection==1
            bindMap.map=if kind=="texture" then bindings[i][2] else undefined
            bindLayer.items=root.layerNames as array
            bindLayer.selection=if kind=="layer" then findItem root.layerObjects bindings[i][2] else 0
            bindingControls=false
        )
        fn showBindings = (
            local i=roleList.selection
            roleList.items=for j=1 to roles.count collect ((CyrusRecipeGet roles[j] "name")+" - "+(if bindings[j][2]==undefined then "UNBOUND" else if (CyrusRecipeGet roles[j] "kind")=="layer" then root.layerCaption bindings[j][2] else bindings[j][2].name))
            roleList.selection=if i>0 and i<=roles.count then i else if roles.count>0 then 1 else 0
            showControls();clearPlan()
        )
        fn bound value = (local i=roleList.selection;if i>0 and i<=bindings.count do (bindings[i][2]=value;showBindings()))
        fn readyPackage value = (
            package=value;roles=#();bindings=#()
            document=CyrusRecipeGet package "recipe";local graph=CyrusRecipeGet package "graph",external=CyrusRecipeGet graph "externalRoles"
            for role in (CyrusRecipeGet document "roles") where assets.selection==2 or findItem external (CyrusRecipeGet role "id")>0 do (append roles role;append bindings #((CyrusRecipeGet role "id"),undefined))
            summary.text=(CyrusRecipeGet document "name")+"\n"+((CyrusRecipeGet graph "nodes").count as string)+" packaged source meshes; "+((CyrusRecipeGet document "layers").count as string)+" layers, including saved Paint. "+(if assets.selection==2 then "Reuse explicitly bound models/maps, including their current materials. No models are imported or deleted." else "Bind its external terrain and other dependencies below.")
            setBusy false;showBindings();status.text="Choose the destination and bind external dependencies, then Review import."
        )
        on editor open do (
            root=CyrusAssetImportOpenData[1];node=CyrusAssetImportOpenData[2];directory=CyrusAssetImportOpenData[3];job=CyrusAssetImportOpenData[4]
            setBusy true;summary.text="Verifying package files and preparing meshes...";status.text="Preparation runs in a file worker. The scene remains unchanged.";progress.active=true
        )
        on roleList selected i do showControls()
        on bindNode picked value do bound value
        on bindMap picked value do if not bindingControls do bound value
        on bindLayer selected i do if not bindingControls and i>0 and i<=root.layerObjects.count do bound root.layerObjects[i]
        on mode selected i do (clearPlan();showControls())
        on variation selected i do clearPlan()
        on assets selected i do if not busy and package!=undefined do readyPackage package
        on suggest pressed do try (
            CyrusRecipeCheckRoot root node;local all=CyrusRecipeSuggestBindings root document
            for pair in bindings do pair[2]=CyrusRecipeResolve all pair[1]
            showBindings()
        )catch(status.text=getCurrentException())
        on review pressed do try(
            if busy or package==undefined do throw "Wait for package preparation."
            plan=CyrusAssetReview root directory bindings newSetup:(mode.selection==2) variation:(if variation.selection==1 then #new else #same) verifiedPackage:package assets:(if assets.selection==2 then #share else #clone)
            commit.enabled=true;status.text=if assets.selection==2 then "Ready: new layers will share the chosen scene sources and their current materials. No source ownership is transferred. Manual mode waits for Update." else "Ready: add packaged sources and layers as one authored operation. Manual mode waits for Update."
        )catch(clearPlan();status.text=getCurrentException())
        on commit pressed do try (
            if plan==undefined do throw "Review the package first."
            job=cyrusAssetPackagePrepare directory (CyrusAssetBitmapDirectory());loading=true;setBusy true;progress.active=true;status.text="Verifying the reviewed content before import..."
        )catch(clearPlan();status.text=getCurrentException())
        on progress tick do try (
            local result=cyrusAssetPackagePoll job
            if result[1]=="preparing" then status.text="Preparing: "+result[2] else (
                progress.active=false
                if result[1]!="ready" do throw (if result[4]!="" then result[4] else "Package preparation was cancelled or replaced.")
                CyrusRecipeCheckRoot root node
                if loading then (
                    CyrusAssetImport plan preparedToken:job;cyrusAssetPackageRelease job;loading=false;setBusy false;clearPlan();showControls();status.text="Loaded as one Undo. Manual mode waits for Update scatter."
                ) else readyPackage (cyrusAssetPackagePrepared job false)
            )
        )catch(progress.active=false;loading=false;setBusy false;clearPlan();review.enabled=package!=undefined;try(cyrusAssetPackageRelease job)catch();status.text=getCurrentException())
        on closeButton pressed do destroyDialog editor
        on editor close do (progress.active=false;try(cyrusAssetPackageRelease job)catch();CyrusAssetImportEditor=undefined)
    )
    CyrusAssetImportOpenData=#(root,node,directory,job);CyrusAssetImportEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)
