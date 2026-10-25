-- Finite renderer adapters. Package strings never select constructors or classes.
-- Material/map records are staged in dependency order; this file publishes no nodes.
global CyrusAssetShaderKind,CyrusAssetCheckRenderer,CyrusAssetCaptureShader,CyrusAssetRestoreShader
global CyrusAssetNewShader,CyrusAssetShaderEncode,CyrusAssetShaderDecode,CyrusAssetShaderApply,CyrusAssetShaderGuard
-- This template is emitted before assets.ms. Declare every later-defined helper
-- here so fresh-session compilation binds global functions, not undefined locals.
global CyrusRecipeObject,CyrusRecipeGet,CyrusRecipePut,CyrusRecipeResolve,CyrusPresetSameValues
global CyrusAssetSettingsEqual,CyrusAssetCheckDefaults,CyrusAssetMap,CyrusAssetMaterial
global cyrusAssetRendererModule,cyrusAssetForestModule,CyrusAssetCheckForest
global CyrusAssetAdapterFields,CyrusAssetAdapterLinks,CyrusAssetAdapterClassID,CyrusAssetAdapterProfile
global CyrusAssetAdapterCategory,CyrusAssetAdapterKinds,CyrusAssetAdapterOutput,CyrusAssetSubobjectFields
global CyrusAssetAdapterArrayLinks,CyrusAssetAdapterAlignedArrays,CyrusAssetAdapterCoordinates
global CyrusAssetShaderOutput,CyrusAssetShaderApplyOutput,cyrusAssetDefaultCurves,CyrusAssetShaderMetres
global CyrusAssetShaderCoordinates,CyrusAssetShaderApplyCoordinates,CyrusAssetCoronaImagePreflight,CyrusAssetCaptureCoronaImage
global CyrusAssetShaderCoordinateOwner,CyrusAssetShaderReadbackEqual,cyrusAssetRefreshCoronaBitmap

fn CyrusAssetShaderKind value = (
    if value==undefined do return undefined
    local identity=value.classID
    for kind in (CyrusAssetAdapterKinds()) do (
        local expected=CyrusAssetAdapterClassID kind
        if expected!=undefined and CyrusPresetSameValues identity expected do return kind
    )
    undefined
)
fn CyrusAssetCheckRenderer = (
    local profile=CyrusAssetAdapterProfile()
    if (maxVersion())[8]!=(CyrusRecipeGet profile "hostYear") do throw "This portable Corona profile requires Max 2027."
    if cyrusAssetRendererModule==undefined do throw "Load the complete matching renderer-adapter native build."
    local path=cyrusAssetRendererModule()
    if path==undefined or path=="" or not doesFileExist path do throw "The registered Corona Physical renderer module is unavailable."
    local version=((dotNetClass "System.Diagnostics.FileVersionInfo").GetVersionInfo path).FileVersion
    if version!=(CyrusRecipeGet profile "pluginVersion") do throw ("Portable Corona assets require renderer "+(CyrusRecipeGet profile "pluginVersion")+"; registered module is "+version+".")
    true
)
fn CyrusAssetCheckForest = (
    if cyrusAssetForestModule==undefined do throw "Load the matching native Forest adapter build."
    local path=cyrusAssetForestModule()
    if path==undefined or path=="" or not doesFileExist path do throw "The registered Forest Color/Edge module is unavailable."
    local version=((dotNetClass "System.Diagnostics.FileVersionInfo").GetVersionInfo path).FileVersion
    if version!="9,4,3,766" do throw ("Portable Forest maps require the measured Forest Pack Lite 9,4,3,766 module; registered version is "+version)
    true
)
fn CyrusAssetNewShader kind = (
    if kind=="forest-color-v1" or kind=="forest-edge-v1" do CyrusAssetCheckForest()

    local value=case kind of (
        "corona-physical-v1": CoronaPhysicalMtl()
        "corona-legacy-v1": CoronaLegacyMtl()
        "corona-normal-v1": CoronaNormal()
        "multi-sub-v1": multiMaterial numsubs:1
        "max-color-correction-v1": Color_Correction()
        "max-vertex-color-v1": Vertex_Color()
        "corona-front-back-v1": CoronaFrontBack()
        "max-mix-v1": Mix()
        "corona-color-v1": CoronaColor()
        "corona-mix-v1": CoronaMix()
        "corona-color-correct-v1": CoronaColorCorrect()
        "max-composite-v1": CompositeTexturemap()
        "forest-color-v1": Forest_Color()
        "forest-edge-v1": Forest_Edge()
        "corona-bitmap-v1": CoronaBitmap()
        "max-gradient-v1": Gradient()
        default: throw "Unknown closed portable shader adapter."
    )
    if not (CyrusPresetSameValues value.classID (CyrusAssetAdapterClassID kind)) do throw ("The installed shader class differs from the qualified adapter: "+kind)
    value
)
fn CyrusAssetShaderMetres = (
    local scale=(units.decodeValue "1m") as double
    if not (scale>0 and scale<1e12) do throw "Portable shader scene units are outside their supported bounds."
    scale
)
fn CyrusAssetShaderEncode value type = (
    if findString type "-array"!=undefined and type!="empty-array" and type!="null-array" do (
        if classof value!=Array and classof value!=ArrayParameter do throw "Portable shader array has the wrong host type."
        local values=value as array
        if values.count<1 or values.count>128 do throw "Portable shader array exceeds its bound."
        local element=substring type 1 (type.count-6)
        return (for item in values collect CyrusAssetShaderEncode item element)
    )

    case type of (
        "color": (
            if classof value!=Color do throw "Portable shader color has the wrong host type."
            #(value.r as double,value.g as double,value.b as double)
        )
        "point3-distance": (
            if classof value!=Point3 do throw "Portable shader distance vector has the wrong host type."
            local scale=CyrusAssetShaderMetres()
            #((value.x as double)/scale,(value.y as double)/scale,(value.z as double)/scale)
        )
        "point3": (
            if classof value!=Point3 do throw "Portable shader vector has the wrong host type."
            #(value.x as double,value.y as double,value.z as double)
        )
        "empty-array": (if (value as array).count!=0 do throw "Active portable shader curves require a separate adapter.";#())
        "null-array": (local values=value as array;if values.count!=100 do throw "Portable shader absent input array has the wrong count.";for item in values where item!=undefined do throw "Additional portable shader inputs require a separate adapter.";values)
        "absent-filename": (if value!=undefined and value!="" do throw "External portable shader LUTs require a separate adapter.";undefined)
        "distance": (
            if not isKindOf value Number do throw "Portable shader distance has the wrong host type."
            (value as double)/(CyrusAssetShaderMetres())
        )
        "number": (
            if not isKindOf value Number do throw "Portable shader number has the wrong host type."
            value as double
        )
        "integer": (
            if classof value!=Integer and classof value!=Integer64 do throw "Portable shader integer has the wrong host type."
            value as integer64
        )
        "boolean": (
            if classof value!=classof true do throw "Portable shader boolean has the wrong host type."
            value
        )
        "string": (
            if classof value!=String do throw "Portable shader string has the wrong host type."
            value
        )
        default: throw "Unknown closed portable shader field type."
    )
)
fn CyrusAssetShaderDecode value type = (
    if findString type "-array"!=undefined and type!="empty-array" and type!="null-array" do (
        local element=substring type 1 (type.count-6)
        return (for item in value collect CyrusAssetShaderDecode item element)
    )

    case type of (
        "color": color value[1] value[2] value[3]
        "integer": value as integer
        "distance": value*(CyrusAssetShaderMetres())
        "point3": point3 value[1] value[2] value[3]
        "point3-distance": (point3 value[1] value[2] value[3])*(CyrusAssetShaderMetres())
        "absent-filename": ""
        default: value
    )
)
-- SI is serialized as double; host parameter blocks store float32. Compare
-- decoded host values exactly, without a second SI rounding or a new epsilon.
fn CyrusAssetShaderReadbackEqual actual encoded type = (
    case type of (
        "distance": ((actual as float)==((CyrusAssetShaderDecode encoded type) as float))
        "point3-distance": (
            local expected=CyrusAssetShaderDecode encoded type
            actual.x==expected.x and actual.y==expected.y and actual.z==expected.z
        )
        default: CyrusAssetSettingsEqual (CyrusAssetShaderEncode actual type) encoded
    )
)
fn CyrusAssetShaderOutput value kind = (
    local outputKind=CyrusAssetAdapterOutput kind
    if outputKind==undefined do return undefined
    local properties=CyrusRecipeObject #()
    for field in (CyrusAssetSubobjectFields outputKind) do CyrusRecipePut properties field[1] (CyrusAssetShaderEncode (getProperty value.output (field[1] as name)) field[2])
    CyrusRecipeObject #(#("kind",outputKind),#("properties",properties))
)
fn CyrusAssetShaderApplyOutput value data kind = (
    local outputKind=CyrusAssetAdapterOutput kind
    if outputKind==undefined do (if data!=undefined do throw "Unexpected portable shader output adapter.";return true)
    if data==undefined or (CyrusRecipeGet data "kind")!=outputKind do throw "Missing or incompatible portable shader output adapter."
    local expected=CyrusAssetNewShader kind
    if classof value.output!=classof expected.output do throw "Unsupported portable shader output class."
    local properties=CyrusRecipeGet data "properties"
    for field in (CyrusAssetSubobjectFields outputKind) do setProperty value.output (field[1] as name) (CyrusAssetShaderDecode (CyrusRecipeGet properties field[1]) field[2])
    for field in (CyrusAssetSubobjectFields outputKind) do (
        local actual=getProperty value.output (field[1] as name)
        if not (CyrusAssetShaderReadbackEqual actual (CyrusRecipeGet properties field[1]) field[2]) do throw ("The host changed portable shader output setting: "+field[1])
    )
    cyrusAssetDefaultCurves value.output expected.output
    true
)
fn CyrusAssetCoronaImagePreflight value = (
    if value.useLegacyGamma or value.showLegacyGamma or value.gamma!=1 or value.colorSpace!=4 or findItem #("Raw","Gamma 2.2 / Rec.709") value.colorSpaceStr==0 do throw "Prepare an explicit modern OCIO CoronaBitmap derivative before packaging: gamma1, OCIO input space, legacy flags off."
    if value.realWorldScale or value.enviroMapping!=0 or value.triplanarMapping or value.useObjectTransform or value.objecttransform!=undefined or value.aspectRatioLock do throw "This CoronaBitmap profile supports explicit UV channel mapping without real-world, environment, triplanar or object-transform modes."
    true
)
fn CyrusAssetShaderCoordinateOwner value kind = (
    if kind=="corona-bitmap-v1" do return value
    if kind=="max-gradient-v1" do (
        local expected=Gradient()
        if classof value.coords!=classof expected.coords or not (CyrusPresetSameValues value.coords.classID #(256L,0L)) do throw "Unsupported ordinary Gradient coordinate class."
        if value.coords.realWorldScale do throw "Prepare an explicit ordinary-UV Gradient derivative before packaging; active real-world coordinates require a separate contract."
        return value.coords
    )
    throw "Unsupported portable shader coordinate owner."
)
fn CyrusAssetShaderCoordinates value kind = (
    local coordinateKind=CyrusAssetAdapterCoordinates kind
    if coordinateKind==undefined do return undefined
    local owner=CyrusAssetShaderCoordinateOwner value kind
    local properties=CyrusRecipeObject #()
    for field in (CyrusAssetSubobjectFields coordinateKind) do CyrusRecipePut properties field[1] (CyrusAssetShaderEncode (getProperty owner (field[1] as name)) field[2])
    CyrusRecipeObject #(#("kind",coordinateKind),#("properties",properties))
)
fn CyrusAssetShaderApplyCoordinates value data kind = (
    local coordinateKind=CyrusAssetAdapterCoordinates kind
    if coordinateKind==undefined do (if data!=undefined do throw "Unexpected portable shader coordinates.";return true)
    if data==undefined or (CyrusRecipeGet data "kind")!=coordinateKind do throw "Missing or incompatible portable shader coordinates."
    local owner=CyrusAssetShaderCoordinateOwner value kind
    local properties=CyrusRecipeGet data "properties"
    -- Mapping mode setters can invert/reset UVW scale. The finite table puts
    -- them first and UVW scale last; verify after every coordinate setter.
    for field in (CyrusAssetSubobjectFields coordinateKind) do setProperty owner (field[1] as name) (CyrusAssetShaderDecode (CyrusRecipeGet properties field[1]) field[2])
    for field in (CyrusAssetSubobjectFields coordinateKind) do (
        local actual=getProperty owner (field[1] as name)
        if not (CyrusAssetShaderReadbackEqual actual (CyrusRecipeGet properties field[1]) field[2]) do throw ("The renderer changed portable shader coordinates: "+field[1])
    )
    if kind=="max-gradient-v1" do CyrusAssetShaderCoordinateOwner value kind
    true
)
fn CyrusAssetShaderApply value properties links kind maps outputData:undefined coordinateData:undefined = (
    -- Table order puts mode controls ahead of the numeric values they can reset.
    for field in (CyrusAssetAdapterFields kind) do (
        local key=field[1] as name
        setProperty value key (CyrusAssetShaderDecode (CyrusRecipeGet properties field[1]) field[2])
    )
    for field in (CyrusAssetAdapterLinks kind) do setProperty value (field as name) (CyrusRecipeResolve maps (CyrusRecipeGet links field))
    for field in (CyrusAssetAdapterArrayLinks kind) do setProperty value (field as name) (for child in (CyrusRecipeGet links field) collect CyrusRecipeResolve maps child)
    CyrusAssetShaderApplyCoordinates value coordinateData kind
    -- Read every supported setting after all setters, including derived aliases.
    for field in (CyrusAssetAdapterFields kind) do (
        local actual=getProperty value (field[1] as name)
        if not (CyrusAssetShaderReadbackEqual actual (CyrusRecipeGet properties field[1]) field[2]) do throw ("The renderer changed portable shader setting: "+field[1])
    )
    for field in (CyrusAssetAdapterLinks kind) where (getProperty value (field as name))!=(CyrusRecipeResolve maps (CyrusRecipeGet links field)) do throw ("The renderer changed portable shader link: "+field)
    for field in (CyrusAssetAdapterArrayLinks kind) do (
        local actual=(getProperty value (field as name)) as array,expected=CyrusRecipeGet links field
        if actual.count!=expected.count do throw "The renderer changed portable shader array link count."
        for i=1 to actual.count where actual[i]!=(CyrusRecipeResolve maps expected[i]) do throw ("The renderer changed portable shader array link: "+field)
    )
    CyrusAssetShaderApplyOutput value outputData kind
    if kind=="corona-bitmap-v1" do (
        -- Evaluate only the admitted fixed image class after all its controls.
        -- Its lazy gamma cache must settle before a Normal dependant is checked.
        if cyrusAssetRefreshCoronaBitmap==undefined do throw "Load the matching native CoronaBitmap cache adapter."
        cyrusAssetRefreshCoronaBitmap value
        for field in (CyrusAssetAdapterFields kind) where not (CyrusAssetShaderReadbackEqual (getProperty value (field[1] as name)) (CyrusRecipeGet properties field[1]) field[2]) do throw ("Image update changed portable shader setting: "+field[1])
        for field in (CyrusAssetSubobjectFields (CyrusAssetAdapterCoordinates kind)) where not (CyrusAssetShaderReadbackEqual (getProperty value (field[1] as name)) (CyrusRecipeGet (CyrusRecipeGet coordinateData "properties") field[1]) field[2]) do throw ("Image update changed portable coordinates: "+field[1])
        for field in (CyrusAssetSubobjectFields (CyrusAssetAdapterOutput kind)) where not (CyrusAssetShaderReadbackEqual (getProperty value.output (field[1] as name)) (CyrusRecipeGet (CyrusRecipeGet outputData "properties") field[1]) field[2]) do throw ("Image update changed portable output: "+field[1])
    )
    true
)
fn CyrusAssetShaderGuard value baseline kind = (
    local supported=#(#name)
    for field in (CyrusAssetAdapterFields kind) do append supported (field[1] as name)
    for field in (CyrusAssetAdapterLinks kind) do append supported (field as name)
    for field in (CyrusAssetAdapterArrayLinks kind) do append supported (field as name)
    local alignedCount=undefined
    for field in (CyrusAssetAdapterAlignedArrays kind) do (
        local count=((getProperty value (field as name)) as array).count
        if alignedCount==undefined then alignedCount=count else if count!=alignedCount do throw "Portable Composite layer arrays have inconsistent lengths."
    )
    if kind=="corona-color-correct-v1" do (
        -- Corona 15's published computed interface alias dereferences null even
        -- on a detached fresh instance. Its authored output controls remain closed.
        if value.additionalOutputs!=0 or value.controlsSource!=0 or value.copiedMap!=undefined or value.showCopiedMap or value.lutEnable or value.curveEnabled do throw "Unsupported Corona Color Correct output, curve or LUT mode."
        if (value.additionalInputTexmap as array).count!=100 do throw "Unsupported Corona Color Correct input array."
        for item in (value.additionalInputTexmap as array) where item!=undefined do throw "Additional Corona Color Correct inputs are unsupported."
        append supported #numIMultipleOutputChannels
    )
    local coordinateKind=CyrusAssetAdapterCoordinates kind
    if coordinateKind!=undefined do (
        local coordinateFields=#()
        for field in (CyrusAssetSubobjectFields coordinateKind) do append coordinateFields (field[1] as name)
        if kind=="max-gradient-v1" then (
            append supported #coords
            -- UVTransform is a known read-only lazy cache: setters reject it;
            -- identical authored fields produce identity until evaluation, then
            -- match the reopened matrix exactly (gradient-ordinary-helper1/
            -- matrix-evaluation.json). Only its value equality is excluded;
            -- CheckDefaults still checks its controller and all unknown fields.
            append coordinateFields #UVTransform
            -- Inactive physical width/height remain strict derived aliases.
            CyrusAssetCheckDefaults (CyrusAssetShaderCoordinateOwner value kind) (CyrusAssetShaderCoordinateOwner baseline kind) coordinateFields
        )else join supported coordinateFields
    )
    -- The resource hook has already verified/copies the source bytes and bounds.
    -- Filename is never a serialized arbitrary property or compared as a path alias.
    if kind=="corona-bitmap-v1" do (CyrusAssetCoronaImagePreflight value;append supported #filename)
    local outputKind=CyrusAssetAdapterOutput kind
    if outputKind!=undefined do (
        append supported #output
        if classof value.output!=classof baseline.output do throw "Unsupported portable shader output class."
        local outputFields=#()
        for field in (CyrusAssetSubobjectFields outputKind) do append outputFields (field[1] as name)
        CyrusAssetCheckDefaults value.output baseline.output outputFields
        cyrusAssetDefaultCurves value.output baseline.output
    )
    -- Compare every unsupported property and controller against the material
    -- reconstructed from captured settings. preSet is derived by Corona setters;
    -- materialLibraryId is read-only and must still equal the fresh default.
    CyrusAssetCheckDefaults value baseline supported
    if kind=="corona-normal-v1" and (value.gammaWarning or baseline.gammaWarning) do throw "Resolve the Corona normal-map input gamma warning before packaging."
    true
)
fn CyrusAssetCaptureShader context value kind = (
    if kind==undefined or (CyrusAssetShaderKind value)!=kind do throw "Unsupported portable shader class identity."
    context.rendererMode=true
    if not context.rendererChecked do (CyrusAssetCheckRenderer();context.rendererChecked=true)
    local category=CyrusAssetAdapterCategory kind
    if category!="map" and category!="material" do throw "Unsupported portable shader category."
    local isMap=category=="map",visiting=if isMap then context.mapVisiting else context.materialVisiting
    local countLimit=if isMap then 256 else 128
    if findItem visiting value>0 do throw "Portable material/map dependency cycles are unsupported."
    if context.mapVisiting.count+context.materialVisiting.count>=8 do throw "Portable shader graph exceeds its depth bound of 8."
    if (if isMap then context.maps.count+context.mapVisiting.count else context.materials.count+context.materialVisiting.count)>=countLimit do throw "Portable material/map count exceeds its profile bound."
    append visiting value
    try (
        local baseline=CyrusAssetNewShader kind,data=undefined
        if kind=="multi-sub-v1" then (
            local count=value.materialList.count,slots=#()
            if count<1 or count>128 or value.materialIDList.count!=count or value.names.count!=count or value.mapEnabled.count!=count do throw "Portable Multi/Sub materials require 1 to 128 consistent slots; Max cannot represent an empty slot array."
            baseline.numsubs=count
            for i=1 to count do (
                local child=value.materialList[i]
                baseline.materialList[i]=child;baseline.materialIDList[i]=value.materialIDList[i];baseline.names[i]=value.names[i];baseline.mapEnabled[i]=value.mapEnabled[i]
                append slots (CyrusRecipeObject #(#("materialID",value.materialIDList[i]),#("name",value.names[i]),#("enabled",value.mapEnabled[i]),#("material",CyrusAssetMaterial context child)))
            )
            baseline.showPreviews=value.showPreviews
            CyrusAssetCheckDefaults value baseline #(#name,#materialList,#materialIDList,#names,#mapEnabled,#showPreviews)
            data=CyrusRecipeObject #(#("id","material-"+((context.materials.count+1) as string)),#("kind",kind),#("name",value.name),#("slots",slots),#("showPreviews",value.showPreviews))
        )else (
            local properties=CyrusRecipeObject #(),links=CyrusRecipeObject #(),references=#(),imageResource=undefined
            if kind=="corona-bitmap-v1" do (
                CyrusAssetCoronaImagePreflight value
                if CyrusAssetCaptureCoronaImage==undefined do throw "Load the complete matching Corona image resource adapter."
                local image=CyrusAssetCaptureCoronaImage context value
                if classof image!=Array or image.count!=2 or classof image[2]!=String or image[2]=="" do throw "The Corona image resource adapter returned an invalid staged image."
                imageResource=image[1]
                -- Resource admission above verifies bytes and bounds before
                -- evaluating this source map's fixed-class lazy cache.
                if cyrusAssetRefreshCoronaBitmap==undefined do throw "Load the matching native CoronaBitmap cache adapter."
                cyrusAssetRefreshCoronaBitmap value
                if (CyrusRecipeGet (CyrusRecipeGet imageResource "color") "inputSpace")!=value.colorSpaceStr do throw "The Corona image resource input space changed during capture."
                -- Filename MUST precede every interpretation/mapping setting.
                baseline.filename=image[2]
            )
            for field in (CyrusAssetAdapterFields kind) do CyrusRecipePut properties field[1] (CyrusAssetShaderEncode (getProperty value (field[1] as name)) field[2])
            for field in (CyrusAssetAdapterLinks kind) do (
                local child=getProperty value (field as name),identity=CyrusAssetMap context child
                CyrusRecipePut links field identity
                if identity!=undefined do append references #(identity,child)
            )
            for field in (CyrusAssetAdapterArrayLinks kind) do (
                local identities=#()
                local children=(getProperty value (field as name)) as array
                if children.count<1 or children.count>128 do throw "Portable shader array links exceed their bound."
                for child in children do (
                    local identity=CyrusAssetMap context child
                    append identities identity
                    if identity!=undefined do append references #(identity,child)
                )
                CyrusRecipePut links field identities
            )
            local outputData=CyrusAssetShaderOutput value kind,coordinateData=CyrusAssetShaderCoordinates value kind
            CyrusAssetShaderApply baseline properties links kind references outputData:outputData coordinateData:coordinateData
            CyrusAssetShaderGuard value baseline kind
            data=CyrusRecipeObject #(#("id",(if isMap then "map-"+((context.maps.count+1) as string) else "material-"+((context.materials.count+1) as string))),#("kind",kind),#("name",value.name),#("properties",properties),#("links",links))
            if isMap do CyrusRecipePut data "roles" #()
            if outputData!=undefined do CyrusRecipePut data "output" outputData
            if coordinateData!=undefined do CyrusRecipePut data "coordinates" coordinateData
            if imageResource!=undefined do for key in #("file","size","color") do CyrusRecipePut data key (CyrusRecipeGet imageResource key)
        )
        -- Children were captured first, so IDs and backing value arrays align.
        if (if isMap then context.maps.count+context.mapVisiting.count else context.materials.count+context.materialVisiting.count)>countLimit do throw "Portable shader children exhausted the reserved graph capacity."
        if isMap then (append context.maps data;append context.mapValues value) else (append context.materials data;append context.materialValues value)
        deleteItem visiting visiting.count
        CyrusRecipeGet data "id"
    )catch(
        local index=findItem visiting value
        if index>0 do deleteItem visiting index
        throw()
    )
)
fn CyrusAssetRestoreShader data maps materials imagePath:undefined = (
    local kind=CyrusRecipeGet data "kind"
    CyrusAssetCheckRenderer()
    if kind=="multi-sub-v1" and (CyrusRecipeGet data "slots").count<1 do throw "Max cannot restore a Multi/Sub material with zero slots."
    local value=CyrusAssetNewShader kind
    value.name=CyrusRecipeGet data "name"
    if kind=="corona-bitmap-v1" do (
        if classof imagePath!=String or imagePath=="" or not doesFileExist imagePath do throw "A validated cached image path is required for CoronaBitmap restoration."
        value.filename=imagePath
    )
    if kind=="multi-sub-v1" then (
        local slots=CyrusRecipeGet data "slots"
        value.numsubs=slots.count
        for i=1 to slots.count do (
            local slot=slots[i]
            value.materialIDList[i]=CyrusRecipeGet slot "materialID"
            value.names[i]=CyrusRecipeGet slot "name"
            value.mapEnabled[i]=CyrusRecipeGet slot "enabled"
            value.materialList[i]=CyrusRecipeResolve materials (CyrusRecipeGet slot "material")
        )
        value.showPreviews=CyrusRecipeGet data "showPreviews"
        if value.materialList.count!=slots.count or value.materialIDList.count!=slots.count or value.names.count!=slots.count or value.mapEnabled.count!=slots.count do throw "The host changed the portable Multi/Sub slot count."
        for i=1 to slots.count do (
            local slot=slots[i]
            if value.materialIDList[i]!=(CyrusRecipeGet slot "materialID") or value.names[i]!=(CyrusRecipeGet slot "name") or value.mapEnabled[i]!=(CyrusRecipeGet slot "enabled") or value.materialList[i]!=(CyrusRecipeResolve materials (CyrusRecipeGet slot "material")) do throw "The host changed a portable Multi/Sub slot."
        )
        if value.showPreviews!=(CyrusRecipeGet data "showPreviews") do throw "The host changed Multi/Sub preview settings."
    )else (
        local outputData=if (CyrusAssetAdapterOutput kind)==undefined then undefined else CyrusRecipeGet data "output"
        local coordinateData=if (CyrusAssetAdapterCoordinates kind)==undefined then undefined else CyrusRecipeGet data "coordinates"
        CyrusAssetShaderApply value (CyrusRecipeGet data "properties") (CyrusRecipeGet data "links") kind maps outputData:outputData coordinateData:coordinateData
        if kind=="corona-bitmap-v1" do CyrusAssetCoronaImagePreflight value
        if kind=="corona-normal-v1" and value.gammaWarning do throw "Restored Corona normal input has an incompatible gamma interpretation."
    )
    value
)
