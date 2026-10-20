/* Native diagnostic preview lifecycle; isolated Max 2027 batch only. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caFxBox, caFxMM
global caPLog = #(), caPPasses = 0, caPFailures = 0
global caPCheck, caPRequire, caPSignature, caPHandles, caPFixture, caPFirstPreview
fn caPCheck label condition =
(
    if condition then (caPPasses += 1; append caPLog ("PASS " + label))
    else (caPFailures += 1; append caPLog ("FAIL " + label))
    condition
)
fn caPRequire label condition =
(
    caPCheck label condition
    if not condition do throw ("Prerequisite failed: " + label)
    condition
)
fn caPSignature rows =
(
    local result = #()
    for row in rows do append result #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
    result as string
)
fn caPHandles rows =
(
    local result = #()
    for row in rows do append result (if isValidNode row[9] then getHandleByAnim row[9] else 0)
    result as string
)
fn caPFixture publish:true =
(
    resetMaxFile #noPrompt
    units.SystemType = #millimeters; units.SystemScale = 1
    fileIn (CA_TEST_ROOT + "tests/max/fixtures.ms")
    local top = caFxBox "PREVIEW_Table" [1000,500,30] [0,0,300]
    local source = caFxBox "PREVIEW_Book" [100,70,20] [2500,0,0]
    local unrelated = caFxBox "PREVIEW_Unrelated" [10,10,10] [5000,0,0]
    local setup = caCreateSetup #(top) 1
    setup.name = "CA_PREVIEW_SETUP"
    caRegisterAsset setup source "Preview Book" 1 31 #(0.0,90.0,180.0,270.0) 1.0 1.0 1.0 false
    local settings = (caSetupSummary setup)[9]
    settings[1] = 313; settings[2] = 0.15; settings[3] = 12; settings[4] = 10
    settings[7] = 0.45; settings[10] = 40; settings[11] = true
    caSetArrangeSettings setup settings
    if publish then
    (
        caGenerate setup #()
        caPRequire "Preview fixture publishes real output" ((caOutputRows setup).count > 0)
    )
    #(setup,top,source,unrelated)
)
fn caPFirstPreview =
(
    local f = caPFixture publish:false
    local setup = f[1], revision = (caSetupSummary f[1])[3]
    caPRequire "First Preview fixture has no published placements" ((caOutputRows setup).count == 0)
    local result = caPreview setup #()
    local boxes = caPreviewBounds setup
    caPRequire "First Preview exposes bounded candidate boxes" (boxes.count > 0 and boxes.count == result[2])
    caPCheck "First Preview reserves regions without authoring scene state" ((caOutputRows setup).count == 0 and (caSetupSummary setup)[3] == revision)
    caPreview setup #()
    local repeated = caPreviewBounds setup
    local repeatedSame = repeated.count == boxes.count
    for i = 1 to boxes.count while repeatedSame do
        if distance repeated[i][1] boxes[i][1] > 0.001 or distance repeated[i][2] boxes[i][2] > 0.001 or abs (repeated[i][3]-boxes[i][3]) > 0.00001 do repeatedSame = false
    caPCheck "Repeated unpublished Preview keeps identical provisional IDs and poses" repeatedSame
    caCommitPreview setup
    local rows = caOutputRows setup
    caPRequire "First Commit preserves candidate count" (rows.count == boxes.count)
    local sameCenters = true, sameExtents = true, sameRotations = true, sameScale = true
    local millimeter = caFxMM 1
    for i = 1 to rows.count do
    (
        local node = rows[i][9], expected = boxes[i]
        local bb = nodeGetBoundingBox node (matrix3 1)
        local centerMM = (bb[1] + bb[2]) * (0.5 / millimeter)
        local halfMM = (bb[2] - bb[1]) * (0.5 / millimeter)
        if (distance centerMM expected[1]) > 0.02 do sameCenters = false
        local c = abs (cos expected[3]), s = abs (sin expected[3])
        local expectedHalf = [c * expected[2].x + s * expected[2].y, s * expected[2].x + c * expected[2].y, expected[2].z]
        if (distance halfMM expectedHalf) > 0.02 do sameExtents = false
        local actualYaw = atan2 node.transform.row1.y node.transform.row1.x
        local delta = abs ((mod (actualYaw - expected[3] + 540) 360) - 180)
        if delta > 0.01 do sameRotations = false
        for axis in #(node.transform.row1,node.transform.row2,node.transform.row3) do if abs ((length axis) - 1) > 0.0001 do sameScale = false
    )
    caPCheck "First Commit reproduces Preview world centers using real mesh bounds" sameCenters
    caPCheck "First Commit reproduces Preview extents using real mesh bounds" sameExtents
    caPCheck "First Commit reproduces Preview yaw using node transforms" sameRotations
    caPCheck "First Commit preserves fixed authored scale independently" sameScale
)
try
(
    caPFirstPreview()
    local f = caPFixture(), setup = f[1]
    local settings = (caSetupSummary setup)[9]
    settings[1] += 1
    caSetArrangeSettings setup settings
    local signature = caPSignature (caOutputRows setup)
    local handles = caPHandles (caOutputRows setup)
    local revision = (caSetupSummary setup)[3]
    local nodeCount = objects.count
    local candidate = caPreview setup #()
    local info = caPreviewInfo setup
    caPRequire "Preview returns bounded result and valid cache" (candidate.count == 6 and candidate[2] > 0 and info.count == 4 and info[1] and info[2] and info[3] == candidate[2])
    caPCheck "Preview creates no scene nodes or native authored revision" (objects.count == nodeCount and (caSetupSummary setup)[3] == revision)
    caPCheck "Preview retains exact published records and node identities" ((caPSignature (caOutputRows setup)) == signature and (caPHandles (caOutputRows setup)) == handles)
    caTick()
    caPCheck "Preview disarms Live and tick retains committed output" ((caSetupSummary setup)[3] == revision and (caPHandles (caOutputRows setup)) == handles and (caPreviewInfo setup)[2])
    local committed = caCommitPreview setup
    caPCheck "Commit recomputes matching candidate count" (committed.count == 6 and committed[2] == candidate[2])
    caPCheck "Commit clears transient preview and publishes new output" (not (caPreviewInfo setup)[1] and (caSetupSummary setup)[6] == 0 and (caPHandles (caOutputRows setup)) != handles)
    revision = (caSetupSummary setup)[3]
    f[2].width += 20
    caTick()
    caPCheck "Successful Commit re-arms relevant Live generation" ((caSetupSummary setup)[3] > revision)

    caPreview setup #()
    f[4].width += 2
    caPCheck "Unrelated edit leaves preview current" ((caPreviewInfo setup)[2])
    signature = caPSignature (caOutputRows setup); handles = caPHandles (caOutputRows setup)
    revision = (caSetupSummary setup)[3]
    f[2].width += 20
    caTick()
    info = caPreviewInfo setup
    caPCheck "Relevant geometry change hides and invalidates preview" (info[1] and not info[2] and info[4] != "")
    caPCheck "Stale preview keeps Live disarmed and retains output" ((caSetupSummary setup)[3] == revision and (caPHandles (caOutputRows setup)) == handles)
    local rejected = false
    try (caCommitPreview setup) catch (rejected = true)
    caPCheck "Stale Commit refuses with retained published result" (rejected and (caPSignature (caOutputRows setup)) == signature and (caPHandles (caOutputRows setup)) == handles)
    caPCheck "Clear removes transient stale cache" (caClearPreview setup and not (caPreviewInfo setup)[1])
    caTick()
    caPCheck "Clear keeps Live disarmed until explicit Update" ((caSetupSummary setup)[3] == revision and (caPHandles (caOutputRows setup)) == handles)
    caGenerate setup #()
    caPCheck "Explicit Generate still works independently of Preview" ((caSetupSummary setup)[6] == 0)

    caPreview setup #()
    settings = (caSetupSummary setup)[9]; settings[1] += 7
    caSetArrangeSettings setup settings
    caPCheck "Authored setting edit invalidates preview" (not (caPreviewInfo setup)[2])
    rejected = false
    try (caCommitPreview setup) catch (rejected = true)
    caPCheck "Commit rejects a changed authored revision" rejected
    caClearPreview setup

    caPreview setup #()
    sliderTime = 1f
    caPCheck "Scene time change invalidates preview" (not (caPreviewInfo setup)[2])
    sliderTime = 0f
    caPCheck "Returning to old time does not revive stale preview" (not (caPreviewInfo setup)[2])
    caClearPreview setup

    caPreview setup #()
    info = caPreviewInfo setup
    rejected = false
    try (caPreview setup #(2147483647)) catch (rejected = true)
    local retained = caPreviewInfo setup
    caPCheck "Failed successor preserves prior complete diagnostic preview" (rejected and retained[1] and retained[2] and retained[3] == info[3])
    caClearPreview setup

    local oldHeight = f[4].height
    undo "Preview Undo sentinel" on (f[4].height += 3)
    caPreview setup #()
    max undo
    caPCheck "Preview adds no scene Undo mutation" (abs (f[4].height - oldHeight) < 0.0001)
    caPCheck "Undo discards transient preview to prevent resurrection" (not (caPreviewInfo setup)[1])
    caPreview setup #()
    local originals, copies
    maxOps.cloneNodes #(setup) cloneType:#copy expandHierarchy:false actualNodeList:&originals newNodes:&copies
    local index = findItem originals setup
    caPRequire "Preview clone fixture maps owner" (index > 0)
    caPCheck "Cloned setup inherits no transient preview" (not (caPreviewInfo copies[index])[1])
    caClearPreview setup

    caPreview setup #()
    local scene = CA_TEST_OUTPUT + "native-preview-reopen.max"
    saveMaxFile scene quiet:true
    caPCheck "Save clears diagnostic preview without serializing it" (not (caPreviewInfo setup)[1])
    loadMaxFile scene useFileUnits:true quiet:true
    setup = getNodeByName "CA_PREVIEW_SETUP"
    caPCheck "Reopen has native output and no transient preview" ((caOutputRows setup).count > 0 and not (caPreviewInfo setup)[1])

    /* Exercise global active-preview capacity with tiny source meshes. */
    resetMaxFile #noPrompt
    units.SystemType = #millimeters; units.SystemScale = 1
    local top = caFxBox "PREVIEW_CapacityTable" [500,300,20] [0,0,300]
    local source = caFxBox "PREVIEW_CapacityBook" [100,70,20] [2500,0,0]
    local owners = #()
    for i = 1 to 9 do
    (
        local owner = caCreateSetup #(top) 1
        caRegisterAsset owner source "Capacity Book" 1 31 #(0.0,90.0) 1.0 1.0 1.0 false
        append owners owner
        if i <= 8 do caPreview owner #()
    )
    rejected = false
    try (caPreview owners[9] #()) catch (rejected = true)
    caPCheck "Ninth active setup preview rejects bounded cache admission" (rejected and not (caPreviewInfo owners[9])[1])
    local preserved = true
    for i = 1 to 8 where not (caPreviewInfo owners[i])[2] do preserved = false
    caPCheck "Cache admission failure preserves eight existing previews" preserved
    caClearPreview owners[1]
    caPreview owners[9] #()
    caPCheck "Clearing one slot admits next native preview" ((caPreviewInfo owners[9])[2])
    for owner in owners do caClearPreview owner
)
catch
(
    caPFailures += 1
    append caPLog ("ERROR " + (getCurrentException() as string))
)
(
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    format "% passes=% failures=%\n" (if caPFailures == 0 then "SUCCESS" else "ERROR") caPPasses caPFailures to:report
    for line in caPLog do format "%\n" line to:report
    close report
)
