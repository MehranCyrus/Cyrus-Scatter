/* Bounded artist-facing metadata controls; asset meshes and library bytes stay native. */
global caAssetUI, caShowAssetUI, caAssetSupportUI, caShowAssetSupportUI
global caRegisterAsset, caAssetRows, caSaveAssetLibrary, caLoadAssetLibrary
global caAssetDetail, caUpdateAsset, caRebindAsset, caUseStoredAsset, caRemoveAssets
global caAssetSupport, caSetAssetSupport, caResetAssetSupport
global caBookRowAssetUI, caShowBookRowAssetUI, caAssetBookRow, caSetAssetBookRow
try (destroyDialog caAssetUI) catch ()

rollout caAssetUI "Cyrus Arrange | Asset Library"
(
    local setupNode = undefined
    local sourceNode = undefined
    local metadataRows = #()
    local lastError = ""
    local editingID = 0L
    local hydrating = false
    label setupLabel "Choose an Arrange setup." pos:[14,10] width:610
    button useSource "Use selected model / group" pos:[14,36] width:290 height:24
    label sourceLabel "No source model selected." pos:[324,42] width:300
    editText assetName "Name:" text:"" pos:[14,72] width:610
    dropdownList category "Category:" items:#("Book","Book stack","Plant","Candle","Frame","Vase","Accessory","Bowl","Tableware","Kitchenware","Tray") selection:7 pos:[14,104] width:290
    checkbox stackable "Has a stable flat top for stacking" checked:false pos:[324,126] width:300
    label eligibility "Allowed furniture:" pos:[14,160] width:610
    checkbox allowTV "TV console" checked:true pos:[14,182] width:125
    checkbox allowShelf "Open shelf" checked:true pos:[145,182] width:125
    checkbox allowCoffee "Coffee table" checked:true pos:[276,182] width:125
    checkbox allowCounter "Kitchen counter" checked:true pos:[407,182] width:145
    checkbox allowDining "Dining table" checked:true pos:[14,207] width:125
    editText yawText "Yaw angles:" text:"0,90,180,270" pos:[145,207] width:479
    spinner weight "Selection weight:" range:[0.001,1000000,1] type:#float pos:[14,242] width:200 fieldWidth:75
    spinner minScale "Min scale:" range:[0.01,100,1] type:#float pos:[224,242] width:190 fieldWidth:75
    spinner maxScale "Max scale:" range:[0.01,100,1] type:#float pos:[424,242] width:200 fieldWidth:75
    button registerButton "Register new asset" pos:[14,275] width:196 height:26
    button updateButton "Update selected metadata" pos:[221,275] width:196 height:26
    button refreshButton "Refresh library list" pos:[428,275] width:196 height:26
    listBox assets "Registered assets (select a row to edit):" items:#() pos:[14,314] width:610 height:8
    button rebindButton "Rebind to selected model" pos:[14,466] width:196 height:26
    button storedButton "Use stored geometry" pos:[221,466] width:196 height:26
    button removeButton "Remove asset entry" pos:[428,466] width:196 height:26
    checkbox removeOutputs "Also remove generated outputs, their complete book rows and supported stack children" checked:false pos:[14,503] width:610
    button saveButton "Save asset library..." pos:[14,534] width:196 height:24
    button loadButton "Load asset library..." pos:[221,534] width:196 height:24
    button supportButton "Edit contact / stack support" pos:[428,534] width:196 height:24
    label materialScope "Stored geometry has no source materials. Missing scene sources need Rebind or explicit Use stored geometry." pos:[14,572] width:610 height:32
    button rowProfileButton "Upright book row profile..." pos:[14,610] width:290 height:26
    editText statusText "Status:" text:"Choose a source model to add, or select an existing asset row to edit." readOnly:true pos:[14,652] width:610 height:62

    fn failure actionName detail =
    (
        lastError = actionName+": "+(detail as string)
        statusText.text = lastError
        false
    )
    fn furnitureMask =
    (
        (if allowTV.checked then 1 else 0) + (if allowShelf.checked then 2 else 0) +
        (if allowCoffee.checked then 4 else 0) + (if allowCounter.checked then 8 else 0) +
        (if allowDining.checked then 16 else 0)
    )
    fn yawValues =
    (
        if yawText.text.count > 1024 do throw "Use at most 64 yaw angles."
        local tokens = filterString yawText.text ",; \t"
        if tokens.count < 1 or tokens.count > 64 do throw "Use between 1 and 64 yaw angles."
        local result = #()
        for token in tokens do append result (token as double)
        result
    )
    fn sourceStateLabel state = case state of (1:"live scene source";2:"stored geometry";3:"MISSING scene source";default:"unknown source state")
    fn showDetail detail =
    (
        if detail.count != 13 do throw "Native asset detail has an unexpected shape."
        editingID = detail[1]
        assetName.text = detail[2]
        category.selection = detail[3]
        local bits = #(1,2,4,8,16)
        local controls = #(allowTV,allowShelf,allowCoffee,allowCounter,allowDining)
        for i = 1 to 5 do controls[i].checked = (bit.and detail[4] bits[i]) != 0
        local angles = ""
        for i = 1 to detail[5].count do
        (
            if i > 1 do angles += ","
            angles += formattedPrint detail[5][i] format:".17g"
        )
        yawText.text = angles
        weight.value = detail[6]
        minScale.value = detail[7]
        maxScale.value = detail[8]
        stackable.checked = detail[9]
        sourceNode = detail[11]
        sourceLabel.text = (sourceStateLabel detail[10])+": "+detail[12]
        true
    )
    fn onEdit index =
    (
        try
        (
            if index < 1 or index > metadataRows.count do throw "Select an asset row first."
            showDetail (caAssetDetail setupNode metadataRows[index][1])
            statusText.text = "Editing an existing asset. Update metadata preserves its ID and captured support."
            lastError = ""
            true
        )
        catch (failure "Read selected asset" (getCurrentException()))
    )
    fn onRefresh =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose an Arrange setup first."
            local rows = caAssetRows setupNode
            if rows.count > 256 do throw "Native asset list exceeds the component limit."
            local labels = #()
            for row in rows do
            (
                if row.count != 10 do throw "Load a matched Arrange native/UI pair."
                local dimensions = row[4]
                local detail = caAssetDetail setupNode row[1]
                local sourceState = " | "+(sourceStateLabel detail[10])
                append labels ((row[1] as string)+" | "+row[2]+" | "+category.items[row[3]]+" | "+(formattedPrint dimensions.x format:".0f")+" x "+(formattedPrint dimensions.y format:".0f")+" x "+(formattedPrint dimensions.z format:".0f")+" mm"+sourceState)
            )
            metadataRows = rows
            hydrating = true
            assets.items = labels
            local foundEditing = false
            for i = 1 to rows.count where rows[i][1] == editingID do
            (
                foundEditing = true
                assets.selection = i
                showDetail (caAssetDetail setupNode editingID)
            )
            if not foundEditing do
            (
                editingID = 0L
                sourceNode = undefined
                sourceLabel.text = "Select an existing row, or choose a new scene model."
            )
            hydrating = false
            setupLabel.text = "Setup: "+setupNode.name+" | "+(rows.count as string)+" asset(s)"
            lastError = ""
            true
        )
        catch (hydrating = false;failure "Read asset library" (getCurrentException()))
    )
    fn bindSetup node =
    (
        setupNode = node
        editingID = 0L
        sourceNode = undefined
        onRefresh()
    )
    fn selectedModelRoots =
    (
        if selection.count > 4096 do throw "Choose one accessory assembly containing at most 4096 selected nodes."
        local chosen = selection as array
        local roots = #()
        for node in chosen do
        (
            local ancestor = node.parent
            local coveredByGroup = false
            local depth = 0
            while ancestor != undefined and not coveredByGroup do
            (
                depth += 1
                if depth > 256 do throw "The selected assembly exceeds the supported hierarchy depth."
                if ancestor.isSelected and (isGroupHead ancestor) do coveredByGroup = true
                ancestor = ancestor.parent
            )
            if not coveredByGroup do append roots node
        )
        roots
    )
    fn onUseSource =
    (
        editingID = 0L
        sourceNode = undefined
        sourceLabel.text = "No source model selected."
        try
        (
            local chosen = selectedModelRoots()
            if chosen.count != 1 do throw "Select exactly one accessory model or its group head."
            sourceNode = chosen[1]
            assetName.text = sourceNode.name
            sourceLabel.text = sourceNode.name
            local tag = getUserProp sourceNode "CyrusArrangeAssetCategory"
            if tag != undefined do
            (
                local suggested = tag as integer
                if suggested != undefined and suggested >= 1 and suggested <= category.items.count do category.selection = suggested
            )
            local topTag = getUserProp sourceNode "CyrusArrangeAssetStackable"
            stackable.checked = (topTag == true or topTag == "true")
            statusText.text = "Set the category and allowed furniture, then Register new asset."
            true
        )
        catch (failure "Choose source" (getCurrentException()))
    )
    fn onRegister =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose an Arrange setup first."
            if not isValidNode sourceNode do throw "Choose a source accessory first."
            if assetName.text.count > 512 do throw "Use a shorter asset name."
            local mask = furnitureMask()
            local angles = yawValues()
            local registered = undefined
            undo "Cyrus Arrange: register asset" on
                (registered = caRegisterAsset setupNode sourceNode assetName.text category.selection mask angles weight.value minScale.value maxScale.value stackable.checked)
            if registered == undefined do throw "Native registration did not complete."
            editingID = registered
            if not onRefresh() do throw lastError
            statusText.text = "Registered "+assetName.text+". Source geometry is preserved."
            true
        )
        catch (failure "Register asset" (getCurrentException()))
    )
    fn onUpdate =
    (
        try
        (
            if editingID == 0L do throw "Select an existing asset row to update."
            local angles = yawValues()
            undo "Cyrus Arrange: edit asset metadata" on
                (caUpdateAsset setupNode editingID assetName.text category.selection (furnitureMask()) angles weight.value minScale.value maxScale.value stackable.checked)
            if not onRefresh() do throw lastError
            statusText.text = "Asset metadata updated. Generate to validate the next arrangement."
            true
        )
        catch (failure "Update metadata" (getCurrentException()))
    )
    fn onRebind =
    (
        try
        (
            if editingID == 0L do throw "Select an existing asset row to rebind."
            local roots = selectedModelRoots()
            if roots.count != 1 do throw "Select exactly one replacement model or group in the scene."
            undo "Cyrus Arrange: rebind asset" on (caRebindAsset setupNode editingID roots[1])
            if not onRefresh() do throw lastError
            statusText.text = "Source rebound. Asset ID and authored metadata are preserved."
            true
        )
        catch (failure "Rebind asset" (getCurrentException()))
    )
    fn onStored =
    (
        try
        (
            if editingID == 0L do throw "Select an existing asset row first."
            undo "Cyrus Arrange: use stored asset" on (caUseStoredAsset setupNode editingID)
            if not onRefresh() do throw lastError
            statusText.text = "Using captured geometry explicitly. Save source materials separately for matching appearance."
            true
        )
        catch (failure "Use stored geometry" (getCurrentException()))
    )
    fn onRemove =
    (
        try
        (
            if editingID == 0L do throw "Select an existing asset row to remove."
            local result = undefined
            undo "Cyrus Arrange: remove asset" on (result = caRemoveAssets setupNode #(editingID) removeOutputs.checked)
            editingID = 0L
            sourceNode = undefined
            if not onRefresh() do throw lastError
            statusText.text = "Removed "+(result[1] as string)+" asset(s) and "+(result[2] as string)+" owned output(s). Source models are preserved."
            true
        )
        catch (failure "Remove asset" (getCurrentException()))
    )
    fn onSupport =
    (
        try
        (
            if editingID == 0L do throw "Select an existing asset row first."
            caShowAssetSupportUI setupNode editingID
            true
        )
        catch (failure "Open support editor" (getCurrentException()))
    )
    fn onSave path:undefined =
    (
        local destination = path
        if destination == undefined do destination = getSaveFileName caption:"Save Arrange asset library" filename:"Arrange-assets.cyalib" types:"Arrange library (*.cyalib)|*.cyalib|"
        if destination == undefined then false
        else
        (
            try
            (
                caSaveAssetLibrary setupNode destination
                statusText.text = "Saved geometry and metadata: "+destination
                true
            )
            catch (failure "Save asset library" (getCurrentException()))
        )
    )
    fn onLoad path:undefined =
    (
        local sourcePath = path
        if sourcePath == undefined do sourcePath = getOpenFileName caption:"Load Arrange asset library" types:"Arrange library (*.cyalib)|*.cyalib|"
        if sourcePath == undefined then false
        else
        (
            try
            (
                undo "Cyrus Arrange: load asset library" on (caLoadAssetLibrary setupNode sourcePath)
                if not onRefresh() do throw lastError
                statusText.text = "Loaded geometry and metadata. Geometry-only rows need source materials for matching appearance."
                true
            )
            catch (failure "Load asset library" (getCurrentException()))
        )
    )
    fn rows = metadataRows
    fn errorMessage = lastError
    fn selectedAssetID = editingID
    on useSource pressed do onUseSource()
    on registerButton pressed do onRegister()
    on updateButton pressed do onUpdate()
    on assets selected index do if not hydrating do onEdit index
    on rebindButton pressed do onRebind()
    on storedButton pressed do onStored()
    on removeButton pressed do onRemove()
    on supportButton pressed do onSupport()
    on rowProfileButton pressed do
    (
        try
        (
            if editingID == 0L do throw "Select a registered Book asset first."
            caShowBookRowAssetUI setupNode editingID
        )
        catch (failure "Open book row profile" (getCurrentException()))
    )
    on refreshButton pressed do onRefresh()
    on saveButton pressed do onSave()
    on loadButton pressed do onLoad()
)

try (destroyDialog caAssetSupportUI) catch ()
rollout caAssetSupportUI "Cyrus Arrange | Authored Support"
(
    local setupNode = undefined
    local assetID = 0L
    local lastError = ""
    label description "Asset-local millimetres. Enter convex counterclockwise points, one x,y,z per line.\nThe anchor belongs inside the contact patch at the complete mesh's base height." pos:[14,12] width:610 height:42
    spinner anchorX "Anchor X:" range:[-1000000000,1000000000,0] type:#float pos:[14,62] width:196
    spinner anchorY "Anchor Y:" range:[-1000000000,1000000000,0] type:#float pos:[221,62] width:196
    spinner anchorZ "Anchor Z:" range:[-1000000000,1000000000,0] type:#float pos:[428,62] width:196
    editText contactText "Contact polygon:" text:"" pos:[14,98] width:300 height:170
    editText topText "Top polygon:" text:"" pos:[324,98] width:300 height:170
    checkbox stackEnabled "Supports stacked children" checked:false pos:[14,282] width:300
    spinner stackHeight "Top above anchor (mm):" range:[0,1000000000,0] type:#float pos:[324,282] width:300 fieldWidth:100
    multiListBox topCategories "Allowed child categories:" items:#("Book","Book stack","Plant","Candle","Frame","Vase","Accessory","Bowl","Tableware","Kitchenware","Tray") pos:[14,320] width:300 height:6
    label boundsLabel "" pos:[324,340] width:300 height:86
    button applyButton "Apply authored support" pos:[14,448] width:196 height:28
    button resetButton "Reset support from geometry" pos:[221,448] width:196 height:28
    button refreshButton "Refresh editor" pos:[428,448] width:196 height:28
    editText statusText "Status:" text:"" readOnly:true pos:[14,492] width:610 height:66
    fn failure action detail = (lastError = action+": "+(detail as string);statusText.text = lastError;false)
    fn pointText points =
    (
        local result = ""
        for p in points do result += (formattedPrint p.x format:".9g")+","+(formattedPrint p.y format:".9g")+","+(formattedPrint p.z format:".9g")+"\n"
        result
    )
    fn readPoints textValue allowEmpty:false =
    (
        if textValue.count > 16384 do throw "A support polygon exceeds the text limit."
        local lines = filterString textValue ";\n\r"
        if lines.count == 0 and allowEmpty then #()
        else
        (
            if lines.count < 3 or lines.count > 64 do throw "Use 3..64 points per polygon."
            local result = #()
            for line in lines do
            (
                local parts = filterString line ", \t"
                if parts.count != 3 do throw "Each point needs exactly three numeric coordinates."
                local x = parts[1] as float
                local y = parts[2] as float
                local z = parts[3] as float
                if x == undefined or y == undefined or z == undefined do throw "Point coordinates must be numeric."
                append result [x,y,z]
            )
            result
        )
    )
    fn onRefresh =
    (
        try
        (
            local data = caAssetSupport setupNode assetID
            if data.count != 9 do throw "Native support detail has an unexpected shape."
            anchorX.value = data[1].x
            anchorY.value = data[1].y
            anchorZ.value = data[1].z
            contactText.text = pointText data[2]
            stackEnabled.checked = data[3]
            stackHeight.value = data[4]
            topText.text = pointText data[5]
            local bits = #(1,2,4,8,16,32,64,128,256,512,1024)
            local chosen = #{}
            for i = 1 to 11 where (bit.and data[6] bits[i]) != 0 do chosen[i] = true
            topCategories.selection = chosen
            boundsLabel.text = "Bounds min: "+(data[8] as string)+"\nBounds max: "+(data[9] as string)+"\nAuthored contact / top: "+(data[7] as string)
            lastError = ""
            statusText.text = "A source refresh preserves authored patches and rejects incompatible geometry."
            true
        )
        catch (failure "Read support" (getCurrentException()))
    )
    fn bindAsset setup id = (setupNode = setup;assetID = id;onRefresh())
    fn onApply =
    (
        try
        (
            local contact = readPoints contactText.text
            local top = if stackEnabled.checked then readPoints topText.text else #()
            local bits = #(1,2,4,8,16,32,64,128,256,512,1024)
            local mask = 0
            if stackEnabled.checked do for i in topCategories.selection do mask += bits[i]
            local height = if stackEnabled.checked then stackHeight.value else 0
            undo "Cyrus Arrange: authored asset support" on
                (caSetAssetSupport setupNode assetID [anchorX.value,anchorY.value,anchorZ.value] contact stackEnabled.checked height top mask)
            if not onRefresh() do throw lastError
            statusText.text = "Authored contact and stacking metadata saved. Generate to validate placement."
            true
        )
        catch (failure "Apply support" (getCurrentException()))
    )
    fn onReset =
    (
        try
        (
            undo "Cyrus Arrange: reset asset support" on (caResetAssetSupport setupNode assetID)
            onRefresh()
        )
        catch (failure "Reset support" (getCurrentException()))
    )
    fn errorMessage = lastError
    on applyButton pressed do onApply()
    on resetButton pressed do onReset()
    on refreshButton pressed do onRefresh()
)
fn caShowAssetSupportUI setup id =
(
    try (destroyDialog caAssetSupportUI) catch ()
    createDialog caAssetSupportUI width:640 height:580
    caAssetSupportUI.bindAsset setup id
    caAssetSupportUI
)

fn caShowAssetUI setup =
(
    try (destroyDialog caAssetUI) catch ()
    createDialog caAssetUI width:640 height:736
    caAssetUI.bindSetup setup
    caAssetUI
)

rollout caBookRowAssetUI "Cyrus Arrange | Upright Book"
(
    local setupNode = undefined
    local assetID = 0L
    local lastError = ""
    label assetLabel "Select a Book asset." pos:[14,12] width:450 height:26
    checkbox eligible "This asset is an individual upright book" checked:false pos:[14,48] width:450
    dropdownList spine "Spine side in the captured asset frame:" items:#("-X","+X","-Y","+Y") selection:4 pos:[14,80] width:450
    label guidance "Choose the outside spine face. Rows turn it toward the surface's front, using only the asset's allowed yaw angles. A prebuilt source group remains one asset." pos:[14,146] width:450 height:48
    button applyButton "Apply profile" pos:[14,208] width:216 height:26
    button refreshButton "Refresh profile" pos:[248,208] width:216 height:26
    editText statusText "Status:" text:"Register first, then explicitly mark eligible books." readOnly:true pos:[14,250] width:450 height:54
    fn failure action detail = (lastError = action+": "+(detail as string);statusText.text = lastError;false)
    fn onRefresh =
    (
        try
        (
            local detail = caAssetDetail setupNode assetID
            local tag = caAssetBookRow setupNode assetID
            if tag < 0 or tag > 4 do throw "Unexpected native spine side."
            assetLabel.text = detail[2]+" | "+(if detail[3] == 1 then "Book" else "Only Book assets can be eligible")
            eligible.checked = tag != 0
            if tag != 0 do spine.selection = tag
            lastError = ""
            true
        )
        catch (failure "Read upright book" (getCurrentException()))
    )
    fn bindAsset node id = (setupNode = node;assetID = id;onRefresh())
    fn onApply =
    (
        try
        (
            local tag = if eligible.checked then spine.selection else 0
            undo "Cyrus Arrange: upright book" on (caSetAssetBookRow setupNode assetID tag)
            if not onRefresh() do throw lastError
            statusText.text = "Profile saved. Generate validates protected rows against the edited profile."
            true
        )
        catch (failure "Apply upright book" (getCurrentException()))
    )
    fn errorMessage = lastError
    on applyButton pressed do onApply()
    on refreshButton pressed do onRefresh()
)
fn caShowBookRowAssetUI setup assetID =
(
    try (destroyDialog caBookRowAssetUI) catch ()
    createDialog caBookRowAssetUI width:480 height:324
    caBookRowAssetUI.bindAsset setup assetID
    caBookRowAssetUI
)
