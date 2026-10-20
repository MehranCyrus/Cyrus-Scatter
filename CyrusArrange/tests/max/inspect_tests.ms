/* Owned disposable Max 2027 diagnostic bootstrap. Re-fileIn intentionally restores
   the geometry inspector function; it is not an installed artist popup action.
   Fresh five JSON exports remain independently verified by the packager. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caShowUI, caUI, CA_OWNED_OVERLAYS
global caFxMM, caFxBox, caFxTVConsole, caFxOpenShelf, caFxRing
global caTestLog, caTestPasses, caTestFailures
global caTestCheck, caTestNear, caTestSignature, caTestSameSources, caTestRun

caTestPasses = 0
caTestFailures = 0
caTestLog = #()

fn caTestCheck label condition =
(
    if condition then
    (
        caTestPasses += 1
        append caTestLog ("PASS " + label)
    )
    else
    (
        caTestFailures += 1
        append caTestLog ("FAIL " + label)
        if caUI != undefined do
        (
            local detail = caUI.errorMessage()
            if detail.count > 0 do append caTestLog ("UI_ERROR " + detail)
        )
    )
    condition
)

fn caTestNear actual expected tolerance:0.1 = (abs (actual - expected)) <= tolerance

fn caTestSignature nodes =
(
    for n in nodes collect
    (
        local m = snapshotAsMesh n
        #(n.handle,n.name,n.transform,(for i = 1 to m.numverts collect getVert m i),(for i = 1 to m.numfaces collect getFace m i))
    )
)

fn caTestSameSources nodes signatures =
(
    if nodes.count != signatures.count then false
    else
    (
        local same = true
        for i = 1 to nodes.count while same do
        (
            local n = nodes[i]
            local s = signatures[i]
            if not isValidNode n then same = false
            else
            (
                if n.handle != s[1] or n.name != s[2] do same = false
                for row = 1 to 4 where (distance n.transform[row] s[3][row]) > 0.00001 do same = false
                local m = snapshotAsMesh n
                if m.numverts != s[4].count or m.numfaces != s[5].count then same = false
                else
                (
                    for j = 1 to m.numverts where (distance (getVert m j) s[4][j]) > 0.00001 do same = false
                    for j = 1 to m.numfaces where (getFace m j) != s[5][j] do same = false
                )
            )
        )
        same
    )
)

fn caTestRun =
(
    append caTestLog "STAGE bootstrap"
    if CA_TEST_ROOT == undefined or CA_TEST_OUTPUT == undefined do throw "Private runner must provide CA_TEST_ROOT and CA_TEST_OUTPUT."
    if (maxVersion())[1] != 29000 do throw "Cyrus Arrange host tests require Max 2027 (29000)."
    CA_AUTO_SHOW_UI = false
    append caTestLog "STAGE reset private scene"
    resetMaxFile #noPrompt
    append caTestLog "STAGE load fixtures"
    fileIn (CA_TEST_ROOT + "tests/max/fixtures.ms")
    append caTestLog "STAGE load UI"
    fileIn (CA_TEST_ROOT + "scripts/CyrusArrange.ms")
    append caTestLog "STAGE open private rollout"
    caShowUI position:[-10000,-10000]
    append caTestLog "STAGE native contract"
    caTestCheck "native version 0.3.2" (caVersion() == "0.3.2")
    local diag = caDiagnostics()
    append caTestLog ("NATIVE_PATH " + diag[1])
    caTestCheck "native diagnostics ten-field contract" (diag.count == 10)
    caTestCheck "native snapshot starts empty" (diag[3] == false)

    append caTestLog "STAGE create furniture fixtures"
    local tv = caFxTVConsole grouped:true
    tv[2][1].name = "CA_FIXTURE_quoted_\"top\"_" + (((dotNetClass "System.Char").ConvertFromUtf32 1046) as string)
    local shelves = caFxOpenShelf offsetMM:[3000,0,0] grouped:true
    local ring = caFxRing offsetMM:[-3000,0,0]
    local sources = tv[2] + shelves[2] + ring
    local original = caTestSignature sources

    append caTestLog "STAGE inspect TV console via buttons"
    select tv[1]
    caTestCheck "actual selection button handler captures group" (caUI.useSelection.pressed())
    caTestCheck "actual Inspect button handler succeeds" (caUI.inspectButton.pressed())
    local summary = caUI.capturedSummary()
    caTestCheck "summary sixteen-field contract" (summary.count == 16)
    caTestCheck "TV dimensions use millimetres" ((caTestNear (summary[10].x-summary[9].x) 1800) and (caTestNear (summary[10].y-summary[9].y) 450) and (caTestNear (summary[10].z-summary[9].z) 600))
    caTestCheck "UI displays dimensions explicitly in world axes" ((findString caUI.snapshotInfo.text "World X/Y/Z (mm):") != undefined)
    caTestCheck "TV captures multiple support regions" (summary[4] >= 3 and summary[6] > 0)
    local hasTop = false
    local hasShelf = false
    local hasBoundedClearance = false
    for i = 1 to summary[4] do
    (
        local region = caRegion i
        if caTestNear region[2].z 600 do hasTop = true
        if caTestNear region[2].z 275 do hasShelf = true
        if region[6] > 0 and region[6] < 600 do hasBoundedClearance = true
    )
    caTestCheck "known top height is captured" hasTop
    caTestCheck "known internal shelf height is captured" hasShelf
    caTestCheck "internal shelf clearance is finite" hasBoundedClearance
    caTestCheck "actual region handler reads summary" (caUI.onRegion 1)
    caTestCheck "actual export handler writes JSON" (caUI.onExport path:(CA_TEST_OUTPUT + "tv-console.json"))
    caTestCheck "JSON exists and is nonempty" ((doesFileExist (CA_TEST_OUTPUT + "tv-console.json")) and ((getFileSize (CA_TEST_OUTPUT + "tv-console.json")) > 100))
    caTestCheck "successful inspection preserves sources" (caTestSameSources sources original)
    append caTestLog "STAGE close and reopen passive UI"
    local beforeUIReopen = caDiagnostics()
    destroyDialog caUI
    caShowUI position:[-10000,-10000]
    caTestCheck "reopening UI preserves captured region view" (caUI.capturedSummary() != undefined and caUI.regions.items.count == summary[4])
    caTestCheck "reopening UI retains native snapshot" ((caDiagnostics())[3] and (caDiagnostics())[9] == summary[4])
    caTestCheck "reopening UI leaves captured work unchanged" ((caDiagnostics())[6] == beforeUIReopen[6] and (caDiagnostics())[8] == beforeUIReopen[8])
    select tv[1]
    caUI.useSelection.pressed()
    caUI.inspectButton.pressed()
    local deduped = caInspect #(tv[1],tv[2][1]) 25 100 5
    caTestCheck "group plus child deduplicates evaluated geometry" (deduped[3] == summary[3] and deduped[4] == summary[4] and deduped[6] == summary[6])

    append caTestLog "STAGE failure retention"
    local beforeFailure = caDiagnostics()
    clearSelection()
    caUI.onUseSelection()
    caTestCheck "actual Inspect button reports empty selection failure" (caUI.inspectButton.pressed() == false)
    local afterFailure = caDiagnostics()
    caTestCheck "failed inspect retains native snapshot" (afterFailure[3] and afterFailure[7] == beforeFailure[7] and afterFailure[8] == beforeFailure[8] and afterFailure[9] == beforeFailure[9])
    caTestCheck "failed inspect retains UI region summary" ((caUI.capturedSummary())[4] == summary[4] and caUI.regions.items.count == summary[4])
    caTestCheck "failed inspect retains useful error" ((caUI.errorMessage()).count > 0)
    local badSettingRejected = false
    try (caInspect #(tv[1]) 0 100 5) catch (badSettingRejected = true)
    caTestCheck "native invalid setting rejects atomically" (badSettingRejected and (caDiagnostics())[9] == beforeFailure[9])
    local helper = point name:"CA_FIXTURE_UnsupportedHelper"
    setUserProp helper "CyrusArrangeFixture" true
    select helper
    caUI.onUseSelection()
    caTestCheck "unsupported helper fails through actual button" (caUI.inspectButton.pressed() == false)
    caTestCheck "unsupported helper retains complete snapshot" ((caDiagnostics())[7] == beforeFailure[7] and (caDiagnostics())[9] == beforeFailure[9])
    delete helper
    select tv[1]
    caUI.onUseSelection()
    caUI.cellMM.value = 0.1
    caTestCheck "fine grid rejects native work budget through button" (caUI.inspectButton.pressed() == false)
    caTestCheck "budget failure retains native and UI snapshot" ((caDiagnostics())[7] == beforeFailure[7] and (caDiagnostics())[9] == beforeFailure[9] and (caUI.capturedSummary())[4] == summary[4])
    caUI.cellMM.value = 25
    caTestCheck "failed inspection preserves sources" (caTestSameSources sources original)

    append caTestLog "STAGE overlay Undo and Redo"
    local objectCount = objects.count
    caTestCheck "actual overlay button creates native mesh" (caUI.overlayButton.pressed())
    local overlay = CA_OWNED_OVERLAYS[CA_OWNED_OVERLAYS.count]
    caTestCheck "overlay has native ownership tag" ((getUserProp overlay "CyrusArrangeGenerated") == true)
    caTestCheck "overlay adds one scene object" (objects.count == objectCount+1)
    local withoutOverlay = caInspect #(tv[1],overlay) 25 100 5
    caTestCheck "tagged overlay is excluded from inspection" (withoutOverlay[3] == summary[3] and withoutOverlay[4] == summary[4] and withoutOverlay[6] == summary[6])
    max undo
    caTestCheck "overlay creation Undo removes mesh" (objects.count == objectCount)
    max redo
    caTestCheck "overlay creation Redo restores mesh" (objects.count == objectCount+1)
    caTestCheck "actual overlay deletion button succeeds" (caUI.deleteOverlayButton.pressed())
    caTestCheck "owned overlay delete removes mesh" (objects.count == objectCount)
    max undo
    caTestCheck "overlay deletion Undo restores mesh" (objects.count == objectCount+1)
    max redo
    caTestCheck "overlay deletion Redo removes mesh" (objects.count == objectCount)
    caTestCheck "overlay operations preserve sources" (caTestSameSources sources original)

    append caTestLog "STAGE inspect open shelf"
    select shelves[1]
    caUI.onUseSelection()
    caTestCheck "grouped open shelf Inspect button succeeds" (caUI.inspectButton.pressed())
    local shelfSummary = caUI.capturedSummary()
    caTestCheck "open shelf physical dimensions" ((caTestNear (shelfSummary[10].x-shelfSummary[9].x) 1200) and (caTestNear (shelfSummary[10].y-shelfSummary[9].y) 350) and (caTestNear (shelfSummary[10].z-shelfSummary[9].z) 1800))
    caTestCheck "open shelf has multiple support levels" (shelfSummary[4] >= 5)
    caTestCheck "shelf export" (caUI.onExport path:(CA_TEST_OUTPUT + "open-shelf.json"))

    append caTestLog "STAGE inspect hole fixture"
    select ring
    caUI.onUseSelection()
    caTestCheck "hole assembly Inspect succeeds" (caUI.inspectButton.pressed())
    local holeSummary = caUI.capturedSummary()
    caTestCheck "hole assembly area excludes central opening" (holeSummary[8] > 500000 and holeSummary[8] < 760000)
    caTestCheck "hole JSON export" (caUI.onExport path:(CA_TEST_OUTPUT + "hole.json"))

    append caTestLog "STAGE inspect transformed fixture"
    local transformed = caFxTVConsole offsetMM:[0,2500,0] grouped:true
    transformed[1].pivot = [0,(caFxMM 2500),0]
    transformed[1].transform = (scaleMatrix [-1.5,0.75,1.2]) * (rotateZMatrix 37) * (transMatrix [0,(caFxMM 2500),0])
    local independentMinZ = 1e30
    local independentMaxZ = -1e30
    for n in transformed[2] do
    (
        local worldBox = nodeGetBoundingBox n (matrix3 1)
        independentMinZ = amin independentMinZ (worldBox[1].z / (caFxMM 1))
        independentMaxZ = amax independentMaxZ (worldBox[2].z / (caFxMM 1))
    )
    caTestCheck "transformed fixture world bounds have upright Z0..720" ((caTestNear independentMinZ 0 tolerance:0.5) and (caTestNear independentMaxZ 720 tolerance:0.5))
    local transformOriginal = caTestSignature transformed[2]
    select transformed[1]
    caUI.onUseSelection()
    caTestCheck "mirrored nonuniform rotated group Inspect succeeds" (caUI.inspectButton.pressed())
    local transformedSummary = caUI.capturedSummary()
    caTestCheck "transformed support height keeps physical scale" ((caTestNear transformedSummary[9].z 0 tolerance:0.5) and (caTestNear transformedSummary[10].z 720 tolerance:0.5))
    local transformedTop = false
    local transformedShelf = false
    for i = 1 to transformedSummary[4] do
    (
        local region = caRegion i
        if caTestNear region[2].z 720 tolerance:0.5 do transformedTop = true
        if caTestNear region[2].z 330 tolerance:0.5 do transformedShelf = true
    )
    caTestCheck "mirrored rotated top support Z720" transformedTop
    caTestCheck "mirrored rotated shelf support Z330" transformedShelf
    caTestCheck "transformed native geometry preserves sources" (caTestSameSources transformed[2] transformOriginal)
    caTestCheck "transformed JSON export" (caUI.onExport path:(CA_TEST_OUTPUT + "transformed.json"))

    append caTestLog "STAGE system units"
    local savedSystemType = units.SystemType
    local savedSystemScale = units.SystemScale
    units.SystemType = #centimeters
    units.SystemScale = 1.0
    local unitFixture = caFxTVConsole offsetMM:[0,-2500,0]
    select unitFixture[2]
    caUI.onUseSelection()
    caTestCheck "centimetre system units Inspect succeeds" (caUI.inspectButton.pressed())
    local unitSummary = caUI.capturedSummary()
    caTestCheck "unit conversion retains 1800 mm width" (caTestNear (unitSummary[10].x-unitSummary[9].x) 1800 tolerance:0.5)
    caTestCheck "unit conversion retains 600 mm height" (caTestNear (unitSummary[10].z-unitSummary[9].z) 600 tolerance:0.5)
    delete unitFixture[2]
    units.SystemType = savedSystemType
    units.SystemScale = savedSystemScale

    append caTestLog "STAGE save and reopen fixture scene"
    select tv[1]
    caUI.onUseSelection()
    caUI.onInspect()
    caUI.onOverlay()
    local scenePath = CA_TEST_OUTPUT + "procedural-furniture.max"
    local savedObjects = objects.count
    caTestCheck "fixture scene saves" (saveMaxFile scenePath quiet:true)
    caTestCheck "fixture scene exists" (doesFileExist scenePath)
    caTestCheck "fixture scene reopens" (loadMaxFile scenePath quiet:true useFileUnits:true)
    caTestCheck "saved scene object count roundtrips" (objects.count == savedObjects)
    local loadedOverlays = for n in objects where ((getUserProp n "CyrusArrangeGenerated") == true) collect n
    caTestCheck "saved overlay ownership roundtrips" (loadedOverlays.count == 1)
    local loadedTV = getNodeByName "CA_FIXTURE_TV_Assembly" exact:true
    select loadedTV
    caUI.onUseSelection()
    caTestCheck "reopened furniture can be inspected again" (caUI.inspectButton.pressed())
    caTestCheck "reopened snapshot export" (caUI.onExport path:(CA_TEST_OUTPUT + "reopened.json"))
    select loadedOverlays
    caTestCheck "selected saved overlay deletion button" (caUI.deleteOverlayButton.pressed())
    caTestCheck "clear button releases snapshot" (caUI.clearButton.pressed())
    caTestCheck "clear native state" ((caDiagnostics())[3] == false)
    caTestCheck "clear UI state" (caUI.capturedSummary() == undefined and caUI.regions.items.count == 0)
    destroyDialog caUI
    true
)

try (caTestRun()) catch
(
    caTestFailures += 1
    append caTestLog ("EXCEPTION " + (getCurrentException() as string))
    append caTestLog ("ERROR_SOURCE " + (getErrorSourceFileName() as string) + ":" + (getErrorSourceFileLine() as string))
    append caTestLog ("STACK " + (getCurrentExceptionStackTrace() as string))
)

if CA_TEST_OUTPUT != undefined do
(
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    if caTestFailures == 0 then format "SUCCESS\n" to:report else format "ERROR\n" to:report
    format "passes=% failures=%\n" caTestPasses caTestFailures to:report
    for line in caTestLog do format "%\n" line to:report
    close report
)
