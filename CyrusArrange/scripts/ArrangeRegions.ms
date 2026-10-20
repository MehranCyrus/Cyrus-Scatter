/* Bounded region policy controls. Furniture analysis and persistent identity stay native. */
global caRegionUI, caShowRegionUI, caArrangeUI
global caAnalyzeSetup, caRegionRows, caSetRegionRules
try (destroyDialog caRegionUI) catch ()

rollout caRegionUI "Cyrus Arrange | Surface Rules"
(
    local setupNode = undefined
    local regionRows = #()
    local selectedID = 0L
    local hydrating = false
    local lastError = ""
    label setupLabel "Choose an Arrange setup." pos:[14,12] width:610 height:26
    button analyzeButton "Analyze furniture" pos:[14,44] width:196 height:28
    button refreshButton "Refresh cached list" pos:[221,44] width:196 height:28
    button sendIDButton "Use ID for selective Generate" pos:[428,44] width:196 height:28
    listBox surfaces "Current native support regions:" items:#() pos:[14,88] width:610 height:7
    editText idText "Region ID:" text:"" readOnly:true pos:[14,230] width:240
    dropdownList role "Role:" items:#("Unknown","Exposed top","Open shelf","Tray","Ledge") selection:1 pos:[324,214] width:300
    editText regionLabel "Label:" text:"" pos:[14,270] width:610
    editText compartmentLabel "Compartment:" text:"" pos:[14,304] width:610
    label allowedLabel "Allowed asset categories:" pos:[14,342] width:610
    checkbox allowBook "Book" checked:true pos:[14,366] width:120
    checkbox allowBookStack "Book stack" checked:true pos:[142,366] width:120
    checkbox allowPlant "Plant" checked:true pos:[270,366] width:100
    checkbox allowCandle "Candle" checked:true pos:[380,366] width:110
    checkbox allowFrame "Frame" checked:true pos:[500,366] width:124
    checkbox allowVase "Vase" checked:true pos:[14,394] width:120
    checkbox allowAccessory "Accessory" checked:true pos:[142,394] width:120
    checkbox allowBowl "Bowl" checked:true pos:[270,394] width:100
    checkbox allowTableware "Tableware" checked:true pos:[380,394] width:110
    checkbox allowKitchenware "Kitchenware" checked:true pos:[500,394] width:124
    checkbox allowTray "Tray" checked:true pos:[14,422] width:120
    spinner density "Density multiplier:" range:[0,4,1] type:#float pos:[14,462] width:240 fieldWidth:88
    checkbox stacking "Allow stacking" checked:true pos:[270,462] width:150
    checkbox excluded "Exclude this region" checked:false pos:[428,462] width:196 tooltip:"Blocks new placement points here. Nearby props may extend across the boundary; use an obstacle for a fully clear area."
    spinner frontAngle "Front direction in world XY (deg):" range:[-360,360,0] type:#float pos:[14,502] width:350 fieldWidth:88
    label frontHint "0 = +X, 90 = +Y; horizontal unit vector." pos:[380,506] width:244 height:30
    label geometryInfo "No region selected." pos:[14,544] width:610 height:62
    button applyButton "Apply surface rules" pos:[14,620] width:290 height:28
    button reloadButton "Reload selected surface" pos:[324,620] width:300 height:28
    editText statusText "Status:" text:"Analyze explicitly, then select a region. Browsing cached rows does not Generate." readOnly:true pos:[14,666] width:610 height:64

    fn failure action detail = (lastError = action+": "+(detail as string);statusText.text = lastError;false)
    fn decimalID value =
    (
        local literal = value as string
        if literal.count > 0 and (literal[literal.count] == "L" or literal[literal.count] == "l") do
            literal = substring literal 1 (literal.count-1)
        literal
    )
    fn categoryControls = #(allowBook,allowBookStack,allowPlant,allowCandle,allowFrame,allowVase,allowAccessory,allowBowl,allowTableware,allowKitchenware,allowTray)
    fn categoryMask =
    (
        local bits = #(1,2,4,8,16,32,64,128,256,512,1024)
        local controls = categoryControls()
        local mask = 0
        for i = 1 to 11 where controls[i].checked do mask += bits[i]
        mask
    )
    fn showRow row =
    (
        if row.count != 13 do throw "Native region row has an unexpected shape."
        selectedID = row[1]
        idText.text = decimalID selectedID
        regionLabel.text = row[2]
        compartmentLabel.text = row[3]
        role.selection = row[4]
        local controls = categoryControls()
        local bits = #(1,2,4,8,16,32,64,128,256,512,1024)
        for i = 1 to 11 do controls[i].checked = (bit.and row[9] bits[i]) != 0
        density.value = row[10]
        stacking.checked = row[11]
        excluded.checked = row[12]
        frontAngle.value = atan2 row[13].y row[13].x
        local size = row[6]-row[5]
        local clearance = if row[7] < 0 then "infinite" else (formattedPrint row[7] format:".1f")+" mm"
        geometryInfo.text = "World min "+(row[5] as string)+" mm | max "+(row[6] as string)+" mm\nWorld X / Y / Z size: "+(formattedPrint size.x format:".1f")+" / "+(formattedPrint size.y format:".1f")+" / "+(formattedPrint size.z format:".1f")+" mm\nMinimum clearance: "+clearance+" | entirely open above: "+(row[8] as string)
        true
    )
    fn onSelect index =
    (
        try
        (
            if index < 1 or index > regionRows.count do throw "Select a current support region."
            showRow regionRows[index]
            statusText.text = "Edit this stable region's policy, then Apply. Analyze again after furniture changes."
            lastError = ""
            true
        )
        catch (failure "Select region" (getCurrentException()))
    )
    fn selectID id =
    (
        local index = 0
        for i = 1 to regionRows.count where regionRows[i][1] == id do index = i
        if index == 0 then failure "Select region" "This region ID is not in the cached active surface list. Analyze current furniture."
        else (surfaces.selection = index;onSelect index)
    )
    fn onRefresh =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose an Arrange setup first."
            local next = caRegionRows setupNode
            if next.count > 4096 do throw "The native surface list exceeds the UI bound."
            local labels = #()
            for row in next do
            (
                if row.count != 13 do throw "Load the matched native surface/UI contract."
                append labels ((decimalID row[1])+" | "+row[2]+" | "+role.items[row[4]]+" | z "+(formattedPrint row[5].z format:".1f")+" mm"+(if row[12] then " | EXCLUDED" else ""))
            )
            hydrating = true
            regionRows = next
            surfaces.items = labels
            local found = false
            for i = 1 to next.count where next[i][1] == selectedID do
            (
                found = true
                surfaces.selection = i
                showRow next[i]
            )
            if not found do
            (
                selectedID = 0L
                idText.text = ""
                geometryInfo.text = "Select a current surface. Previously selected IDs may be missing after geometry changes."
            )
            hydrating = false
            setupLabel.text = setupNode.name+" | "+(next.count as string)+" current support region(s)"
            lastError = ""
            true
        )
        catch (hydrating = false;failure "Read cached surfaces" (getCurrentException()))
    )
    fn bindSetup setup = (setupNode = setup;selectedID = 0L;onRefresh())
    fn onAnalyze =
    (
        try
        (
            local count = undefined
            undo "Cyrus Arrange: analyze furniture surfaces" on (count = caAnalyzeSetup setupNode)
            if not onRefresh() do throw lastError
            statusText.text = "Analyzed "+(count as string)+" support regions. Outputs retained; Manual waits for Generate, armed Live can update."
            true
        )
        catch (failure "Analyze furniture" (getCurrentException()))
    )
    fn onApply =
    (
        try
        (
            if selectedID == 0L do throw "Select a current support region first."
            if regionLabel.text.count > 512 or compartmentLabel.text.count > 512 do throw "Use labels of at most 512 characters."
            local front = [cos frontAngle.value,sin frontAngle.value,0]
            undo "Cyrus Arrange: surface rules" on
                (caSetRegionRules setupNode selectedID regionLabel.text compartmentLabel.text role.selection (categoryMask()) density.value stacking.checked excluded.checked front)
            if not onRefresh() do throw lastError
            statusText.text = "Surface rules saved. Manual waits for Generate; armed Live can update. Locked conflicts retain prior output."
            true
        )
        catch (failure "Apply surface rules" (getCurrentException()))
    )
    fn onReload =
    (
        local id = selectedID
        if not onRefresh() then false
        else selectID id
    )
    fn onSendID =
    (
        try
        (
            if selectedID == 0L do throw "Select a current support region first."
            if caArrangeUI == undefined or caArrangeUI.currentSetup() != setupNode do throw "Open this setup in the arrangement workflow first."
            caArrangeUI.regionText.text = decimalID selectedID
            statusText.text = "Region ID copied to the workflow selection field. Generate or Reroll there to use it."
            lastError = ""
            true
        )
        catch (failure "Use selective region ID" (getCurrentException()))
    )
    fn rows = regionRows
    fn currentRegionID = selectedID
    fn errorMessage = lastError
    on surfaces selected index do if not hydrating do onSelect index
    on analyzeButton pressed do onAnalyze()
    on refreshButton pressed do onRefresh()
    on applyButton pressed do onApply()
    on reloadButton pressed do onReload()
    on sendIDButton pressed do onSendID()
)

fn caShowRegionUI setup =
(
    try (destroyDialog caRegionUI) catch ()
    createDialog caRegionUI width:640 height:750
    caRegionUI.bindSetup setup
    caRegionUI
)
