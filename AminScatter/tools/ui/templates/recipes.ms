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
global CyrusRecipeRestorePaint,CyrusRecipeDirectory,CyrusRecipeSuggestBindings
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
    cyrusRecipeCheckStatic owner
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
    if cyrusRecipeVersion==undefined or cyrusRecipeVersion()!=1 or cyrusBrushRecipeExport==undefined do throw "Load the complete Cyrus 0.82.6 script/native pair and restart Max."
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
    if cyrusRecipeVersion==undefined or cyrusRecipeVersion()!=1 do throw "Restart Max with the complete Cyrus 0.82.6 package."
    if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
    rollout browser "Cyrus library - complete recipes" width:530 height:690 (
        local root=undefined,node=undefined,owners=#(),directory="",entries=#(),files=#(),page=1,document=undefined,bindings=#(),layerChoices=#(),metadataCache=#(),metadataIndex=dotNetObject "System.Collections.Hashtable",metadataNext=1,bindingControls=false
        label saveTitle "Save Everything includes Paint, curves, Bands and settings." pos:[12,10] width:506 height:20
        multiListBox saveLayers "Layers to save - evaluation order" pos:[12,34] width:506 height:4
        edittext recipeName "Name:" pos:[12,116] width:506
        button saveRecipe "Save Everything" pos:[12,145] width:150
        button chooseFolder "Library folder..." pos:[176,145] width:130
        label directoryInfo "" pos:[12,178] width:506 height:32
        listbox recipes "Saved recipes" pos:[12,214] width:506 height:5
        button refreshButton "Refresh" pos:[12,321] width:90
        button previousButton "Previous" pos:[112,321] width:90
        button nextButton "Next" pos:[212,321] width:90
        button reviewButton "Review bindings" pos:[368,321] width:150
        listbox roleList "Required bindings - review before import" pos:[12,356] width:506 height:5
        pickbutton bindNode "Pick scene object..." pos:[12,462] width:160 autoDisplay:false
        mapbutton bindMap "Pick texture map..." pos:[186,462] width:160
        dropdownlist bindLayer "Destination layer:" items:#() pos:[12,496] width:250
        button suggestButton "Match unique scene names" pos:[280,496] width:238
        checkbox newSetupCheck "Import as a new setup (otherwise Add layers)" pos:[12,536] width:506
        button importButton "Import reviewed recipe" pos:[12,563] width:210
        button closeButton "Close" pos:[428,563] width:90
        label status "Browsing does not calculate scattering. Paint transfer requires compatible terrain and saved system units." pos:[12,604] width:506 height:72
        fn validRoot = (CyrusRecipeCheckRoot root node)
        fn refresh = (
            validRoot();document=undefined;bindings=#();roleList.items=#()
            files=getFiles (pathConfig.appendPath directory "*.csrecipe.json")
            page=amax 1 (amin page (amax 1 (ceil(files.count/128.0))))
            entries=#();local invalid=0,first=(page-1)*128+1,last=amin files.count (page*128)
            for i=first to last do try(
                local info=dotNetObject "System.IO.FileInfo" files[i],size=info.Length,stamp=info.LastWriteTimeUtc.Ticks,index=if metadataIndex.ContainsKey files[i] then metadataIndex.Item[files[i]] else 0
                if index==0 or metadataCache[index][2]!=size or metadataCache[index][3]!=stamp then (
                    local summary=undefined
                    try(summary=cyrusRecipeInfo files[i])catch()
                    local cached=#(files[i],size,stamp,summary)
                    if index==0 then (
                        if metadataCache.count<512 then (append metadataCache cached;index=metadataCache.count)
                        else (index=metadataNext;metadataIndex.Remove metadataCache[index][1];metadataCache[index]=cached;metadataNext=mod metadataNext 512+1)
                        metadataIndex.Add files[i] index
                    ) else metadataCache[index]=cached
                    if summary==undefined then invalid+=1 else append entries #(files[i],summary)
                ) else (
                    local summary=metadataCache[index][4]
                    if summary==undefined then invalid+=1 else append entries #(files[i],summary)
                )
            )catch(invalid+=1)
            local labels=for entry in entries collect (entry[2][1]+" | "+(entry[2][2] as string)+" layers | "+(entry[2][3] as string)+" Paint documents")
            local current=recipes.items,changed=current.count!=labels.count
            if not changed do for i=1 to labels.count where current[i]!=labels[i] do changed=true
            -- Resetting 128 identical native list rows causes avoidable UI work.
            if changed do recipes.items=labels
            if changed or recipes.selection<1 do recipes.selection=if entries.count>0 then 1 else 0
            directoryInfo.text=directory
            status.text="Page "+(page as string)+" / "+((amax 1 (ceil(files.count/128.0))) as string)+"; "+(invalid as string)+" invalid entries skipped. Select, then Review bindings."
            previousButton.enabled=page>1;nextButton.enabled=last<files.count
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
            bindControls()
        )
        on browser open do (
            root=CyrusRecipeOpenRoot;node=CyrusRecipeOpenNode;owners=root.logicalLayers();directory=CyrusRecipeDirectory()
            saveLayers.items=for owner in owners collect (root.layerCaption owner)
            saveLayers.selection=if owners.count>0 then #{1..owners.count} else #{};recipeName.text="Planting setup"
            try(refresh();bindControls())catch(status.text=getCurrentException())
        )
        on saveRecipe pressed do try(
            validRoot();local selected=for i in saveLayers.selection collect owners[i]
            local label=trimRight (trimLeft recipeName.text),data=CyrusRecipeCapture root selected label
            local path=pathConfig.appendPath directory ((CyrusRecipeGet data "id")+".csrecipe.json")
            cyrusRecipeWrite path data;refresh();status.text="Saved all supported authored settings and Paint. Pending Manual edits were saved without Update. Models and other scene dependencies remain external roles."
        )catch(status.text=getCurrentException())
        on chooseFolder pressed do try(
            local chosen=getSavePath caption:"Choose Cyrus recipe library" initialDir:directory
            if chosen!=undefined do (directory=chosen;page=1;refresh())
        )catch(status.text=getCurrentException())
        on refreshButton pressed do try(refresh())catch(status.text=getCurrentException())
        on previousButton pressed do try(page-=1;refresh())catch(status.text=getCurrentException())
        on nextButton pressed do try(page+=1;refresh())catch(status.text=getCurrentException())
        on reviewButton pressed do try(
            validRoot();if recipes.selection<1 or recipes.selection>entries.count do throw "Select a saved recipe."
            document=cyrusRecipeRead entries[recipes.selection][1]
            bindings=for role in (CyrusRecipeGet document "roles") collect #((CyrusRecipeGet role "id"),undefined)
            showBindings();status.text="Bind each role, or match unique names and review them. Paint needs matching geometry, receiver frame and system units. Field overlays stay off on import."
        )catch(status.text=getCurrentException())
        on suggestButton pressed do try(validRoot();if document==undefined do throw "Review a recipe first.";bindings=CyrusRecipeSuggestBindings root document;showBindings())catch(status.text=getCurrentException())
        on roleList selected i do bindControls()
        on bindNode picked value do try(local index=selectedRole();if index>0 do (bindings[index][2]=value;showBindings()))catch(status.text=getCurrentException())
        on bindMap picked value do if not bindingControls do try(local index=selectedRole();if index>0 do (bindings[index][2]=value;showBindings()))catch(status.text=getCurrentException())
        on bindLayer selected i do try(local index=selectedRole();if index>0 and i>0 and i<=layerChoices.count do (bindings[index][2]=layerChoices[i];showBindings()))catch(status.text=getCurrentException())
        on importButton pressed do try(
            validRoot();if document==undefined do throw "Review a recipe first."
            local result=CyrusRecipeImport root document bindings newSetup:newSetupCheck.checked
            status.text=if result[1].updateMode==1 then "Imported as one Undo. Manual mode: Update scatter to calculate." else "Imported as one Undo. Live follows relevant dependency changes."
        )catch(status.text=getCurrentException())
        on closeButton pressed do destroyDialog browser
        on browser close do CyrusRecipeBrowser=undefined
    )
    CyrusRecipeOpenRoot=root;CyrusRecipeOpenNode=node;CyrusRecipeBrowser=browser
    createDialog browser style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)
