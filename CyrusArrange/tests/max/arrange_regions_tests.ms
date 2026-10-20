/* Root-controlled disposable Max 2027 host. No dialogs, downloads or computer use. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caShowAdvancedArrangeUI, caArrangeUI, caShowRegionUI, caRegionUI
global caFxMM, caFxBox, caCreateSetup, caSetupSummary, caSetArrangeSettings
global caAnalyzeSetup, caRegionRows, caSetRegionRules, caRegisterAsset, caGenerate, caOutputRows, caSetLocked
global caRegLog, caRegPasses, caRegFailures, caRegFinished, caRegWrite, caRegNote, caRegCheck, caRegRequire
global caRegSameIDs, caRegFind, caRegSamePolicy, caRegSameOutputs, caRegRun
caRegLog = #()
caRegPasses = 0
caRegFailures = 0
caRegFinished = false
fn caRegWrite =
(
    if CA_TEST_OUTPUT != undefined do
    (
        local report = createFile (CA_TEST_OUTPUT+"result.txt")
        local state = if caRegFinished then (if caRegFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
        format "% passes=% failures=%\n" state caRegPasses caRegFailures to:report
        for line in caRegLog do format "%\n" line to:report
        close report
    )
    true
)
fn caRegNote line = (append caRegLog line;caRegWrite();true)
fn caRegCheck label condition =
(
    if condition then (caRegPasses += 1;caRegNote ("PASS "+label))
    else
    (
        caRegFailures += 1
        caRegNote ("FAIL "+label)
        if caRegionUI != undefined do caRegNote ("REGION_UI "+caRegionUI.errorMessage())
        if caArrangeUI != undefined do caRegNote ("WORKFLOW_UI "+caArrangeUI.errorMessage())
    )
    condition
)
fn caRegRequire label condition =
(
    caRegCheck label condition
    if not condition do throw ("Required prerequisite failed: "+label)
    true
)
fn caRegFind rows id =
(
    local found = undefined
    for row in rows while found == undefined do if row[1] == id do found = row
    found
)
fn caRegSameIDs a b =
(
    local same = a.count == b.count
    for row in a while same do if (caRegFind b row[1]) == undefined do same = false
    same
)
fn caRegSamePolicy a b =
(
    if a == undefined or b == undefined then false
    else
    (
        a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4] and a[9] == b[9] and
        abs(a[10]-b[10]) < 0.00001 and a[11] == b[11] and a[12] == b[12] and (distance a[13] b[13]) < 0.00001
    )
)
fn caRegSameOutputs a b handles:true =
(
    local same = a.count == b.count
    for row in a while same do
    (
        local other = caRegFind b row[1]
        if other == undefined then same = false
        else
        (
            for i in #(1,2,3,7,8) where row[i] != other[i] do same = false
            if handles and row[9] != other[9] do same = false
            if distance row[4] other[4] > 0.001 or abs(row[5]-other[5]) > 0.00001 or abs(row[6]-other[6]) > 0.00001 do same = false
        )
    )
    same
)
global caRegClusterBoundary, caCategoryRules, caSetCategoryRules, caSetCollisionScope
fn caRegClusterBoundary =
(
    caRegNote "STAGE clustered anchors cannot borrow a forbidden coplanar surface"
    resetMaxFile #noPrompt
    units.SystemType = #millimeters; units.SystemScale = 1
    local left = box name:"CA_REGION_CLUSTER_ALLOWED" width:30 length:30 height:20 pos:[0,0,0]
    local right = box name:"CA_REGION_CLUSTER_FORBIDDEN" width:80 length:80 height:20 pos:[60,0,0]
    local source = box name:"CA_REGION_CLUSTER_SOURCE" width:20 length:20 height:10 pos:[0,1000,0]
    local setup = caCreateSetup #(left,right) 1
    local settings = (caSetupSummary setup)[9]
    settings[1]=1; settings[2]=1; settings[3]=0; settings[4]=0; settings[5]=1
    settings[6]=0; settings[7]=0; settings[8]=2; settings[10]=5; settings[11]=false
    caSetArrangeSettings setup settings
    caSetCollisionScope setup #() false
    caRegisterAsset setup source "Original 20mm region boundary probe" 7 31 #(0.0) 1 1 1 false
    local rules=caCategoryRules setup 1
    for row in rules do (row[2]=1;row[3]=if row[1]==7 then 8 else 0;row[4]=false)
    caSetCategoryRules setup 1 rules
    caAnalyzeSetup setup
    local regions=caRegionRows setup, allowed=undefined, forbidden=undefined
    for row in regions do
    (
        if row[6].x<20 then allowed=row else forbidden=row
    )
    caRegRequire "cluster fixture has two separated coplanar supports" (regions.count==2 and allowed!=undefined and forbidden!=undefined and abs(allowed[5].z-20)<0.01 and abs(forbidden[5].z-20)<0.01)
    caSetRegionRules setup allowed[1] "Allowed small board" "" 3 64 1 false false [0,-1,0]
    for mode=1 to 2 do
    (
        local label=if mode==1 then "excluded neighbor" else "zero-density neighbor"
        caSetRegionRules setup forbidden[1] label "" 3 2047 (if mode==1 then 1 else 0) false (mode==1) [0,-1,0]
        local identitiesOK=true, boundsOK=true, targetsOK=true, protectedOK=true
        for seed=1 to 32 do
        (
            local previousIDs=#()
            for output in (caOutputRows setup) do append previousIDs output[1]
            if previousIDs.count>0 do caSetLocked setup previousIDs false
            settings[1]=seed
            caSetArrangeSettings setup settings
            local stats=caGenerate setup #()
            local outputs=caOutputRows setup, ids=#()
            if stats[1]!=3 or stats[2]!=1 or stats[5]!=2 or outputs.count!=1 do targetsOK=false
            for output in outputs do
            (
                append ids output[1]
                if output[3]!=allowed[1] or output[8]!=0L do identitiesOK=false
                local bounds=nodeGetBoundingBox output[9] (matrix3 1)
                if bounds[1].x < -15.01 or bounds[2].x > 15.01 or bounds[1].y < -15.01 or bounds[2].y > 15.01 or abs(bounds[1].z-20)>0.01 or abs(bounds[2].z-30)>0.01 or distance (bounds[2]-bounds[1]) [20,20,10]>0.01 do boundsOK=false
            )
            -- A generated legal base must also pass the stricter retained-output path.
            caSetLocked setup ids true
            try
            (
                local retained=caGenerate setup #()
                if retained[2]!=1 or retained[3]!=1 do protectedOK=false
                local locked=caOutputRows setup
                if locked.count!=outputs.count then protectedOK=false
                else for output in locked do
                (
                    local original=caRegFind outputs output[1]
                    if original==undefined then protectedOK=false
                    else
                    (
                        for index in #(1,2,3,8) where original[index]!=output[index] do protectedOK=false
                        if distance original[4] output[4]>0.001 or abs(original[5]-output[5])>0.00001 or abs(original[6]-output[6])>0.00001 or not output[7] do protectedOK=false
                    )
                )
            )
            catch (protectedOK=false;caRegNote ("Cluster retained failure "+label+" seed="+(seed as string)+": "+(getCurrentException() as string)))
        )
        caRegCheck (label+": all32seeds keep allowed region identities") identitiesOK
        caRegCheck (label+": actual meshes remain fully on the30mm board") boundsOK
        caRegCheck (label+": requested3 accepts1 and reports2 underfilled") targetsOK
        caRegCheck (label+": every accepted result locks and regenerates unchanged") protectedOK
    )
    true
)

fn caRegRun =
(
    if CA_TEST_ROOT == undefined or CA_TEST_OUTPUT == undefined do throw "Runner must provide private project/output paths."
    if (maxVersion())[1] != 29000 do throw "Surface tests require Max 2027 only."
    CA_AUTO_SHOW_UI = false
    caRegNote "STAGE disposable scene and lazy surface-panel integration"
    resetMaxFile #noPrompt
    units.SystemType = #millimeters
    units.SystemScale = 1
    fileIn (CA_TEST_ROOT+"tests/max/fixtures.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeWorkflow.ms")
    local lower = caFxBox "Region_Lower" [1200,600,30] [-900,0,700]
    local upper = caFxBox "Region_Upper" [1200,600,30] [900,0,1100]
    local furniture = group #(lower,upper) name:"CA_FIXTURE_Region_Furniture"
    local setup = undefined
    undo "Region fixture setup" on (setup = caCreateSetup #(furniture) 1)
    local setupName = setup.name
    local upperName = upper.name
    caShowAdvancedArrangeUI setup:setup
    setDialogPos caArrangeUI [-10000,-10000]
    caArrangeUI.regionText.text = "4294967295"
    local parsedMaximum = caArrangeUI.requestedRegions()
    caRegCheck "selective ID parser preserves unsigned 32-bit Integer64 IDs" (parsedMaximum.count == 1 and parsedMaximum[1] == 4294967295L)
    caArrangeUI.regionText.text = "4294967296"
    local overflowRejected = false
    try (caArrangeUI.requestedRegions()) catch (overflowRejected = true)
    caRegCheck "selective ID parser rejects IDs above native range" overflowRejected
    caArrangeUI.regionText.text = "4294967295L,4294967295l"
    local parsedPrintedMaximum = caArrangeUI.requestedRegions()
    caRegCheck "printed Integer64 suffix preserves exact maximum ID and deduplicates" (parsedPrintedMaximum.count == 1 and parsedPrintedMaximum[1] == 4294967295L)
    for badToken in #("1.5","+1","-1","1e2","1L2","1LL","L","0","4294967296") do
    (
        caArrangeUI.regionText.text = badToken
        local invalidRejected = false
        try (caArrangeUI.requestedRegions()) catch (invalidRejected = true)
        caRegCheck ("strict region ID parser rejects "+badToken) invalidRejected
    )
    caArrangeUI.regionText.text = ""
    caRegRequire "Surface rules real workflow button lazy-loads panel" (caArrangeUI.regionsButton.pressed())
    setDialogPos caRegionUI [-10000,-10000]
    caRegCheck "opening panel performs no implicit analysis" ((caRegionUI.rows()).count == 0)
    caRegNote "BEGIN explicit Analyze real panel button"
    caRegRequire "Analyze finds two separated support surfaces" (caRegionUI.analyzeButton.pressed() and (caRegionUI.rows()).count == 2)
    local firstRows = caRegionRows setup
    caRegCheck "region metadata contract has exactly thirteen fields" (firstRows[1].count == 13 and firstRows[2].count == 13)
    local lowerRow = undefined
    local upperRow = undefined
    for row in firstRows do
    (
        if abs(row[5].z-730) < 0.01 do lowerRow = row
        if abs(row[5].z-1130) < 0.01 do upperRow = row
    )
    caRegRequire "world support heights identify both regions independently of row order" (lowerRow != undefined and upperRow != undefined)
    caRegCheck "region bounds and clearance are physical world millimetres" (lowerRow[7] == -1 and lowerRow[8] and upperRow[7] == -1 and upperRow[8])
    local lowerID = lowerRow[1]
    local upperID = upperRow[1]
    caRegNote "BEGIN repeated Analyze and topology-only changes"
    caRegRequire "repeat Analyze succeeds" (caRegionUI.analyzeButton.pressed())
    caRegCheck "same furniture preserves exact persistent region IDs" (caRegSameIDs firstRows (caRegionRows setup))
    lower.widthsegs = 3
    lower.lengthsegs = 4
    upper.widthsegs = 4
    upper.lengthsegs = 3
    caRegRequire "retessellated unchanged furniture reanalyzes" (caRegionUI.analyzeButton.pressed())
    caRegCheck "coplanar retessellation preserves exact surface IDs" (caRegSameIDs firstRows (caRegionRows setup))

    caRegNote "STAGE authored region labels masks roles density stacking and front"
    caRegRequire "select persistent lower region" (caRegionUI.selectID lowerID)
    local beforePolicy = caRegFind (caRegionRows setup) lowerID
    caRegionUI.regionLabel.text = "Display surface \"A\""
    caRegionUI.compartmentLabel.text = "Left display bay"
    caRegionUI.role.selection = 3
    for control in (caRegionUI.categoryControls()) do control.checked = false
    caRegionUI.allowBook.checked = true
    caRegionUI.density.value = 1.25
    caRegionUI.stacking.checked = false
    caRegionUI.excluded.checked = false
    caRegionUI.frontAngle.value = 90
    caRegNote "BEGIN Apply authored surface policy"
    caRegRequire "Apply real panel button saves a native region policy" (caRegionUI.applyButton.pressed())
    local editedPolicy = caRegFind (caRegionRows setup) lowerID
    caRegCheck "labels compartment and role are explicit native metadata" (editedPolicy[2] == "Display surface \"A\"" and editedPolicy[3] == "Left display bay" and editedPolicy[4] == 3)
    caRegCheck "allowed mask density and stack rule are stored" (editedPolicy[9] == 1 and editedPolicy[10] == 1.25 and not editedPolicy[11] and not editedPolicy[12])
    caRegCheck "world XY front angle becomes horizontal normalized direction" (abs(editedPolicy[13].x) < 0.00001 and abs(editedPolicy[13].y-1) < 0.00001 and editedPolicy[13].z == 0)
    caRegNote "BEGIN region-policy Undo"
    max undo
    caRegCheck "Undo restores complete prior surface policy" (caRegSamePolicy beforePolicy (caRegFind (caRegionRows setup) lowerID))
    caRegNote "BEGIN region-policy Redo"
    max redo
    caRegCheck "Redo restores complete authored surface policy" (caRegSamePolicy editedPolicy (caRegFind (caRegionRows setup) lowerID))
    caRegionUI.onRefresh()
    caRegionUI.selectID lowerID
    caRegRequire "use stable ID through real selective-Generate button" (caRegionUI.sendIDButton.pressed())
    caRegCheck "selective ID text has no Integer64 suffix" (caArrangeUI.regionText.text == (caRegionUI.decimalID lowerID) and (findString caArrangeUI.regionText.text "L") == undefined)
    caArrangeUI.regionText.text = ""

    caRegNote "STAGE native policy consumption and analysis publication retention"
    local book = caFxBox "Region_Book_Source" [80,60,20] [0,3000,0]
    local plant = caFxBox "Region_Plant_Proxy_Source" [90,90,150] [300,3000,0]
    local bookID = caRegisterAsset setup book "Region flat book" 1 31 #(0) 1 1 1 true
    local plantID = caRegisterAsset setup plant "Region plant test proxy" 3 31 #(0,90,180,270) 1 1 1 false
    caRegionUI.selectID upperID
    for control in (caRegionUI.categoryControls()) do control.checked = false
    caRegionUI.allowPlant.checked = true
    caRegionUI.density.value = 1
    caRegionUI.stacking.checked = false
    caRegionUI.frontAngle.value = 90
    caRegRequire "second region receives independent category policy" (caRegionUI.applyButton.pressed())
    caArrangeUI.seedText.text = "63"
    caArrangeUI.density.value = 0.6
    caArrangeUI.emptySpace.value = 0.25
    caArrangeUI.cluster.value = 1
    caArrangeUI.style.selection = 3
    caRegNote "BEGIN Generate with region-specific category masks"
    caRegRequire "Generate accepts region-specific rules" (caArrangeUI.generateButton.pressed())
    local mixed = caOutputRows setup
    caRegRequire "region fixture generates nonempty actual outputs" (mixed.count > 0)
    local lowerWitness = 0
    local upperWitness = 0
    local physicalOnly = true, descriptiveCrossings = 0
    for row in mixed do
    (
        if row[3] == lowerID do (lowerWitness += 1;if row[2] == plantID do descriptiveCrossings += 1)
        if row[3] == upperID do (upperWitness += 1;if row[2] == bookID do descriptiveCrossings += 1)
        if row[8] != 0 or (row[2] != bookID and row[2] != plantID) do physicalOnly = false
        local support = caRegFind (caRegionRows setup) row[3]
        local bounds = nodeGetBoundingBox row[9] (matrix3 1)
        if support == undefined then physicalOnly = false
        else if bounds[1].x < support[5].x-0.03 or bounds[2].x > support[6].x+0.03 or bounds[1].y < support[5].y-0.03 or bounds[2].y > support[6].y+0.03 or abs(bounds[1].z-support[5].z)>0.03 do physicalOnly = false
    )
    caRegCheck "descriptive category masks do not restrict physically supported selected props" (physicalOnly and descriptiveCrossings > 0 and lowerWitness > 0 and upperWitness > 0)
    caRegNote "BEGIN Analyze after committed Generate"
    caRegRequire "Analyze retains committed outputs while publishing metadata" (caRegionUI.analyzeButton.pressed() and (caRegSameOutputs mixed (caOutputRows setup)))
    caRegCheck "analysis leaves manual pending state" ((caSetupSummary setup)[6] != 0)
    caRegCheck "repeat analysis preserves authored policy" (caRegSamePolicy editedPolicy (caRegFind (caRegionRows setup) lowerID))
    caRegionUI.selectID lowerID
    caRegionUI.stacking.checked = true
    caRegRequire "enable stacking on one support region" (caRegionUI.applyButton.pressed())
    caRegRequire "Generate consumes region stacking permission" (caArrangeUI.generateButton.pressed())
    local stackWitness = 0
    for row in (caOutputRows setup) where row[3] == lowerID and row[8] != 0 do stackWitness += 1
    caRegCheck "enabled region creates supported stack children" (stackWitness > 0)
    caRegionUI.stacking.checked = false
    caRegRequire "disable stacking again through panel" (caRegionUI.applyButton.pressed())
    caRegRequire "regenerate after disabling region stacking" (caArrangeUI.generateButton.pressed())
    local unwantedStacks = 0
    for row in (caOutputRows setup) where row[8] != 0 do unwantedStacks += 1
    caRegCheck "disabled stacking removes generated stack children" (unwantedStacks == 0)
    for control in (caRegionUI.categoryControls()) do control.checked = false
    local beforeMaskOnly = caOutputRows setup
    caRegRequire "empty regional category mask remains valid descriptive metadata" (caRegionUI.applyButton.pressed())
    caRegRequire "Generate accepts an empty descriptive mask" (caArrangeUI.generateButton.pressed())
    caRegCheck "changing only a descriptive mask preserves complete seeded placements" (caRegSameOutputs beforeMaskOnly (caOutputRows setup) handles:false)
    caRegionUI.allowBook.checked = true
    caRegRequire "restore regional book eligibility" (caRegionUI.applyButton.pressed())
    caRegionUI.selectID upperID
    caRegionUI.density.value = 0
    caRegRequire "density zero policy applies" (caRegionUI.applyButton.pressed())
    caRegRequire "Generate consumes region density zero" (caArrangeUI.generateButton.pressed())
    local zeroDensity = caOutputRows setup
    local zeroWitness = 0
    for row in zeroDensity where row[3] == upperID do zeroWitness += 1
    caRegCheck "zero multiplier suppresses only the selected region" (zeroWitness == 0 and zeroDensity.count > 0)
    caRegionUI.density.value = 1
    caRegionUI.excluded.checked = true
    caRegRequire "surface exclusion applies through panel" (caRegionUI.applyButton.pressed())
    caRegRequire "Generate consumes native region exclusion" (caArrangeUI.generateButton.pressed())
    local excludedWitness = 0
    for row in (caOutputRows setup) where row[3] == upperID do excludedWitness += 1
    caRegCheck "excluded region stays in editable list but receives no outputs" (excludedWitness == 0 and (caRegFind (caRegionRows setup) upperID)[12])
    caRegionUI.excluded.checked = false
    caRegRequire "restore excluded region" (caRegionUI.applyButton.pressed())
    caRegRequire "restore complete arrangement" (caArrangeUI.generateButton.pressed())

    caRegNote "STAGE locked-region conflicts retain complete native publication"
    local current = caOutputRows setup
    local lockedID = current[1][1]
    local lockedRegion = current[1][3]
    caSetLocked setup #(lockedID) true
    local locked = caOutputRows setup
    caRegionUI.selectID lockedRegion
    caRegionUI.excluded.checked = true
    caRegRequire "artist can author exclusion before explicit Generate" (caRegionUI.applyButton.pressed())
    caRegNote "BEGIN conflicting locked region Generate"
    caRegCheck "conflicting locked exclusion rejects Generate explicitly" (caArrangeUI.generateButton.pressed() == false)
    caRegCheck "failed locked-region successor retains all nodes and transforms" (caRegSameOutputs locked (caOutputRows setup))
    caRegionUI.excluded.checked = false
    caRegRequire "restore locked region policy" (caRegionUI.applyButton.pressed())
    caSetLocked setup #(lockedID) false
    caRegRequire "resolved lock conflict regenerates" (caArrangeUI.generateButton.pressed())

    caRegNote "STAGE scene save-load retains persistent surface rules"
    local savedRows = caRegionRows setup
    local scenePath = CA_TEST_OUTPUT+"arrange-region-policies.max"
    caRegRequire "save native surface-policy scene" (saveMaxFile scenePath quiet:true)
    destroyDialog caRegionUI
    destroyDialog caArrangeUI
    caRegNote "BEGIN native scene reopen"
    caRegRequire "reopen native surface-policy scene" (loadMaxFile scenePath quiet:true useFileUnits:true)
    local restored = getNodeByName setupName exact:true
    local restoredRows = caRegionRows restored
    caRegCheck "scene roundtrip retains exact active region identities" (caRegSameIDs savedRows restoredRows)
    local policiesRoundtrip = true
    for row in savedRows where not (caRegSamePolicy row (caRegFind restoredRows row[1])) do policiesRoundtrip = false
    caRegCheck "scene roundtrip retains every authored surface policy field" policiesRoundtrip
    caShowAdvancedArrangeUI setup:restored
    setDialogPos caArrangeUI [-10000,-10000]
    caRegRequire "reopen surface panel through workflow" (caArrangeUI.regionsButton.pressed())
    setDialogPos caRegionUI [-10000,-10000]
    caRegRequire "reanalysis after load succeeds" (caRegionUI.analyzeButton.pressed())
    caRegCheck "reanalysis after load preserves exact persistent IDs" (caRegSameIDs savedRows (caRegionRows restored))

    caRegNote "STAGE missing surface fails explicitly without stale ID transfer"
    local beforeDeletionOutputs = caOutputRows restored
    local restoredUpper = getNodeByName upperName exact:true
    delete restoredUpper
    caRegNote "BEGIN Analyze after deleting one support board"
    caRegRequire "Analyze reconciles removal without replacing existing outputs" (caRegionUI.analyzeButton.pressed() and (caRegionUI.rows()).count == 1 and (caRegSameOutputs beforeDeletionOutputs (caOutputRows restored)))
    caRegCheck "surviving surface retains its persistent ID" ((caRegionUI.rows())[1][1] == lowerID)
    caRegCheck "missing surface cannot be selected as another surface" ((caRegionUI.selectID upperID) == false)
    local staleRejected = false
    try (caSetRegionRules restored upperID "stale" "" 1 2047 1 true false [1,0,0]) catch (staleRejected = true)
    caRegCheck "native policy setter rejects missing persistent ID" staleRejected
    caArrangeUI.regionText.text = caRegionUI.decimalID upperID
    caRegNote "BEGIN stale selective region Generate"
    caRegCheck "missing selective region fails Generate explicitly" (caArrangeUI.generateButton.pressed() == false)
    caRegCheck "missing-region failure retains complete prior output" (caRegSameOutputs beforeDeletionOutputs (caOutputRows restored))
    destroyDialog caRegionUI
    destroyDialog caArrangeUI
    caRegClusterBoundary()
    true
)
try (caRegRun()) catch
(
    caRegFailures += 1
    caRegNote ("EXCEPTION "+(getCurrentException() as string))
    caRegNote ("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
    caRegNote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
caRegFinished = true
caRegWrite()
