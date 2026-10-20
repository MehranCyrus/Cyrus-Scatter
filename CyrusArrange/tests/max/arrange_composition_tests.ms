/* Actual native row/UI/preview checks in the runner's disposable Max 2027 profile. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caCreateBookRowFixtures, caBRWorldGeometryBounds, caShowAssetUI, caAssetUI, caBookRowAssetUI, caShowAdvancedArrangeUI, caArrangeUI, caCompositionUI
global caCLog = #(), caCPasses = 0, caCFailures = 0, caCFinished = false
global caCWrite, caCNote, caCCheck, caCRequire, caCFind, caCSamePoses, caCConfigure, caCVerifyRows, caCRun
fn caCWrite =
(
    local report = createFile (CA_TEST_OUTPUT+"result.txt")
    local state = if caCFinished then (if caCFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
    format "% passes=% failures=%\n" state caCPasses caCFailures to:report
    for line in caCLog do format "%\n" line to:report
    close report
)
fn caCNote line = (append caCLog line;caCWrite();true)
fn caCCheck label condition =
(
    if condition then (caCPasses += 1;caCNote ("PASS "+label))
    else (caCFailures += 1;caCNote ("FAIL "+label))
    condition
)
fn caCRequire label condition = (caCCheck label condition;if not condition do throw ("Prerequisite failed: "+label);true)
fn caCFind rows id =
(
    local found = undefined
    for row in rows while found == undefined do if row[1] == id do found = row
    found
)
fn caCSamePoses first second =
(
    local same = first.count == second.count
    for row in first while same do
    (
        local other = caCFind second row[1]
        if other == undefined then same = false
        else
        (
            for i in #(1,2,3,7,8) where row[i] != other[i] do same = false
            if distance row[4] other[4] > 0.001 or abs(row[5]-other[5]) > 0.00001 or abs(row[6]-other[6]) > 0.00001 do same = false
        )
    )
    same
)
fn caCConfigure setup maximumBooks:3 =
(
    local settings = (caSetupSummary setup)[9]
    settings[1] = 7231L;settings[2] = 1;settings[3] = 20;settings[4] = 12
    settings[5] = 0;settings[6] = 0;settings[7] = 0;settings[8] = 2;settings[10] = 20;settings[11] = false
    caSetArrangeSettings setup settings
    local rules = caCategoryRules setup settings[9]
    for row in rules do row[3] = if row[1] == 1 then maximumBooks else 0
    caSetCategoryRules setup settings[9] rules
    caSetCollisionScope setup #() false
    true
)
fn caCVerifyRows setup label topBounds:undefined =
(
    local groups = caCompositionRows setup
    local outputs = caOutputRows setup
    local valid = groups.count > 0
    local memberIDs = #()
    local separate = true, adjacency = true, fronts = true, scaleOK = true, supportOK = true
    for row in groups do
    (
        if row.count != 6 or row[2] != 1 or row[4].count != 3 do valid = false
        local previousBounds = undefined, frontY = undefined, baseZ = undefined
        for id in row[4] do
        (
            if (findItem memberIDs id) != 0 do separate = false
            append memberIDs id
            local output = caCFind outputs id
            if output == undefined then valid = false
            else
            (
                if not isValidNode output[9] then valid = false
                else
                (
                    local bounds = nodeGetBoundingBox output[9] (matrix3 1)
                    if output[8] != 0L or output[3] != row[3] do valid = false
                    if abs(output[6]-1) > 0.00001 do scaleOK = false
                    if previousBounds != undefined do
                        if abs((bounds[1].x-previousBounds[2].x)-row[6]) > 0.03 do adjacency = false
                    if frontY != undefined do if abs(bounds[1].y-frontY) > 0.03 do fronts = false
                    if baseZ != undefined do if abs(bounds[1].z-baseZ) > 0.03 do supportOK = false
                    if topBounds != undefined do
                    (
                        if bounds[1].x < topBounds[1].x+11.98 or bounds[2].x > topBounds[2].x-11.98 or bounds[1].y < topBounds[1].y+11.98 or bounds[2].y > topBounds[2].y-11.98 do supportOK = false
                        if abs(bounds[1].z-topBounds[2].z) > 0.03 do supportOK = false
                    )
                    previousBounds = bounds;frontY = bounds[1].y;baseZ = bounds[1].z
                )
            )
        )
    )
    caCCheck (label+": complete three-member native group records") valid
    caCCheck (label+": separate real output identities with no reused members") separate
    caCCheck (label+": measured full-box internal gap is 3mm under global20mm") adjacency
    caCCheck (label+": authored spine envelopes front-align") fronts
    caCCheck (label+": original fixed-size books stay scale1") scaleOK
    caCCheck (label+": members share support and obey independent table bounds") supportOK
    valid and separate and adjacency and fronts and scaleOK and supportOK
)
fn caCRun =
(
    if (maxVersion())[1] != 29000 do throw "Composition tests require Max 2027."
    CA_AUTO_SHOW_UI = false
    resetMaxFile #noPrompt
    units.SystemType = #millimeters;units.SystemScale = 1
    fileIn (CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeAssets.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeWorkflow.ms")
    caCNote "STAGE original physical book models and passive profile controls"
    local fixture = caCreateBookRowFixtures()
    local books = fixture[1]
    for i = 1 to books.count do
    (
        local headBounds = nodeGetBoundingBox books[i][1] (matrix3 1)
        local bounds = caBRWorldGeometryBounds books[i][1]
        local size = bounds[2]-bounds[1]
        caCNote ("MEASURE book "+(i as string)+" groupHead="+((headBounds[2]-headBounds[1]) as string)+" geometry="+(size as string))
        caCCheck ("original book "+(i as string)+" has exact authored dimensions") (distance size [books[i][4],books[i][5],books[i][3]] < 0.02)
    )
    local tableBounds = caBRWorldGeometryBounds fixture[2]
    local tableHead = nodeGetBoundingBox fixture[2] (matrix3 1)
    caCNote ("MEASURE table groupHead="+(tableHead as string)+" geometry="+(tableBounds as string))
    caCRequire "modeled table matches independent 1200x600x730 geometry" (distance tableBounds[1] [-600,-300,0] < 0.02 and distance tableBounds[2] [600,300,730] < 0.02)
    local setup = caCreateSetup #(fixture[2]) 1
    setup.name = "CA_COMPOSITION_MAIN"
    local defaults = caCompositionSettings setup
    caCCheck "new setup composition is disabled with explicit defaults" (defaults.count == 5 and defaults[1] == false and defaults[2] == 2 and defaults[3] == 6 and defaults[4] == 3 and defaults[5] == 0)
    local ids = #()
    for book in books do append ids (caRegisterAsset setup book[1] book[2] 1 3 #(0.0) 1.0 1.0 1.0 false)
    caCCheck "Book category alone does not infer row eligibility" ((caAssetBookRow setup ids[1]) == 0 and (caAssetBookRow setup ids[2]) == 0 and (caAssetBookRow setup ids[3]) == 0)
    local revision = (caSetupSummary setup)[3]
    caShowAssetUI setup
    setDialogPos caAssetUI [-10000,-10000]
    caAssetUI.assets.selection = 1
    caCRequire "asset UI selects the first registered book" (caAssetUI.onEdit 1)
    caAssetUI.rowProfileButton.pressed()
    setDialogPos caBookRowAssetUI [-10000,-10000]
    caCCheck "opening and refreshing row profile does not author or solve" ((caSetupSummary setup)[3] == revision and (caOutputRows setup).count == 0)
    caBookRowAssetUI.eligible.checked = true;caBookRowAssetUI.spine.selection = 3
    caCRequire "actual profile Apply handler saves explicit minusY spine" (caBookRowAssetUI.applyButton.pressed() and (caAssetBookRow setup ids[1]) == 3)
    caSetAssetBookRow setup ids[2] 3;caSetAssetBookRow setup ids[3] 3
    revision = (caSetupSummary setup)[3]
    local rejected = false
    try (caSetAssetBookRow setup ids[1] 5) catch (rejected = true)
    caCCheck "invalid spine tag rejects without revision or metadata changes" (rejected and (caSetupSummary setup)[3] == revision and (caAssetBookRow setup ids[1]) == 3)
    caCConfigure setup
    caShowAdvancedArrangeUI setup:setup
    setDialogPos caArrangeUI [-10000,-10000]
    revision = (caSetupSummary setup)[3]
    caCRequire "main workflow opens actual composition panel" (caArrangeUI.compositionButton.pressed())
    setDialogPos caCompositionUI [-10000,-10000]
    caCCheck "composition browsing leaves revision and placements unchanged" ((caSetupSummary setup)[3] == revision and (caOutputRows setup).count == 0)
    caCompositionUI.bookRows.checked = true;caCompositionUI.minimumBooks.value = 3;caCompositionUI.maximumBooks.value = 3;caCompositionUI.rowGap.value = 3;caCompositionUI.heightBalance.value = 0
    caCRequire "actual composition Apply handler persists native options" (caCompositionUI.applyButton.pressed() and (caCompositionSettings setup)[1])
    caCNote "STAGE first preview and atomic real-node publication"
    revision = (caSetupSummary setup)[3]
    local objectCount = objects.count
    local previewResult = caPreview setup #()
    local boxes = caPreviewBounds setup
    caCRequire "row preview exceeds the retired category cap with complete individual bounds" (previewResult[2] > 3 and boxes.count == previewResult[2])
    caCCheck "preview creates neither output nodes nor persisted groups" (objects.count == objectCount and (caSetupSummary setup)[3] == revision and (caOutputRows setup).count == 0 and (caCompositionRows setup).count == 0)
    caCommitPreview setup
    local outputs = caOutputRows setup
    caCRequire "commit matches every preview member and creates multiple native rows beyond the retired cap" (outputs.count == boxes.count and (caCompositionRows setup).count > 1)
    local sameBoxes = true
    for i = 1 to outputs.count do
    (
        local bounds = nodeGetBoundingBox outputs[i][9] (matrix3 1)
        if distance ((bounds[1]+bounds[2])*0.5) boxes[i][1] > 0.03 or distance ((bounds[2]-bounds[1])*0.5) boxes[i][2] > 0.03 do sameBoxes = false
    )
    caCCheck "actual member meshes reproduce preview world centers and extents" sameBoxes
    caCVerifyRows setup "TV category table" topBounds:#([-600,-300,0],[600,300,730])
    local rowSignature = (caCompositionRows setup) as string
    caGenerate setup #()
    caCCheck "same seed reproduces ordered group IDs and complete member poses" (rowSignature == ((caCompositionRows setup) as string) and caCSamePoses outputs (caOutputRows setup))
    local stats = caCompositionStats setup
    caCCheck "native composition statistics describe all successfully formed rows" (stats.count == 6 and stats[1] and stats[2] >= stats[3] and stats[3] == (caCompositionRows setup).count and stats[5] == 0 and stats[6] == 0)
    caCompositionUI.onRefresh()
    caCompositionUI.rows.selection = 1
    caCRequire "actual row selection action selects every real member" (caCompositionUI.selectButton.pressed() and selection.count == 3)
    caCNote "STAGE profile/settings edits invalidate staged preview"
    local before = caOutputRows setup
    caPreview setup #()
    caSetAssetBookRow setup ids[1] 4
    rejected = false
    try (caCommitPreview setup) catch (rejected = true)
    caCCheck "profile edit rejects stale commit and preserves complete output" (rejected and caCSamePoses before (caOutputRows setup))
    caSetAssetBookRow setup ids[1] 3
    caPreview setup #()
    caSetCompositionSettings setup #(true,3,3,3,1)
    rejected = false
    try (caCommitPreview setup) catch (rejected = true)
    caCCheck "balance edit rejects stale preview and clears transient statistics" (rejected and not (caCompositionStats setup)[1])
    caGenerate setup #()
    caCVerifyRows setup "Balanced row" topBounds:#([-600,-300,0],[600,300,730])
    stats = caCompositionStats setup
    caCCheck "enabled balance reports at most eight alternatives per row" (stats[1] and stats[5] <= 8*(caCompositionRows setup).count and stats[6] <= (caCompositionRows setup).count)
    caSetCompositionSettings setup #(false,3,3,3,0)
    caGenerate setup #()
    caCCheck "disabled rows regenerate ordinary independent books beyond the descriptive cap" ((caCompositionRows setup).count == 0 and (caOutputRows setup).count > 3)
    caCNote "STAGE actual TV console and open-shelf geometry"
    for categoryIndex = 1 to 2 do
    (
        local furniture = fixture[categoryIndex+2]
        local other = caCreateSetup #(furniture) categoryIndex
        other.name = "CA_COMPOSITION_FURNITURE_"+(categoryIndex as string)
        for book in books do
        (
            local id = caRegisterAsset other book[1] book[2] 1 3 #(0.0) 1.0 1.0 1.0 false
            caSetAssetBookRow other id 3
        )
        caCConfigure other maximumBooks:18
        caSetCompositionSettings other #(true,3,3,3,0)
        caGenerate other #()
        caCVerifyRows other (if categoryIndex == 1 then "Modeled TV console" else "Modeled open shelf")
    )
    local libraryPath = CA_TEST_OUTPUT+"book-row-library-v2.cyalib"
    caSaveAssetLibrary setup libraryPath
    caCCheck "authored row library is saved through the public native API" (doesFileExist libraryPath)
    local imported = caCreateSetup #(fixture[2]) 1
    caLoadAssetLibrary imported libraryPath
    local importedRows = caAssetRows imported
    local importedProfiles = importedRows.count == 3
    for asset in importedRows do if (caAssetBookRow imported asset[1]) != 3 or asset[10] do importedProfiles = false
    caCCheck "portable library2 retains explicit profiles with unbound geometry" importedProfiles
    local invalidCategory = caRegisterAsset imported books[1][1] "Grouped source remains one ordinary accessory" 7 31 #(0.0) 1.0 1.0 1.0 false
    revision = (caSetupSummary imported)[3]
    rejected = false
    try (caSetAssetBookRow imported invalidCategory 3) catch (rejected = true)
    caCCheck "nonBook source group cannot silently acquire row capability" (rejected and (caSetupSummary imported)[3] == revision and (caAssetBookRow imported invalidCategory) == 0)
    saveMaxFile (CA_TEST_OUTPUT+"book-row-workflow.max") quiet:true
    caCCheck "representative row setups save as a real Max scene" (doesFileExist (CA_TEST_OUTPUT+"book-row-workflow.max"))
    for dialog in #(caCompositionUI,caBookRowAssetUI,caAssetUI,caArrangeUI) do try (destroyDialog dialog) catch ()
    true
)
try (caCRun()) catch
(
    caCFailures += 1
    caCNote ("EXCEPTION "+(getCurrentException() as string))
    caCNote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
caCFinished = true
caCWrite()
