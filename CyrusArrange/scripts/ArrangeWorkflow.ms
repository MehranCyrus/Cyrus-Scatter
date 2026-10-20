/* Artist controls over the native setup document. No scripted solve or polling timer. */
global caArrangeUI, caShowArrangeUI, caShowAdvancedArrangeUI, caShowAssetUI, caRulesUI, caShowRulesUI, caHomeUI
global caCreateSetup, caSetupSummary, caSetArrangeSettings, caGenerate, caOutputRows, caSetLocked, caRefreshAssets
global caSuggestFurniture, caCategoryRules, caSetCategoryRules, caResetCategoryRules
global caPreview, caPreviewInfo, caCommitPreview, caClearPreview
global caRegionUI, caShowRegionUI, CA_ARRANGE_SCRIPT_DIR
global caCollisionUI, caShowCollisionUI
global caCompositionUI, caShowCompositionUI, caCompositionSettings, caSetCompositionSettings, caCompositionRows, caCompositionStats
CA_ARRANGE_SCRIPT_DIR = getFilenamePath (getSourceFileName())
try (destroyDialog caArrangeUI) catch ()

rollout caArrangeUI "Cyrus Arrange | Advanced Settings"
(
    local setupNode = undefined
    local outputRows = #()
    local hydrating = false
    local lastError = ""
    label setupLabel "Create a setup from selected furniture, or select an existing setup." pos:[14,10] width:610 height:32
    button createButton "Create from selected furniture" pos:[14,48] width:196 height:26
    button useSetupButton "Use selected setup" pos:[221,48] width:196 height:26
    button assetsButton "Asset Library" pos:[428,48] width:196 height:26
    dropdownList category "Furniture:" items:#("TV console","Open shelf","Coffee table","Kitchen counter","Dining table") selection:1 pos:[14,86] width:196
    dropdownList style "Style:" items:#("Minimal","Balanced","Layered") selection:2 pos:[221,86] width:196
    editText seedText "Seed:" text:"1" pos:[428,103] width:196
    spinner density "Density:" range:[0,1,0.5] type:#float pos:[14,142] width:196 fieldWidth:80
    spinner spacing "Spacing (mm):" range:[0,1000000,20] type:#float pos:[221,142] width:196 fieldWidth:80
    spinner edge "Edge gap (mm):" range:[0,1000000,15] type:#float pos:[428,142] width:196 fieldWidth:80
    spinner cluster "Grouping:" range:[0,1,0.5] type:#float pos:[14,172] width:196 fieldWidth:80
    spinner heightVariation "Scale variation:" range:[0,1,0.25] type:#float pos:[221,172] width:196 fieldWidth:80 tooltip:"Varies uniform scale within each asset's minimum and maximum. Fixed-size assets stay unchanged."
    spinner emptySpace "Empty space:" range:[0,1,0.4] type:#float pos:[428,172] width:196 fieldWidth:80
    spinner cellMM "Sample grid (mm):" range:[0.1,1000000,25] type:#float pos:[14,202] width:196 fieldWidth:80
    checkbox live "Live after first Generate" checked:false pos:[221,202] width:196
    button applyButton "Apply settings" pos:[428,198] width:196 height:26
    editText regionText "Region IDs:" text:"" pos:[14,238] width:260 tooltip:"Region IDs belong to the current furniture inspection. Empty means all regions."
    button regionsButton "Surface rules..." pos:[285,234] width:160 height:26
    button collisionButton "Collision scope..." pos:[457,234] width:167 height:26
    button generateButton "Regenerate same seed" pos:[14,272] width:196 height:28
    button rerollButton "New variation" pos:[221,272] width:196 height:28
    button refreshAssetsButton "Refresh source assets" pos:[428,272] width:196 height:28
    button previewButton "Preview bounds" pos:[14,310] width:196 height:28 tooltip:"Preview shows estimated bounds; Commit revalidates current inputs."
    button commitButton "Commit preview" pos:[221,310] width:196 height:28
    button clearPreviewButton "Clear preview" pos:[428,310] width:196 height:28
    label populationInfo "No arrangement yet. Empty Region IDs means all regions." pos:[14,348] width:610 height:32
    multiListBox outputs "Owned outputs (ID | asset | region | lock):" items:#() pos:[14,390] width:610 height:8
    button selectOutputButton "Select listed outputs" pos:[14,544] width:196 height:24
    button lockButton "Lock selected outputs" pos:[221,544] width:196 height:24
    button unlockButton "Unlock selected outputs" pos:[428,544] width:196 height:24
    button refreshButton "Refresh setup view" pos:[14,580] width:196 height:24
    button rulesButton "Allowed-category rules" pos:[221,580] width:196 height:24
    button suggestButton "Suggest furniture category" pos:[428,580] width:196 height:24
    label liveInfo "Manual settings wait for Apply / Generate." pos:[14,614] width:400 height:20
    button compositionButton "Book rows / height balance..." pos:[428,608] width:196 height:26
    editText statusText "Status:" text:"Choose furniture and create a setup. Add accessories in Asset Library." readOnly:true pos:[14,644] width:610 height:92

    fn failure actionName detail =
    (
        lastError = actionName+": "+(detail as string)
        statusText.text = lastError
        false
    )
    fn seedValue =
    (
        if seedText.text.count < 1 or seedText.text.count > 19 do throw "Enter a nonnegative integer seed (at most 19 digits)."
        local result = 0L
        for i = 1 to seedText.text.count do
        (
            local digitIndex = findString "0123456789" seedText.text[i]
            if digitIndex == undefined do throw "The seed must contain decimal digits only."
            local digit = digitIndex-1
            if result > 922337203685477580L or (result == 922337203685477580L and digit > 7) do
                throw "Seed exceeds the supported positive Integer64 range."
            result = result*10L+digit
        )
        result
    )
    fn seedDisplay value =
    (
        -- Integer64's literal representation adds L; preserve every decimal digit.
        local literal = value as string
        if literal.count > 0 and (literal[literal.count] == "L" or literal[literal.count] == "l") do
            literal = substring literal 1 (literal.count-1)
        literal
    )
    fn authoredSettings =
        #(seedValue(),density.value,spacing.value,edge.value,cluster.value,heightVariation.value,emptySpace.value,style.selection,category.selection,cellMM.value,live.checked)
    fn requestedRegions =
    (
        if regionText.text.count > 32768 do throw "The region selection text is too long."
        local tokens = filterString regionText.text ",; \t"
        if tokens.count > 4096 do throw "Choose at most 4096 region IDs."
        local ids = #()
        for token in tokens do
        (
            local literal = token
            if literal.count > 0 and (literal[literal.count] == "L" or literal[literal.count] == "l") do
                literal = substring literal 1 (literal.count-1)
            if literal.count < 1 or literal.count > 10 do throw "Region IDs must contain 1..10 decimal digits."
            local value = 0L
            for i = 1 to literal.count do
            (
                local digitIndex = findString "0123456789" literal[i]
                if digitIndex == undefined do throw "Region IDs must be positive decimal integers separated by commas."
                local digit = digitIndex-1
                if value > 429496729L or (value == 429496729L and digit > 5) do
                    throw "Region IDs must lie within 1..4294967295."
                value = value*10L+digit
            )
            if value < 1 do throw "Region IDs must lie within 1..4294967295."
            appendIfUnique ids value
        )
        ids
    )
    fn onRefresh =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup."
            local summary = caSetupSummary setupNode
            if summary.count != 9 or summary[9].count != 11 do throw "Load the matched native/UI setup contract."
            local nextRows = caOutputRows setupNode
            if nextRows.count > 2000 do throw "Native output list exceeds the UI bound."
            local labels = #()
            for row in nextRows do
            (
                if row.count != 9 do throw "Native output row has an unexpected shape."
                append labels ((row[1] as string)+" | asset "+(row[2] as string)+" | region "+(row[3] as string)+" | "+(if row[7] then "locked" else "free"))
            )
            hydrating = true
            local settings = summary[9]
            seedText.text = seedDisplay settings[1]
            density.value = settings[2]
            spacing.value = settings[3]
            edge.value = settings[4]
            cluster.value = settings[5]
            heightVariation.value = settings[6]
            emptySpace.value = settings[7]
            style.selection = settings[8]
            category.selection = settings[9]
            cellMM.value = settings[10]
            live.checked = settings[11]
            outputRows = nextRows
            outputs.items = labels
            setupLabel.text = "Setup: "+summary[2]+" | revision "+(summary[3] as string)
            populationInfo.text = (summary[4] as string)+" registered assets | "+(summary[5] as string)+" placements | "+(if summary[6] == 0 then "current" else "changes pending")
            local preview = caPreviewInfo setupNode
            if preview[1] do populationInfo.text += "\nPreview: "+(preview[3] as string)+" bounds | "+(if preview[2] then "ready to commit" else preview[4])
            liveInfo.text = if summary[7] then "Live: native updates coalesce after first Generate." else "Manual: settings wait for Apply / Generate."
            hydrating = false
            lastError = ""
            if summary[8] != "" do statusText.text = summary[8]
            true
        )
        catch
        (
            hydrating = false
            failure "Refresh setup" (getCurrentException())
        )
    )
    fn bindSetup node =
    (
        setupNode = node
        onRefresh()
    )
    fn onCreate =
    (
        try
        (
            local furniture = selection as array
            if furniture.count == 0 do throw "Select the furniture model or its group first."
            local node = undefined
            undo "Cyrus Arrange: create setup" on (node = caCreateSetup furniture category.selection)
            if not bindSetup node do throw lastError
            statusText.text = "Setup created. Add prepared accessories in Asset Library, then Generate."
            true
        )
        catch (failure "Create setup" (getCurrentException()))
    )
    fn onUseSetup =
    (
        try
        (
            local chosen = selection as array
            if chosen.count != 1 do throw "Select exactly one existing Arrange setup."
            bindSetup chosen[1]
        )
        catch (failure "Choose setup" (getCurrentException()))
    )
    fn onApply =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup."
            local settings = authoredSettings()
            undo "Cyrus Arrange: settings" on (caSetArrangeSettings setupNode settings)
            if not onRefresh() do throw lastError
            statusText.text = if live.checked then "Settings applied. Native Live updates begin after a first successful Generate." else "Settings applied. Press Generate to update placements."
            true
        )
        catch (failure "Apply settings" (getCurrentException()))
    )
    fn onEdited =
    (
        if not hydrating do
        (
            if live.checked and isValidNode setupNode then onApply()
            else statusText.text = "Draft settings. Apply settings or Generate to publish them."
        )
    )
    fn resultSummary result =
    (
        if result.count != 6 do throw "Unexpected native arrangement result."
        local text = "Accepted "+(seedDisplay result[2])+" of "+(seedDisplay result[1])+" requested | kept "+(seedDisplay result[3])+" | underfilled "+(seedDisplay result[5])
        if result[6].count > 0 do text += "\n"+(result[6][1] as string)
        text
    )
    fn onGenerate reroll:false =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup."
            if reroll do
            (
                local currentSeed = seedValue()
                if currentSeed >= 9223372036854775807L do throw "Choose a smaller seed before rerolling."
                seedText.text = seedDisplay (currentSeed+1L)
            )
            local settings = authoredSettings()
            local regions = requestedRegions()
            local result = undefined
            undo "Cyrus Arrange: generate" on
            (
                caSetArrangeSettings setupNode settings
                result = caGenerate setupNode regions
            )
            if result.count != 6 do throw "Unexpected native generation result."
            if not onRefresh() do throw lastError
            statusText.text = resultSummary result
            true
        )
        catch (failure "Generate" (getCurrentException()))
    )
    fn onRefreshAssets =
    (
        try
        (
            undo "Cyrus Arrange: refresh assets" on (caRefreshAssets setupNode)
            if not onRefresh() do throw lastError
            statusText.text = "Source assets refreshed. Generate to update their placement fit."
            true
        )
        catch (failure "Refresh assets" (getCurrentException()))
    )
    fn onPreview =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup."
            local settings = authoredSettings()
            local regions = requestedRegions()
            local result = undefined
            undo "Cyrus Arrange: preview settings" on
            (
                caSetArrangeSettings setupNode settings
                result = caPreview setupNode regions
            )
            if not onRefresh() do throw lastError
            statusText.text = "Preview bounds | "+(resultSummary result)+"\nOutputs retained; Live pauses until Commit or Generate."
            true
        )
        catch (failure "Preview bounds" (getCurrentException()))
    )
    fn onCommitPreview =
    (
        try
        (
            local result = undefined
            undo "Cyrus Arrange: commit preview" on (result = caCommitPreview setupNode)
            if not onRefresh() do throw lastError
            statusText.text = "Committed | "+(resultSummary result)
            true
        )
        catch (failure "Commit preview" (getCurrentException()))
    )
    fn onClearPreview =
    (
        try
        (
            caClearPreview setupNode
            if not onRefresh() do throw lastError
            statusText.text = "Preview cleared. Outputs retained; Generate re-arms Live."
            true
        )
        catch (failure "Clear preview" (getCurrentException()))
    )
    fn selectedOutputIDs =
    (
        local ids = #()
        local indexes = outputs.selection as array
        for index in indexes where index >= 1 and index <= outputRows.count do appendIfUnique ids outputRows[index][1]
        local chosen = selection as array
        if chosen.count > 4096 do throw "Select at most 4096 scene nodes."
        for row in outputRows where isValidNode row[9] and (findItem chosen row[9]) > 0 do appendIfUnique ids row[1]
        ids
    )
    fn onSelectOutputs =
    (
        local nodes = #()
        for index in outputs.selection where index >= 1 and index <= outputRows.count do
            if isValidNode outputRows[index][9] do append nodes outputRows[index][9]
        if nodes.count > 0 then (select nodes;true) else false
    )
    fn onLock value =
    (
        try
        (
            local ids = selectedOutputIDs()
            if ids.count == 0 do throw "Select generated objects in the viewport or output list."
            undo "Cyrus Arrange: output locks" on (caSetLocked setupNode ids value)
            if not onRefresh() do throw lastError
            statusText.text = (if value then "Locked " else "Unlocked ")+"selected outputs, including every member of affected book rows."
            true
        )
        catch (failure "Change locks" (getCurrentException()))
    )
    fn onAssets =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup."
            caShowAssetUI setupNode
            true
        )
        catch (failure "Open asset library" (getCurrentException()))
    )
    fn onComposition =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup."
            caShowCompositionUI setupNode
            true
        )
        catch (failure "Open book rows" (getCurrentException()))
    )
    fn onSuggest =
    (
        try
        (
            local result = caSuggestFurniture (selection as array)
            if result.count != 2 do throw "Native furniture suggestion has an unexpected shape."
            if result[1] == 0 do throw result[2]
            hydrating = true
            category.selection = result[1]
            hydrating = false
            statusText.text = result[2]+" Review the category, then Apply settings or create a setup."
            lastError = ""
            true
        )
        catch (hydrating = false;failure "Suggest furniture" (getCurrentException()))
    )
    fn onRules =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup first."
            caShowRulesUI setupNode category.selection
            true
        )
        catch (failure "Open category rules" (getCurrentException()))
    )
    fn onRegions =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup first."
            if caShowRegionUI == undefined do fileIn (CA_ARRANGE_SCRIPT_DIR+"ArrangeRegions.ms")
            caShowRegionUI setupNode
            true
        )
        catch (failure "Open surface rules" (getCurrentException()))
    )
    fn onCollision =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose or create an Arrange setup first."
            if caShowCollisionUI == undefined do fileIn (CA_ARRANGE_SCRIPT_DIR+"ArrangeCollision.ms")
            caShowCollisionUI setupNode
            true
        )
        catch (failure "Open collision scope" (getCurrentException()))
    )
    fn currentSetup = setupNode
    fn rows = outputRows
    fn errorMessage = lastError
    on createButton pressed do onCreate()
    on useSetupButton pressed do onUseSetup()
    on assetsButton pressed do onAssets()
    on compositionButton pressed do onComposition()
    on suggestButton pressed do onSuggest()
    on rulesButton pressed do onRules()
    on regionsButton pressed do onRegions()
    on collisionButton pressed do onCollision()
    on applyButton pressed do onApply()
    on generateButton pressed do onGenerate()
    on rerollButton pressed do onGenerate reroll:true
    on refreshAssetsButton pressed do onRefreshAssets()
    on previewButton pressed do onPreview()
    on commitButton pressed do onCommitPreview()
    on clearPreviewButton pressed do onClearPreview()
    on refreshButton pressed do onRefresh()
    on selectOutputButton pressed do onSelectOutputs()
    on lockButton pressed do onLock true
    on unlockButton pressed do onLock false
    on density changed value do onEdited()
    on spacing changed value do onEdited()
    on edge changed value do onEdited()
    on cluster changed value do onEdited()
    on heightVariation changed value do onEdited()
    on emptySpace changed value do onEdited()
    on cellMM changed value do onEdited()
    on live changed value do onEdited()
    on category selected value do onEdited()
    on style selected value do onEdited()
    on seedText entered value do onEdited()
    on caArrangeUI close do
        if caHomeUI != undefined and caHomeUI.currentSetup() == setupNode do caHomeUI.onRefresh preserveDrafts:true
)

try (destroyDialog caRulesUI) catch ()
rollout caRulesUI "Cyrus Arrange | Allowed Categories"
(
    local setupNode = undefined
    local furnitureCategory = 1
    local ruleRows = #()
    local currentIndex = 0
    local hydrating = false
    local lastError = ""
    label categoryLabel "" pos:[14,12] width:610 height:28
    listBox ruleList "Category | weight | maximum per support region | stack children:" items:#() pos:[14,48] width:610 height:11
    spinner ruleWeight "Weight:" range:[0.001,1000000,1] type:#float pos:[14,268] width:196 fieldWidth:85
    spinner maxCount "Maximum per region:" range:[0,2000,0] type:#integer pos:[221,268] width:230 fieldWidth:85
    checkbox allowOnStack "Allow as stack child" checked:false pos:[462,268] width:162
    label helpText "A maximum of zero disables a category. Asset furniture masks also apply.\nThese rules belong to this setup and furniture category; switching categories retains its rules." pos:[14,308] width:610 height:42
    button applyButton "Apply category rules" pos:[14,362] width:196 height:28
    button resetButton "Restore category defaults" pos:[221,362] width:196 height:28
    button refreshButton "Reload current rules" pos:[428,362] width:196 height:28
    editText statusText "Status:" text:"" readOnly:true pos:[14,408] width:610 height:68
    fn failure action detail = (lastError = action+": "+(detail as string);statusText.text = lastError;false)
    fn storeRow =
    (
        if currentIndex >= 1 and currentIndex <= ruleRows.count do
            ruleRows[currentIndex] = #(ruleRows[currentIndex][1],ruleWeight.value,maxCount.value,allowOnStack.checked)
        true
    )
    fn loadRow index =
    (
        if index >= 1 and index <= ruleRows.count do
        (
            currentIndex = index
            ruleWeight.value = ruleRows[index][2]
            maxCount.value = ruleRows[index][3]
            allowOnStack.checked = ruleRows[index][4]
        )
        true
    )
    fn onRefresh =
    (
        try
        (
            local next = caCategoryRules setupNode furnitureCategory
            if next.count != 11 do throw "Native category rules must contain eleven rows."
            local names = #("Book","Book stack","Plant","Candle","Frame","Vase","Accessory","Bowl","Tableware","Kitchenware","Tray")
            local labels = #()
            for row in next do
            (
                if row.count != 4 do throw "Native category rule has an unexpected shape."
                append labels (names[row[1]]+" | "+(formattedPrint row[2] format:".4g")+" | "+(row[3] as string)+" | "+(if row[4] then "stack allowed" else "base only"))
            )
            hydrating = true
            ruleRows = next
            ruleList.items = labels
            ruleList.selection = 1
            loadRow 1
            hydrating = false
            lastError = ""
            statusText.text = "Edit category values, then Apply. Passive browsing does not generate placements."
            true
        )
        catch (hydrating = false;failure "Read category rules" (getCurrentException()))
    )
    fn bindSetup setup category =
    (
        setupNode = setup
        furnitureCategory = category
        local names = #("TV console","Open shelf","Coffee table","Kitchen counter","Dining table")
        categoryLabel.text = setup.name+" | "+names[category]
        onRefresh()
    )
    fn onApply =
    (
        try
        (
            storeRow()
            undo "Cyrus Arrange: category rules" on (caSetCategoryRules setupNode furnitureCategory ruleRows)
            if not onRefresh() do throw lastError
            statusText.text = "Category rules saved. Generate to validate the next arrangement."
            true
        )
        catch (failure "Apply category rules" (getCurrentException()))
    )
    fn onReset =
    (
        try
        (
            undo "Cyrus Arrange: reset category rules" on (caResetCategoryRules setupNode furnitureCategory)
            onRefresh()
        )
        catch (failure "Restore category rules" (getCurrentException()))
    )
    fn rows = ruleRows
    fn errorMessage = lastError
    on ruleList selected index do if not hydrating do (storeRow();loadRow index)
    on applyButton pressed do onApply()
    on resetButton pressed do onReset()
    on refreshButton pressed do onRefresh()
)
fn caShowRulesUI setup category =
(
    try (destroyDialog caRulesUI) catch ()
    createDialog caRulesUI width:640 height:494
    caRulesUI.bindSetup setup category
    caRulesUI
)

fn caShowAdvancedArrangeUI setup:undefined =
(
    try (destroyDialog caArrangeUI) catch ()
    createDialog caArrangeUI width:640 height:754
    if setup != undefined do caArrangeUI.bindSetup setup
    caArrangeUI
)

rollout caCompositionUI "Cyrus Arrange | Book Rows"
(
    local setupNode = undefined
    local groupRows = #()
    local lastError = ""
    label setupLabel "Choose a TV console or open-shelf setup." pos:[14,12] width:530 height:28
    checkbox bookRows "Generate rows of individual upright books" checked:false pos:[14,48] width:530
    spinner minimumBooks "Minimum books:" range:[2,6,2] type:#integer pos:[14,80] width:254 fieldWidth:64
    spinner maximumBooks "Maximum books:" range:[2,6,6] type:#integer pos:[286,80] width:254 fieldWidth:64
    spinner rowGap "Gap within a row (mm):" range:[0,1000000,3] type:#float pos:[14,114] width:254 fieldWidth:64
    spinner heightBalance "Row height balance:" range:[0,1,0] type:#float pos:[286,114] width:254 fieldWidth:64 tooltip:"Translates new unlocked rows to improve their region's left/right height profile. Keeps book sizes and other props fixed. Zero disables the pass."
    label guidance "Mark individual Book assets as upright in Asset Library. Allowed yaw angles must face the surface front. Rows use 2-6 population slots; a grouped source remains one asset." pos:[14,152] width:530 height:48
    button applyButton "Apply composition settings" pos:[14,212] width:254 height:26
    button refreshButton "Refresh saved settings" pos:[286,212] width:254 height:26
    listBox rows "Generated rows (select to inspect):" items:#() pos:[14,252] width:530 height:6
    label selectedInfo "Locking any member locks its whole row. Unlock a broken row before regenerating." pos:[14,370] width:530 height:36
    button selectButton "Select all members of this row" pos:[14,414] width:254 height:26
    label statsInfo "Generate to measure composition." pos:[14,454] width:530 height:36
    editText statusText "Status:" text:"Changes wait for Generate in Manual mode." readOnly:true pos:[14,502] width:530 height:54
    fn failure action detail = (lastError = action+": "+(detail as string);statusText.text = lastError;false)
    fn onRefresh =
    (
        try
        (
            local settings = caCompositionSettings setupNode
            if settings.count != 5 do throw "Unexpected native composition settings."
            bookRows.checked = settings[1]
            minimumBooks.value = settings[2]
            maximumBooks.value = settings[3]
            rowGap.value = settings[4]
            heightBalance.value = settings[5]
            local category = (caSetupSummary setupNode)[9][9]
            local supported = category == 1 or category == 2
            bookRows.enabled = supported
            minimumBooks.enabled = supported
            maximumBooks.enabled = supported
            rowGap.enabled = supported
            heightBalance.enabled = supported
            groupRows = caCompositionRows setupNode
            if groupRows.count > 5000 do throw "Native row list exceeds its bound."
            local labels = #()
            for row in groupRows do
            (
                if row.count != 6 do throw "Unexpected native row record."
                append labels ((row[1] as string)+" | surface "+(row[3] as string)+" | "+(row[4].count as string)+" books")
            )
            rows.items = labels
            setupLabel.text = "Setup: "+setupNode.name+(if supported then "" else " | Book rows require TV console or open shelf")
            local stats = caCompositionStats setupNode
            if stats.count != 6 do throw "Unexpected native composition statistics."
            statsInfo.text = if stats[1] then ((stats[3] as string)+" new rows | "+(stats[4] as string)+" unsuccessful row attempts | "+(stats[6] as string)+" balanced moves") else "No current Generate statistics. Saved row records remain listed above."
            lastError = ""
            true
        )
        catch (failure "Read book rows" (getCurrentException()))
    )
    fn bindSetup node = (setupNode = node;onRefresh())
    fn onApply =
    (
        try
        (
            local options = #(bookRows.checked,minimumBooks.value,maximumBooks.value,rowGap.value,heightBalance.value)
            undo "Cyrus Arrange: book rows" on (caSetCompositionSettings setupNode options)
            if not onRefresh() do throw lastError
            statusText.text = "Settings saved. Generate to form rows; protected rows retain their saved gap."
            true
        )
        catch (failure "Apply book rows" (getCurrentException()))
    )
    fn onSelect =
    (
        try
        (
            local index = rows.selection
            if index < 1 or index > groupRows.count do throw "Select a generated row first."
            local members = groupRows[index][4]
            local outputs = caOutputRows setupNode
            local chosen = #()
            for output in outputs where (findItem members output[1]) > 0 do
                if isValidNode output[9] do append chosen output[9]
            if chosen.count != members.count do throw "A row member is missing. Unlock and regenerate the row, or Undo its deletion."
            select chosen
            statusText.text = "Selected every member. A row lock or unlock applies to all these books."
            true
        )
        catch (failure "Select row members" (getCurrentException()))
    )
    fn errorMessage = lastError
    on applyButton pressed do onApply()
    on refreshButton pressed do onRefresh()
    on selectButton pressed do onSelect()
)
fn caShowCompositionUI setup =
(
    try (destroyDialog caCompositionUI) catch ()
    createDialog caCompositionUI width:560 height:578
    caCompositionUI.bindSetup setup
    caCompositionUI
)


/* Main artist workflow. Discovery reads native bindings; only explicit commands mutate. */
global caHomeUI, caHomePropsUI, caShowHomePropsUI, caSceneSetups, caGenerateVariation
global caRegisterAssets, caCreatePropGroup, caReadExactSeed
fn caReadExactSeed text =
(
    local value = 0L
    if text.count < 1 or text.count > 19 do throw "Enter a nonnegative whole-number seed."
    for i = 1 to text.count do
    (
        local digitIndex = findString "0123456789" text[i]
        if digitIndex == undefined do throw "The seed must contain digits only."
        local digit = digitIndex-1
        if value > 922337203685477580L or (value == 922337203685477580L and digit > 7) do throw "Seed is too large."
        value = value*10L+digit
    )
    value
)
try (callbacks.removeScripts id:#CyrusArrangeHomeSelection) catch ()
try (destroyDialog caHomeUI) catch ()
try (destroyDialog caHomePropsUI) catch ()

rollout caHomePropsUI "Cyrus Arrange | Props"
(
    local setupNode = undefined
    local independentOwner = false
    local ownerGuid = undefined
    local opened = false
    local lastError = ""
    label hint "Select original models or existing groups, choose a type, then Add. Each model or group becomes one prop." pos:[14,12] width:432 height:42
    listBox props "Props available to this arrangement:" items:#() pos:[14,62] width:432 height:8
    dropdownList propType "Type for new props:" items:#("Book","Book stack","Plant","Candle","Frame","Vase","Accessory","Bowl","Tableware","Kitchenware","Tray") selection:7 pos:[14,218] width:432
    button addButton "Add selected props" pos:[14,274] width:432 height:30 tooltip:"Add selected original models and groups together. Existing entries are kept unchanged."
    label groupHint "For one reusable composition, arrange the pieces together first, then select at least two models or groups." pos:[14,314] width:432 height:34
    editText groupName "Group name:" text:"Decor group" pos:[14,356] width:432
    button groupButton "Create decor group" pos:[14,388] width:432 height:30 tooltip:"Copy the selection into one reusable prop, keeping its relative positions and real size. Originals stay unchanged."
    button moreButton "Library & detailed options..." pos:[14,430] width:432 height:28
    editText statusText "" text:"New props use their real size. Decor groups copy the current arrangement of their pieces." readOnly:true pos:[14,470] width:432 height:66
    fn fail message = (lastError = message as string;if opened do statusText.text = lastError;false)
    fn isCurrentOwner node =
    (
        opened and setupNode == node and isValidNode node and
            (independentOwner or (caHomeUI != undefined and caHomeUI.currentSetup() == node))
    )
    fn requireOwner =
    (
        if not isCurrentOwner setupNode do
            throw "The active furniture changed. Open Props... again from the main window."
        -- A Modify rollout can close when the artist selects accessory models.
        -- This bounded dialog keeps its captured document, not a stale selection.
        if (caSetupSummary setupNode)[1] != ownerGuid do
            throw "This arrangement document changed. Open Props... again from its current icon."
        true
    )
    fn onRefresh =
    (
        try
        (
            requireOwner()
            local rows = caAssetRows setupNode
            props.items = for row in rows collect ((row[2] as string)+" | "+propType.items[row[3]])
            true
        )
        catch (fail (getCurrentException()))
    )
    fn bindSetup node standalone:false =
    (
        setupNode = node
        independentOwner = standalone
        ownerGuid = (caSetupSummary node)[1]
        groupName.text = "Decor group"
        hint.text = "Props for "+node.name+". Select original models or groups, choose their type, then Add."
        onRefresh()
    )
    fn refreshAfterIntake commandSetup message =
    (
        -- A scene callback may have switched owners or closed this window.
        -- Do not hydrate another arrangement with the completed command's UI.
        if not isCurrentOwner commandSetup then true
        else
        (
            if not onRefresh() do throw lastError
            if caHomeUI != undefined and caHomeUI.currentSetup() == commandSetup do
                caHomeUI.onRefresh preserveDrafts:true
            if isCurrentOwner commandSetup do
            (
                statusText.text = message
                lastError = ""
            )
            true
        )
    )
    fn onAdd =
    (
        local commandSetup = setupNode
        try
        (
            requireOwner()
            local chosen = selection as array
            local result = undefined
            undo "Cyrus Arrange: add props" on
                (result = caRegisterAssets commandSetup chosen propType.selection)
            local message = "Added "+(result[1].count as string)+" prop(s); "+(result[2].count as string)+" already available. Real size is preserved. Click Generate."
            refreshAfterIntake commandSetup message
        )
        catch (fail (getCurrentException()))
    )
    fn onCreateGroup =
    (
        local commandSetup = setupNode
        try
        (
            requireOwner()
            local chosen = selection as array
            local result = undefined
            undo "Cyrus Arrange: create decor group" on
                (result = caCreatePropGroup commandSetup chosen groupName.text propType.selection)
            local copiedGroup = result[1]
            if not isValidNode copiedGroup do throw "The new decor source is no longer in the scene."
            if isCurrentOwner commandSetup do
                select copiedGroup
            refreshAfterIntake commandSetup ("Added "+copiedGroup.name+" as one prop. Copies keep the arranged spacing and real size. Select this group to add it to other furniture.")
        )
        catch (fail (getCurrentException()))
    )
    fn onMore =
    (
        try (requireOwner();caShowAssetUI setupNode;true)
        catch (fail (getCurrentException()))
    )
    fn errorMessage = lastError
    on addButton pressed do onAdd()
    on groupButton pressed do onCreateGroup()
    on moreButton pressed do onMore()
    on caHomePropsUI open do opened = true
    on caHomePropsUI close do
    (
        opened = false
        setupNode = undefined
        ownerGuid = undefined
        independentOwner = false
    )
)
fn caShowHomePropsUI setup independentOwner:false =
(
    try (destroyDialog caHomePropsUI) catch ()
    createDialog caHomePropsUI width:460 height:552
    caHomePropsUI.bindSetup setup standalone:independentOwner
    caHomePropsUI
)

rollout caHomeUI "Cyrus Arrange 0.3.2"
(
    local setupNode = undefined
    local setupRows = #()
    local hydrating = false
    local discovering = false
    local lastError = ""
    local loadedSettings = #()
    local loadedAmount = 0.0
    local loadedSpacing = 0.0
    local opened = false
    label intro "Choose furniture, add props, then Generate." pos:[14,12] width:432 height:22
    dropdownList arrangement "Arrangement in this scene:" items:#("Select furniture to begin") selection:1 pos:[14,40] width:432
    dropdownList furnitureType "Furniture type:" items:#("TV console","Open shelf","Coffee table","Kitchen counter","Dining table") selection:1 pos:[14,104] width:432
    button useFurnitureButton "Use selected furniture" pos:[14,164] width:210 height:30
    button propsButton "Props..." pos:[236,164] width:210 height:30
    label furnitureInfo "No arrangement selected." pos:[14,206] width:432 height:34
    spinner amount "Amount (%):" range:[0,100,10] type:#float pos:[14,252] width:210 fieldWidth:84 tooltip:"Placement density as a percentage. Available space and rules limit the actual count."
    spinner spacing "Spacing (mm):" range:[0,1000000,20] type:#float pos:[236,252] width:210 fieldWidth:84
    button generateButton "Generate" pos:[14,292] width:432 height:44 tooltip:"Create a new variation. Enable Repeat seed to reproduce this seed."
    checkbox keepSeed "Repeat seed" checked:false pos:[14,353] width:120 tooltip:"Show the seed and repeat it. Off creates a new seed on each successful Generate."
    editText seedText "Seed:" text:"1" pos:[146,350] width:300 visible:false enabled:false
    button lockButton "Keep selected props" pos:[14,394] width:210 height:28
    button unlockButton "Release selected props" pos:[236,394] width:210 height:28
    button advancedButton "Advanced..." pos:[14,438] width:432 height:28
    button refreshButton "Refresh" pos:[236,438] width:210 height:28 visible:false tooltip:"Read saved settings after edits in Advanced. Does not generate."
    editText statusText "" text:"Select furniture in Max, then click Use selected furniture. Saved arrangements are listed above." readOnly:true pos:[14,482] width:432 height:82

    fn fail message = (lastError = message as string;statusText.text = lastError;false)
    fn decimal value = (trimRight (value as string) "Ll")
    fn readSeed = caReadExactSeed seedText.text
    fn currentSetup = (if opened and isValidNode setupNode then setupNode else undefined)
    fn syncSeedControls =
    (
        seedText.visible = keepSeed.checked
        seedText.enabled = keepSeed.checked
        true
    )
    fn onRefresh preserveDrafts:false =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose an arrangement or select furniture first."
            local oldAmount = amount.value, oldSpacing = spacing.value
            local oldSeed = seedText.text, oldType = furnitureType.selection
            local preserveAmount = preserveDrafts and loadedSettings.count == 11 and oldAmount != loadedAmount
            local preserveSpacing = preserveDrafts and loadedSettings.count == 11 and oldSpacing != loadedSpacing
            local preserveSeed = preserveDrafts and loadedSettings.count == 11 and oldSeed != (decimal loadedSettings[1])
            local preserveType = preserveDrafts and loadedSettings.count == 11 and oldType != loadedSettings[9]
            local summary = caSetupSummary setupNode
            local settings = summary[9]
            loadedSettings = for value in settings collect value
            hydrating = true
            furnitureType.selection = settings[9]
            amount.value = settings[2]*100.0
            spacing.value = settings[3]
            seedText.text = decimal settings[1]
            loadedAmount = amount.value
            loadedSpacing = spacing.value
            if preserveAmount do amount.value = oldAmount
            if preserveSpacing do spacing.value = oldSpacing
            if preserveSeed do seedText.text = oldSeed
            if preserveType do furnitureType.selection = oldType
            syncSeedControls()
            furnitureInfo.text = furnitureType.items[settings[9]]+" | "+(decimal summary[4])+" prop models | "+(decimal summary[5])+" placed"
            hydrating = false
            statusText.text = if summary[4] == 0 then "Furniture ready. Click Props... to add an original model, then Generate." else "Ready. Generate makes a new variation; Repeat seed shows and repeats the saved seed."
            if summary[8] != "" do statusText.text = summary[8]
            lastError = ""
            true
        )
        catch (hydrating = false;fail (getCurrentException()))
    )
    fn bindSetup node =
    (
        if not isValidNode node then fail "This arrangement is no longer in the scene. Select furniture again."
        else
        (
            local sameOwner = setupNode == node
            if not sameOwner do try (destroyDialog caHomePropsUI) catch ()
            setupNode = node
            hydrating = true
            for i = 1 to setupRows.count where setupRows[i][1] == node do arrangement.selection = i
            hydrating = false
            onRefresh preserveDrafts:sameOwner
        )
    )
    fn onDiscover =
    (
        if discovering then false
        else
        (
            discovering = true
            local succeeded = false
            try
            (
                local rows = caSceneSetups (selection as array)
                local matches = for row in rows where row[2] collect row[1]
                local desired = if isValidNode setupNode then setupNode else undefined
                if matches.count == 1 then desired = matches[1]
                else if matches.count > 1 then desired = undefined
                else if desired == undefined and rows.count == 1 then desired = rows[1][1]
                local index = 0
                for i = 1 to rows.count where rows[i][1] == desired do index = i
                if index == 0 do desired = undefined
                hydrating = true
                setupRows = rows
                arrangement.items = if rows.count == 0 then #("Select furniture to begin") else
                    (for row in rows collect ((if row[3].count > 0 and isValidNode row[3][1] then row[3][1].name else row[1].name)+" | "+row[1].name))
                arrangement.selection = index
                hydrating = false
                if desired != undefined then
                (
                    if setupNode != desired do bindSetup desired
                )
                else
                (
                    try (destroyDialog caHomePropsUI) catch ()
                    setupNode = undefined
                    loadedSettings = #()
                    furnitureInfo.text = "No arrangement selected."
                    statusText.text = if rows.count == 0 then "Select furniture and click Use selected furniture." else "Choose an arrangement from the list, or select its furniture in Max."
                )
                succeeded = true
            )
            catch (hydrating = false;fail (getCurrentException()))
            discovering = false
            succeeded
        )
    )
    fn onUseFurniture =
    (
        try
        (
            local chosen = selection as array
            if chosen.count == 0 do throw "Select the furniture model or its group in Max first."
            local rows = caSceneSetups chosen
            local matches = for row in rows where row[2] collect row[1]
            if matches.count > 1 do throw "This selection belongs to several arrangements. Choose one in the arrangement list."
            local node = undefined
            local created = false
            if matches.count == 1 then node = matches[1]
            else
            (
                local furniture = caAssetUI.selectedModelRoots()
                undo "Cyrus Arrange: choose furniture" on (node = caCreateSetup furniture furnitureType.selection)
                created = true
            )
            if not bindSetup node do throw lastError
            onDiscover()
            if created do amount.value = 10
            true
        )
        catch (fail (getCurrentException()))
    )
    fn onGenerate =
    (
        local commandSetup = setupNode
        discovering = true
        try
        (
            if not isValidNode commandSetup do throw "Select furniture and click Use selected furniture first."
            local summary = caSetupSummary commandSetup
            if summary[4] == 0 do throw "No props yet. Click Props... and add your original models or groups."
            local settings = summary[9]
            local enteredSeed = if keepSeed.checked then readSeed() else settings[1]
            -- Only main-window drafts override the current native state. A
            -- change applied in Advanced is not overwritten by an untouched
            -- field in this already-open window.
            if loadedSettings.count != 11 do throw "Refresh the arrangement before generating."
            if keepSeed.checked and seedText.text != (decimal loadedSettings[1]) do settings[1] = enteredSeed
            if amount.value != loadedAmount do settings[2] = amount.value/100.0
            if spacing.value != loadedSpacing do settings[3] = spacing.value
            if furnitureType.selection != loadedSettings[9] do settings[9] = furnitureType.selection
            -- Native command stages settings/seed and publishes them with output;
            -- there is no earlier caSetArrangeSettings commit to undo on failure.
            local result = caGenerateVariation commandSetup settings #() (not keepSeed.checked)
            if not onRefresh() do throw lastError
            statusText.text = (decimal result[2])+" placed / "+(decimal result[1])+" requested | "+(decimal result[3])+" kept | "+(decimal result[5])+" unfilled\nSeed "+seedText.text
            if result[6].count > 0 do statusText.text += "\n"+(result[6][1] as string)
            discovering = false
            true
        )
        catch (discovering = false;fail (getCurrentException()))
    )
    fn onLock value =
    (
        local commandSetup = setupNode
        discovering = true
        try
        (
            if not isValidNode commandSetup do throw "Choose furniture first."
            local chosen = selection as array
            local ids = for row in (caOutputRows commandSetup) where (findItem chosen row[9]) > 0 collect row[1]
            if ids.count == 0 do throw "Select this arrangement's generated props in the viewport first."
            undo "Cyrus Arrange: keep props" on (caSetLocked commandSetup ids value)
            onRefresh()
            statusText.text = if value then "Selected props are kept during Generate. A book row is kept together." else "Selected props are free to change during Generate."
            discovering = false
            true
        )
        catch (discovering = false;fail (getCurrentException()))
    )
    fn onAdvanced =
    (
        try (if not isValidNode setupNode do throw "Choose furniture first.";caShowAdvancedArrangeUI setup:setupNode;true)
        catch (fail (getCurrentException()))
    )
    fn onProps =
    (
        try (if not isValidNode setupNode do throw "Choose furniture first.";caShowHomePropsUI setupNode;true)
        catch (fail (getCurrentException()))
    )
    fn errorMessage = lastError
    on arrangement selected index do if not hydrating and index >= 1 and index <= setupRows.count do bindSetup setupRows[index][1]
    on useFurnitureButton pressed do onUseFurniture()
    on propsButton pressed do onProps()
    on generateButton pressed do onGenerate()
    on lockButton pressed do onLock true
    on unlockButton pressed do onLock false
    on advancedButton pressed do onAdvanced()
    on keepSeed changed state do syncSeedControls()
    on seedText entered value do (keepSeed.checked = true;syncSeedControls())
    on refreshButton pressed do (onDiscover();if isValidNode setupNode do onRefresh())
    on caHomeUI open do
    (
        opened = true
        syncSeedControls()
        callbacks.removeScripts id:#CyrusArrangeHomeSelection
        callbacks.addScript #selectionSetChanged "if caHomeUI != undefined do caHomeUI.onDiscover()" id:#CyrusArrangeHomeSelection persistent:false
        callbacks.addScript #filePostOpen "if caHomeUI != undefined do caHomeUI.onDiscover()" id:#CyrusArrangeHomeSelection persistent:false
        callbacks.addScript #systemPostReset "if caHomeUI != undefined do caHomeUI.onDiscover()" id:#CyrusArrangeHomeSelection persistent:false
    )
    on caHomeUI close do
    (
        opened = false
        callbacks.removeScripts id:#CyrusArrangeHomeSelection
        try (destroyDialog caHomePropsUI) catch ()
    )
)
fn caShowArrangeUI setup:undefined =
(
    try (destroyDialog caHomeUI) catch ()
    createDialog caHomeUI width:460 height:580
    caHomeUI.onDiscover()
    if setup != undefined do caHomeUI.bindSetup setup
    caHomeUI
)
