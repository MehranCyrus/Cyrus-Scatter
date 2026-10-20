/* Explicit obstacle references only. Native code owns expansion, validation and collision queries. */
global caCollisionUI, caShowCollisionUI
global caSetCollisionScope, caCollisionScope
try (destroyDialog caCollisionUI) catch ()

rollout caCollisionUI "Cyrus Arrange | Collision Scope"
(
    local setupNode = undefined
    local scopeRows = #()
    local hydrating = false
    local lastError = ""
    label setupLabel "Choose an Arrange setup." pos:[14,12] width:610 height:28
    checkbox requireFront "Require a clear horizontal approach" checked:false pos:[14,48] width:610
    label approachHint "Useful for shelves: candidates need room to approach from the surface's front direction.\nThis changes the fit requirement. Explicit obstacles below are also checked for collisions." pos:[14,78] width:610 height:42
    multiListBox obstacles "Explicit obstacle roots / groups:" items:#() pos:[14,132] width:610 height:8
    button replaceButton "Replace with selected" pos:[14,290] width:147 height:28
    button addButton "Add selected" pos:[173,290] width:147 height:28
    button removeButton "Remove chosen rows" pos:[332,290] width:147 height:28
    button clearButton "Clear obstacle scope" pos:[491,290] width:133 height:28
    button applyButton "Apply approach setting" pos:[14,334] width:290 height:28
    button refreshButton "Refresh cached scope" pos:[324,334] width:300 height:28
    label missingHint "Missing references stay visible until removed or replaced. No automatic scene search.\nManual mode waits for Generate; armed Live can update relevant scope changes." pos:[14,382] width:610 height:42
    editText statusText "Status:" text:"Select scene geometry to replace or add explicit obstacles." readOnly:true pos:[14,440] width:610 height:64

    fn failure action detail = (lastError = action+": "+(detail as string);statusText.text = lastError;false)
    fn currentNodes =
    (
        local result = #()
        for row in scopeRows do append result row[1]
        result
    )
    fn onRefresh =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose an Arrange setup first."
            local data = caCollisionScope setupNode
            if data.count != 2 or data[2].count > 4096 do throw "Native collision scope has an unexpected shape or exceeds the UI bound."
            local labels = #()
            for row in data[2] do
            (
                if row.count != 2 do throw "Native obstacle row has an unexpected shape."
                local labelText = row[2] as string
                if labelText.count > 512 do labelText = (substring labelText 1 512)+"..."
                append labels ((if isValidNode row[1] then "" else "MISSING | ")+labelText)
            )
            hydrating = true
            scopeRows = data[2]
            requireFront.checked = data[1]
            obstacles.items = labels
            hydrating = false
            setupLabel.text = setupNode.name+" | "+(scopeRows.count as string)+" explicit obstacle root(s)"
            lastError = ""
            true
        )
        catch (hydrating = false;failure "Read collision scope" (getCurrentException()))
    )
    fn bindSetup setup = (setupNode = setup;onRefresh())
    fn publishScope roots action =
    (
        try
        (
            if not isValidNode setupNode do throw "Choose an Arrange setup first."
            if roots.count > 4096 do throw "Choose at most 4096 explicit obstacle roots."
            undo "Cyrus Arrange: collision scope" on (caSetCollisionScope setupNode roots requireFront.checked)
            if not onRefresh() do throw lastError
            statusText.text = action+" saved. Native validation is authoritative; Manual waits for Generate."
            true
        )
        catch
        (
            local message = getCurrentException()
            -- Restore the last accepted scope view, then retain the operation's error.
            try (onRefresh()) catch ()
            failure action message
        )
    )
    fn selectedNodes =
    (
        if selection.count == 0 do throw "Select scene obstacle geometry or groups first, or use Clear obstacle scope."
        if selection.count > 4096 do throw "Choose at most 4096 selected scene nodes."
        selection as array
    )
    fn onReplace =
    (
        try (publishScope (selectedNodes()) "Replace obstacle scope")
        catch (failure "Replace obstacle scope" (getCurrentException()))
    )
    fn onAdd =
    (
        try
        (
            local next = currentNodes()
            join next (selectedNodes())
            publishScope next "Add obstacles"
        )
        catch (failure "Add obstacles" (getCurrentException()))
    )
    fn onRemove =
    (
        try
        (
            local chosen = obstacles.selection as array
            if chosen.count == 0 do throw "Choose one or more obstacle rows to remove."
            local next = #()
            for i = 1 to scopeRows.count where (findItem chosen i) == 0 do append next scopeRows[i][1]
            publishScope next "Remove obstacles"
        )
        catch (failure "Remove obstacles" (getCurrentException()))
    )
    fn onClear = publishScope #() "Clear obstacle scope"
    fn onApplyApproach = publishScope (currentNodes()) "Apply approach requirement"
    fn rows = scopeRows
    fn currentSetup = setupNode
    fn errorMessage = lastError
    on replaceButton pressed do onReplace()
    on addButton pressed do onAdd()
    on removeButton pressed do onRemove()
    on clearButton pressed do onClear()
    on applyButton pressed do onApplyApproach()
    on refreshButton pressed do onRefresh()
    on requireFront changed value do if not hydrating do statusText.text = "Draft approach setting. Apply approach setting or use a scope action to save it."
)

fn caShowCollisionUI setup =
(
    try (destroyDialog caCollisionUI) catch ()
    createDialog caCollisionUI width:640 height:524
    caCollisionUI.bindSetup setup
    caCollisionUI
)
