-- Bounded data-only recipes. Scene mutation is confined to CyrusRecipeImport.
global CyrusRecipeBrowser,CyrusRecipeOpenRoot,CyrusRecipeOpenNode
global CyrusRecipeObject,CyrusRecipeGet,CyrusRecipeCapture,CyrusRecipeImport,CyrusOpenRecipeLibrary
-- This template is prepended before the plugin/controller template. Declare
-- late-bound globals explicitly so cold compilation cannot capture undefined
-- function locals before the controller has registered them.
global AminScatterObject,CyrusScatterEdit,CyrusNewLayerID,CyrusAnalyzerFilter,CyrusRequireAuthor
global CyrusPointSuspended,CyrusBrushSessionLayer,CyrusViewportRedraw
global CyrusRecipeCaptureContext,CyrusRecipePut,CyrusRecipeOwnerNode,CyrusRecipeCheckRoot
global CyrusRecipeRole,CyrusRecipeCaptureValue,CyrusRecipeCaptureSettings,CyrusRecipeCapturePaint
global CyrusRecipeResolve,CyrusRecipeValidateBindings,CyrusRecipeApplyValue,CyrusRecipeApplySettings
global CyrusRecipeRestorePaint,CyrusRecipeDirectory,CyrusRecipeBundledDirectory,CyrusRecipeSuggestBindings,CyrusOpenPresets
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
    local pairs=#()
    for field in (cyrusRecipeSchema()) do (
        local key=field[1],kind=field[2],value=getProperty owner (key as name)
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
fn CyrusRecipeCapture root selected name = (
    CyrusRequireAuthor()
    if cyrusRecipeVersion==undefined or cyrusRecipeVersion()!=1 or cyrusBrushRecipeExport==undefined do throw "Load the complete Cyrus 0.82.6.1 script/native pair and restart Max."
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
    local document=CyrusRecipeObject #(#("format","cyrus.planting-recipe"),#("formatVersion",1),#("evaluationContract","CyrusUnified1"),#("sceneSchema",58),#("hostYear",2027),#("id",CyrusNewLayerID()),#("name",name),#("unitsPerMetre",context.metres),#("exportScope","complete-setup"),#("rootSettings",rootSettings),#("roles",context.roles),#("layers",layers),#("spacingRelationships",rules))
    CyrusRecipeCheckRoot root node
    for owner in owners where findItem root.layerObjects owner==0 do throw "A selected layer was removed during capture."
    cyrusRecipeValidate document
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
fn CyrusRecipeApplySettings owner settings bindings = (
    local metres=(units.decodeValue "1m") as double
    for field in (cyrusRecipeSchema()) do (
        local key=field[1],kind=field[2],value=CyrusRecipeGet settings key
        if matchPattern kind pattern:"*tab" then (
            kind=substring kind 1 (kind.count-3)
            value=for entry in value collect (CyrusRecipeApplyValue bindings entry kind metres)
        ) else value=CyrusRecipeApplyValue bindings value kind metres
        setProperty owner (key as name) value
    )
    -- Source row/correspondence IDs are local to each new owner. Numeric Path/
    -- Band IDs are already owner-local; their fresh owner gives a new namespace.
    local before=#(),after=#()
    for key in #(#sourceRowIDs,#visualSourceKeys,#strokeSourceIDs,#procSourceIDs,#procSourceSlots,#procReceiverIDs) do (
        local values=(getProperty owner key) as array
        for i=1 to values.count do if not matchPattern values[i] pattern:"placeholder:*" do (
            local index=findItem before values[i]
            if index==0 do (append before values[i];append after (CyrusNewLayerID());index=before.count)
            values[i]=after[index]
        )
        setProperty owner key values
    )
    owner.procReceiverID="";for value in owner.procReceiverIDs do owner.procReceiverID+=value+"|"
    owner.nextPathID=1;for value in owner.pathIDs do owner.nextPathID=amax owner.nextPathID (value+1)
    owner.nextBandID=1;for value in owner.strokeIDs do owner.nextBandID=amax owner.nextBandID (value+1)
    owner.fieldFalloff=false;owner.fieldBoundaries=false
    true
)
fn CyrusRecipeRestorePaint data target document = (
    if data==undefined do return undefined
    local unitsNow=(units.decodeValue "1m") as double,unitsSaved=CyrusRecipeGet document "unitsPerMetre"
    if target!=undefined and abs(unitsNow-unitsSaved)>1e-9*(amax 1.0 (abs unitsSaved)) do throw "Native Paint requires its saved system-unit context. Original coverage is retained; use matching units before binding."
    cyrusBrushRecipeImport (CyrusRecipeGet data "payload") target (CyrusRecipeGet data "radius") (CyrusRecipeGet data "erase") (CyrusRecipeGet data "frame")
)

fn CyrusRecipeImport destination document bindings newSetup:false = (
    CyrusRequireAuthor()
    if theHold.Holding() do throw "Finish the current undoable operation before importing a recipe."
    if CyrusBrushSessionLayer!=undefined do throw "Stop the brush before importing a recipe."
    cyrusRecipeValidate document
    local node=if destination==undefined then undefined else CyrusRecipeOwnerNode destination
    if not newSetup do CyrusRecipeCheckRoot destination node
    CyrusRecipeValidateBindings (if newSetup then undefined else destination) document bindings
    local layers=CyrusRecipeGet document "layers"
    if (if newSetup then 0 else destination.layerObjects.count)+layers.count>10 do throw "Import exceeds the ten-population capacity."
    local oldSuspended=CyrusPointSuspended,root=destination,createdNode=undefined,imported=#(),identityMap=#(),committed=false
    theHold.Begin();CyrusPointSuspended=true
    try (
        with animate off (
            if newSetup do (
                createdNode=AminScatterObject name:(CyrusRecipeGet document "name")
                root=createdNode.baseObject;node=createdNode;root.setLayerTransfer true
                CyrusRecipeApplySettings root (CyrusRecipeGet document "rootSettings") bindings
                root.layerID=CyrusNewLayerID();root.layerObjects=#();root.layerNames=#();root.layerEnabled=#();root.layerVisible=#()
            )
            for record in layers do (
                local owner=createInstance AminScatterObject
                owner.setLayerTransfer true;owner.layerID=CyrusNewLayerID();owner.logicalParentID="";owner.isPaintArea=false
                CyrusRecipeApplySettings owner (CyrusRecipeGet record "settings") bindings
                owner.editLayerKey=root.nextEditLayerKey;root.nextEditLayerKey+=1
                owner.procOrder=root.layerObjects.count+imported.count+1;owner.procSetOrder=owner.procOrder
                owner.paintAreas=#()
                local paint=CyrusRecipeGet record "paint"
                owner.paintDocument=CyrusRecipeRestorePaint paint (if paint==undefined then undefined else CyrusRecipeResolve bindings (CyrusRecipeGet paint "receiverRole")) document
                for areaRecord in (CyrusRecipeGet record "areas") do (
                    local area=createInstance AminScatterObject
                    area.setLayerTransfer true;area.layerID=CyrusNewLayerID();area.logicalParentID=owner.layerID;area.isPaintArea=true
                    CyrusRecipeApplySettings area (CyrusRecipeGet areaRecord "settings") bindings
                    area.areaTarget=CyrusRecipeResolve bindings (CyrusRecipeGet areaRecord "receiverRole")
                    local areaPaint=CyrusRecipeGet areaRecord "paint"
                    if areaPaint!=undefined and (CyrusRecipeResolve bindings (CyrusRecipeGet areaPaint "receiverRole"))!=area.areaTarget do throw "Paint document and area binding disagree."
                    area.paintDocument=CyrusRecipeRestorePaint areaPaint area.areaTarget document
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
        for owner in imported do owner.markInputDirty()
        root.bindNativeUI();CyrusViewportRedraw()
    )
    #(root,imported,node)
)

fn CyrusRecipeDirectory = (
    local folder=(dotNetClass "System.Environment").GetFolderPath ((dotNetClass "System.Environment+SpecialFolder").MyDocuments)
    pathConfig.appendPath folder "CyrusScatter\\Library"
)
fn CyrusRecipeBundledDirectory version = (pathConfig.appendPath (pathConfig.appendPath (getDir #userScripts) "CyrusScatter") ("Library-"+version))
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
fn CyrusOpenRecipeLibrary root = (
    local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    if cyrusRecipeLibraryVersion==undefined or cyrusRecipeLibraryVersion()!=1 do throw "Restart Max with the complete Cyrus 0.82.6.1 package."
    if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
    rollout browser "Cyrus library - complete recipes" width:850 height:650 (
        local root=undefined,node=undefined,owners=#(),directory="",entries=#(),page=1,document=undefined,bindings=#(),layerChoices=#(),bindingControls=false
        local scan=0L,thumbnailFile="",imageKey="",image=undefined,categories=#("All categories"),scanState="complete"
        label saveTitle "Save selected layers with Paint and all supported settings" pos:[12,10] width:300 height:32
        multiListBox saveLayers "Layers - evaluation order" pos:[12,44] width:300 height:4
        edittext recipeName "Name:" pos:[12,128] width:300
        edittext recipeCategory "Category:" pos:[12,156] width:300
        edittext recipeTags "Tags:" pos:[12,184] width:300 tooltip:"Separate up to 16 tags with commas. Search also matches names, categories and descriptions."
        edittext recipeDescription "Description:" pos:[12,212] width:300 height:58
        button chooseThumbnail "Use PNG thumbnail..." pos:[12,282] width:180
        button clearThumbnail "Clear" pos:[202,282] width:110
        label thumbnailInfo "Optional PNG, up to 1024 px and 2 MiB" pos:[12,314] width:300 height:32
        dotNetControl thumbnailView "System.Windows.Forms.PictureBox" pos:[12,352] width:300 height:168
        label previewTitle "Selected recipe preview" pos:[12,526] width:300 height:20
        button saveRecipe "Save Everything" pos:[12,554] width:145
        button preflightButton "Check selected layers" pos:[167,554] width:145
        dropdownlist settingsCategory items:#("Amount settings","Transform settings") pos:[12,584] width:145
        button settingsPresets "Settings presets..." pos:[167,584] width:145
        label directoryInfo "" pos:[330,10] width:508 height:32
        dropdownlist libraryLocation items:#("My recipes","Bundled examples","Custom folder") pos:[330,46] width:145
        button chooseFolder "Choose folder..." pos:[485,46] width:130 enabled:false
        button refreshButton "Refresh" pos:[625,46] width:85
        button cancelButton "Cancel scan" pos:[720,46] width:118 enabled:false
        edittext searchText "Search:" pos:[330,80] width:320
        dropdownlist categoryFilter items:#("All categories") pos:[660,80] width:178
        listbox recipes "Complete recipes" pos:[330,114] width:508 height:7
        button previousButton "Previous" pos:[330,258] width:90
        button nextButton "Next" pos:[430,258] width:90
        label pageInfo "" pos:[532,260] width:306 height:20
        dotNetControl contentInfo "System.Windows.Forms.TextBox" pos:[330,290] width:508 height:70
        button reviewButton "Review bindings" pos:[330,368] width:160
        button suggestButton "Match unique scene names" pos:[508,368] width:330
        listbox roleList "External assets / terrain - bind before import" pos:[330,402] width:508 height:4
        pickbutton bindNode "Pick scene object..." pos:[330,486] width:150 autoDisplay:false
        mapbutton bindMap "Pick texture..." pos:[490,486] width:150
        dropdownlist bindLayer "Layer:" items:#() pos:[650,482] width:188
        checkbox newSetupCheck "New setup (unchecked: Add layers to this setup)" pos:[330,522] width:508
        button importButton "Import reviewed recipe" pos:[330,554] width:210 enabled:false
        button closeButton "Close" pos:[748,554] width:90
        label status "Browsing never calculates scattering. Refresh rereads changed library files." pos:[12,618] width:826 height:28
        timer scanTimer interval:250 active:false
        fn validRoot = (CyrusRecipeCheckRoot root node)
        fn clearReview = (document=undefined;bindings=#();roleList.items=#();importButton.enabled=false;true)
        fn clearImage = (
            thumbnailView.Image=undefined
            if image!=undefined do (image.Dispose();image=undefined)
            imageKey="";true
        )
        fn showSelected = (
            clearReview()
            if recipes.selection<1 or recipes.selection>entries.count do (clearImage();contentInfo.text="No matching recipes.";return false)
            local entry=entries[recipes.selection],info=entry[2],names="",tags="",newLine=(dotNetClass "System.Environment").NewLine
            for name in info[9] do names+=(if names=="" then name else ", "+name)
            for tag in info[6] do tags+=(if tags=="" then tag else ", "+tag)
            contentInfo.text=((info[2] as integer) as string)+" layers: "+names+newLine+((info[3] as integer) as string)+" Paint documents; "+((info[8] as integer) as string)+" external roles. "+info[7]+(if tags=="" then "" else newLine+"Tags: "+tags)
            if info[13]!="" do status.text=info[13]
            local key=entry[1]+"|"+info[11]
            if key!=imageKey do (
                clearImage();imageKey=key;previewTitle.text="Selected recipe preview"
                if info[12] do try (
                    local path=cyrusRecipeThumbnail entry[1]
                    if path!="" do (
                        local stream=dotNetObject "System.IO.FileStream" path ((dotNetClass "System.IO.FileMode").Open) ((dotNetClass "System.IO.FileAccess").Read) ((dotNetClass "System.IO.FileShare").ReadWrite)
                        local decoded=undefined
                        try (
                            decoded=(dotNetClass "System.Drawing.Image").FromStream stream
                            image=dotNetObject "System.Drawing.Bitmap" decoded
                            decoded.Dispose();decoded=undefined;stream.Dispose()
                        )catch(if decoded!=undefined do decoded.Dispose();stream.Dispose();throw())
                        thumbnailView.Image=image
                    )
                )catch(previewTitle.text="Thumbnail unavailable";status.text=getCurrentException())
            )
            true
        )
        fn showPage = (
            if scan==0 do return false
            local filter=if categoryFilter.selection>1 then categories[categoryFilter.selection] else ""
            local result=cyrusRecipeLibraryPage scan searchText.text filter page
            if page>result[8] do (page=result[8] as integer;result=cyrusRecipeLibraryPage scan searchText.text filter page)
            scanState=result[1];scanTimer.active=scanState=="scanning";cancelButton.enabled=scanTimer.active
            refreshButton.enabled=not scanTimer.active;libraryLocation.enabled=not scanTimer.active;chooseFolder.enabled=not scanTimer.active and libraryLocation.selection==3
            local chosen=if recipes.selection>0 and recipes.selection<=entries.count then entries[recipes.selection][1] else ""
            local oldCategories=categoryFilter.items,newCategories=#("All categories")
            join newCategories result[9]
            local changed=oldCategories.count!=newCategories.count
            if not changed do for i=1 to oldCategories.count where oldCategories[i]!=newCategories[i] do changed=true
            if changed do (
                bindingControls=true;categories=newCategories;categoryFilter.items=categories
                categoryFilter.selection=amax 1 (findItem categories filter);bindingControls=false
            )
            entries=result[10]
            local labels=for entry in entries collect (entry[2][1]+" | "+((entry[2][2] as integer) as string)+" layers | "+((entry[2][3] as integer) as string)+" Paint")
            local current=recipes.items,changedRows=current.count!=labels.count
            if not changedRows do for i=1 to labels.count where current[i]!=labels[i] do changedRows=true
            if changedRows do recipes.items=labels
            local paths=for entry in entries collect entry[1],selected=findItem paths chosen
            recipes.selection=if selected>0 then selected else if entries.count>0 then 1 else 0
            previousButton.enabled=page>1;nextButton.enabled=page<result[8]
            pageInfo.text="Page "+(page as string)+" / "+((result[8] as integer) as string)+"; "+((result[7] as integer) as string)+" matches"
            status.text=(if scanTimer.active then "Scanning: " else if scanState=="cancelled" then "Cancelled: " else "Ready: ")+((result[3] as integer) as string)+" indexed; "+((result[4] as integer) as string)+" invalid."+(if result[5] then " Library limit reached; choose a smaller folder." else "")+(if result[6]!="" then " "+result[6] else "")
            showSelected();true
        )
        fn refresh = (
            validRoot();clearReview();clearImage();page=1
            scan=cyrusRecipeLibraryStart #(directory);scanTimer.active=true;directoryInfo.text=directory
            showPage()
        )
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
        fn captureSelection = (
            validRoot();local selected=for i in saveLayers.selection where i<=owners.count collect owners[i]
            CyrusRecipeCapture root selected (trimRight (trimLeft recipeName.text))
        )
        on browser open do (
            root=CyrusRecipeOpenRoot;node=CyrusRecipeOpenNode;owners=root.logicalLayers();directory=CyrusRecipeDirectory()
            makeDir directory all:true
            thumbnailView.SizeMode=(dotNetClass "System.Windows.Forms.PictureBoxSizeMode").Zoom
            contentInfo.Multiline=true;contentInfo.ReadOnly=true;contentInfo.WordWrap=true
            contentInfo.ScrollBars=(dotNetClass "System.Windows.Forms.ScrollBars").Vertical
            contentInfo.BackColor=(dotNetClass "System.Drawing.Color").FromArgb 65 65 65
            contentInfo.ForeColor=(dotNetClass "System.Drawing.Color").FromArgb 230 230 230
            local nativeFont=windows.sendMessage recipeName.hwnd[1] 0x0031 0 0
            if nativeFont!=0 do contentInfo.Font=(dotNetClass "System.Drawing.Font").FromHfont (dotNetObject "System.IntPtr" nativeFont)
            saveLayers.items=for owner in owners collect (root.layerCaption owner)
            saveLayers.selection=if owners.count>0 then #{1..owners.count} else #{};recipeName.text="Planting setup"
            try(refresh();bindControls())catch(status.text=getCurrentException())
        )
        on saveRecipe pressed do try(
            local data=captureSelection(),tags=#()
            for value in filterString recipeTags.text "," do (
                local tag=trimRight (trimLeft value)
                if tag!="" do appendIfUnique tags tag
            )
            local metadata=CyrusRecipeObject #(#("category",trimRight (trimLeft recipeCategory.text)),#("tags",tags),#("description",recipeDescription.text))
            local saveDirectory=if libraryLocation.selection==2 then CyrusRecipeDirectory() else directory
            makeDir saveDirectory all:true
            local path=pathConfig.appendPath saveDirectory ((CyrusRecipeGet data "id")+".csrecipe.json")
            cyrusRecipeWrite path data
            local message="Saved all supported settings and Paint without Update. External assets require binding."
            if libraryLocation.selection==2 do message+=" Saved in My recipes."
            try(cyrusRecipePresentationWrite path metadata thumbnailFile)catch(message="Recipe saved safely, but its tags/thumbnail were not saved: "+getCurrentException())
            if scanTimer.active then (cyrusRecipeLibraryCancel scan;status.text=message+" Refresh after the scan stops.")
            else (refresh();status.text=message)
        )catch(status.text=getCurrentException())
        on preflightButton pressed do try(
            local data=captureSelection()
            status.text="Ready: "+((CyrusRecipeGet data "layers").count as string)+" layers; "+((CyrusRecipeGet data "roles").count as string)+" external roles. Paint and supported settings accounted for."
        )catch(status.text=getCurrentException())
        on chooseThumbnail pressed do (
            local path=getOpenFileName caption:"Choose an actual preset preview" types:"PNG image (*.png)|*.png|"
            if path!=undefined do (thumbnailFile=path;thumbnailInfo.text=filenameFromPath path)
        )
        on clearThumbnail pressed do (thumbnailFile="";thumbnailInfo.text="Optional PNG, up to 1024 px and 2 MiB")
        on libraryLocation selected index do try(
            directory=if index==1 then CyrusRecipeDirectory() else if index==2 then CyrusRecipeBundledDirectory (root.uiVersion()) else directory
            searchText.text="";categoryFilter.selection=1;refresh()
        )catch(status.text=getCurrentException())
        on chooseFolder pressed do try(
            local chosen=getSavePath caption:"Choose Cyrus recipe library" initialDir:directory
            if chosen!=undefined do (directory=chosen;refresh())
        )catch(status.text=getCurrentException())
        on refreshButton pressed do try(refresh())catch(status.text=getCurrentException())
        on scanTimer tick do try(validRoot();showPage())catch(scanTimer.active=false;cancelButton.enabled=false;try(cyrusRecipeLibraryCancel scan)catch();status.text=getCurrentException())
        on cancelButton pressed do try(cyrusRecipeLibraryCancel scan;status.text="Stopping library scan...")catch(status.text=getCurrentException())
        on searchText changed value do try(page=1;showPage())catch(status.text=getCurrentException())
        on categoryFilter selected index do if not bindingControls do try(page=1;showPage())catch(status.text=getCurrentException())
        on previousButton pressed do try(page-=1;showPage())catch(status.text=getCurrentException())
        on nextButton pressed do try(page+=1;showPage())catch(status.text=getCurrentException())
        on recipes selected index do try(showSelected();bindControls())catch(status.text=getCurrentException())
        on reviewButton pressed do try(
            validRoot();if scanTimer.active do throw "Wait for the library scan, or Cancel it, before reviewing a recipe."
            if recipes.selection<1 or recipes.selection>entries.count do throw "Select a saved recipe."
            document=cyrusRecipeRead entries[recipes.selection][1]
            bindings=for role in (CyrusRecipeGet document "roles") collect #((CyrusRecipeGet role "id"),undefined)
            showBindings();status.text="Review every binding. Paint requires compatible geometry, frame and saved system units."
        )catch(clearReview();status.text=getCurrentException())
        on suggestButton pressed do try(validRoot();if document==undefined do throw "Review a recipe first.";bindings=CyrusRecipeSuggestBindings root document;showBindings())catch(status.text=getCurrentException())
        on roleList selected i do bindControls()
        on bindNode picked value do try(validRoot();local index=selectedRole();if index>0 do (bindings[index][2]=value;showBindings()))catch(status.text=getCurrentException())
        on bindMap picked value do if not bindingControls do try(validRoot();local index=selectedRole();if index>0 do (bindings[index][2]=value;showBindings()))catch(status.text=getCurrentException())
        on bindLayer selected i do try(validRoot();local index=selectedRole();if index>0 and i>0 and i<=layerChoices.count do (bindings[index][2]=layerChoices[i];showBindings()))catch(status.text=getCurrentException())
        on importButton pressed do try(
            validRoot();if document==undefined do throw "Review a recipe first."
            local result=CyrusRecipeImport root document bindings newSetup:newSetupCheck.checked
            status.text=if result[1].updateMode==1 then "Imported as one Undo. Manual mode: Update scatter to calculate." else "Imported as one Undo. Live follows relevant changes."
        )catch(status.text=getCurrentException())
        on settingsPresets pressed do try(
            validRoot();local owner=root.selectedLayer()
            if owner==undefined do throw "Select a destination layer first."
            CyrusOpenPresets root (root.logicalParent owner) (if settingsCategory.selection==1 then "population" else "transforms")
        )catch(status.text=getCurrentException())
        on closeButton pressed do destroyDialog browser
        on browser close do (
            scanTimer.active=false
            if scan!=0 do try(cyrusRecipeLibraryCancel scan)catch()
            clearImage();CyrusRecipeBrowser=undefined
        )
    )
    CyrusRecipeOpenRoot=root;CyrusRecipeOpenNode=node;CyrusRecipeBrowser=browser
    createDialog browser style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)
