/* Cyrus Arrange 0.3.2. Bounded UI over the native geometry inspector. */
global CA_AUTO_SHOW_UI
global CA_OWNED_OVERLAYS
global caUI
global caShowUI
global caSummary
if CA_AUTO_SHOW_UI == undefined do CA_AUTO_SHOW_UI = true
if CA_OWNED_OVERLAYS == undefined do CA_OWNED_OVERLAYS = #()
try (destroyDialog caUI) catch ()

rollout caUI "Cyrus Arrange 0.3.2 | Geometry Inspector"
(
    local targets = #()
    local summary = undefined
    local lastError = ""
    local lastSuccess = "No captured snapshot."

    label scopeLabel "Inspect a selected TV console or open shelf assembly." pos:[14,10] width:600
    dropdownList furnitureCategory "Furniture label:" items:#("TV console", "Open shelf") selection:1 pos:[14,32] width:290
    button useSelection "Use current selection / group" pos:[324,48] width:300 height:24
    label selectionInfo "No source assembly chosen." pos:[14,80] width:600
    spinner cellMM "Sample spacing (mm):" range:[0.1,1000000,25] type:#float pos:[14,106] width:290 fieldWidth:85
    spinner clearanceMM "Minimum free height (mm):" range:[0,1000000000,100] type:#float pos:[324,106] width:300 fieldWidth:85
    spinner slopeDeg "Maximum support slope (degrees):" range:[0,45,5] type:#float pos:[14,134] width:290 fieldWidth:85
    button inspectButton "Inspect geometry" pos:[324,132] width:300 height:24
    label snapshotInfo "No captured snapshot." pos:[14,166] width:600 height:35
    listBox regions "Captured support regions (sampled):" items:#() pos:[14,204] width:610 height:8
    editText regionDetails "Region:" text:"Select a captured region." readOnly:true pos:[14,355] width:610 height:48
    button overlayButton "Create sampled-area overlay" pos:[14,414] width:290 height:24
    button deleteOverlayButton "Delete owned / selected Arrange overlays" pos:[324,414] width:300 height:24
    button exportButton "Export captured snapshot JSON..." pos:[14,448] width:290 height:24
    button clearButton "Clear captured snapshot" pos:[324,448] width:300 height:24
    editText statusText "Status:" text:"Ready. Inspect runs only when requested." readOnly:true pos:[14,486] width:610 height:70
    label limits "Sampled geometry only. No accessory placement.\nEnclosed spaces and accessibility are not recognized." pos:[14,570] width:610 height:32

    fn setFailure actionName detail =
    (
        lastError = actionName + ": " + (detail as string)
        statusText.text = lastError + "\nPrevious complete snapshot is retained."
        false
    )

    fn isOwnedOverlay node =
    (
        if not isValidNode node then false
        else
        (
            local tag = getUserProp node "CyrusArrangeGenerated"
            tag == true or tag == "true" or tag == "True"
        )
    )

    fn onUseSelection =
    (
        targets = selection as array
        selectionInfo.text = (targets.count as string) + " selected source node(s); group expansion is native."
        statusText.text = "Selection captured. Press Inspect geometry to calculate."
        true
    )

    fn onRegion index =
    (
        if summary == undefined or index < 1 or index > summary[4] then false
        else
        (
            try
            (
                local row = caRegion index
                local freeHeight = if row[7] then "open above" else ((formattedPrint row[6] format:".1f") + " mm")
                regionDetails.text = "ID " + (row[1] as string) + " | height " + (formattedPrint row[2].z format:".1f") + " mm | free height " + freeHeight + "\nSampled area " + (formattedPrint row[4] format:".0f") + " mm2 | usable " + (formattedPrint row[5] format:".0f") + " mm2 | " + (row[9] as string) + " usable cells"
                true
            )
            catch (setFailure "Read region" (getCurrentException()))
        )
    )

    fn presentSummary nextSummary statusMessage =
    (
        if nextSummary.count != 16 do throw "Unexpected native summary; load the matched native/UI pair."
        if nextSummary[4] > 4096 do throw "Native region summary exceeds the inspector UI limit."
        local nextItems = #()
        for i = 1 to nextSummary[4] do
        (
            local row = caRegion i
            local h = if row[7] then "open" else ((formattedPrint row[6] format:".0f") + " mm")
            append nextItems ("Region " + (row[1] as string) + " | Z " + (formattedPrint row[2].z format:".0f") + " mm | usable " + (formattedPrint row[5] format:".0f") + " mm2 | clearance " + h)
        )
        summary = nextSummary
        regions.items = nextItems
        cellMM.value = summary[14]
        clearanceMM.value = summary[15]
        slopeDeg.value = summary[16]
        local worldSize = summary[10] - summary[9]
        lastSuccess = (summary[4] as string) + " regions | " + (summary[3] as string) + " triangles | " + (summary[6] as string) + " usable sampled cells\nWorld X/Y/Z (mm): " + (formattedPrint worldSize.x format:".1f") + " / " + (formattedPrint worldSize.y format:".1f") + " / " + (formattedPrint worldSize.z format:".1f")
        snapshotInfo.text = lastSuccess
        lastError = ""
        statusText.text = statusMessage
        if summary[11].count > 0 do statusText.text += "\n" + (summary[11][1] as string)
        if summary[4] > 0 then (regions.selection = 1; onRegion 1)
        else regionDetails.text = "No horizontal support regions met the capture settings."
        true
    )

    fn onInspect =
    (
        try
        (
            if caVersion() != "0.3.2" do throw "Load the matched Cyrus Arrange 0.3.2 native/UI pair."
            local nextSummary = caInspect targets cellMM.value clearanceMM.value slopeDeg.value
            presentSummary nextSummary ("Captured " + furnitureCategory.selected + ". Source edits require Inspect again.")
        )
        catch (setFailure "Inspect failed" (getCurrentException()))
    )

    fn onOverlay =
    (
        try
        (
            local retained = for n in CA_OWNED_OVERLAYS where isValidNode n collect n
            if retained.count >= 64 do throw "Delete previous Arrange overlays before creating more (64 retained nodes)."
            local node = undefined
            undo "Cyrus Arrange: create overlay" on (node = caCreateOverlay())
            if not isOwnedOverlay node do throw "Native overlay creation did not return an owned node."
            append retained node
            CA_OWNED_OVERLAYS = retained
            statusText.text = "Created a regular mesh from usable sampled cells. Undo is available."
            true
        )
        catch (setFailure "Create overlay" (getCurrentException()))
    )

    fn onDeleteOverlay =
    (
        try
        (
            local owned = for n in CA_OWNED_OVERLAYS where isOwnedOverlay n collect n
            local selectedNodes = selection as array
            if selectedNodes.count > 4096 do throw "Select at most 4096 overlays for one delete command."
            for n in selectedNodes where isOwnedOverlay n do appendIfUnique owned n
            if owned.count == 0 then
            (
                statusText.text = "No owned overlays found. Select a saved Arrange overlay to delete it."
                false
            )
            else
            (
                undo "Cyrus Arrange: delete overlays" on (delete owned)
                CA_OWNED_OVERLAYS = #()
                statusText.text = "Deleted " + (owned.count as string) + " tagged Arrange overlay node(s). Undo is available."
                true
            )
        )
        catch (setFailure "Delete overlays" (getCurrentException()))
    )

    fn onExport path:undefined =
    (
        local destination = path
        if destination == undefined do destination = getSaveFileName caption:"Export Cyrus Arrange snapshot" types:"JSON (*.json)|*.json|" filename:"CyrusArrange-snapshot.json"
        if destination == undefined then false
        else
        (
            try
            (
                if caExport destination != true do throw "Native export did not complete."
                statusText.text = "Exported captured snapshot: " + destination
                true
            )
            catch (setFailure "Export snapshot" (getCurrentException()))
        )
    )

    fn onClear =
    (
        try
        (
            caClear()
            summary = undefined
            regions.items = #()
            snapshotInfo.text = "No captured snapshot."
            regionDetails.text = "Select an assembly and Inspect geometry."
            lastSuccess = "No captured snapshot."
            lastError = ""
            statusText.text = "Released native snapshot. Existing scene overlays are separate meshes."
            true
        )
        catch (setFailure "Clear snapshot" (getCurrentException()))
    )

    fn capturedSummary = summary
    fn errorMessage = lastError
    fn sourceTargets = targets

    on useSelection pressed do onUseSelection()
    on inspectButton pressed do onInspect()
    on regions selected index do onRegion index
    on overlayButton pressed do onOverlay()
    on deleteOverlayButton pressed do onDeleteOverlay()
    on exportButton pressed do onExport()
    on clearButton pressed do onClear()
    on caUI open do
    (
        try
        (
            local diagnostics = caDiagnostics()
            if diagnostics[3] do
            (
                presentSummary (caSummary()) "Restored the native captured snapshot. Source edits require Inspect again."
                selectionInfo.text = "Cached " + (summary[2] as string) + " source node(s). Choose current selection before inspecting again."
            )
        )
        catch (setFailure "Read cached snapshot" (getCurrentException()))
    )
)

fn caShowUI position:undefined =
(
    try (destroyDialog caUI) catch ()
    if position == undefined then createDialog caUI width:640 height:620
    else createDialog caUI width:640 height:620 pos:position
    caUI
)
if CA_AUTO_SHOW_UI do caShowUI()
