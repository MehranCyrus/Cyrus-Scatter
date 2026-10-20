/*
  Native arrangement lifecycle qualification; owned Max 2027 batch only.
  Run with tools/run_max_tests.py --test-script tests/max/arrange_lifecycle_tests.ms.
  No external assets, UI automation, asynchronous waits or artist scenes.

  A deleted BOUND asset source must fail Update and retain published output.
  A deliberately IMPORTED geometry-only asset remains a valid source-free asset.
  Group and clone commands follow Autodesk's documented MAXScript interfaces:
  Node Group-Related Methods, GUID-FB6EA335-79C3-437E-8DD8-68B56981F771;
  maxOps.CloneNodes, GUID-48C5E2F2-DE34-4EA3-A84C-4DBD463DBF90.
*/
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caFxMM, caFxBox
global caLifeLog = #(), caLifePasses = 0, caLifeFailures = 0, caLifeFinished = false
global caLifeWrite, caLifeCheck, caLifeRequire, caLifeRun, caLifeReset
global caLifeSignature, caLifeHandles, caLifeAllValid, caLifeFindRow, caLifeNear
global caLifeFixture, caLifeGroups, caLifeLiveAndLocks, caLifeDeletion
global caLifeCloneOwner, caLifeCloneSystem, caLifeReopen, caLifeFailuresRetain

fn caLifeWrite =
(
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    local state = if caLifeFinished then (if caLifeFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
    format "% passes=% failures=%\n" state caLifePasses caLifeFailures to:report
    for line in caLifeLog do format "%\n" line to:report
    close report
)
fn caLifeCheck label condition =
(
    if condition then (caLifePasses += 1; append caLifeLog ("PASS " + label))
    else (caLifeFailures += 1; append caLifeLog ("FAIL " + label))
    caLifeWrite()
    condition
)
fn caLifeRequire label condition =
(
    caLifeCheck label condition
    if not condition do throw ("Prerequisite failed: " + label)
    condition
)
fn caLifeRun label operation =
(
    append caLifeLog ("CASE " + label)
    caLifeWrite()
    try (operation()) catch
    (
        caLifeFailures += 1
        append caLifeLog ("ERROR " + label + ": " + (getCurrentException() as string))
        caLifeWrite()
    )
)
fn caLifeReset =
(
    resetMaxFile #noPrompt
    units.SystemType = #millimeters
    units.SystemScale = 1
    fileIn (CA_TEST_ROOT + "tests/max/fixtures.ms")
)
fn caLifeSignature rows =
(
    local record = #()
    for row in rows do append record #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
    record as string
)
fn caLifeHandles rows =
(
    local result = #()
    for row in rows do append result (if isValidNode row[9] then getHandleByAnim row[9] else 0)
    result as string
)
fn caLifeAllValid rows =
(
    local valid = rows.count > 0
    for row in rows where not isValidNode row[9] do valid = false
    valid
)
fn caLifeFindRow rows id =
(
    local found = undefined
    for row in rows where row[1] == id do found = row
    found
)
fn caLifeNear a b tolerance:0.02 = (distance a b) <= tolerance

/* Fixture tuple: setup, furniture group, furniture members, asset group,
   asset members, unrelated node. Open groups permit documented detach calls. */
fn caLifeFixture live:false =
(
    caLifeReset()
    local top = caFxBox "LIFE_TableTop" [1000,500,30] [0,0,300]
    local leg = caFxBox "LIFE_TableLeg" [35,350,300] [-450,0,0]
    local furniture = group #(top,leg) name:"CA_LIFE_FURNITURE"
    setGroupOpen furniture true
    local book = caFxBox "LIFE_BookBody" [100,70,20] [2500,0,0]
    local cover = caFxBox "LIFE_BookCover" [100,70,2] [2500,0,20]
    local source = group #(book,cover) name:"CA_LIFE_SOURCE"
    setGroupOpen source true
    local unrelated = caFxBox "LIFE_Unrelated" [20,20,20] [5000,0,0]
    local setup = caCreateSetup #(furniture,top,furniture) 1
    setup.name = "CA_LIFE_SETUP"
    caRegisterAsset setup source "Lifecycle Book" 1 31 #(0.0,90.0,180.0,270.0) 1.0 1.0 1.0 false
    local settings = (caSetupSummary setup)[9]
    settings[1] = 121; settings[2] = 0.15; settings[3] = 12; settings[4] = 10
    settings[5] = 0.2; settings[6] = 0; settings[7] = 0.45
    settings[8] = 1; settings[9] = 1; settings[10] = 40; settings[11] = live
    caSetArrangeSettings setup settings
    local generated = caGenerate setup #()
    caLifeRequire "Fixture publishes nonempty native output" (generated[2] > 0 and caLifeAllValid (caOutputRows setup))
    caLifeRequire "Fixture starts clean" ((caSetupSummary setup)[6] == 0)
    #(setup,furniture,#(top,leg),source,#(book,cover),unrelated)
)

fn caLifeGroups =
(
    local f = caLifeFixture()
    local setup = f[1], furniture = f[2], top = f[3][1], source = f[4], book = f[5][1]
    local revision = (caSetupSummary setup)[3]
    local signature = caLifeSignature (caOutputRows setup)
    local handles = caLifeHandles (caOutputRows setup)
    f[6].width += 7
    f[6].pos += [0,50,0]
    caTick()
    caLifeCheck "Unrelated geometry/TM edits leave Manual clean" ((caSetupSummary setup)[6] == 0 and (caSetupSummary setup)[3] == revision)
    top.width += 40
    caTick()
    caLifeCheck "Furniture group child edit marks Manual pending" ((caSetupSummary setup)[6] != 0)
    caLifeCheck "Manual tick retains records and output identity" ((caSetupSummary setup)[3] == revision and (caLifeSignature (caOutputRows setup)) == signature and (caLifeHandles (caOutputRows setup)) == handles)
    caGenerate setup #()
    book.width += 8
    caTick()
    caLifeCheck "Asset group child geometry edit is observed" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    caLifeCheck "Asset group child recapture updates dimensions" (abs ((caAssetRows setup)[1][4].x - 108) < 0.02)
    book.pos += [3,0,0]
    caTick()
    caLifeCheck "Asset group child transform edit is observed" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()

    local extraFurniture = caFxBox "LIFE_NewFurnitureMember" [150,150,20] [650,0,300]
    attachNodesToGroup #(extraFurniture) furniture
    caTick()
    caLifeCheck "New furniture group member invalidates captured roots" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    extraFurniture.width += 15
    caTick()
    caLifeCheck "New furniture member is watched after Update" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    detachNodesFromGroup #(extraFurniture)
    caTick()
    caLifeCheck "Removed furniture member invalidates arrangement" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    extraFurniture.width += 15
    caTick()
    caLifeCheck "Removed furniture member stops invalidating after Update" ((caSetupSummary setup)[6] == 0)

    local extraAsset = caFxBox "LIFE_NewAssetMember" [30,20,8] [2570,0,0]
    attachNodesToGroup #(extraAsset) source
    caTick()
    caLifeCheck "New asset group member invalidates captured roots" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    caLifeCheck "New asset member is included in native capture" ((caAssetRows setup)[1][4].x > 125)
    extraAsset.height += 2
    caTick()
    caLifeCheck "New asset member is watched after Update" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    detachNodesFromGroup #(extraAsset)
    caTick()
    caLifeCheck "Removed asset member invalidates arrangement" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    extraAsset.height += 2
    caTick()
    caLifeCheck "Removed asset member stops invalidating after Update" ((caSetupSummary setup)[6] == 0)
)

fn caLifeLiveAndLocks =
(
    local f = caLifeFixture live:true
    local setup = f[1], top = f[3][1], book = f[5][1]
    local revision = (caSetupSummary setup)[3]
    f[6].height += 5
    caTick()
    caLifeCheck "Unrelated edit does not rebuild Live setup" ((caSetupSummary setup)[3] == revision and (caSetupSummary setup)[6] == 0)
    top.width += 40
    caTick()
    caLifeCheck "Live tick rebuilds relevant furniture descendant" ((caSetupSummary setup)[3] > revision and (caSetupSummary setup)[6] == 0)
    revision = (caSetupSummary setup)[3]
    book.width += 4
    caTick()
    caLifeCheck "Live tick rebuilds relevant asset descendant" ((caSetupSummary setup)[3] > revision and abs ((caAssetRows setup)[1][4].x - 104) < 0.02)
    revision = (caSetupSummary setup)[3]
    local first = (caOutputRows setup)[1]
    local moved = rotateZMatrix 30
    moved.row4 = [0,0,330]
    first[9].transform = moved
    caTick()
    caLifeCheck "Live retains manually moved output until authored Update" ((caSetupSummary setup)[3] == revision and caLifeNear first[9].pos moved.row4)
    caLifeCheck "Output-only edit reports pending state" ((caSetupSummary setup)[6] != 0 and (caSetupSummary setup)[8] != "")
    caSetLocked setup #(first[1]) true
    local locked = caLifeFindRow (caOutputRows setup) first[1]
    caLifeRequire "Lock captures edited world contact point" (locked != undefined and locked[7] and caLifeNear locked[4] moved.row4)
    caLifeCheck "Lock captures edited upright yaw and scale" (abs (locked[5] - 30) < 0.01 and abs (locked[6] - 1) < 0.0001)
    caGenerate setup #()
    local after = caLifeFindRow (caOutputRows setup) first[1]
    caLifeRequire "Regeneration retains moved locked placement identity" (after != undefined)
    caLifeCheck "Regeneration retains moved locked pose" (after[7] and caLifeNear after[4] moved.row4 and caLifeNear after[9].pos moved.row4 and abs (after[5] - 30) < 0.01)
    local settings = (caSetupSummary setup)[9]
    settings[11] = false
    caSetArrangeSettings setup settings
    caGenerate setup #()
    revision = (caSetupSummary setup)[3]
    top.width += 20
    caTick()
    caLifeCheck "Switching Live off restores Manual retention" ((caSetupSummary setup)[3] == revision and (caSetupSummary setup)[6] != 0)
)

fn caLifeDeletion =
(
    local f = caLifeFixture()
    local setup = f[1]
    local records = caLifeSignature (caOutputRows setup)
    local handles = caLifeHandles (caOutputRows setup)
    local victim = (caOutputRows setup)[1][9]
    undo "Lifecycle delete output" on (delete victim)
    caTick()
    caLifeCheck "Output deletion nulls native positional reference" ((caOutputRows setup)[1][9] == undefined and (caLifeSignature (caOutputRows setup)) == records)
    caLifeCheck "Output deletion marks arrangement pending" ((caSetupSummary setup)[6] != 0)
    max undo
    caLifeCheck "Undo output deletion restores real references" (caLifeAllValid (caOutputRows setup) and (caLifeHandles (caOutputRows setup)) == handles)
    max redo
    caLifeCheck "Redo output deletion nulls same reference" ((caOutputRows setup)[1][9] == undefined)
    max undo
    caGenerate setup #()
    records = caLifeSignature (caOutputRows setup)
    handles = caLifeHandles (caOutputRows setup)
    local library = CA_TEST_OUTPUT + "lifecycle-source-free.cyalib"
    caSaveAssetLibrary setup library
    undo "Lifecycle delete bound asset source" on (delete f[4])
    caTick()
    caLifeCheck "Bound source deletion nulls source reference" (not (caAssetRows setup)[1][10])
    local rejected = false
    try (caGenerate setup #()) catch (rejected = true)
    caLifeCheck "Missing bound source fails instead of becoming imported geometry" rejected
    caLifeCheck "Missing bound source retains published records and nodes" ((caLifeSignature (caOutputRows setup)) == records and (caLifeHandles (caOutputRows setup)) == handles and caLifeAllValid (caOutputRows setup))
    max undo
    caLifeCheck "Undo source deletion restores native source reference" ((caAssetRows setup)[1][10])
    caGenerate setup #()
    caLifeCheck "Restored source updates successfully" ((caSetupSummary setup)[6] == 0)
    local imported = caCreateSetup #(f[2]) 1
    caLoadAssetLibrary imported library
    local generated = caGenerate imported #()
    caLifeCheck "Imported geometry-only asset remains source-free and valid" (not (caAssetRows imported)[1][10] and generated[2] > 0 and caLifeAllValid (caOutputRows imported))

    records = caLifeSignature (caOutputRows setup)
    handles = caLifeHandles (caOutputRows setup)
    undo "Lifecycle delete furniture root" on (delete f[2])
    rejected = false
    try (caGenerate setup #()) catch (rejected = true)
    caLifeCheck "Missing furniture root fails with retained output" (rejected and (caLifeSignature (caOutputRows setup)) == records and (caLifeHandles (caOutputRows setup)) == handles)
    max undo
    caGenerate setup #()
    caLifeCheck "Undo furniture deletion restores root binding" ((caSetupSummary setup)[6] == 0)
    records = caLifeSignature (caOutputRows setup)
    handles = caLifeHandles (caOutputRows setup)
    local ownedNodes = for row in caOutputRows setup collect row[9]
    undo "Lifecycle delete setup owner" on (delete setup)
    local ownOutputSurvives = true
    for node in ownedNodes where not isValidNode node do ownOutputSurvives = false
    caLifeCheck "Deleting setup owner preserves its ordinary output nodes" ownOutputSurvives
    local outputSurvives = true
    for row in caOutputRows imported where not isValidNode row[9] do outputSurvives = false
    caLifeCheck "Deleting one setup does not delete another setup output" outputSurvives
    max undo
    setup = getNodeByName "CA_LIFE_SETUP"
    caLifeCheck "Undo setup deletion restores native owner and output bindings" (isValidNode setup and (caLifeSignature (caOutputRows setup)) == records and (caLifeHandles (caOutputRows setup)) == handles)
)

fn caLifeCloneOwner =
(
    local f = caLifeFixture()
    local setup = f[1], id = (caSetupSummary f[1])[1]
    local records = caLifeSignature (caOutputRows setup)
    local handles = caLifeHandles (caOutputRows setup)
    local originals, copies
    local success = maxOps.cloneNodes #(setup) cloneType:#copy expandHierarchy:false actualNodeList:&originals newNodes:&copies
    caLifeRequire "Setup-only clone succeeds" success
    local index = findItem originals setup
    caLifeRequire "Setup-only clone returns mapped owner" (index > 0)
    local clone = copies[index]
    caLifeCheck "Setup-only clone allocates new document namespace" ((caSetupSummary clone)[1] != id)
    caLifeCheck "Setup-only clone clears placements and output ownership" ((caSetupSummary clone)[5] == 0 and (caOutputRows clone).count == 0)
    caLifeCheck "Setup-only clone preserves original state and nodes" ((caLifeSignature (caOutputRows setup)) == records and (caLifeHandles (caOutputRows setup)) == handles)
    caGenerate clone #()
    local disjoint = caLifeAllValid (caOutputRows clone)
    local oldNodes = for row in caOutputRows setup collect row[9]
    for row in caOutputRows clone do if (findItem oldNodes row[9]) > 0 do disjoint = false
    caLifeCheck "Setup-only clone generates independently owned output" disjoint
    caLifeCheck "Clone generation preserves original output identity" ((caLifeHandles (caOutputRows setup)) == handles)
    local tagged = true
    for row in caOutputRows clone do if (getUserProp row[9] "CyrusArrangeOwner") != (caSetupSummary clone)[1] do tagged = false
    caLifeCheck "New clone output diagnostics match its namespace" tagged
)

fn caLifeCloneSystem =
(
    local f = caLifeFixture()
    local setup = f[1], id = (caSetupSummary f[1])[1]
    local records = caLifeSignature (caOutputRows setup)
    local handles = caLifeHandles (caOutputRows setup)
    local originals, copies
    local all = #(setup,f[2],f[4])
    for row in caOutputRows setup do append all row[9]
    local success = maxOps.cloneNodes all cloneType:#copy expandHierarchy:true actualNodeList:&originals newNodes:&copies
    caLifeRequire "Whole-system clone succeeds" success
    local index = findItem originals setup
    caLifeRequire "Whole-system clone returns mapped owner" (index > 0)
    local clone = copies[index]
    caLifeCheck "Whole-system clone allocates new namespace" ((caSetupSummary clone)[1] != id)
    caLifeCheck "Whole-system clone retains mapped placement records" ((caLifeSignature (caOutputRows clone)) == records)
    local mappedOutputs = caLifeAllValid (caOutputRows clone)
    for row in caOutputRows clone do if (findItem copies row[9]) == 0 do mappedOutputs = false
    caLifeCheck "Whole-system clone references cloned output nodes" mappedOutputs
    caLifeCheck "Whole-system clone leaves original outputs unchanged" ((caLifeHandles (caOutputRows setup)) == handles)
    caGenerate clone #()
    index = findItem originals f[3][1]
    caLifeRequire "Whole-system clone returns mapped furniture child" (index > 0)
    copies[index].width += 20
    caTick()
    caLifeCheck "Cloned furniture child invalidates cloned setup" ((caSetupSummary clone)[6] != 0)
    caLifeCheck "Cloned furniture child leaves original setup clean" ((caSetupSummary setup)[6] == 0)
    caGenerate clone #()
    index = findItem originals f[5][1]
    caLifeRequire "Whole-system clone returns mapped asset child" (index > 0)
    copies[index].width += 12
    caGenerate clone #()
    caLifeCheck "Cloned source recapture uses mapped source binding" (abs ((caAssetRows clone)[1][4].x - 112) < 0.02 and abs ((caAssetRows setup)[1][4].x - 100) < 0.02)
    caLifeCheck "Clone edits/regeneration retain original published result" ((caLifeSignature (caOutputRows setup)) == records and (caLifeHandles (caOutputRows setup)) == handles)
)

fn caLifeReopen =
(
    local f = caLifeFixture live:true
    local setup = f[1]
    local first = (caOutputRows setup)[1]
    caSetLocked setup #(first[1]) true
    caGenerate setup #()
    local records = caLifeSignature (caOutputRows setup)
    local id = (caSetupSummary setup)[1]
    local revision = (caSetupSummary setup)[3]
    local settings = (caSetupSummary setup)[9] as string
    local assetRows = caAssetRows setup
    local scene = CA_TEST_OUTPUT + "lifecycle-reopen.max"
    saveMaxFile scene quiet:true
    loadMaxFile scene useFileUnits:true quiet:true
    setup = getNodeByName "CA_LIFE_SETUP"
    caLifeRequire "Reopen restores native scene owner" (isValidNode setup)
    caLifeCheck "Reopen preserves document namespace and revision" ((caSetupSummary setup)[1] == id and (caSetupSummary setup)[3] == revision)
    caLifeCheck "Reopen preserves settings and authored Live preference" (((caSetupSummary setup)[9] as string) == settings and (caSetupSummary setup)[7])
    caLifeCheck "Reopen preserves exact placement/lock records" ((caLifeSignature (caOutputRows setup)) == records)
    caLifeCheck "Reopen restores output and asset source references" (caLifeAllValid (caOutputRows setup) and (caAssetRows setup)[1][10] and (caAssetRows setup)[1][4] == assetRows[1][4])
    caTick()
    caLifeCheck "Reopened Live setup waits for explicit validation" ((caSetupSummary setup)[3] == revision and (caSetupSummary setup)[6] != 0)
    -- Moving the source group preserves its canonical mesh and exact support
    -- region IDs. A changed furniture footprint correctly retires a protected ID.
    local source = getNodeByName "CA_LIFE_SOURCE"
    source.pos += [20,0,0]
    caTick()
    caLifeCheck "Reopened Live remains disarmed after dependency edit" ((caSetupSummary setup)[3] == revision)
    caGenerate setup #()
    revision = (caSetupSummary setup)[3]
    source.pos += [20,0,0]
    caTick()
    caLifeCheck "Explicit post-load Update re-arms relevant Live updates" ((caSetupSummary setup)[3] > revision and (caSetupSummary setup)[6] == 0)
)

fn caLifeFailuresRetain =
(
    local f = caLifeFixture()
    local setup = f[1]
    local records = caLifeSignature (caOutputRows setup)
    local handles = caLifeHandles (caOutputRows setup)
    local settings = (caSetupSummary setup)[9]
    settings[10] = 0.1
    caSetArrangeSettings setup settings
    local revision = (caSetupSummary setup)[3]
    local rejected = false
    try (caGenerate setup #()) catch (rejected = true)
    caLifeCheck "Excessively fine support grid rejects bounded work" rejected
    caLifeCheck "Failed generation retains native placement state" ((caLifeSignature (caOutputRows setup)) == records and (caSetupSummary setup)[3] == revision)
    caLifeCheck "Failed generation retains same valid output objects" ((caLifeHandles (caOutputRows setup)) == handles and caLifeAllValid (caOutputRows setup))
    caLifeCheck "Failed generation reports retained-result error" ((caSetupSummary setup)[8] != "" and (caSetupSummary setup)[6] != 0)
    settings[10] = 40
    caSetArrangeSettings setup settings
    rejected = false
    try (caGenerate setup #(2147483647)) catch (rejected = true)
    caLifeCheck "Unknown regeneration region fails atomically" (rejected and (caLifeSignature (caOutputRows setup)) == records and (caLifeHandles (caOutputRows setup)) == handles)
    local invalid = point name:"CA_LIFE_UNSUPPORTED_GROUP_MEMBER" pos:[0,0,0]
    attachNodesToGroup #(invalid) f[2]
    caTick()
    rejected = false
    try (caGenerate setup #()) catch (rejected = true)
    caLifeCheck "Unsupported new group member rejects partial capture" (rejected and (caLifeSignature (caOutputRows setup)) == records and (caLifeHandles (caOutputRows setup)) == handles)
    detachNodesFromGroup #(invalid)
    delete invalid
    caGenerate setup #()
    caLifeCheck "Repair after failure publishes successfully and clears error" ((caSetupSummary setup)[6] == 0 and (caSetupSummary setup)[8] == "" and caLifeAllValid (caOutputRows setup))
)

caLifeRun "Group dependency edits and membership, Manual isolation" caLifeGroups
caLifeRun "Relevant Live updates, output edit protection and pose locking" caLifeLiveAndLocks
caLifeRun "Reference deletion, Undo/Redo and imported geometry policy" caLifeDeletion
caLifeRun "Setup-only clone ownership" caLifeCloneOwner
caLifeRun "Whole-system clone remapping and isolation" caLifeCloneSystem
caLifeRun "Scene save/reopen and Live re-arming" caLifeReopen
caLifeRun "Generation failure retains previous published result" caLifeFailuresRetain
caLifeFinished = true
caLifeWrite()
