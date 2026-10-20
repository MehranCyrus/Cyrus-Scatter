/* Independent collision scope and native reference lifecycle, owned Max 2027.
   All meshes are original primitives. No artist scene, host launch or UI automation.
   Collision avoidance is checked independently with fixture world-space AABBs;
   the accessory fixture uses only cardinal rotations and uniform unit scale. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caFxBox, caFxMM, caCollisionUI, caShowCollisionUI
global caOLog = #(), caOPasses = 0, caOFailures = 0, caOFinished = false
global caOWrite, caOCheck, caORequire, caORun, caOReset, caOFixture
global caOSignature, caOHandles, caOValid, caORegionSignature, caOAABBOverlap
global caODefaults, caOStatic, caOApproach, caOReferences, caOGroups, caOLive
global caOClones, caOReopen, caOUI

fn caOWrite =
(
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    local status = if caOFinished then (if caOFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
    format "% passes=% failures=%\n" status caOPasses caOFailures to:report
    for line in caOLog do format "%\n" line to:report
    close report
)
fn caOCheck label condition =
(
    if condition then (caOPasses += 1; append caOLog ("PASS " + label))
    else (caOFailures += 1; append caOLog ("FAIL " + label))
    caOWrite()
    condition
)
fn caORequire label condition =
(
    caOCheck label condition
    if not condition do throw ("Prerequisite failed: " + label)
    condition
)
fn caORun label operation =
(
    append caOLog ("CASE " + label); caOWrite()
    try (operation()) catch
    (
        caOFailures += 1
        append caOLog ("ERROR " + label + ": " + (getCurrentException() as string))
        caOWrite()
    )
)
fn caOReset =
(
    try (destroyDialog caCollisionUI) catch()
    resetMaxFile #noPrompt
    units.SystemType = #millimeters; units.SystemScale = 1
    fileIn (CA_TEST_ROOT + "tests/max/fixtures.ms")
)
fn caOSignature rows =
(
    local result = #()
    for row in rows do append result #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
    result as string
)
fn caOHandles rows =
(
    local result = #()
    for row in rows do append result (if isValidNode row[9] then getHandleByAnim row[9] else 0)
    result as string
)
fn caOValid rows =
(
    local valid = rows.count > 0
    for row in rows where not isValidNode row[9] do valid = false
    valid
)
fn caORegionSignature setup =
(
    local result = #()
    for row in caRegionRows setup do append result #(row[1],row[5],row[6],row[7],row[8])
    result as string
)
fn caOAABBOverlap left right =
(
    local a = nodeGetBoundingBox left (matrix3 1)
    local b = nodeGetBoundingBox right (matrix3 1)
    local e = caFxMM 0.02
    a[1].x < b[2].x-e and a[2].x > b[1].x+e and a[1].y < b[2].y-e and a[2].y > b[1].y+e and a[1].z < b[2].z-e and a[2].z > b[1].z+e
)
/* Tuple: owner, furniture top, source book, obstacle root, obstacle children,
   unrelated node. Far obstacles cannot intersect this tabletop or its front ray. */
fn caOFixture live:false bind:true =
(
    caOReset()
    local top = caFxBox "OBS_Table" [1200,700,30] [0,0,300]
    local book = caFxBox "OBS_Book" [100,70,20] [2500,0,0]
    local a = caFxBox "OBS_ChildA" [80,80,60] [4000,0,330]
    local b = caFxBox "OBS_ChildB" [80,80,60] [4200,0,330]
    local obstacle = group #(a,b) name:"CA_OBS_GROUP"
    setGroupOpen obstacle true
    local unrelated = caFxBox "OBS_Unrelated" [20,20,20] [6000,0,0]
    local setup = caCreateSetup #(top) 3
    setup.name = "CA_OBS_SETUP"
    caRegisterAsset setup book "Obstacle Book" 1 31 #(0.0,90.0,180.0,270.0) 1.0 1.0 1.0 false
    local settings = (caSetupSummary setup)[9]
    settings[1] = 593; settings[2] = 0.18; settings[3] = 12; settings[4] = 10
    settings[5] = 0.2; settings[6] = 0; settings[7] = 0.45
    settings[8] = 1; settings[9] = 3; settings[10] = 40; settings[11] = live
    caSetArrangeSettings setup settings
    if bind do caSetCollisionScope setup #(obstacle) false
    caGenerate setup #()
    caORequire "Fixture publishes nonempty clean output" (caOValid (caOutputRows setup) and (caSetupSummary setup)[6] == 0)
    #(setup,top,book,obstacle,#(a,b),unrelated)
)

fn caODefaults =
(
    caOReset()
    local top = caFxBox "OBS_DefaultTop" [1200,700,30] [0,0,300]
    for category = 1 to 5 do
    (
        local setup = caCreateSetup #(top) category
        local scope = caCollisionScope setup
        caOCheck ("Descriptive category " + (category as string) + " starts without an implicit front-access restriction") (scope.count == 2 and not scope[1] and scope[2].count == 0)
    )
)

fn caOStatic =
(
    local f = caOFixture bind:false
    local setup = f[1], first = (caOutputRows f[1])[1]
    local regions = caORegionSignature setup
    caSetLocked setup #(first[1]) true
    local block = caFxBox "OBS_IntersectLocked" [180,180,80] first[4]
    caORequire "Independent fixture obstacle overlaps an existing output" (caOAABBOverlap block first[9])
    caSetCollisionScope setup #(block,block) false
    caOCheck "Obstacle roots deduplicate in native scope" ((caCollisionScope setup)[2].count == 1 and (caCollisionScope setup)[2][1][1] == block)
    local records = caOSignature (caOutputRows setup), handles = caOHandles (caOutputRows setup)
    local revision = (caSetupSummary setup)[3], rejected = false
    try (caGenerate setup #()) catch (rejected = true)
    caOCheck "Protected placement collision rejects generation" rejected
    caOCheck "Collision failure retains exact records, nodes and authored revision" ((caOSignature (caOutputRows setup)) == records and (caOHandles (caOutputRows setup)) == handles and (caSetupSummary setup)[3] == revision and caOValid (caOutputRows setup))
    rejected = false
    try (caPreview setup #()) catch (rejected = true)
    caOCheck "Protected collision also rejects Preview without replacing output" (rejected and (caOHandles (caOutputRows setup)) == handles)
    caOCheck "Obstacle collision leaves furniture support identities unchanged" ((caORegionSignature setup) == regions)
    caSetLocked setup #(first[1]) false
    local generated = caGenerate setup #()
    caORequire "Unlock permits a nonempty collision-aware successor" (generated[2] > 0 and caOValid (caOutputRows setup))
    local avoids = true, furnitureOnly = true
    for row in caOutputRows setup do
    (
        if caOAABBOverlap row[9] block do avoids = false
        if abs (row[4].z-330) > 0.02 do furnitureOnly = false
    )
    caOCheck "Published meshes independently avoid the external obstacle" avoids
    caOCheck "Obstacle top never becomes an authorized support surface" (furnitureOnly and (caORegionSignature setup) == regions)
    local before = (caCollisionScope setup)[2][1][1], rejectedOverlap = false, rejectedGenerated = false
    try (caSetCollisionScope setup #(f[2]) false) catch (rejectedOverlap = true)
    try (caSetCollisionScope setup #((caOutputRows setup)[1][9]) false) catch (rejectedGenerated = true)
    caOCheck "Furniture overlap and generated output reject scope edits atomically" (rejectedOverlap and rejectedGenerated and (caCollisionScope setup)[2][1][1] == before)
    caSetCollisionScope setup #() false
    caOCheck "Empty scope explicitly clears obstacle roots" ((caCollisionScope setup)[2].count == 0)
    caGenerate setup #()
    caOCheck "Cleared scope publishes successfully" ((caSetupSummary setup)[6] == 0)
)

fn caOApproach =
(
    local f = caOFixture bind:false
    local setup = f[1], wall = caFxBox "OBS_FrontBarrier" [1600,50,180] [0,-430,330]
    caSetCollisionScope setup #(wall) false
    caGenerate setup #()
    caORequire "Static placement fits behind an external front barrier" ((caOutputRows setup).count > 0)
    local first = (caOutputRows setup)[1]
    caSetLocked setup #(first[1]) true
    caSetCollisionScope setup #(wall) true
    local records = caOSignature (caOutputRows setup), handles = caOHandles (caOutputRows setup)
    local rejected = false
    try (caGenerate setup #()) catch (rejected = true)
    caOCheck "Authored front access rejects the blocked protected approach" (rejected and (caOSignature (caOutputRows setup)) == records and (caOHandles (caOutputRows setup)) == handles)
    caSetLocked setup #(first[1]) false
    local blocked = caGenerate setup #()
    caOCheck "Front barrier rejects all unprotected candidates" (blocked[2] == 0 and (caOutputRows setup).count == 0)
    caSetCollisionScope setup #(wall) false
    caGenerate setup #()
    caOCheck "Disabling front access permits static placements again" (caOValid (caOutputRows setup) and not (caCollisionScope setup)[1])
)

fn caOReferences =
(
    local f = caOFixture()
    local setup = f[1], obstacle = f[4], originalHandle = getHandleByAnim f[4]
    local records = caOSignature (caOutputRows setup), handles = caOHandles (caOutputRows setup)
    undo "Obstacle source deletion" on (delete obstacle)
    caTick()
    caOCheck "Deleted obstacle remains an explicit missing binding" ((caCollisionScope setup)[2].count == 1 and (caCollisionScope setup)[2][1][1] == undefined and (caSetupSummary setup)[6] != 0)
    local rejected = false
    try (caGenerate setup #()) catch (rejected = true)
    caOCheck "Missing obstacle rejects generation and retains published result" (rejected and (caOSignature (caOutputRows setup)) == records and (caOHandles (caOutputRows setup)) == handles and caOValid (caOutputRows setup))
    max undo
    caOCheck "Undo obstacle deletion restores the actual native root reference" (isValidNode (caCollisionScope setup)[2][1][1] and getHandleByAnim (caCollisionScope setup)[2][1][1] == originalHandle)
    max redo
    caOCheck "Redo deletion nulls the same obstacle slot" ((caCollisionScope setup)[2][1][1] == undefined)
    max undo
    caGenerate setup #()
    caOCheck "Restored obstacle binding regenerates successfully" ((caSetupSummary setup)[6] == 0)
    local replacement = f[6]
    undo "Obstacle scope authored edit" on (caSetCollisionScope setup #(replacement) true)
    caOCheck "Authored replacement updates roots and approach policy together" ((caCollisionScope setup)[1] and (caCollisionScope setup)[2][1][1] == replacement)
    max undo
    caOCheck "Scope Undo restores both roots and approach policy" (not (caCollisionScope setup)[1] and getHandleByAnim (caCollisionScope setup)[2][1][1] == originalHandle)
    max redo
    caOCheck "Scope Redo restores the complete successor" ((caCollisionScope setup)[1] and (caCollisionScope setup)[2][1][1] == replacement)
)

fn caOGroups =
(
    local f = caOFixture()
    local setup = f[1], obstacle = f[4], child = f[5][1]
    caSetCollisionScope setup #(obstacle,child,obstacle) false
    caOCheck "Group plus selected child normalizes to one preserved root" ((caCollisionScope setup)[2].count == 1 and (caCollisionScope setup)[2][1][1] == obstacle)
    caGenerate setup #()
    local revision = (caSetupSummary setup)[3], handles = caOHandles (caOutputRows setup)
    child.width += 4
    caTick()
    caOCheck "Obstacle child geometry marks Manual pending without publishing" ((caSetupSummary setup)[6] != 0 and (caSetupSummary setup)[3] == revision and (caOHandles (caOutputRows setup)) == handles)
    caGenerate setup #()
    child.pos += [15,0,0]
    caTick()
    caOCheck "Obstacle child transform invalidates the arrangement" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    local extra = caFxBox "OBS_NewChild" [40,40,50] [4400,0,330]
    attachNodesToGroup #(extra) obstacle
    caTick()
    caOCheck "New obstacle group member invalidates the preserved root" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    extra.height += 3
    caTick()
    caOCheck "New obstacle descendant is watched after successful generation" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    detachNodesFromGroup #(extra)
    caTick()
    caOCheck "Removed obstacle descendant invalidates membership" ((caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    extra.width += 5
    caTick()
    caOCheck "Detached obstacle descendant stops invalidating after generation" ((caSetupSummary setup)[6] == 0)
    caPreview setup #()
    f[6].height += 5
    caOCheck "Unrelated edit leaves obstacle-aware preview valid" ((caPreviewInfo setup)[2])
    child.width += 5
    caOCheck "Obstacle descendant edit invalidates transient preview" (not (caPreviewInfo setup)[2])
    local rejected = false
    try (caCommitPreview setup) catch (rejected = true)
    caOCheck "Stale obstacle preview cannot commit over existing outputs" (rejected and caOValid (caOutputRows setup))
)

fn caOLive =
(
    local f = caOFixture live:true
    local setup = f[1], child = f[5][1]
    local revision = (caSetupSummary setup)[3], handles = caOHandles (caOutputRows setup)
    f[6].width += 2; f[6].pos += [0,10,0]
    caTick()
    caOCheck "Unrelated edits leave armed Live clean and preserve output" ((caSetupSummary setup)[3] == revision and (caSetupSummary setup)[6] == 0 and (caOHandles (caOutputRows setup)) == handles)
    child.width += 2
    caTick()
    caOCheck "Relevant obstacle child edit drives armed Live generation" ((caSetupSummary setup)[3] > revision and (caSetupSummary setup)[6] == 0)
    revision = (caSetupSummary setup)[3]
    undo "Move bound obstacle group" on (f[4].pos += [20,0,0])
    caTick()
    caOCheck "Obstacle group transform drives Live generation" ((caSetupSummary setup)[3] > revision and (caSetupSummary setup)[6] == 0)
    local settings = (caSetupSummary setup)[9]; settings[11] = false
    caSetArrangeSettings setup settings
    caGenerate setup #()
    local oldPos = copy f[4].pos
    undo "Move Manual obstacle group" on (f[4].pos += [30,0,0])
    caTick()
    caOCheck "Obstacle movement is pending in Manual" ((caSetupSummary setup)[6] != 0)
    max undo
    caOCheck "Undo restores obstacle group transform and root binding" ((distance f[4].pos oldPos) < 0.001 and (caCollisionScope setup)[2][1][1] == f[4])
    max redo
    caOCheck "Redo restores obstacle movement through the same binding" ((distance f[4].pos (oldPos+[30,0,0])) < 0.001 and (caCollisionScope setup)[2][1][1] == f[4])
)

fn caOClones =
(
    local f = caOFixture()
    local setup = f[1], originals, copies
    local handles = caOHandles (caOutputRows setup), originalId = (caSetupSummary setup)[1]
    local success = maxOps.cloneNodes #(setup) cloneType:#copy expandHierarchy:false actualNodeList:&originals newNodes:&copies
    caORequire "Setup-only obstacle owner clone succeeds" success
    local index = findItem originals setup
    caORequire "Setup-only clone owner appears in mapping" (index > 0)
    local clone = copies[index]
    caOCheck "Setup-only clone keeps external obstacle reference and policy" ((caCollisionScope clone)[2][1][1] == f[4] and not (caCollisionScope clone)[1])
    caOCheck "Setup-only clone has distinct namespace and no output claim" ((caSetupSummary clone)[1] != originalId and (caOutputRows clone).count == 0 and (caOHandles (caOutputRows setup)) == handles)
    caGenerate clone #()
    caOCheck "Setup-only clone can generate with its retained obstacle binding" (caOValid (caOutputRows clone) and (caOHandles (caOutputRows setup)) == handles)

    local all = #(setup,f[2],f[3],f[4])
    for row in caOutputRows setup do append all row[9]
    success = maxOps.cloneNodes all cloneType:#copy expandHierarchy:true actualNodeList:&originals newNodes:&copies
    caORequire "Whole-system obstacle clone succeeds" success
    index = findItem originals setup
    caORequire "Whole-system clone owner appears in mapping" (index > 0)
    clone = copies[index]
    index = findItem originals f[4]
    caORequire "Whole-system clone obstacle root appears in mapping" (index > 0)
    caOCheck "Whole-system clone remaps independent obstacle root" ((caCollisionScope clone)[2][1][1] == copies[index] and (caCollisionScope clone)[2][1][1] != f[4])
    caOCheck "Whole-system clone retains placement records and mapped outputs" ((caOSignature (caOutputRows clone)) == (caOSignature (caOutputRows setup)) and caOValid (caOutputRows clone))
    caGenerate clone #()
    index = findItem originals f[5][1]
    caORequire "Whole-system clone includes obstacle child" (index > 0)
    copies[index].width += 6
    caTick()
    caOCheck "Cloned obstacle child invalidates only its mapped owner" ((caSetupSummary clone)[6] != 0 and (caSetupSummary setup)[6] == 0 and (caOHandles (caOutputRows setup)) == handles)
    caGenerate clone #()
    caOCheck "Cloned obstacle successor preserves original output ownership" ((caSetupSummary clone)[6] == 0 and (caOHandles (caOutputRows setup)) == handles)
)

fn caOReopen =
(
    local f = caOFixture live:true
    local setup = f[1]
    caSetCollisionScope setup #(f[4]) true
    caGenerate setup #()
    local records = caOSignature (caOutputRows setup), id = (caSetupSummary setup)[1]
    local revision = (caSetupSummary setup)[3]
    local scene = CA_TEST_OUTPUT + "obstacle-reopen.max"
    saveMaxFile scene quiet:true
    loadMaxFile scene useFileUnits:true quiet:true
    setup = getNodeByName "CA_OBS_SETUP"
    local obstacle = getNodeByName "CA_OBS_GROUP", child = getNodeByName "CA_FIXTURE_OBS_ChildA"
    caORequire "Reopen restores obstacle scene owner and sources" (isValidNode setup and isValidNode obstacle and isValidNode child)
    caOCheck "Reopen preserves collision roots and approach policy" ((caCollisionScope setup)[1] and (caCollisionScope setup)[2].count == 1 and (caCollisionScope setup)[2][1][1] == obstacle)
    caOCheck "Reopen preserves native namespace, revision and published records" ((caSetupSummary setup)[1] == id and (caSetupSummary setup)[3] == revision and (caOSignature (caOutputRows setup)) == records and caOValid (caOutputRows setup))
    child.width += 3
    caTick()
    caOCheck "Reopened Live remains disarmed on obstacle edit until validation" ((caSetupSummary setup)[3] == revision and (caSetupSummary setup)[6] != 0)
    caGenerate setup #()
    revision = (caSetupSummary setup)[3]
    child.width += 3
    caTick()
    caOCheck "Explicit post-load generation restores obstacle Live watch" ((caSetupSummary setup)[3] > revision and (caSetupSummary setup)[6] == 0)
)

fn caOUI =
(
    local f = caOFixture()
    fileIn (CA_TEST_ROOT + "scripts/ArrangeCollision.ms")
    caShowCollisionUI f[1]
    local setup = f[1], revision = (caSetupSummary f[1])[3], handles = caOHandles (caOutputRows f[1])
    caCollisionUI.onRefresh()
    caOCheck "Collision UI opens and refreshes without authored changes" (caCollisionUI.currentSetup() == setup and (caCollisionUI.rows()).count == 1 and (caSetupSummary setup)[3] == revision and (caOHandles (caOutputRows setup)) == handles)
    select #(f[4],f[5][1],f[4])
    caCollisionUI.onReplace()
    caOCheck "Replace handler uses normalized native group roots" ((caCollisionScope setup)[2].count == 1 and (caCollisionScope setup)[2][1][1] == f[4] and caCollisionUI.errorMessage() == "")
    select f[6]
    caCollisionUI.onAdd()
    caOCheck "Add handler appends an independent obstacle root" ((caCollisionScope setup)[2].count == 2 and (caCollisionUI.rows()).count == 2)
    caCollisionUI.requireFront.checked = true
    caCollisionUI.onApplyApproach()
    caOCheck "Approach handler explicitly persists collision policy" ((caCollisionScope setup)[1])
    local before = (caCollisionScope setup) as string
    select f[2]
    caCollisionUI.onReplace()
    caOCheck "Rejected UI furniture overlap reports error and rehydrates successful scope" (caCollisionUI.errorMessage() != "" and ((caCollisionScope setup) as string) == before and (caCollisionUI.rows()).count == 2)
    caCollisionUI.obstacles.selection = #{1}
    caCollisionUI.onRemove()
    caOCheck "Remove handler deletes only selected authored roots" ((caCollisionScope setup)[2].count == 1)
    caCollisionUI.onClear()
    caOCheck "Clear handler preserves approach policy and published output" ((caCollisionScope setup)[2].count == 0 and (caCollisionScope setup)[1] and (caOHandles (caOutputRows setup)) == handles)
    destroyDialog caCollisionUI
)

caORun "Category-independent access defaults" caODefaults
caORun "Static collision, protected failure, independent supports and scope admission" caOStatic
caORun "Authored front approach against independent geometry" caOApproach
caORun "Missing obstacle source and scope Undo/Redo" caOReferences
caORun "Group descendants, membership and preview freshness" caOGroups
caORun "Relevant Live, unrelated edits and obstacle movement Undo" caOLive
caORun "Setup-only and whole-system clone reference ownership" caOClones
caORun "Save/reopen obstacle persistence and Live re-arming" caOReopen
caORun "Actual collision rollout handlers and error retention" caOUI
caOFinished = true
caOWrite()
