-- Bounded data-only recipes. Scene mutation is confined to CyrusRecipeImport.
global CyrusRecipeBrowser,CyrusRecipeOpenRoot,CyrusRecipeOpenNode,CyrusRecipeOpenSurface,CyrusRecipeScriptDirectory
global CyrusLibraryCheckSurface,CyrusLibraryDestination,CyrusLibraryVersion,CyrusRecipeErrorText
fn CyrusRecipeErrorText value = (
    local message=trimLeft (value as string),prefix="-- Runtime error: "
    while findString message prefix==1 do message=trimLeft (substring message (prefix.count+1) -1)
    message
)
global AminScatterObject,CyrusRecipeCheckRoot,CyrusRecipeOwnerNode
fn CyrusLibraryVersion = "0.86.6.1"
fn CyrusLibraryCheckSurface node = (
    if not isValidNode node or superclassof node!=GeometryClass or classof node.baseObject==AminScatterObject do throw "Select one terrain mesh, then open Cyrus Library."
    true
)
fn CyrusLibraryDestination surface hint = (
    CyrusLibraryCheckSurface surface
    if hint!=undefined do (CyrusRecipeCheckRoot hint (CyrusRecipeOwnerNode hint);return hint)
    local owners=#()
    for node in objects where classof node.baseObject==AminScatterObject do (
        local root=node.baseObject,uses=false
        for layer in root.logicalLayers() where findItem (layer.validSurfaces()) surface>0 do uses=true
        if uses do appendIfUnique owners root
    )
    if owners.count>1 do throw "This terrain belongs to several Scatter setups. Open Recipes from the setup that should receive the new layers."
    if owners.count==1 then owners[1] else undefined
)
CyrusRecipeScriptDirectory=getFilenamePath (getSourceFileName())
global CyrusRecipeObject,CyrusRecipeGet,CyrusRecipeCapture,CyrusRecipeImport,CyrusOpenRecipeLibrary
-- This template is prepended before the plugin/controller template. Declare
-- late-bound globals explicitly so cold compilation cannot capture undefined
-- function locals before the controller has registered them.
global AminScatterObject,CyrusScatterEdit,CyrusNewLayerID,CyrusAnalyzerFilter,CyrusRequireAuthor
global CyrusPointSuspended,CyrusBrushSessionLayer,CyrusViewportRedraw,CyrusReceiverVariationDomains,CyrusRemapLayerCorrespondence
global CyrusRecipeCaptureContext,CyrusRecipePut,CyrusRecipeOwnerNode,CyrusRecipeCheckRoot
global CyrusRecipeRole,CyrusRecipeCaptureValue,CyrusRecipeCaptureSettings,CyrusRecipeCapturePaint
global CyrusRecipeResolve,CyrusRecipeValidateBindings,CyrusRecipeApplyValue,CyrusRecipeApplySettings
global CyrusRecipeRestorePaint,CyrusRecipeDirectory,CyrusRecipeBundledDirectory,CyrusRecipeSuggestBindings,CyrusOpenPresets,CyrusPresetSameValues,CyrusRecipeViewPreferences,CyrusRecipeIsBundled,CyrusRecipeEditDetails,CyrusRecipeDetailEditor,CyrusRecipeDetailOpenData
global CyrusOpenAssetExport,CyrusOpenAssetImport,CyrusOpenReadyPreset,CyrusPresetPackageDirectory,CyrusPresetSaveReady,CyrusPresetReviseReady
global CyrusRecipeFields,CyrusRecipeSchemaCache=undefined
-- The matching module's fixed schema is read-only for these consumers. Avoid
-- rebuilding hundreds of rows for every owner on every explicit capture.
fn CyrusRecipeFields = (
    if CyrusRecipeSchemaCache==undefined do CyrusRecipeSchemaCache=cyrusRecipeSchema()
    CyrusRecipeSchemaCache
)
struct CyrusRecipeCaptureContext (root,node,owners,roles=#(),values=#(),metres=1.0,paintBytes=0,paintDocuments=0)
fn CyrusRecipeObject pairs = #(#recipeObject,pairs)
fn CyrusRecipeGet object key = (
    if object.count!=2 or object[1]!=#recipeObject do throw "Invalid recipe object."
    for pair in object[2] where pair[1]==key do return pair[2]
    throw ("Missing recipe field: "+key)
)
fn CyrusRecipePut object key value = (
    for pair in object[2] where pair[1]==key do (pair[2]=value;return value)
    append object[2] #(key,value);value
)
fn CyrusRecipeOwnerNode root = (
    local nodes=for node in refs.dependentNodes root where isValidNode node and node.baseObject==root collect node
    if nodes.count!=1 do throw "Recipes require one unambiguous Scatter controller."
    nodes[1]
)
fn CyrusRecipeCheckRoot root node = (
    if root==undefined or not isValidNode node or node.baseObject!=root do throw "The recipe controller was removed or replaced."
    root.procAssertSchema();true
)
fn CyrusRecipeRole context value kind purpose = (
    if value==undefined do return undefined
    if kind=="node" and not isValidNode value do throw ("Missing scene dependency: "+purpose)
    local index=findItem context.values value
    if index>0 do (
        local row=context.roles[index]
        if (CyrusRecipeGet row "kind")!=kind do throw "A dependency has incompatible role kinds."
        appendIfUnique (CyrusRecipeGet row "purposes") purpose
        return (CyrusRecipeGet row "id")
    )
    local identity="role-"+((context.roles.count+1) as string),label=if kind=="layer" then context.root.layerCaption value else value.name
    local row=CyrusRecipeObject #(#("id",identity),#("kind",kind),#("name",label),#("purposes",#(purpose)),#("requirements",undefined))
    append context.values value;append context.roles row
    if kind=="node" and isProperty value #collectEnabled do (
        cyrusRecipeCheckStatic value.baseObject
        local members=for source in value.savedSources collect (CyrusRecipeRole context source "node" "containerSavedSource")
        CyrusRecipePut row "requirements" (CyrusRecipeObject #(#("width",value.width/context.metres),#("length",value.length/context.metres),#("collectEnabled",value.collectEnabled),#("showLabel",value.showLabel),#("savedSources",members)))
    )
    identity
)
fn CyrusRecipeCaptureValue context value kind field = (
    case kind of (
        "node":(CyrusRecipeRole context value "node" field)
        "texturemap":(CyrusRecipeRole context value "texture" field)
        "color":#(value.r as double,value.g as double,value.b as double)
        "worldunits":((value as double)/context.metres)
        "float":(value as double)
        default:value
    )
)
fn CyrusRecipeCaptureSettings context owner = (
    local staticError=undefined
    try(cyrusRecipeCheckStatic owner)catch(staticError=getCurrentException())
    if staticError!=undefined do (
        local label=if owner==context.root then "setup settings" else if owner.isPaintArea then "Paint Area "+owner.paintSetName else context.root.layerCaption owner
        throw ("Cannot save "+label+": "+staticError)
    )
    -- Enroll only bounded correspondence metadata; Save does not evaluate terrain.
    if owner!=context.root and not owner.isPaintArea do owner.procEnsureCorrespondence()
    local pairs=#(),projection=undefined,basis=#()
    if owner.densityCoordinateMode==2 do (
        projection=owner.densityProjectionFrame()
        for row=1 to 3 do join basis #(projection[row].x,projection[row].y,projection[row].z)
    )
    for field in (CyrusRecipeFields()) do (
        local key=field[1],kind=field[2],value=if key=="procReceiverVariationIDs" then CyrusReceiverVariationDomains owner else getProperty owner (key as name)
        if projection!=undefined do (
            if key=="densityFrameBasis" do value=basis
            if key=="densityFrameOriginWU" do value=#(projection.row4.x,projection.row4.y,projection.row4.z)
        )
        if matchPattern kind pattern:"*tab" then (
            kind=substring kind 1 (kind.count-3)
            value=for entry in value collect (CyrusRecipeCaptureValue context entry kind key)
        ) else value=CyrusRecipeCaptureValue context value kind key
        append pairs #(key,value)
    )
    CyrusRecipeObject pairs
)
fn CyrusRecipeCapturePaint context owner = (
    if owner.paintDocument==undefined do return undefined
    if context.paintDocuments>=256 do throw "Save Everything exceeds the 256 Paint-document recipe limit. Select fewer layers; the scene is preserved."
    local data=cyrusBrushRecipeExport owner.paintDocument
    local bytes=data[1].count/2
    if context.paintBytes+bytes>67108864 do throw "Save Everything exceeds the 64 MiB Paint recipe limit. Select fewer layers; the scene is preserved."
    context.paintDocuments+=1;context.paintBytes+=bytes
    CyrusRecipeObject #(#("payload",data[1]),#("receiverRole",CyrusRecipeRole context (cyrusBrushTarget owner.paintDocument) "node" "paintReceiver"),#("radius",data[2]),#("erase",data[3]),#("frame",data[4]))
)
fn CyrusRecipeCapture root selected name bindingResult:undefined = (
    CyrusRequireAuthor()
    if cyrusRecipeVersion==undefined or cyrusRecipeVersion()!=7 or cyrusBrushRecipeExport==undefined do throw "Load the complete Cyrus 0.86.6.1 script/native pair and restart Max."
    local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if root.paintDocument!=undefined or root.paintAreas.count>0 or root.procRadiusIDs.count>0 do throw "This setup contains root-owned authored Paint/radius data outside the current layer contract. Save Everything was cancelled; the scene is preserved."
    local owners=for owner in root.logicalLayers() where findItem selected owner>0 collect owner
    if owners.count==0 or owners.count!=selected.count do throw "Select one or more current layers to save."
    for edit in root.procModifiers() where cyrusEditRecipeHasData edit do throw "Save Everything cannot yet export authored Scatter Edit changes. The modifier and scene are preserved."
    for owner in owners where owner.procRadiusIDs.count>0 do throw ("Save Everything cannot yet export per-instance radius overrides: "+root.layerCaption owner)
    local context=CyrusRecipeCaptureContext root:root node:node owners:owners metres:((units.decodeValue "1m") as double)
    local rootSettings=CyrusRecipeCaptureSettings context root,layers=#(),rules=#()
    for owner in owners do (
        local index=findItem root.layerObjects owner,areas=#()
        if owner.paintAreas.count>128 do throw "Save Everything exceeds the per-layer Paint Area limit; the scene is preserved."
        for area in owner.paintAreas do (
            if area.logicalParentID!=owner.layerID or not area.isPaintArea do throw "Paint Area ownership is invalid; complete save was cancelled."
            if area.procRadiusIDs.count>0 or area.paintAreas.count>0 do throw ("Save Everything cannot yet export nested Paint/radius overrides in Paint Area: "+area.paintSetName)
            if area.paintDocument!=undefined and cyrusBrushTarget area.paintDocument!=area.areaTarget do throw "Paint document and area targets differ; complete save was cancelled."
            append areas (CyrusRecipeObject #(#("id",area.layerID),#("settings",CyrusRecipeCaptureSettings context area),#("receiverRole",CyrusRecipeRole context area.areaTarget "node" "paintReceiver"),#("paint",CyrusRecipeCapturePaint context area)))
        )
        append layers (CyrusRecipeObject #(#("id",owner.layerID),#("name",root.layerNames[index]),#("enabled",root.layerEnabled[index]),#("visible",root.layerVisible[index]),#("settings",CyrusRecipeCaptureSettings context owner),#("paint",CyrusRecipeCapturePaint context owner),#("areas",areas)))
    )
    for i=1 to root.procRuleA.count do (
        local a=undefined,b=undefined
        for owner in root.layerObjects do (if owner.layerID==root.procRuleA[i] do a=owner;if owner.layerID==root.procRuleB[i] do b=owner)
        if a==undefined or b==undefined do throw "A saved spacing relationship has a missing owner."
        if findItem owners a>0 or findItem owners b>0 do (
            local aid=if findItem owners a>0 then a.layerID else CyrusRecipeRole context a "layer" "spacing"
            local bid=if findItem owners b>0 then b.layerID else CyrusRecipeRole context b "layer" "spacing"
            append rules (CyrusRecipeObject #(#("scope",root.procRuleScope[i]),#("a",aid),#("b",bid),#("enabled",root.procRuleEnabled[i]),#("multiplier",root.procRuleMultiplier[i] as double),#("gap",(root.procRuleGapWU[i] as double)/context.metres),#("planar",root.procRulePlanar[i])))
        )
    )
    local document=CyrusRecipeObject #(#("format","cyrus.planting-recipe"),#("formatVersion",7),#("revision",1),#("presentation",undefined),#("evaluationContract","CyrusUnified1"),#("sceneSchema",58),#("hostYear",((maxVersion())[1]/1000+1998)),#("id",CyrusNewLayerID()),#("name",name),#("unitsPerMetre",context.metres),#("exportScope","complete-setup"),#("rootSettings",rootSettings),#("roles",context.roles),#("layers",layers),#("spacingRelationships",rules))
    CyrusRecipeCheckRoot root node
    for owner in owners where findItem root.layerObjects owner==0 do throw "A selected layer was removed during capture."
    cyrusRecipeValidate document
    if bindingResult!=undefined do for i=1 to context.roles.count do append bindingResult #((CyrusRecipeGet context.roles[i] "id"),context.values[i])
    document
)
fn CyrusRecipeResolve bindings identity = (
    if identity==undefined do return undefined
    for pair in bindings where pair[1]==identity do return pair[2]
    throw ("Bind required recipe role: "+identity)
)
fn CyrusRecipeValidateBindings root document bindings = (
    local roles=CyrusRecipeGet document "roles",metres=(units.decodeValue "1m") as double
    if bindings.count!=roles.count do throw "Resolve every dependency before importing."
    local seen=#()
    for pair in bindings do (if findItem seen pair[1]>0 do throw "Duplicate role binding.";append seen pair[1])
    for role in roles do (
        local identity=CyrusRecipeGet role "id",kind=CyrusRecipeGet role "kind",value=CyrusRecipeResolve bindings identity,purposes=CyrusRecipeGet role "purposes"
        if value==undefined do throw ("Missing dependency: "+CyrusRecipeGet role "name")
        case kind of (
            "node":(
                if not isValidNode value or classof value.baseObject==AminScatterObject do throw "Bind a valid scene object to this role."
                for purpose in purposes do (
                    if findItem #("surface","surfaceNodes","procReceiverNodes","paintReceiver") purpose>0 and superclassof value!=GeometryClass do throw "Receiver roles need mesh geometry."
                    if findItem #("areaNodes","patternPaths") purpose>0 and superclassof value!=Shape do throw "Path/Area roles need spline shapes."
                    if findItem #("areaAnalyzer","fallAnalyzer","analyzerNode") purpose>0 and not (CyrusAnalyzerFilter value) do throw "This role requires a Surface Analyzer."
                )
                local requirements=CyrusRecipeGet role "requirements"
                if requirements!=undefined do (
                    if not isProperty value #collectEnabled do throw "This role requires a Cyrus source container."
                    if abs(value.width/metres-(CyrusRecipeGet requirements "width"))>0.000001 or abs(value.length/metres-(CyrusRecipeGet requirements "length"))>0.000001 or value.collectEnabled!=(CyrusRecipeGet requirements "collectEnabled") or value.showLabel!=(CyrusRecipeGet requirements "showLabel") do throw "Source container settings differ from the saved role. Bind a compatible container."
                    local saved=for ref in (CyrusRecipeGet requirements "savedSources") collect (CyrusRecipeResolve bindings ref)
                    local actual=value.savedSources as array,same=saved.count==actual.count
                    if same do for i=1 to saved.count where saved[i]!=actual[i] do same=false
                    if not same do throw "Source container saved membership differs from the recipe."
                )
            )
            "texture":(if superclassof value!=textureMap do throw "This role requires a texture map.")
            "layer":(if root==undefined or findItem root.layerObjects value==0 do throw "External spacing roles require a layer in the destination setup. Include the partner when saving a new setup.")
        )
    )
    true
)
fn CyrusRecipeApplyValue bindings value kind metres = (
    case kind of (
        "node":(CyrusRecipeResolve bindings value)
        "texturemap":(CyrusRecipeResolve bindings value)
        "color":(color value[1] value[2] value[3])
        "worldunits":(value*metres)
        default:value
    )
)
fn CyrusRecipeApplySettings owner settings bindings variation:#new projectionRoot:undefined = (
    local metres=(units.decodeValue "1m") as double
    for field in (CyrusRecipeFields()) do (
        local key=field[1],kind=field[2],value=CyrusRecipeGet settings key
        if matchPattern kind pattern:"*tab" then (
            kind=substring kind 1 (kind.count-3)
            value=for entry in value collect (CyrusRecipeApplyValue bindings entry kind metres)
        ) else value=CyrusRecipeApplyValue bindings value kind metres
        setProperty owner (key as name) value
    )
    -- Recipe frames are saved in world coordinates. Scene layer offsets are
    -- relative to their destination Scatter, preserving both phase and ownership
    -- without moving the destination node or its existing layers.
    if projectionRoot!=undefined and owner.densityCoordinateMode==2 and owner.densityFrameBasis.count==9 do (
        local b=owner.densityFrameBasis,o=owner.densityFrameOriginWU
        local world=matrix3 [b[1],b[2],b[3]] [b[4],b[5],b[6]] [b[7],b[8],b[9]] [o[1],o[2],o[3]],transform=projectionRoot.objectTransform
        if abs(dot transform.row1 (cross transform.row2 transform.row3))<1e-12 do throw "Destination Scatter frame is singular."
        local offset=world*(inverse transform),values=#()
        for row=1 to 3 do join values #(offset[row].x,offset[row].y,offset[row].z)
        owner.densityFrameBasis=values;owner.densityFrameOriginWU=#(offset.row4.x,offset.row4.y,offset.row4.z)
    )
    -- Ownership is always fresh; saved random domains are an explicit choice.
    CyrusRemapLayerCorrespondence owner variation:variation
    owner.nextPathID=1;for value in owner.pathIDs do owner.nextPathID=amax owner.nextPathID (value+1)
    owner.nextBandID=1;for value in owner.strokeIDs do owner.nextBandID=amax owner.nextBandID (value+1)
    owner.fieldFalloff=false;owner.fieldBoundaries=false
    true
)
fn CyrusRecipeRestorePaint data target document packaged:false footprint:undefined = (
    if data==undefined do return undefined
    local unitsNow=(units.decodeValue "1m") as double,unitsSaved=CyrusRecipeGet document "unitsPerMetre"
    if footprint!=undefined do return (cyrusBrushPresetTransfer (CyrusRecipeGet data "payload") target (CyrusRecipeGet data "radius") (CyrusRecipeGet data "erase") unitsSaved unitsNow footprint)
    if packaged do return (cyrusBrushPresetRestore (CyrusRecipeGet data "payload") target (CyrusRecipeGet data "radius") (CyrusRecipeGet data "erase") (CyrusRecipeGet data "frame") (unitsNow/unitsSaved))
    if target!=undefined and abs(unitsNow-unitsSaved)>1e-9*(amax 1.0 (abs unitsSaved)) do throw "Native Paint requires its saved system-unit context. Original coverage is retained; use matching units before binding."
    cyrusBrushRecipeImport (CyrusRecipeGet data "payload") target (CyrusRecipeGet data "radius") (CyrusRecipeGet data "erase") (CyrusRecipeGet data "frame")
)

fn CyrusRecipeImport destination document bindings newSetup:false variation:#new prepareAssets:undefined packagedPaintReceivers:undefined paintFootprint:undefined calculate:false = (
    if findItem #(#same,#new) variation==0 do throw "Choose Saved or New variation."
    CyrusRequireAuthor()
    if theHold.Holding() do throw "Finish the current undoable operation before importing a recipe."
    if CyrusBrushSessionLayer!=undefined do throw "Stop the brush before importing a recipe."
    cyrusRecipeValidate document
    local node=if destination==undefined then undefined else CyrusRecipeOwnerNode destination
    if not newSetup do CyrusRecipeCheckRoot destination node
    if prepareAssets==undefined do CyrusRecipeValidateBindings (if newSetup then undefined else destination) document bindings
    local layers=CyrusRecipeGet document "layers"
    if (if newSetup then 0 else destination.layerObjects.count)+layers.count>10 do throw "Import exceeds the ten-population capacity."
    if cyrusRecipeImportWorkingBytes==undefined do throw "Recipe import needs the matching native memory-admission build. Restart Max with the complete package."
    if newSetup and cyrusRecipeTrackCreated==undefined do throw "New setup import needs the matching native cache-lifetime build. Restart Max with the complete package."
    local workingBytes=cyrusRecipeImportWorkingBytes document
    if heapFree<workingBytes do gc light:true
    if heapFree<workingBytes do throw "Recipe import needs more free MAXScript working memory to preserve Undo. Reduce the saved layer/Paint content or use a less loaded scene. No layers were added."
    local oldSuspended=CyrusPointSuspended,root=destination,createdNode=undefined,imported=#(),identityMap=#(),committed=false
    theHold.Begin();CyrusPointSuspended=true
    try (
        if packagedPaintReceivers!=undefined and not newSetup do cyrusPresetTrackPublication (join #(destination) (destination.layerObjects as array))
        if not newSetup do cyrusEditOwnerLayers (destination.procModifiers()) (for leaf in destination.layerObjects collect leaf.editLayerKey)
        with animate off (
            if prepareAssets!=undefined do (
                -- Only the trusted package command supplies this internal factory.
                -- Its created sources and the recipe share this single hold.
                local stage=prepareAssets[1]
                bindings=stage prepareAssets[2] bindings
                CyrusRecipeValidateBindings (if newSetup then undefined else destination) document bindings
            )
            if newSetup do (
                createdNode=AminScatterObject name:(CyrusRecipeGet document "name")
                root=createdNode.baseObject;node=createdNode;root.setLayerTransfer true
                cyrusRecipeTrackCreated root
                CyrusRecipeApplySettings root (CyrusRecipeGet document "rootSettings") bindings variation:variation projectionRoot:node
                root.layerID=CyrusNewLayerID();root.layerObjects=#();root.layerNames=#();root.layerEnabled=#();root.layerVisible=#()
            )
            for record in layers do (
                local owner=createInstance AminScatterObject
                cyrusRecipeTrackCreated owner
                owner.setLayerTransfer true;owner.layerID=CyrusNewLayerID();owner.logicalParentID="";owner.isPaintArea=false
                CyrusRecipeApplySettings owner (CyrusRecipeGet record "settings") bindings variation:variation projectionRoot:node
                owner.editLayerKey=root.nextEditLayerKey;root.nextEditLayerKey+=1
                owner.procOrder=root.layerObjects.count+imported.count+1;owner.procSetOrder=owner.procOrder
                owner.paintAreas=#()
                local paint=CyrusRecipeGet record "paint"
                local paintTarget=if paint==undefined then undefined else CyrusRecipeResolve bindings (CyrusRecipeGet paint "receiverRole")
                owner.paintDocument=CyrusRecipeRestorePaint paint paintTarget document packaged:(packagedPaintReceivers!=undefined and findItem packagedPaintReceivers paintTarget>0) footprint:paintFootprint
                for areaRecord in (CyrusRecipeGet record "areas") do (
                    local area=createInstance AminScatterObject
                    cyrusRecipeTrackCreated area
                    area.setLayerTransfer true;area.layerID=CyrusNewLayerID();area.logicalParentID=owner.layerID;area.isPaintArea=true
                    CyrusRecipeApplySettings area (CyrusRecipeGet areaRecord "settings") bindings variation:variation projectionRoot:node
                    area.areaTarget=CyrusRecipeResolve bindings (CyrusRecipeGet areaRecord "receiverRole")
                    local areaPaint=CyrusRecipeGet areaRecord "paint"
                    if areaPaint!=undefined and (CyrusRecipeResolve bindings (CyrusRecipeGet areaPaint "receiverRole"))!=area.areaTarget do throw "Paint document and area binding disagree."
                    area.paintDocument=CyrusRecipeRestorePaint areaPaint area.areaTarget document packaged:(packagedPaintReceivers!=undefined and findItem packagedPaintReceivers area.areaTarget>0) footprint:paintFootprint
                    area.setLayerTransfer false;append owner.paintAreas area
                    append identityMap #((CyrusRecipeGet areaRecord "id"),area)
                )
                owner.syncStrokes();owner.requireCurrentAnalyzers()
                if owner.meshMaskEnabled do for receiver in owner.validSurfaces() do cyrusMeshDensityKey receiver (owner.meshMaskPayload())
                owner.setOverlapOwner root;owner.setLayerTransfer false
                append imported owner;append identityMap #((CyrusRecipeGet record "id"),owner)
            )
            if not newSetup do CyrusRecipeCheckRoot destination node
            for i=1 to imported.count do (
                local record=layers[i],owner=imported[i],label=CyrusRecipeGet record "name",uniqueLabel=label,suffix=2
                while findItem root.layerNames uniqueLabel>0 do (uniqueLabel=label+" "+(suffix as string);suffix+=1)
                append root.layerObjects owner;append root.layerNames uniqueLabel
                append root.layerEnabled (CyrusRecipeGet record "enabled");append root.layerVisible (CyrusRecipeGet record "visible")
            )
            local endpoints=for pair in identityMap collect pair
            for pair in bindings do append endpoints pair
            local metres=(units.decodeValue "1m") as double
            for rule in (CyrusRecipeGet document "spacingRelationships") do root.procSetPair (CyrusRecipeGet rule "scope") (CyrusRecipeResolve endpoints (CyrusRecipeGet rule "a")) (CyrusRecipeResolve endpoints (CyrusRecipeGet rule "b")) (CyrusRecipeGet rule "enabled") (CyrusRecipeGet rule "multiplier") ((CyrusRecipeGet rule "gap")*metres) (CyrusRecipeGet rule "planar")
            root.activeLayer=findItem root.layerObjects imported[1]
            root.setLayerTransfer false;root.procValidate()
            if calculate do (
                -- Ready Load succeeds only after its first complete calculation.
                -- Keep that work inside this hold so a late failure rolls back
                -- assets, authored layers and the previous publication together.
                -- Calling the engine directly preserves its exceptions; the
                -- ordinary interactive refresh records errors in diagnostics.
                root.evaluateProcedural()
                root.procEnsureDisplay()
            )
        )
        theHold.Accept "Cyrus import recipe";committed=true
    )catch(
        local failure=getCurrentException()
        theHold.Cancel();CyrusPointSuspended=oldSuspended
        if newSetup and isValidNode createdNode do delete createdNode
        throw()
    )
    CyrusPointSuspended=oldSuspended
    if committed do (
        if not calculate do for owner in imported do owner.markInputDirty()
        root.bindNativeUI();CyrusViewportRedraw()
    )
    #(root,imported,node)
)

fn CyrusRecipeDirectory = (
    local folder=(dotNetClass "System.Environment").GetFolderPath ((dotNetClass "System.Environment+SpecialFolder").MyDocuments)
    pathConfig.appendPath folder "CyrusScatter\\Library"
)
fn CyrusRecipeViewPreferences = (pathConfig.appendPath (getDir #plugcfg) "CyrusScatter-Gallery.ini")
fn CyrusRecipeBundledDirectory version = (pathConfig.appendPath CyrusRecipeScriptDirectory ("Library-"+version))
fn CyrusRecipeSuggestBindings root document = (
    local bindings=#()
    for role in (CyrusRecipeGet document "roles") do (
        local kind=CyrusRecipeGet role "kind",label=CyrusRecipeGet role "name",candidates=#()
        case kind of (
            "node":(candidates=for node in objects where node.name==label and classof node.baseObject!=AminScatterObject collect node)
            "layer":(for i=1 to root.layerObjects.count where root.layerNames[i]==label do append candidates root.layerObjects[i])
            "texture":(for owner in (join #(root) (root.layerObjects as array)) where owner.densityMap!=undefined and owner.densityMap.name==label do appendIfUnique candidates owner.densityMap)
        )
        append bindings #((CyrusRecipeGet role "id"),(if candidates.count==1 then candidates[1] else undefined))
    )
    bindings
)
fn CyrusRecipeIsBundled path version = (
    local io=dotNetClass "System.IO.Path",file=toLower (io.GetFullPath path),bundle=toLower (io.GetFullPath (CyrusRecipeBundledDirectory version))
    matchPattern file pattern:(bundle+"\\*")
)
fn CyrusRecipeEditDetails path expected version = (
    CyrusRequireAuthor()
    if CyrusRecipeIsBundled path version do throw "Bundled examples are read-only. Save a copy in My recipes first."
    local summary=cyrusRecipeInfo path
    if summary[11]!=expected do throw "Recipe changed. Refresh the library before editing its details."
    local saved=cyrusRecipeReadMetadata path,presentation=CyrusRecipeGet saved "presentation"
    local imagePath=if summary[12] then cyrusRecipeThumbnail path else "",capture=if presentation==undefined then undefined else CyrusRecipeGet presentation "capture"
    if CyrusRecipeDetailEditor!=undefined do try(destroyDialog CyrusRecipeDetailEditor)catch()
    rollout editor "Edit saved recipe details" width:430 height:370 (
        local path="",expected="",imagePath="",capture=undefined
        label identity "" pos:[12,10] width:406 height:40
        edittext savedName "Name:" pos:[12,56] width:406
        edittext savedCategory "Category:" pos:[12,88] width:406
        edittext savedTags "Tags:" pos:[12,120] width:406
        edittext savedDescription "Description:" pos:[12,152] width:406 height:76
        label note "Changes only the saved name/tags/description. Layer settings, Paint and scene objects are retained." pos:[12,238] width:406 height:44
        button commitDetails "Save details" pos:[12,288] width:196
        button closeDetails "Close" pos:[220,288] width:198
        label detailStatus "" pos:[12,322] width:406 height:40
        on editor open do (
            local data=CyrusRecipeDetailOpenData,summary=data[3]
            path=data[1];expected=data[2];imagePath=data[4];capture=data[5]
            identity.text=filenameFromPath path+" | revision "+((summary[15] as integer) as string)
            savedName.text=summary[1];savedCategory.text=summary[5];savedDescription.text=summary[7]
            local tags="";for tag in summary[6] do tags+=(if tags=="" then tag else ", "+tag)
            savedTags.text=tags
        )
        on commitDetails pressed do try (
            if CyrusPresetReviseEditor!=undefined do throw "Wait for the current preset revision to finish before saving details again."
            local tags=#()
            for value in filterString savedTags.text "," do (local tag=trimRight (trimLeft value);if tag!="" do appendIfUnique tags tag)
            local metadata=CyrusRecipeObject #(#("category",trimRight (trimLeft savedCategory.text)),#("tags",tags),#("description",savedDescription.text))
            local previous=expected
            expected=cyrusRecipeEntryWrite path (CyrusRecipeObject #(#("name",trimRight (trimLeft savedName.text)))) metadata imagePath capture expected true
            CyrusPresetReviseReady path previous expected
            -- The previous image path remains immutable and readable across revisions.
            local summary=cyrusRecipeInfo path
            identity.text=filenameFromPath path+" | revision "+((summary[15] as integer) as string)
            detailStatus.text="Saved details. Previous revision retained; Paint was not hydrated."
            if CyrusRecipeBrowser!=undefined do try(CyrusRecipeBrowser.refreshEntry path)catch(detailStatus.text+=" Refresh the browser to see the change.")
        )catch(detailStatus.text=getCurrentException())
        on closeDetails pressed do destroyDialog editor
        on editor close do CyrusRecipeDetailEditor=undefined
    )
    CyrusRecipeDetailOpenData=#(path,expected,summary,imagePath,capture);CyrusRecipeDetailEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)

global CyrusRecipeSaveEditor,CyrusRecipeSaveOpenData,CyrusOpenRecipeSave,CyrusRecipeLoadEditor,CyrusRecipeLoadOpenData,CyrusOpenRecipeLoad
fn CyrusOpenRecipeSave root directory path:"" expected:"" = (
    local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    CyrusRequireAuthor()
    if path!="" and (cyrusRecipeInfo path)[11]!=expected do throw "Recipe changed. Refresh before updating it."
    if path!="" and CyrusRecipeIsBundled path (root.uiVersion()) do throw "Bundled examples are read-only. Save a copy in My recipes."
    if CyrusRecipeSaveEditor!=undefined do try(destroyDialog CyrusRecipeSaveEditor)catch()
    rollout editor "Save planting recipe" width:440 height:590 (
        local root,node,owners=#(),directory="",reviewPath="",reviewHash="",thumbnailFile="",thumbnailCapture=undefined,ownedCapture="",captureBindings=#()
        label title "Save selected layers, their settings and Paint" pos:[12,12] width:416
        multiListBox saveLayers "Layers - evaluation order" pos:[12,38] width:416 height:5
        edittext recipeName "Name:" pos:[12,142] width:416
        edittext recipeCategory "Collection:" pos:[12,173] width:416
        edittext recipeTags "Tags:" pos:[12,204] width:416 tooltip:"Separate tags with commas."
        edittext recipeDescription "Description:" pos:[12,235] width:416 height:66
        button chooseThumbnail "Use PNG thumbnail..." pos:[12,314] width:280
        button clearThumbnail "Clear" pos:[304,314] width:124
        button captureThumbnail "Capture viewport" pos:[12,348] width:202 tooltip:"Capture published plants without recalculating. Update pending settings first."
        button updateCapture "Update + capture" pos:[226,348] width:202 tooltip:"Explicitly update the Scatter setup, then capture the active viewport."
        label thumbnailInfo "Optional PNG, up to 1024 px and 2 MiB" pos:[12,384] width:416 height:40
        label saveNote "Complete settings and Paint are saved. Include assets for a preset that loads without model picking." pos:[12,429] width:416 height:28
        checkbox readyPreset "Include models, materials, terrain and paths" pos:[12,461] width:416 checked:true tooltip:"Save a ready-to-use preset. Static supported assets are packaged with complete Paint. Uncheck for a settings-only recipe with external bindings."
        button saveRecipe "Save new copy" pos:[12,482] width:132
        button updateRecipe "Update selected" pos:[154,482] width:132 enabled:false
        button closeButton "Close" pos:[296,482] width:132
        label status "" pos:[12,524] width:416 height:56
        fn validRoot = (CyrusRecipeCheckRoot root node)
        fn captureSelection = (
            validRoot();local selected=for i in saveLayers.selection where i<=owners.count collect owners[i]
            captureBindings=#()
            CyrusRecipeCapture root selected (trimRight (trimLeft recipeName.text)) bindingResult:captureBindings
        )
        fn metadataValues = (
            local tags=#()
            for value in filterString recipeTags.text "," do (
                local tag=trimRight (trimLeft value)
                if tag!="" do appendIfUnique tags tag
            )
            CyrusRecipeObject #(#("category",trimRight (trimLeft recipeCategory.text)),#("tags",tags),#("description",recipeDescription.text))
        )
        fn capturePreview updateFirst = (
            validRoot();local selected=for i in saveLayers.selection where i<=owners.count collect owners[i]
            if selected.count==0 do throw "Select layers to capture."
            if updateFirst do root.refreshAll()
            if root.groupSnapshotKey=="" or root.groupSnapshotKey!=root.procInputKey() do throw "Settings are pending. Use Update + capture, or Update scatter first."
            if node.isHidden do throw "Show this Scatter setup before capturing its viewport preview."
            local published=#()
            for owner in selected do (
                local index=findItem root.procPublishedOwners owner,slot=findItem root.layerObjects owner
                if index==0 or index>root.groupSnapshotRows.count do throw "A selected layer has no published result. Update first."
                if not (root.enabledLayer slot) or not (root.visibleLayer slot) do throw "Enable and show all selected layers before capturing."
                append published root.groupSnapshotRows[index]
            )
            if (for rows in published where rows.count>0 collect rows).count==0 do throw "The selected layers contain no published plants."
            local data=captureSelection(),authored=cyrusRecipeContentFingerprint data,publishedHash=cyrusRecipePublicationFingerprint published
            local viewportImage=undefined,small=undefined,newPath=pathConfig.appendPath (getDir #temp) ("CyrusCapture-"+CyrusNewLayerID()+".png")
            try (
                completeRedraw()
                viewportImage=viewport.getViewportDib captureAlpha:false gammaCorrect:true
                local ratio=amin 1.0 (512.0/(amax viewportImage.width viewportImage.height))
                small=bitmap (amax 1 ((viewportImage.width*ratio) as integer)) (amax 1 ((viewportImage.height*ratio) as integer)) filename:newPath
                copy viewportImage small
                if not (save small) do throw "Could not save the captured thumbnail."
                close small;small=undefined;close viewportImage;viewportImage=undefined
                if cyrusRecipeContentFingerprint (captureSelection())!=authored do throw "Settings changed while capturing. Capture again."
                if ownedCapture!="" do deleteFile ownedCapture
                ownedCapture=newPath;thumbnailFile=newPath
                thumbnailCapture=CyrusRecipeObject #(#("method","viewport-published"),#("authoredSHA256",authored),#("publicationSHA256",publishedHash),#("view",((viewport.getType()) as string)+" | "+((viewport.getTM()) as string)),#("capturedUTC",((dotNetClass "System.DateTime").UtcNow.ToString "o")))
                thumbnailInfo.text="Captured current viewport; Save to attach it."
                status.text="Captured published plants. Camera, selection and rendering settings were retained."
            )catch(
                if small!=undefined do close small
                if viewportImage!=undefined do close viewportImage
                if doesFileExist newPath do deleteFile newPath
                throw()
            )
        )

        fn saveEntry updating = (
            validRoot()
            if updating and (reviewPath=="" or reviewHash=="") do throw "Choose a saved recipe to update."
            local data=captureSelection(),path=if updating then reviewPath else pathConfig.appendPath directory ((CyrusRecipeGet data "id")+".csrecipe.json")
            local digest=cyrusRecipeEntryWrite path data (metadataValues()) thumbnailFile thumbnailCapture (if updating then reviewHash else "") false
            if updating do reviewHash=digest
            status.text=if updating then "Updated recipe and Paint. Previous revision retained." else "Saved new recipe and Paint. Models and terrain require binding on load."
            if readyPreset.checked do (
                status.text="Settings and Paint saved. Packaging the preset assets..."
                CyrusPresetSaveReady root path digest captureBindings
            )
            if CyrusRecipeBrowser!=undefined do try(CyrusRecipeBrowser.refreshEntry path)catch(status.text+=" Refresh the library to see it.")
            path
        )
        on editor open do (
            root=CyrusRecipeSaveOpenData[1];node=CyrusRecipeSaveOpenData[2];directory=CyrusRecipeSaveOpenData[3]
            reviewPath=CyrusRecipeSaveOpenData[4];reviewHash=CyrusRecipeSaveOpenData[5]
            owners=root.logicalLayers();saveLayers.items=for owner in owners collect root.layerCaption owner
            saveLayers.selection=if owners.count>0 then #{1..owners.count} else #{};recipeName.text="Planting setup"
            updateRecipe.enabled=reviewPath!=""
            if reviewPath!="" do (
                local info=cyrusRecipeInfo reviewPath,document=cyrusRecipeReadMetadata reviewPath,presentation=CyrusRecipeGet document "presentation"
                recipeName.text=info[1];recipeCategory.text=info[5];recipeDescription.text=info[7]
                local tags="";for value in info[6] do tags+=(if tags=="" then value else ", "+value)
                recipeTags.text=tags
                if info[12] do (thumbnailFile=cyrusRecipeThumbnail reviewPath;thumbnailInfo.text="Existing preview. Capture again if the scene settings changed.")
                if presentation!=undefined do thumbnailCapture=CyrusRecipeGet presentation "capture"
            )
        )
        on saveRecipe pressed do try(saveEntry false)catch(status.text=getCurrentException())
        on updateRecipe pressed do try(saveEntry true)catch(status.text=getCurrentException())
        on captureThumbnail pressed do try(capturePreview false)catch(status.text=getCurrentException())
        on updateCapture pressed do try(capturePreview true)catch(status.text=getCurrentException())
        on chooseThumbnail pressed do (
            local path=getOpenFileName caption:"Choose an actual preset preview" types:"PNG image (*.png)|*.png|"
            if path!=undefined do (thumbnailFile=path;thumbnailCapture=undefined;thumbnailInfo.text="External PNG: "+filenameFromPath path)
        )
        on clearThumbnail pressed do (thumbnailFile="";thumbnailCapture=undefined;thumbnailInfo.text="No thumbnail")
        on closeButton pressed do destroyDialog editor
        on editor close do (if ownedCapture!="" do deleteFile ownedCapture;CyrusRecipeSaveEditor=undefined)
    )
    CyrusRecipeSaveOpenData=#(root,node,directory,path,expected);CyrusRecipeSaveEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)
fn CyrusOpenRecipeLoad root path expected = (
    local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if (cyrusRecipeInfo path)[11]!=expected do throw "Recipe changed. Refresh before loading it."
    local document=cyrusRecipeRead path
    if (cyrusRecipeInfo path)[11]!=expected do throw "Recipe changed while reading. Refresh before loading it."
    if CyrusRecipeLoadEditor!=undefined do try(destroyDialog CyrusRecipeLoadEditor)catch()
    rollout editor "Load planting recipe - review bindings" width:650 height:440 (
        local root,node,document,bindings=#(),layerChoices=#(),bindingControls=false,reviewPath="",reviewHash=""
        label title "" pos:[12,12] width:626 height:42
        button suggestButton "Match unique scene names" pos:[12,62] width:260
        listbox roleList "Terrain and model roles" pos:[12,101] width:626 height:7
        pickbutton bindNode "Pick scene object..." pos:[12,250] width:195 autoDisplay:false
        mapbutton bindMap "Pick texture..." pos:[219,250] width:195
        dropdownlist bindLayer "Layer:" items:#() pos:[426,246] width:212
        checkbox newSetupCheck "New setup" pos:[12,294] width:220
        dropdownlist importVariation items:#("New variation","Saved variation") selection:1 pos:[330,288] width:308
        button importButton "Add layers" pos:[12,328] width:300 enabled:false
        button closeButton "Close" pos:[330,328] width:308
        label status "Review every binding. Paint requires compatible geometry, frame and saved system units." pos:[12,372] width:626 height:56
        fn validRoot = (CyrusRecipeCheckRoot root node)
        fn selectedRole = (local index=roleList.selection;if document==undefined or index<1 or index>bindings.count then 0 else index)
        fn bindControls = (
            bindingControls=true
            local index=selectedRole(),kind=if index==0 then "" else CyrusRecipeGet (CyrusRecipeGet document "roles")[index] "kind"
            bindNode.enabled=kind=="node";bindMap.enabled=kind=="texture";bindLayer.enabled=kind=="layer"
            bindMap.map=if index>0 and kind=="texture" then bindings[index][2] else undefined
            bindingControls=false
        )
        fn showBindings = (
            local selected=roleList.selection,roles=CyrusRecipeGet document "roles"
            roleList.items=for i=1 to roles.count collect ((CyrusRecipeGet roles[i] "name")+" ["+(CyrusRecipeGet roles[i] "kind")+"] -> "+(if bindings[i][2]==undefined then "UNBOUND" else if (CyrusRecipeGet roles[i] "kind")=="layer" then root.layerCaption bindings[i][2] else bindings[i][2].name))
            roleList.selection=if roles.count==0 then 0 else amax 1 (amin roles.count selected)
            layerChoices=root.layerObjects as array;bindLayer.items=root.layerNames as array
            importButton.enabled=true;bindControls()
        )

        on editor open do (
            root=CyrusRecipeLoadOpenData[1];node=CyrusRecipeLoadOpenData[2];reviewPath=CyrusRecipeLoadOpenData[3];reviewHash=CyrusRecipeLoadOpenData[4];document=CyrusRecipeLoadOpenData[5]
            title.text=(CyrusRecipeGet document "name")+" | "+((CyrusRecipeGet document "layers").count as string)+" layers"
            bindings=for role in (CyrusRecipeGet document "roles") collect #((CyrusRecipeGet role "id"),undefined)
            showBindings()
        )
        on suggestButton pressed do try(validRoot();if document==undefined do throw "Review a recipe first.";bindings=CyrusRecipeSuggestBindings root document;showBindings())catch(status.text=getCurrentException())
        on roleList selected i do bindControls()
        on bindNode picked value do try(validRoot();local index=selectedRole();if index>0 do (bindings[index][2]=value;showBindings()))catch(status.text=getCurrentException())
        on bindMap picked value do if not bindingControls do try(validRoot();local index=selectedRole();if index>0 do (bindings[index][2]=value;showBindings()))catch(status.text=getCurrentException())
        on bindLayer selected i do try(validRoot();local index=selectedRole();if index>0 and i>0 and i<=layerChoices.count do (bindings[index][2]=layerChoices[i];showBindings()))catch(status.text=getCurrentException())
        on importButton pressed do try(
            validRoot();if document==undefined do throw "Review a recipe first."
            if (cyrusRecipeInfo reviewPath)[11]!=reviewHash do throw "The saved recipe changed. Close this review and load it again."
            local result=CyrusRecipeImport root document bindings newSetup:newSetupCheck.checked variation:(if importVariation.selection==2 then #same else #new)
            status.text=if result[1].updateMode==1 then "Imported as one Undo. Manual mode: Update scatter to calculate." else "Imported as one Undo. Live follows relevant changes."
        )catch(status.text=getCurrentException())
        on newSetupCheck changed value do importButton.text=if value then "Create new setup" else "Add layers"

        on closeButton pressed do destroyDialog editor
        on editor close do CyrusRecipeLoadEditor=undefined
    )
    CyrusRecipeLoadOpenData=#(root,node,path,expected,document);CyrusRecipeLoadEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)

-- Selective reuse projects a complete recipe onto explicit setting groups. It
-- never reads Paint payloads, replaces source/receiver arrays, or changes IDs.
global CyrusStylePlan,CyrusStyleFields,CyrusStyleSnapshot,CyrusStyleSettings,CyrusStylePrepare,CyrusStyleCommit,CyrusOpenRecipeStyle,CyrusStyleEditor,CyrusStyleOpenData,CyrusStyleCheckBounds,CyrusStyleCheckCurves,CyrusStyleCheckGraph,CyrusFallUnpack
struct CyrusStylePlan (root,node,owner,ownerID,path,digest,recordID,groups,seedPolicy,values,previous,controllers,inputKey,changed)
fn CyrusStyleCheckBounds owner = (
    local total=0
    for field in CyrusRecipeFields() where matchPattern field[2] pattern:"*tab" do (
        local value=getProperty owner (field[1] as name)
        if value.count>65536 do throw "A destination setting array exceeds the style limit."
        total+=value.count
        if total>262144 do throw "Destination setting arrays exceed the bounded style budget."
    )
    true
)
fn CyrusStyleCheckGraph samples packed multiplier = (
    if packed.count==0 do return true
    -- Evaluate with Max's own curve control, matching the authored graph editor.
    -- This detached hidden control never edits or closes an artist's open graph.
    rollout witness "Cyrus curve validation" width:32 height:32 (
        curveControl graph "" width:32 height:32 numCurves:1 x_range:[0,1] y_range:[0,100] asPopup:false
    )
    try (
        createDialog witness hidden:true
        undo off (
            local curve=witness.graph.curves[1]
            curve.numPoints=packed.count/8
            for i=1 to curve.numPoints do (
                local point=curve.points[i],j=(i-1)*8
                point.value=[packed[j+1],packed[j+2]];point.inTangent=[packed[j+3],packed[j+4]];point.outTangent=[packed[j+5],packed[j+6]]
                point.bezier=packed[j+7]>0;point.corner=packed[j+8]>0
                point.lock_x=(i==1 or i==curve.numPoints);curve.points[i]=point
            )
            for i=0 to 256 do (
                local actual=amax 0.0 ((getValue curve 0 (i/256.0))/100.0)
                if not multiplier do actual=amin 1.0 actual
                local position=i*(samples.count-1)/256.0,lo=(floor position) as integer,hi=amin (samples.count-1) (lo+1)
                local expected=samples[lo+1]+(samples[hi+1]-samples[lo+1])*(position-lo)
                if abs(actual-expected)>0.0001*(amax 1.0 (abs expected)) do throw "Recipe graph handles do not match its sampled curve. Resave it from a valid graph."
            )
        )
        destroyDialog witness
    )catch(try(destroyDialog witness)catch();throw())
    true
)
fn CyrusStyleCheckCurves owner values = (
    for fields in #(#("meshMaskSamples","meshMaskGraph","density_curve",false),#("fallDensityCurve","fallDensityGraph","density_curve",false),#("fallScaleCurve","fallScaleGraph","scale_curve",true)) do (
        local samples=undefined,graph=""
        for pair in values do (if pair[1]==fields[1] do samples=pair[2];if pair[1]==fields[2] do graph=pair[2])
        if samples!=undefined do (
            if samples.count==0 do samples=if fields[1]=="meshMaskSamples" then #(0.0,1.0) else #(1.0,1.0)
            local packed=CyrusFallUnpack graph
            cyrusPresetEncode fields[3] "Recipe style curve" #(samples,packed,fields[4])
            CyrusStyleCheckGraph samples packed fields[4]
        )
    )
    true
)
fn CyrusStyleFields group = (
    case group of (
        "Amount":#("amount","populationMode","plantsPerM2","procPopulation","procAttemptFactor","procRounds","procRepair")
        "Grid layout":#("placementMode","gridColumnWU","gridRowWU","gridOriginXWU","gridOriginYWU","gridHeading","gridJitter")
        "Transforms":(join (for field in cyrusPresetSchema "transforms" collect field[1]) #("orientationTarget"))
        "Slope and altitude":#("slopeEnabled","slopeMinimum","slopeMaximum","slopeLowerFade","slopeUpperFade","altitudeEnabled","altitudeMinimum","altitudeMaximum","altitudeLowerFade","altitudeUpperFade")
        "Surface density":#("meshMaskSource","meshMaskEnabled","meshMaskChannel","meshMaskComponent","meshMaskMinimum","meshMaskMaximum","meshMaskInvert","meshMaskSamples","meshMaskGraph")
        "Density texture":(join #("distributionMode","densityMap","invertDensity","densityUVChannel","densityResolution") (for key in AminScatterImageDensityFields collect key as string))
        "Area falloff":#("fallAnalyzer","fallDelete","fallDeleteWidth","fallScale","fallScaleWidth","fallScaleCurve","fallScaleGraph","fallDensity","fallDensityWidth","fallDensityCurve","fallDensityGraph")
        default:throw "Unsupported style group."
    )
)
fn CyrusStyleSnapshot owner = (
    CyrusStyleCheckBounds owner
    for field in CyrusRecipeFields() collect (
        local value=getProperty owner (field[1] as name)
        if matchPattern field[2] pattern:"*tab" do value=value as array
        value
    )
)
fn CyrusStyleSettings root owner values = (
    CyrusStyleCheckBounds owner
    local context=CyrusRecipeCaptureContext root:root node:(CyrusRecipeOwnerNode root) owners:#(owner) metres:((units.decodeValue "1m") as double),pairs=#()
    for field in CyrusRecipeFields() do (
        local key=field[1],kind=field[2],value=getProperty owner (key as name)
        if key=="procReceiverVariationIDs" do value=CyrusReceiverVariationDomains owner
        for pair in values where pair[1]==key do value=pair[2]
        if matchPattern kind pattern:"*tab" then (
            kind=substring kind 1 (kind.count-3)
            value=for item in value collect (CyrusRecipeCaptureValue context item kind key)
        ) else value=CyrusRecipeCaptureValue context value kind key
        append pairs #(key,value)
    )
    CyrusRecipeObject pairs
)
fn CyrusStylePrepare root owner path digest recordID groups bindings seedPolicy:#current = (
    CyrusRequireAuthor();local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if cyrusRecipeStyleValidate==undefined do throw "Apply Style requires the matching complete Cyrus 0.86.6.1 package."
    if owner==undefined or owner.isPaintArea or findItem root.layerObjects owner==0 do throw "Choose a current logical destination layer."
    if groups.count==0 do throw "Select at least one setting group."
    if findItem #(#current,#saved,#new) seedPolicy==0 do throw "Choose Keep, Saved or New seeds."
    if CyrusBrushSessionLayer!=undefined do throw "Stop the brush before reviewing a style."
    cyrusRecipeCheckStatic owner
    for edit in root.procModifiers() where cyrusEditRecipeHasData edit do throw "Apply Style currently requires a setup without authored Scatter Edit records. The existing edits are preserved."
    for member in (join #(owner) (owner.paintAreas as array)) where member.procRadiusIDs.count>0 do throw "Apply Style currently requires a destination without per-instance radius overrides. Existing overrides are preserved."
    if (cyrusRecipeInfo path)[11]!=digest do throw "The recipe changed. Refresh and review it again."
    local document=cyrusRecipeReadMetadata path,record=undefined
    for layer in (CyrusRecipeGet document "layers") where (CyrusRecipeGet layer "id")==recordID do record=layer
    if record==undefined do throw "The saved layer was removed from the recipe."
    local settings=CyrusRecipeGet record "settings",fields=#(),values=#(),controllers=#(),metres=(units.decodeValue "1m") as double,schema=CyrusRecipeFields()
    for group in groups do for key in CyrusStyleFields group do appendIfUnique fields key
    if seedPolicy!=#current do join fields #("randomSeed","procSamplingSalt","diversitySeed")
    for key in fields do (
        local spec=undefined;for field in schema where field[1]==key do spec=field
        if spec==undefined do throw ("Unsupported style field: "+key)
        local kind=spec[2],value=CyrusRecipeGet settings key,roleID=undefined
        if findItem #("node","texturemap") kind>0 do roleID=value
        if matchPattern kind pattern:"*tab" then (
            kind=substring kind 1 (kind.count-3)
            value=for item in value collect (CyrusRecipeApplyValue bindings item kind metres)
        ) else value=CyrusRecipeApplyValue bindings value kind metres
        if roleID!=undefined and value==undefined do throw ("Bind the selected setting's dependency: "+key)
        if findItem #("node","texturemap") kind>0 and value!=undefined do (
            if kind=="node" and (not isValidNode value or classof value.baseObject==AminScatterObject) do throw "Bind a valid scene object for the selected setting."
            if key=="fallAnalyzer" and not (CyrusAnalyzerFilter value) do throw "Area falloff requires a Surface Analyzer binding."
            if kind=="texturemap" and superclassof value!=TextureMap do throw "Bind a texture map for the density role."
        )
        if seedPolicy==#new and findItem #("randomSeed","procSamplingSalt","diversitySeed") key>0 do (
            local identity=(dotNetClass "System.Guid").NewGuid();value=bit.and (identity.GetHashCode()) 2147483647
            if value==getProperty owner (key as name) do value=if value==2147483647 then 0 else value+1
        )
        append values #(key,value)
        if findItem #("float","worldunits","integer") spec[2]>0 do (
            local control=getPropertyController owner (key as name)
            if control!=undefined do append controllers #(key,control)
        )
    )
    CyrusStyleCheckCurves owner values
    cyrusRecipeStyleValidate owner (CyrusStyleSettings root owner values) fields
    -- Capture the reviewed proposal, not a live selection or a deferred random draw.
    local changed=#()
    for pair in values do (
        local old=getProperty owner (pair[1] as name)
        if classof pair[2]==Array do old=old as array
        if not (CyrusPresetSameValues old pair[2]) do append changed pair[1]
    )
    if (cyrusRecipeInfo path)[11]!=digest do throw "The recipe changed while reviewing. Refresh and review again."
    CyrusStylePlan root:root node:node owner:owner ownerID:owner.layerID path:path digest:digest recordID:recordID groups:(deepCopy groups) seedPolicy:seedPolicy values:values previous:(CyrusStyleSnapshot owner) controllers:controllers inputKey:(root.procInputKey()) changed:changed
)
fn CyrusStyleCommit plan = (
    CyrusRequireAuthor()
    if theHold.Holding() do throw "Finish the current Undo operation before applying a style."
    CyrusRecipeCheckRoot plan.root plan.node
    if findItem plan.root.layerObjects plan.owner==0 or plan.owner.layerID!=plan.ownerID do throw "The reviewed layer was removed or replaced."
    if (cyrusRecipeInfo plan.path)[11]!=plan.digest do throw "The recipe changed. Review the new version before applying."
    if not (CyrusPresetSameValues (CyrusStyleSnapshot plan.owner) plan.previous) or plan.root.procInputKey()!=plan.inputKey do throw "The destination changed after review. Review the style again."
    cyrusRecipeCheckStatic plan.owner
    for pair in plan.controllers where (getPropertyController plan.owner (pair[1] as name))!=pair[2] do throw "A destination controller changed. Review again."
    CyrusStyleCheckCurves plan.owner plan.values
    cyrusRecipeStyleValidate plan.owner (CyrusStyleSettings plan.root plan.owner plan.values) (for pair in plan.values collect pair[1])
    if plan.changed.count==0 do return false
    local oldTransfer=plan.owner.getLayerTransfer(),oldSuspended=CyrusPointSuspended
    theHold.Begin();CyrusPointSuspended=true;plan.owner.setLayerTransfer true
    try (
        with animate off (
            for pair in plan.controllers where findItem plan.changed pair[1]>0 do setPropertyController plan.owner (pair[1] as name) (copy pair[2])
            for pair in plan.values where findItem plan.changed pair[1]>0 do setProperty plan.owner (pair[1] as name) pair[2]
            plan.root.procValidate()
        )
        plan.owner.setLayerTransfer oldTransfer;CyrusPointSuspended=oldSuspended
        theHold.Accept "Cyrus apply style"
    )catch(
        theHold.Cancel();plan.owner.setLayerTransfer oldTransfer;CyrusPointSuspended=oldSuspended;throw()
    )
    plan.owner.markInputDirty();plan.root.bindNativeUI();CyrusViewportRedraw();true
)
fn CyrusOpenRecipeStyle root path digest = (
    local node=CyrusRecipeOwnerNode root,owner=root.selectedLayer()
    CyrusRecipeCheckRoot root node
    if owner==undefined do throw "Select a destination layer first."
    if (cyrusRecipeInfo path)[11]!=digest do throw "Recipe changed. Refresh before applying its style."
    local document=cyrusRecipeReadMetadata path
    if CyrusStyleEditor!=undefined do try(destroyDialog CyrusStyleEditor)catch()
    rollout editor "Apply recipe style" width:660 height:650 (
        local root,node,owner,path,digest,document,records=#(),roles=#(),bindings=#(),plan=undefined,bindingControls=false,bindControls
        label destination "" pos:[12,12] width:636 height:32
        dropdownlist sourceLayer "Saved layer:" items:#() pos:[12,50] width:636
        multiListBox groups "Setting groups" items:#("Amount","Grid layout","Transforms","Slope and altitude","Surface density","Density texture","Area falloff") pos:[12,106] width:290 height:7
        label retained "Keep: terrain, models, Paint, layer order, Bands, spacing relationships and source/receiver identities.\n\nOnly selected setting groups change. Static destination layers are supported." pos:[322,122] width:326 height:136
        dropdownlist seeds "Seeds:" items:#("Keep destination seeds","Use saved seeds","Choose new seeds") selection:1 pos:[12,266] width:636
        label seedsNote "Seed choices cover sampling and model-assignment seeds. Receiver variation domains stay with the destination." pos:[12,316] width:636 height:36
        listbox roleList "Explicit bindings used by selected groups" items:#() pos:[12,362] width:636 height:4
        pickbutton bindNode "Bind scene object..." pos:[12,458] width:308 autoDisplay:false enabled:false
        mapbutton bindMap "Bind texture..." pos:[340,458] width:308 enabled:false
        button review "Review changes" pos:[12,500] width:202
        button applyStyle "Apply Style" pos:[228,500] width:202 enabled:false
        button closeButton "Close" pos:[446,500] width:202
        label status "Review before applying. Existing authored Edit/radius records and controlled curve arrays are protected." pos:[12,542] width:636 height:96
        fn clearPlan = (plan=undefined;applyStyle.enabled=false)
        fn showRoles = (
            clearPlan();roles=#();bindings=#()
            if sourceLayer.selection<1 do return false
            local settings=CyrusRecipeGet records[sourceLayer.selection] "settings",keys=#(),allRoles=CyrusRecipeGet document "roles"
            for index in groups.selection do for key in CyrusStyleFields groups.items[index] do appendIfUnique keys key
            for field in CyrusRecipeFields() where findItem keys field[1]>0 and findItem #("node","texturemap") field[2]>0 do (
                local id=CyrusRecipeGet settings field[1]
                if id!=undefined do for role in allRoles where (CyrusRecipeGet role "id")==id do (
                    if (findItem (for pair in bindings collect pair[1]) id)==0 do (append roles role;append bindings #(id,undefined))
                )
            )
            roleList.items=for role in roles collect ((CyrusRecipeGet role "name")+" - UNBOUND")
            roleList.selection=if roles.count>0 then 1 else 0
            bindControls();true
        )
        fn bindControls = (
            bindingControls=true;local i=roleList.selection,kind=if i<1 or i>roles.count then "" else CyrusRecipeGet roles[i] "kind"
            bindNode.enabled=kind=="node";bindMap.enabled=kind=="texture"
            bindMap.map=if kind=="texture" then bindings[i][2] else undefined
            bindingControls=false
        )
        fn bound value = (
            local i=roleList.selection;if i>0 and i<=bindings.count do (
                bindings[i][2]=value
                roleList.items=for j=1 to roles.count collect ((CyrusRecipeGet roles[j] "name")+" - "+(if bindings[j][2]==undefined then "UNBOUND" else bindings[j][2].name))
                roleList.selection=i;clearPlan()
            )
        )
        on editor open do (
            root=CyrusStyleOpenData[1];node=CyrusStyleOpenData[2];owner=CyrusStyleOpenData[3];path=CyrusStyleOpenData[4];digest=CyrusStyleOpenData[5];document=CyrusStyleOpenData[6]
            destination.text="Destination: "+root.layerCaption owner
            records=CyrusRecipeGet document "layers";sourceLayer.items=for record in records collect CyrusRecipeGet record "name";sourceLayer.selection=1
            groups.selection=#{1};showRoles()
        )
        on sourceLayer selected i do showRoles()
        on groups selectionEnd do showRoles()
        on seeds selected i do clearPlan()
        on roleList selected i do bindControls()
        on bindNode picked value do bound value
        on bindMap picked value do if not bindingControls do bound value
        on review pressed do try (
            local selected=for index in groups.selection collect groups.items[index]
            plan=CyrusStylePrepare root owner path digest (CyrusRecipeGet records[sourceLayer.selection] "id") selected bindings seedPolicy:((#(#current,#saved,#new))[seeds.selection])
            status.text=if plan.changed.count==0 then "No effective changes. Apply leaves the scene and Undo history unchanged." else ((plan.changed.count as string)+" settings will change. Terrain, Paint, models and relationships are retained. Manual mode waits for Update.")
            applyStyle.enabled=true
        )catch(clearPlan();status.text=getCurrentException())
        on applyStyle pressed do try (
            if plan==undefined do throw "Review the style first."
            local changed=CyrusStyleCommit plan
            clearPlan();status.text=if changed then "Applied as one Undo. Manual mode waits for Update." else "Already applied. Scene and Undo history retained."
        )catch(clearPlan();status.text=getCurrentException())
        on closeButton pressed do destroyDialog editor
        on editor close do CyrusStyleEditor=undefined
    )
    CyrusStyleOpenData=#(root,node,owner,path,digest,document);CyrusStyleEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)

fn CyrusOpenRecipeLibrary root surface:undefined = (
    if root!=undefined do CyrusRecipeCheckRoot root (CyrusRecipeOwnerNode root)
    if surface==undefined do (
        local selected=for node in selection where superclassof node==GeometryClass and classof node.baseObject!=AminScatterObject collect node
        if selected.count==1 then surface=selected[1]
        else if root!=undefined do (
            local layer=root.selectedLayer(),receivers=if layer==undefined then #() else layer.validSurfaces()
            if receivers.count==1 do surface=receivers[1]
        )
    )
    CyrusLibraryCheckSurface surface
    root=CyrusLibraryDestination surface root
    local node=if root==undefined then undefined else CyrusRecipeOwnerNode root
    if cyrusRecipeLibraryVersion==undefined or cyrusRecipeLibraryVersion()!=4 do throw "Restart Max with the complete Cyrus 0.86.6.1 package."
    local galleryPath=pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll",galleryAssembly=dotNet.loadAssembly galleryPath
    if galleryAssembly==undefined do throw "The Cyrus gallery assembly could not load."
    local assemblyName=galleryAssembly.GetName()
    if assemblyName.Version.ToString()!="0.86.6.1" or toLower galleryAssembly.Location!=toLower galleryPath do throw "Restart Max with the complete Cyrus 0.86.6.1 gallery package."
    if CyrusRecipeBrowser!=undefined do (
        local window=CyrusRecipeBrowser,handle=try(window.hwnd as integer64)catch(0L)
        if (dotNetClass "CyrusScatter.UI.LibraryWindow").RestoreAndActivate handle do (
            window.bindContext root node surface
            CyrusRecipeOpenRoot=root;CyrusRecipeOpenNode=node;CyrusRecipeOpenSurface=surface
            return true
        )
        try(destroyDialog window)catch()
    )
    rollout browser "Cyrus Library" width:1000 height:680 (
        local root,node,surface,sessionID="",directory="",customDirectory="",entries=#(),collections=#(),categories=#(),page=1,scan=0L,scanState="complete",bindingControls=false
        dotNetControl panel "CyrusScatter.UI.LibraryPanel" pos:[0,0] width:1000 height:680
        timer scanTimer interval:250 active:false
        fn validRoot = (CyrusRecipeCheckRoot root node)
        fn bindDestination owner ownerNode = (root=owner;node=ownerNode;panel.HasSetup=true)
        fn bindContext owner ownerNode receiver = (
            if root!=owner or node!=ownerNode or surface!=receiver do (
                root=owner;node=ownerNode;surface=receiver;sessionID=CyrusNewLayerID()
                panel.HasSetup=root!=undefined and isValidNode node and node.baseObject==root
            )
        )
        fn selectedEntry = (local i=panel.Gallery.SelectedIndex+1;if i<1 or i>entries.count then undefined else entries[i])
        fn showSelected = (
            panel.HasSetup=root!=undefined and isValidNode node and node.baseObject==root
            local entry=selectedEntry(),i=panel.Gallery.SelectedIndex+1
            if panel.CollectionsView then (
                panel.DetailText=if i>0 and i<=collections.count then collections[i][1]+" | "+((collections[i][2] as integer) as string)+" recipes" else "Choose a collection, or All recipes in the library tree."
                panel.SetSelectionActions (i>0 and i<=collections.count) false scanTimer.active
            ) else (
                panel.DetailText=if entry==undefined then "No matching recipes." else entry[2][1]+" | "+((entry[2][2] as integer) as string)+" layers; "+((entry[2][3] as integer) as string)+" Paint documents. "+entry[2][17]+"\n"+entry[2][16]+"\n"+entry[2][7]
                panel.SetSelectionActions (entry!=undefined) (panel.LibraryIndex!=2) scanTimer.active
            )
        )
        fn showPage = (
            if scan==0 do return false
            local result=cyrusRecipeLibraryPage scan panel.SearchText panel.Category page
            local pages=if panel.CollectionsView then result[12] else result[8]
            if page>pages do (page=pages as integer;result=cyrusRecipeLibraryPage scan panel.SearchText panel.Category page)
            scanState=result[1];scanTimer.active=scanState=="scanning"
            if not (CyrusPresetSameValues categories result[9]) do (
                categories=result[9];panel.BeginCollections()
                for i=1 to amin 128 categories.count do panel.AddCollection categories[i]
                panel.EndCollections()
            )
            local previous=if panel.CollectionsView then collections else entries,newRows=if panel.CollectionsView then result[11] else result[10]
            local changed=not (CyrusPresetSameValues previous newRows)
            entries=result[10];collections=result[11]
            if changed or panel.Gallery.ItemCount!=newRows.count do (
                local chosen=panel.Gallery.SelectedId,selected=0
                bindingControls=true;panel.Gallery.BeginPage()
                for i=1 to newRows.count do (
                    local row=newRows[i],id=row[1],title=if panel.CollectionsView then row[1] else row[2][1],detail=if panel.CollectionsView then ((row[2] as integer) as string)+" recipes" else ((row[2][2] as integer) as string)+" layers | "+row[2][17]
                    local descriptor=if panel.CollectionsView then row[3] else row[2][14]
                    panel.Gallery.AddItem id title detail (if descriptor.count==3 then descriptor[1] else "") (if descriptor.count==3 then descriptor[2] else "") (if descriptor.count==3 then descriptor[3] as integer else 0)
                    if id==chosen do selected=i
                )
                panel.Gallery.EndPage (if selected>0 then selected-1 else if newRows.count>0 then 0 else -1)
                bindingControls=false
            )
            panel.SetPage page (pages as integer) ((if panel.CollectionsView then result[13] else result[7]) as integer) scanTimer.active
            panel.LocationText=(#("My recipes","Bundled examples","Custom library"))[panel.LibraryIndex]+" / "+(if panel.CollectionsView then "Collections" else if panel.Category=="" then "All recipes" else panel.Category)
            panel.StatusText=(if scanTimer.active then "Scanning: " else "Ready: ")+((result[3] as integer) as string)+" recipes; "+((result[4] as integer) as string)+" invalid."+(if result[5] then " Catalog limit reached; choose a smaller folder." else "")+(if categories.count>128 then " Tree shows first 128 collections; use the paged collection tiles for all." else "")+(if result[6]!="" then " "+result[6] else "")
            showSelected();true
        )
        fn refresh = (
            page=1;entries=#();collections=#();categories=#()
            panel.BeginCollections();panel.EndCollections()
            scan=cyrusRecipeLibraryStart #(directory);scanTimer.active=true;showPage()
        )
        fn navigate category overview = (
            bindingControls=true;panel.SetNavigation panel.LibraryIndex category overview
            entries=#();collections=#();page=1;bindingControls=false;showPage()
        )
        fn refreshEntry path = (
            if scanTimer.active do (panel.StatusText="Saved. Refresh after the active scan completes.";return false)
            local io=dotNetClass "System.IO.Path"
            if toLower (io.GetFullPath (getFilenamePath path))==toLower (io.GetFullPath (directory+"\\")) then (cyrusRecipeLibraryUpdate scan path;showPage())
            else panel.StatusText="Saved. Select its library folder to browse it."
            true
        )
        fn loadSelected = (
            if scanTimer.active do throw "Wait for the library scan or cancel it before loading."
            if panel.CollectionsView then (
                local i=panel.Gallery.SelectedIndex+1
                if i>0 and i<=collections.count do navigate collections[i][1] false
            ) else (
                local entry=selectedEntry()
                if entry==undefined do throw "Select a recipe."
                local packageDirectory=getFilenamePath entry[1]
                local readyDirectory=CyrusPresetPackageDirectory entry[1] entry[2][11]
                CyrusLibraryCheckSurface surface
                if root==undefined do (root=CyrusLibraryDestination surface undefined;node=if root==undefined then undefined else CyrusRecipeOwnerNode root)
                if root!=undefined do validRoot()
                if doesFileExist (pathConfig.appendPath readyDirectory "cyrus.package.json") then CyrusOpenReadyPreset root readyDirectory expected:entry[2][11] surface:surface
                else if doesFileExist (pathConfig.appendPath packageDirectory "cyrus.package.json") then CyrusOpenReadyPreset root packageDirectory expected:entry[2][11] surface:surface
                else throw "The models and assets for this recipe are unavailable. It may be settings-only, or its asset package is missing/incomplete. Restore the complete recipe folder or save it again with Include models, materials, terrain and paths enabled."
            )
        )
        fn action name = (
            if findItem #("save","update","style","export") name>0 do validRoot()
            case name of (
                "selection":showSelected()
                "load":loadSelected()
                "home":(bindingControls=true;panel.SearchText="";bindingControls=false;navigate "" true)
                "search":(if panel.SearchText!="" and panel.CollectionsView do panel.SetNavigation panel.LibraryIndex "" false;entries=#();collections=#();page=1;showPage())
                "collection":(entries=#();collections=#();page=1;showPage())
                "library":(
                    if panel.LibraryIndex==3 and customDirectory=="" then (directory=CyrusRecipeDirectory();panel.SetNavigation 1 "" true;refresh();panel.StatusText="Choose a custom library folder.")
                    else (directory=if panel.LibraryIndex==1 then CyrusRecipeDirectory() else if panel.LibraryIndex==2 then CyrusRecipeBundledDirectory (CyrusLibraryVersion()) else customDirectory;refresh())
                )
                "folder":(local chosen=getSavePath caption:"Choose Cyrus recipe library" initialDir:directory;if chosen!=undefined do (customDirectory=chosen;directory=chosen;panel.SetNavigation 3 "" true;refresh()))
                "refresh":refresh()
                "cancel":(cyrusRecipeLibraryCancel scan;panel.StatusText="Stopping library scan...")
                "previous":(page-=1;showPage())
                "next":(page+=1;showPage())
                "view":(
                    setINISetting (CyrusRecipeViewPreferences()) "View" "Mode" (if panel.ViewIndex==1 then "list" else "tiles")
                    setINISetting (CyrusRecipeViewPreferences()) "View" "Size" ((#("small","medium","large"))[panel.ZoomIndex+1])
                )
                "save":CyrusOpenRecipeSave root (if panel.LibraryIndex==2 then CyrusRecipeDirectory() else directory)
                "update":(
                    local entry=selectedEntry();if entry==undefined or panel.CollectionsView do throw "Select a recipe."
                    CyrusOpenRecipeSave root directory path:entry[1] expected:entry[2][11]
                )
                "style":(
                    local entry=selectedEntry();if entry==undefined or panel.CollectionsView do throw "Select a recipe."
                    CyrusOpenRecipeStyle root entry[1] entry[2][11]
                )
                "export":(
                    local entry=selectedEntry();if entry==undefined or panel.CollectionsView do throw "Select a recipe."
                    CyrusOpenAssetExport root entry[1] entry[2][11]
                )
                "edit":(
                    local entry=selectedEntry();if entry==undefined or panel.CollectionsView do throw "Select a recipe."
                    CyrusRecipeEditDetails entry[1] entry[2][11] (CyrusLibraryVersion())
                )
            )
        )
        on browser open do (
            root=CyrusRecipeOpenRoot;node=CyrusRecipeOpenNode;surface=CyrusRecipeOpenSurface;sessionID=CyrusNewLayerID();directory=CyrusRecipeDirectory()
            -- Max may restore a previous smaller dialog size without a resized
            -- event. Bind the control to that actual size before its first scan.
            local size=getDialogSize browser
            panel.width=amax 1 size.x;panel.height=amax 1 size.y
            panel.UserScale=CustomControlsOptions.UIUserScaleFactor
            local prefs=CyrusRecipeViewPreferences(),mode=getINISetting prefs "View" "Mode",size=getINISetting prefs "View" "Size"
            bindingControls=true;panel.ViewIndex=if mode=="list" then 1 else 0;panel.ZoomIndex=if size=="large" then 2 else if size=="small" then 0 else 1;bindingControls=false
            try(refresh())catch(panel.StatusText=getCurrentException())
        )
        on panel ActionRequested sender args do if not bindingControls do try(action panel.RequestedAction)catch(panel.StatusText=getCurrentException())
        on scanTimer tick do try(showPage())catch(scanTimer.active=false;try(cyrusRecipeLibraryCancel scan)catch();panel.StatusText=getCurrentException())
        on browser resized size do (panel.width=amax 1 size.x;panel.height=amax 1 size.y)
        on browser close do (
            scanTimer.active=false;if scan!=0 do try(cyrusRecipeLibraryCancel scan)catch()
            panel.Dispose()
            CyrusRecipeBrowser=undefined
        )
    )
    CyrusRecipeOpenRoot=root;CyrusRecipeOpenNode=node;CyrusRecipeOpenSurface=surface;CyrusRecipeBrowser=browser
    createDialog browser width:1000 height:680 style:#(#style_titlebar,#style_sysmenu,#style_resizing,#style_minimizebox,#style_maximizebox)
    true
)
