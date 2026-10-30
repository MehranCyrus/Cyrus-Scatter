-- Native .max scene presets. Host graph/file-stream access stays on the Max
-- thread; the managed store only sees bounded copied metadata and bytes.
global CyrusScenePresetSave,CyrusScenePresetMerge,CyrusOpenScenePreset,CyrusScenePresetLoadEditor,CyrusScenePresetLoadData
global CyrusScenePresetNodes,CyrusScenePresetRemap,CyrusSceneMap,CyrusSceneRemapBinding
global CyrusScenePresetCheckNodes
global CyrusPointSuspended,CyrusBrushSessionLayer,cyrusScenePresetVersion,cyrusScenePresetEncode,cyrusEditSceneRemap
global CyrusScenePresetCapturing=false

fn CyrusSceneMap value pairs = (
    for pair in pairs where pair[1]==value do return pair[2]
    value
)
fn CyrusSceneRemapBinding value pairs = (
    if value!="" do for pair in pairs do value=substituteString value pair[1] pair[2]
    value
)
fn CyrusScenePresetCheckNodes nodes = (
    local shaders=#(),cursor=1
    for node in nodes do (
        if matchPattern ((classof node.baseObject) as string) pattern:"Missing_*" do throw ("An object plug-in is unavailable: "+node.name)
        for modifier in node.modifiers do if matchPattern ((classof modifier) as string) pattern:"Missing_*" do throw ("A modifier plug-in is unavailable: "+node.name)
        for key in #(#position,#rotation,#scale) do (
            local controller=try(getPropertyController node key)catch(undefined)
            if controller!=undefined and matchPattern ((classof controller) as string) pattern:"Missing_*" do throw ("A controller plug-in is unavailable: "+node.name)
        )
        if node.material!=undefined do appendIfUnique shaders node.material
    )
    while cursor<=shaders.count do (
        local shader=shaders[cursor];cursor+=1
        if matchPattern ((classof shader) as string) pattern:"Missing_*" do throw "A material or texture plug-in used by this setup is unavailable."
        if superclassof shader==material do for i=1 to getNumSubMtls shader do (local child=getSubMtl shader i;if child!=undefined do appendIfUnique shaders child)
        for i=1 to getNumSubTexmaps shader do (local child=getSubTexmap shader i;if child!=undefined do appendIfUnique shaders child)
        if shaders.count>100000 do throw "The setup exceeds the material graph limit."
    )
    true
)
fn CyrusScenePresetNodes root = (
    local node=CyrusRecipeOwnerNode root
    CyrusRecipeCheckRoot root node
    local graph=#(node),nodes=#(),cursor=1
    for collider in root.interactionSceneColliders where isValidNode collider do appendIfUnique graph collider
    while cursor<=graph.count do (
        local item=graph[cursor];cursor+=1
        if isValidNode item and item!=rootNode do (
            if classof item.baseObject==AminScatterObject and item.baseObject!=root do throw "This setup depends on another Scatter setup. Save each setup separately."
            appendIfUnique nodes item
            if isValidNode item.parent and item.parent!=rootNode do appendIfUnique graph item.parent
            for child in item.children do appendIfUnique graph child
            if nodes.count>10000 do throw "Scene presets support at most 10,000 objects."
        )
        for dependency in (refs.dependsOn item) where dependency!=undefined and dependency!=rootNode do appendIfUnique graph dependency
        if graph.count>100000 do throw "This setup exceeds the scene dependency limit."
    )
    nodes
)
fn CyrusScenePresetSave root name metadata image original:"" expected:"" = (
    CyrusRequireAuthor()
    if cyrusScenePresetVersion==undefined or cyrusScenePresetVersion()!=1 or cyrusEditSceneRemap==undefined do throw "Install the complete CyrusScatter 0.87.6.7 package and restart Max."
    if (maxVersion())[1]/1000+1998!=2027 do throw "Scene presets currently require Max 2027."
    if theHold.Holding() or CyrusBrushSessionLayer!=undefined do throw "Finish the current operation before saving a scene preset."
    name=trimRight (trimLeft name)
    if name=="" do throw "Name this scene preset."
    local nodes=CyrusScenePresetNodes root,store=CyrusSharedStore(),ticket=undefined
    CyrusScenePresetCheckNodes nodes
    try (
        ticket=store.BeginSceneSave original expected
        local file=pathConfig.appendPath ticket.Directory "scene.max"
        local previousCapture=CyrusScenePresetCapturing,saved=false
        CyrusScenePresetCapturing=true
        try(saved=saveNodes nodes file quiet:true)catch(CyrusScenePresetCapturing=previousCapture;throw())
        CyrusScenePresetCapturing=previousCapture
        if not saved do throw "Max could not save this setup."
        local assets=getMAXFileAssetMetadata file,descriptors=#()
        if assets.count>1024 do throw "Scene presets support at most 1,024 collected assets."
        for asset in assets do (
            local path=asset.resolvedFilename
            if path=="" do (
                local live=AssetManager.GetAssetById asset.assetId
                if live!=undefined do (path=live.GetFullFilePath();live.Reset())
            )
            if path=="" and doesFileExist (pathConfig.appendPath maxFilePath asset.filename) do path=pathConfig.appendPath maxFilePath asset.filename
            if path=="" do path=mapPaths.getFullFilePath asset.filename
            if path==undefined or path=="" or not doesFileExist path do throw ("Missing asset: "+asset.filename)
            -- Nested scenes and pattern resources need recursive collection;
            -- refuse rather than publish a misleading complete preset.
            if findString (toLower (asset.type as string)) "xref"!=undefined or findString path "*"!=undefined or findString path "?"!=undefined do throw ("Collect this external scene or sequence before saving: "+asset.filename)
            append descriptors (CyrusRecipeObject #(#("id",asset.assetId),#("type",asset.type as string),#("path",path)))
        )
        local savedImage=""
        if image!="" do (savedImage=pathConfig.appendPath ticket.Directory "capture.png";(dotNetClass "System.IO.File").Copy image savedImage false)
        local operation=store.PublishScene ticket name (cyrusScenePresetEncode metadata) (cyrusScenePresetEncode (for owner in root.logicalLayers() collect root.layerCaption owner)) (1.0/((units.decodeValue "1m") as double)) nodes.count (cyrusScenePresetEncode descriptors) savedImage
        CyrusSharedQueue (CyrusSharedSaveJob store:store ticket:ticket managed:operation path:ticket.RecipePath)
    )catch(if ticket!=undefined do try(store.Discard ticket)catch();throw())
)
fn CyrusScenePresetRemap root = (
    local owners=#(root),pairs=#()
    for owner in root.layerObjects do appendIfUnique owners owner
    for owner in (owners as array) do for area in owner.paintAreas do appendIfUnique owners area
    fn enroll value pairs = (
        if value!="" and not matchPattern value pattern:"placeholder:*" and (CyrusSceneMap value pairs)==value do append pairs #(value,CyrusNewLayerID())
    )
    for owner in owners do (
        enroll owner.layerID pairs
        for key in #(#sourceRowIDs,#clearanceSourceIDs,#interactionSourceIDs,#interactionProxySourceIDs,#visualSourceKeys,#strokeSourceIDs,#procSourceIDs,#procSourceSlots) do for value in getProperty owner key do enroll value pairs
    )
    for owner in owners do (
        local domains=if owner.procReceiverNodes.count>0 then CyrusReceiverVariationDomains owner else #()
        owner.layerID=CyrusSceneMap owner.layerID pairs
        owner.logicalParentID=CyrusSceneMap owner.logicalParentID pairs
        for key in #(#sourceRowIDs,#clearanceSourceIDs,#interactionSourceIDs,#interactionProxySourceIDs,#visualSourceKeys,#strokeSourceIDs,#procSourceIDs,#procSourceSlots,#clearanceTargets,#procRuleA,#procRuleB) do setProperty owner key (for value in getProperty owner key collect CyrusSceneMap value pairs)
        -- Receiver slots are local to their new owner. Keep their saved domain
        -- and proof intact; changing the slot adds a Variation term and would
        -- invalidate saved radius geometry even though the .max mesh is exact.
        owner.procReceiverVariationIDs=domains
        owner.procReceiverID="";for value in owner.procReceiverIDs do owner.procReceiverID+=value+"|"
        owner.procRadiusBinding=CyrusSceneRemapBinding owner.procRadiusBinding pairs
        owner.uiAreaID=CyrusSceneMap owner.uiAreaID pairs
    )
    local clones=cyrusEditSceneRemap (root.procModifiers()) pairs
    for owner in owners do (
        owner.procRadiusIDs=for value in owner.procRadiusIDs collect CyrusSceneMap value clones
        owner.procRadiusBinding=CyrusSceneRemapBinding owner.procRadiusBinding clones
    )
    root.invalidateGroups()
    true
)
fn CyrusScenePresetMerge path expected staged = (
    CyrusRequireAuthor()
    if theHold.Holding() or CyrusBrushSessionLayer!=undefined do throw "Finish the current operation before merging a scene preset."
    local info=cyrusRecipeInfo path,document=cyrusRecipeReadMetadata path,store=CyrusSharedStore()
    local io=dotNetClass "System.IO.Path",full=io.GetFullPath staged,stageDirectory=io.GetDirectoryName full
    if io.GetFileName full!="scene.max" or (io.GetDirectoryName stageDirectory)!=(pathConfig.appendPath store.Root "staging") or not matchPattern (io.GetFileName stageDirectory) pattern:"scene-load-????????????????????????????????" do throw "Prepare this scene preset again before merging."
    if info[11]!=expected or info[17]!="Scene preset" do throw "This preset changed. Refresh the Library."
    if (CyrusRecipeGet document "maxYear")!=((maxVersion())[1]/1000+1998) do throw "Use the Max version shown on this scene preset."
    local meters=1.0/((units.decodeValue "1m") as double),saved=CyrusRecipeGet document "metersPerUnit"
    if abs(meters-saved)>1e-9*(amax meters saved) do throw ("Set system units to 1 unit = "+((saved*100.0) as string)+" cm before merging. Portable presets adapt to other units.")
    local assets=getMAXFileAssetMetadata staged,declared=CyrusRecipeGet document "assets"
    if assets.count!=declared.count do throw "Scene asset metadata differs from its saved descriptor."
    for asset in assets do (
        local found=false
        for item in declared where (CyrusRecipeGet item "id")==asset.assetId do (
            if (CyrusRecipeGet item "type")!=(asset.type as string) do throw "Scene asset type changed."
            asset.filename=pathConfig.appendPath (getFilenamePath path) (CyrusRecipeGet (CyrusRecipeGet item "payload") "file");found=true
        )
        if not found do throw "An undeclared scene asset was found."
    )
    setMAXFileAssetMetadata staged assets
    local missing=#(),names=getMAXFileObjectNames staged quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
    -- Max headers can retain unused studio/legacy custom-attribute classes.
    -- Validate actual merged geometry, stacks and shader graphs below.
    if names.count!=(CyrusRecipeGet document "nodeCount") do throw "Scene object count differs from the saved preset."
    local before=objects as array,merged=#(),oldSuspended=CyrusPointSuspended,previousSelection=selection as array,result=undefined,failure=undefined
    CyrusPointSuspended=true
    try (
        -- This is deliberately standard Max merge, with its explicit UI notice.
        -- It is not a portable recipe transaction and clears Max Undo history.
        with undo off (
            if not (mergeMAXFile staged #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg missingExtFilesAction:#abort missingXRefsAction:#abort mergedNodes:&merged includeFullGroup:true) do throw "Max could not merge this scene preset."
            local setups=for node in merged where isValidNode node and classof node.baseObject==AminScatterObject collect node
            if setups.count!=1 do throw "The scene preset must contain one complete Scatter setup."
            CyrusScenePresetCheckNodes merged
            result=setups[1]
            CyrusScenePresetRemap result.baseObject
            result.baseObject.refreshAll()
            if result.baseObject.groupSnapshotKey=="" or result.baseObject.interactionError!="" do (
                local message=result.baseObject.interactionError
                if message=="" do for leaf in result.baseObject.layerObjects where leaf.previewError!="" and message=="" do message=leaf.previewError
                if message=="" do message="The restored setup could not calculate."
                throw message
            )
        )
        select result
    )catch(
        failure=getCurrentException()
        -- Capture all nodes even if Max aborts before returning mergedNodes.
        local created=for node in objects where findItem before node==0 collect node
        with undo off (if created.count>0 do delete created)
        try(select (for node in previousSelection where isValidNode node collect node))catch()
        CyrusPointSuspended=oldSuspended
    )
    CyrusPointSuspended=oldSuspended
    if failure!=undefined do throw failure
    CyrusViewportRedraw()
    result
)
fn CyrusOpenScenePreset path expected = (
    if CyrusScenePresetLoadEditor!=undefined do try(destroyDialog CyrusScenePresetLoadEditor)catch()
    rollout editor "Load scene preset" width:420 height:152 (
        local path="",expected="",operation=undefined,store=undefined,sceneOwner=undefined
        label nameText "" pos:[12,12] width:396 height:22
        label notice "Adds a new setup. Clears Max Undo history." pos:[12,40] width:396 height:24
        button mergeButton "Merge" pos:[12,76] width:190
        button closeButton "Close" pos:[218,76] width:190
        label status "" pos:[12,111] width:396 height:32
        timer poll interval:150 active:false
        on editor open do (
            path=CyrusScenePresetLoadData[1];expected=CyrusScenePresetLoadData[2];nameText.text=(cyrusRecipeInfo path)[1]
            store=CyrusSharedStore();sceneOwner=rootNode
        )
        on mergeButton pressed do try(
            if rootNode!=sceneOwner do throw "The scene changed. Open the preset again."
            operation=store.PrepareScene path expected;mergeButton.enabled=false;status.text="Checking scene and collected files...";poll.active=true
        )catch(status.text=CyrusRecipeErrorText (getCurrentException()))
        on poll tick do if operation!=undefined and operation.Terminal do (
            poll.active=false
            try (
                if operation.State!="complete" do throw (if operation.State=="cancelled" then "Cancelled." else operation.Error)
                if rootNode!=sceneOwner do throw "The scene changed. Open the preset again."
                status.text="Merging setup..."
                CyrusScenePresetMerge path expected operation.Result
                store.DiscardSceneLoad operation.Result
                status.text="Setup restored.";operation=undefined
            )catch(
                local failure=getCurrentException()
                if operation!=undefined and operation.State=="complete" do try(store.DiscardSceneLoad operation.Result)catch()
                operation=undefined;status.text=CyrusRecipeErrorText failure
            )
            mergeButton.enabled=true
        )
        on closeButton pressed do destroyDialog editor
        on editor close do (if operation!=undefined do store.CancelSceneLoad operation;CyrusScenePresetLoadEditor=undefined)
    )
    CyrusScenePresetLoadData=#(path,expected);CyrusScenePresetLoadEditor=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
)
