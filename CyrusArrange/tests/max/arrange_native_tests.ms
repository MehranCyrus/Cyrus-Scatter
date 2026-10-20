/* Native workflow/lifecycle test. Isolated Max 2027 batch only. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caFxMM, caFxBox, caFxTVConsole, caFxOpenShelf
global caArrangeCheck, caArrangeSignature
global caArrangeLog = #(), caArrangePasses = 0, caArrangeFailures = 0
fn caArrangeCheck label condition =
(
    if condition then (caArrangePasses += 1; append caArrangeLog ("PASS " + label))
    else (caArrangeFailures += 1; append caArrangeLog ("FAIL " + label))
    condition
)
fn caArrangeSignature rows =
(
    local result = #()
    for row in rows do append result #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
    result as string
)
try
(
    resetMaxFile #noPrompt
    units.SystemType = #millimeters
    units.SystemScale = 1
    fileIn (CA_TEST_ROOT + "tests/max/fixtures.ms")
    local furniture = (caFxTVConsole())[2]
    local source = caFxBox "RegisteredBook" [150,100,25] [2500,0,0]
    source.material = standardMaterial name:"CA_TEST_Book" diffuse:(color 160 70 40)
    local setup = caCreateSetup furniture 1
    setup.name = "CA_NATIVE_SETUP"
    caArrangeCheck "Native setup created" (isValidNode setup and (caSetupSummary setup)[4] == 0)
    local assetID = caRegisterAsset setup source "Flat Book" 1 31 #(0.0,90.0,180.0,270.0) 1.0 1.0 1.0 true
    caArrangeCheck "Registered dimensions are mm" ((caAssetRows setup)[1][4] == [150,100,25])
    local settings = (caSetupSummary setup)[9]
    settings[1] = 17; settings[2] = 0.25; settings[3] = 10; settings[4] = 12
    settings[5] = 0.8; settings[7] = 0.5; settings[8] = 3
    caSetArrangeSettings setup settings
    local generated = caGenerate setup #()
    local first = caOutputRows setup
    caArrangeCheck "Native generation creates real output" (generated[2] > 0 and first.count == generated[2])
    caArrangeCheck "Successful update clears dirty" ((caSetupSummary setup)[6] == 0)
    local goodNodes = true
    for row in first do
    (
        if not isValidNode row[9] then goodNodes = false
        else if (getUserProp row[9] "CyrusArrangeOwner") != (caSetupSummary setup)[1] then goodNodes = false
    )
    caArrangeCheck "Output references match scene ownership" goodNodes
    local original = caArrangeSignature first
    caGenerate setup #()
    caArrangeCheck "Seed regenerates identical records" ((caArrangeSignature (caOutputRows setup)) == original)
    caSetLocked setup #(first[1][1]) true
    local lockedBefore = (caOutputRows setup)[1]
    settings = (caSetupSummary setup)[9]; settings[1] += 1
    caSetArrangeSettings setup settings
    caArrangeCheck "Manual settings preserve existing output" ((caOutputRows setup).count == first.count)
    caGenerate setup #()
    local afterLock = caOutputRows setup
    local foundLock = false
    for row in afterLock where row[1] == first[1][1] do foundLock = row[7] and row[4] == first[1][4]
    caArrangeCheck "Reroll preserves locked transform" foundLock
    local savedSignature = caArrangeSignature afterLock
    local savedCount = afterLock.count
    settings = (caSetupSummary setup)[9]; settings[2] = -1
    local rejected = false
    try (caSetArrangeSettings setup settings) catch (rejected = true)
    caArrangeCheck "Invalid settings rejected atomically" (rejected and (caArrangeSignature (caOutputRows setup)) == savedSignature)
    caSaveAssetLibrary setup (CA_TEST_OUTPUT + "books.cyalib")
    local imported = caCreateSetup furniture 1
    imported.name = "CA_IMPORTED_SETUP"
    caLoadAssetLibrary imported (CA_TEST_OUTPUT + "books.cyalib")
    caArrangeCheck "Portable geometry library imports" ((caAssetRows imported).count == 1 and not (caAssetRows imported)[1][10])
    local loadedGenerated = caGenerate imported #()
    caArrangeCheck "Imported asset generates without source reference" (loadedGenerated[2] > 0)
    local scene = CA_TEST_OUTPUT + "native-arrangement.max"
    saveMaxFile scene quiet:true
    loadMaxFile scene useFileUnits:true quiet:true
    setup = getNodeByName "CA_NATIVE_SETUP"
    source = getNodeByName "CA_FIXTURE_RegisteredBook"
    caArrangeCheck "Scene reopens native owner" (isValidNode setup and (caSetupSummary setup)[5] == savedCount)
    caArrangeCheck "Placement state survives reopen exactly" ((caArrangeSignature (caOutputRows setup)) == savedSignature)
    caArrangeCheck "Asset source reference survives reopen" ((caAssetRows setup)[1][10])
    local validOutputs = true
    for row in caOutputRows setup where not isValidNode row[9] do validOutputs = false
    caArrangeCheck "Output references survive reopen" validOutputs
    caGenerate setup #()
    caArrangeCheck "Loaded seed reproduces arrangement" ((caArrangeSignature (caOutputRows setup)) == savedSignature)
    local beforeUndo = caArrangeSignature (caOutputRows setup)
    settings = (caSetupSummary setup)[9]; settings[1] += 31
    undo "Arrange test reroll" on (caSetArrangeSettings setup settings; caGenerate setup #())
    local afterUndo = caArrangeSignature (caOutputRows setup)
    caArrangeCheck "Changed seed changes unlocked placements" (beforeUndo != afterUndo)
    max undo
    caArrangeCheck "Undo restores native state and outputs" ((caArrangeSignature (caOutputRows setup)) == beforeUndo)
    max redo
    caArrangeCheck "Redo restores native state and outputs" ((caArrangeSignature (caOutputRows setup)) == afterUndo)
    local oldCount = (caOutputRows setup).count
    local oldRevision = (caSetupSummary setup)[3]
    undo "Change furniture" on (furniture = getNodeByName "CA_FIXTURE_TV_Top"; furniture.width += caFxMM 50)
    caArrangeCheck "Furniture edit marks Manual pending" ((caSetupSummary setup)[6] != 0 and (caSetupSummary setup)[3] == oldRevision and (caOutputRows setup).count == oldCount)
    caTick()
    caArrangeCheck "Manual tick does not rebuild" ((caSetupSummary setup)[3] == oldRevision)
)
catch
(
    caArrangeFailures += 1
    append caArrangeLog ("ERROR " + (getCurrentException() as string))
)
(
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    format "% passes=% failures=%\n" (if caArrangeFailures == 0 then "SUCCESS" else "ERROR") caArrangePasses caArrangeFailures to:report
    for line in caArrangeLog do format "%\n" line to:report
    close report
)
