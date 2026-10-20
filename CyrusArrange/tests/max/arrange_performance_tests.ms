/* Serial Max 2027 command benchmark and output equivalence.
   Build a fresh matched pair and use tools/run_max_tests.py. NEVER fileIn this resetting test in an artist scene.
   Every Generate/Preview/Commit trial is FULL RECAPTURE / QUERY REBUILD.
   There is no retained geometry/query cache or warm-cache speedup claim.
   Root owns all launches. File/log/oracle work is outside each Stopwatch interval.
*/
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caCreateBookRowFixtures, caBRWorldGeometryBounds
global caShowAdvancedArrangeUI, caArrangeUI, caShowAssetUI, caAssetUI
global caPLog = #(), caPPasses = 0, caPFailures = 0, caPFinished = false
global caPStage = "initialization", caPSerial = 0, caPCase = "", caPPublished = 0
global caPProcess, caPWatch, caPFixedTrials = 10, caPAlternateTrials = 10
global caPWrite, caPNote, caPStep, caPCheck, caPRequire, caPNumber, caPCSV
global caPMemory, caPFind, caPCapture, caPSame, caPSameGroups, caPSameStats
global caPGeometry, caPBounds, caPVerify, caPVerifyGroups, caPRecordSnapshot
global caPRecordRegions, caPMeasure, caPSetSeed, caPPreviewCheck, caPBrowse
global caPCaseRun, caPRun

fn caPWrite =
(
    local report = createFile (CA_TEST_OUTPUT+"result.txt")
    local state = if caPFinished then (if caPFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
    format "% passes=% failures=%\n" state caPPasses caPFailures to:report
    for line in caPLog do format "%\n" line to:report
    flush report
    close report
)
fn caPNote line = (append caPLog line; caPWrite(); true)
fn caPStep line = (caPStage = line; caPNote ("STAGE "+line))
fn caPCheck label condition =
(
    if condition then (caPPasses += 1; caPNote ("PASS "+label))
    else (caPFailures += 1; caPNote ("FAIL "+label))
    condition
)
fn caPRequire label condition = (caPCheck label condition; if not condition do throw ("Prerequisite failed: "+label); true)
fn caPNumber value =
(
    -- Convert.ToString can select its SByte overload for a native MAXScript
    -- Integer/IntegerPtr. Keep integral text exact before using .NET for reals.
    if classOf value == Integer then (value as string)
    else if classOf value == Integer64 then (trimRight (value as string) "Ll")
    else if classOf value == IntegerPtr then (trimRight ((value as Integer64) as string) "Ll")
    else if classOf value == String then value
    else (dotNetClass "System.Convert").ToString value (dotNetClass "System.Globalization.CultureInfo").InvariantCulture
)
fn caPCSV fileName values =
(
    local out = openFile (CA_TEST_OUTPUT+fileName) mode:"a"
    if out == undefined do throw ("Cannot append benchmark output "+fileName)
    for i = 1 to values.count do
    (
        if i > 1 do format "," to:out
        local literal = substituteString (caPNumber values[i]) "\"" "\"\""
        format "\"%\"" literal to:out
    )
    format "\n" to:out
    flush out
    close out
)
fn caPMemory =
(
    caPProcess.Refresh()
    #(caPProcess.WorkingSet64, caPProcess.PrivateMemorySize64, caPProcess.PeakWorkingSet64)
)
fn caPFind rows id =
(
    local found = undefined
    for row in rows while found == undefined do if row[1] == id do found = row
    found
)
fn caPGeometry root =
(
    local pending = #(root), nodes = #()
    while pending.count > 0 do
    (
        local node = pending[pending.count]
        deleteItem pending pending.count
        for child in node.children do append pending child
        if not (isGroupHead node) and (superClassOf node) == GeometryClass do append nodes node
        if nodes.count+pending.count > 4096 do throw "Performance fixture exceeds bounded hierarchy."
    )
    nodes
)
fn caPBounds nodes = for node in nodes collect (nodeGetBoundingBox node (matrix3 1))

-- Snapshot stores all native pose fields plus independently measured actual node
-- bounds, transform rows and handle. No mesh vertex arrays leave the host.
fn caPCapture setup =
(
    local poses = #()
    for row in (caOutputRows setup) do
    (
        if row.count != 9 or not isValidNode row[9] do throw "Invalid native output row/node."
        local bounds = nodeGetBoundingBox row[9] (matrix3 1)
        local tm = row[9].transform
        local outputHandle = getHandleByAnim row[9]
        if caPSerial == 1 and poses.count == 0 do caPNote ("HANDLE type="+((classOf outputHandle) as string)+" raw="+(outputHandle as string)+" formatted="+(caPNumber outputHandle))
        if (outputHandle as Integer64) <= 0 or ((caPNumber outputHandle) as Integer64) != (outputHandle as Integer64) or (getAnimByHandle outputHandle) != row[9] do throw "Actual output handle does not roundtrip through exact CSV formatting."
        append poses #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8],bounds[1],bounds[2],tm.row1,tm.row2,tm.row3,tm.row4,outputHandle)
    )
    #(poses,caCompositionRows setup)
)
fn caPSame first second handles:false =
(
    local same = first.count == second.count
    for row in first while same do
    (
        local other = caPFind second row[1]
        if other == undefined then same = false
        else
        (
            for field in #(1,2,3,7,8) where row[field] != other[field] do same = false
            for field in #(4,9,10,14) where distance row[field] other[field] > 0.002 do same = false
            for field in #(11,12,13) where distance row[field] other[field] > 0.00001 do same = false
            if abs(row[5]-other[5]) > 0.00001 or abs(row[6]-other[6]) > 0.00001 do same = false
            if handles and row[15] != other[15] do same = false
        )
    )
    same
)
fn caPSameGroups first second =
(
    local same = first.count == second.count
    for row in first while same do
    (
        local other = caPFind second row[1]
        if other == undefined then same = false
        else
        (
            if row[2] != other[2] or row[3] != other[3] or row[4].count != other[4].count do same = false
            if distance row[5] other[5] > 0.00001 or abs(row[6]-other[6]) > 0.00001 do same = false
            for i = 1 to row[4].count while same do if row[4][i] != other[4][i] do same = false
        )
    )
    same
)
fn caPSameStats first second =
(
    local same = first.count == 6 and second.count == 6
    if same do
    (
        for i = 1 to 5 where first[i] != second[i] do same = false
        if (first[6] as string) != (second[6] as string) do same = false
    )
    same
)
fn caPVerifyGroups snapshot =
(
    local valid = true, used = #()
    for groupRow in snapshot[2] do
    (
        if groupRow.count != 6 or groupRow[2] != 1 or groupRow[4].count < 2 or groupRow[4].count > 4 do valid = false
        local previous = undefined
        for id in groupRow[4] do
        (
            local member = caPFind snapshot[1] id
            if member == undefined then valid = false
            else
            (
                if (findItem used id) != 0 or member[3] != groupRow[3] or member[8] != 0L do valid = false
                append used id
                if previous != undefined do
                    if abs((member[9].x-previous[10].x)-groupRow[6]) > 0.03 or abs(member[9].y-previous[9].y) > 0.03 or abs(member[9].z-previous[9].z) > 0.03 do valid = false
                previous = member
            )
        )
    )
    valid
)
fn caPVerify snapshot assetSizes sourceBounds =
(
    local valid = true
    for row in snapshot[1] do
    (
        local asset = caPFind assetSizes row[2]
        if asset == undefined then valid = false
        else
        (
            local size = row[10]-row[9]
            if distance size (asset[2]*row[6]) > 0.03 or abs(row[5]) > 0.00001 or abs(row[6]-1.0) > 0.00001 do valid = false
            if distance row[14] row[4] > 0.003 do valid = false
            if distance row[9] (row[4]-[size.x/2,size.y/2,0]) > 0.03 do valid = false
            if row[7] or row[8] != 0L do valid = false
        )
        local supported = false
        for bounds in sourceBounds do
        (
            -- Fixture furniture consists of independently measured axis-aligned
            -- closed boxes. Require full footprint on a physical board top.
            if abs(row[9].z-bounds[2].z) < 0.03 and row[9].x >= bounds[1].x-0.03 and row[10].x <= bounds[2].x+0.03 and row[9].y >= bounds[1].y-0.03 and row[10].y <= bounds[2].y+0.03 do supported = true
            local overlap = [amin #(row[10].x,bounds[2].x)-amax #(row[9].x,bounds[1].x),amin #(row[10].y,bounds[2].y)-amax #(row[9].y,bounds[1].y),amin #(row[10].z,bounds[2].z)-amax #(row[9].z,bounds[1].z)]
            if overlap.x > 0.03 and overlap.y > 0.03 and overlap.z > 0.03 do valid = false
        )
        if not supported do valid = false
    )
    for i = 1 to snapshot[1].count do for j = i+1 to snapshot[1].count do
    (
        local a = snapshot[1][i], b = snapshot[1][j]
        local dx = amin #(a[10].x,b[10].x)-amax #(a[9].x,b[9].x)
        local dy = amin #(a[10].y,b[10].y)-amax #(a[9].y,b[9].y)
        local dz = amin #(a[10].z,b[10].z)-amax #(a[9].z,b[9].z)
        if dx > 0.03 and dy > 0.03 and dz > 0.03 do valid = false
    )
    valid and (caPVerifyGroups snapshot)
)
fn caPRecordSnapshot operation phase iteration seed snapshot =
(
    for row in snapshot[1] do
    (
        local values = #(caPSerial,caPCase,operation,phase,iteration,seed)
        for i in #(1,2,3) do append values row[i]
        for component = 1 to 3 do append values row[4][component]
        for i in #(5,6,7,8) do append values row[i]
        append values row[15]
        for i in #(9,10,11,12,13,14) do for component = 1 to 3 do append values row[i][component]
        caPCSV "poses.csv" values
    )
    for row in snapshot[2] do
        caPCSV "groups.csv" #(caPSerial,caPCase,operation,phase,iteration,seed,row[1],row[2],row[3],row[4] as string,row[5].x,row[5].y,row[5].z,row[6])
)
fn caPRecordRegions setup =
(
    for row in (caRegionRows setup) do
        caPCSV "regions.csv" #(caPSerial,caPCase,row[1],row[4],row[5].x,row[5].y,row[5].z,row[6].x,row[6].y,row[6].z,row[7],row[8],row[12])
)
fn caPMeasure setup operation phase iteration seed =
(
    caPSerial += 1
    caPStep (caPCase+" | "+operation+" | "+phase+" | trial "+(iteration as string)+" | seed "+(seed as string)+" | full recapture rebuild")
    local before = caPMemory(), result = undefined
    local revisionBefore = (caSetupSummary setup)[3]
    local publishedBefore = caPPublished
    caPWatch.Reset()
    caPWatch.Start()
    case operation of
    (
        "Generate": (result = caGenerate setup #())
        "Preview": (result = caPreview setup #())
        "CommitPreview": (result = caCommitPreview setup)
        default: (caPWatch.Stop(); throw "Unknown timed operation.")
    )
    caPWatch.Stop()
    local elapsed = caPWatch.Elapsed.TotalMilliseconds
    local elapsedTicks = caPWatch.ElapsedTicks
    local after = caPMemory()
    if operation != "Preview" do caPPublished += 1
    local snapshot = caPCapture setup
    local previewCount = if operation == "Preview" then (caPreviewInfo setup)[3] else 0
    caPCSV "metrics.csv" #(caPSerial,caPCase,operation,phase,iteration,seed,"full_recapture_rebuild",elapsed,elapsedTicks,result[1],result[2],result[3],result[4],result[5],result[6].count,snapshot[1].count,snapshot[2].count,(caRegionRows setup).count,previewCount,before[1],after[1],before[2],after[2],before[3],after[3],publishedBefore,revisionBefore,(caSetupSummary setup)[3])
    caPRecordSnapshot operation phase iteration seed snapshot
    caPRecordRegions setup
    caPNote ("MEASURE serial="+(caPSerial as string)+" elapsed_ms="+(caPNumber elapsed)+" target="+(result[1] as string)+" accepted="+(result[2] as string)+" candidates="+(result[4] as string)+" underfilled="+(result[5] as string))
    #(result,snapshot)
)
fn caPSetSeed setup seed =
(
    local settings = (caSetupSummary setup)[9]
    if settings[1] != seed do (settings[1] = seed; caSetArrangeSettings setup settings)
)
fn caPPreviewCheck setup expected committed label =
(
    local boxes = caPreviewBounds setup
    local valid = boxes.count == expected[1].count
    for i = 1 to boxes.count while valid do
    (
        local pose = expected[1][i]
        if distance boxes[i][1] ((pose[9]+pose[10])*0.5) > 0.03 or distance boxes[i][2] ((pose[10]-pose[9])*0.5) > 0.03 or abs(boxes[i][3]-pose[5]) > 0.00001 do valid = false
    )
    for i = 1 to boxes.count do caPCSV "preview-bounds.csv" #(caPSerial,caPCase,i,boxes[i][1].x,boxes[i][1].y,boxes[i][1].z,boxes[i][2].x,boxes[i][2].y,boxes[i][2].z,boxes[i][3])
    local current = caPCapture setup
    caPCheck (label+": preview full bounds match independently measured Generate outputs") valid
    caPCheck (label+": preview retains every committed pose group and actual node handle") (caPSame committed[1] current[1] handles:true and caPSameGroups committed[2] current[2])
)
fn caPBrowse setup =
(
    caPStep (caPCase+" | passive UI browsing")
    local before = caPCapture setup, revision = (caSetupSummary setup)[3]
    caShowAdvancedArrangeUI setup:setup
    caShowAssetUI setup
    setDialogPos caArrangeUI [-10000,-10000]
    setDialogPos caAssetUI [-10000,-10000]
    for trial = 1 to 10 do
    (
        select setup
        local memoryBefore = caPMemory()
        caPWatch.Reset(); caPWatch.Start()
        local refreshed = caArrangeUI.onRefresh() and caAssetUI.onRefresh()
        caPWatch.Stop()
        local elapsed = caPWatch.Elapsed.TotalMilliseconds, ticks = caPWatch.ElapsedTicks
        local memoryAfter = caPMemory()
        caPCSV "browsing.csv" #(caPCase,trial,elapsed,ticks,memoryBefore[1],memoryAfter[1],memoryBefore[2],memoryAfter[2],memoryBefore[3],memoryAfter[3])
        caPRequire (caPCase+": actual passive UI handlers trial "+(trial as string)) refreshed
    )
    local after = caPCapture setup
    caPCheck (caPCase+": browsing selection and refresh preserve revision poses groups and node handles") ((caSetupSummary setup)[3] == revision and caPSame before[1] after[1] handles:true and caPSameGroups before[2] after[2])
    destroyDialog caAssetUI
    destroyDialog caArrangeUI
)
fn caPCaseRun caseLabel category rowMode densityValue =
(
    caPCase = caseLabel; caPPublished = 0
    caPStep (caseLabel+" | fresh owned scene and original source-backed models")
    resetMaxFile #noPrompt
    units.SystemType = #millimeters; units.SystemScale = 1
    sliderTime = 0
    local fixture = caCreateBookRowFixtures()
    local furniture = if category == 1 then fixture[3] else fixture[4]
    local sourceNodes = caPGeometry furniture
    local sourceBounds = caPBounds sourceNodes
    local geometryBounds = caBRWorldGeometryBounds furniture
    local setup = caCreateSetup #(furniture) category
    setup.name = "CA_PERFORMANCE_"+caseLabel
    local assetSizes = #()
    for book in fixture[1] do
    (
        local bounds = caBRWorldGeometryBounds book[1]
        local id = caRegisterAsset setup book[1] book[2] 1 3 #(0.0) 1.0 1.0 1.0 false
        append assetSizes #(id,bounds[2]-bounds[1])
        if rowMode do caSetAssetBookRow setup id 3
    )
    local settings = (caSetupSummary setup)[9]
    settings[1] = 7231L; settings[2] = densityValue; settings[3] = 20; settings[4] = 12
    settings[5] = 0.35; settings[6] = 0; settings[7] = 0.2; settings[8] = 2; settings[9] = category; settings[10] = 25; settings[11] = false
    caSetArrangeSettings setup settings
    local rules = caCategoryRules setup category
    for row in rules do row[3] = if row[1] == 1 then 500 else 0
    caSetCategoryRules setup category rules
    if rowMode do caSetCompositionSettings setup #(true,2,4,3.0,0.5)
    caPNote ("CONFIG case="+caseLabel+" settings="+(settings as string)+" furniture_geometry_bounds="+(geometryBounds as string)+" source_nodes="+(sourceNodes.count as string)+" asset_sizes="+(assetSizes as string))
    caPRequire (caseLabel+": manual native setup has three actual bound sources") ((caSetupSummary setup)[4] == 3 and not (caSetupSummary setup)[7] and (caOutputRows setup).count == 0)
    local initial = caPMeasure setup "Generate" "initial scene first command" 0 7231L
    caPRequire (caseLabel+": initial full rebuild has real admitted placements") (initial[1][2] > 0 and initial[1][2] == initial[2][1].count and initial[1][4] > 0)
    caPCheck (caseLabel+": observed target and underfill agree with actual accepted output count") (initial[1][1] >= initial[1][2] and initial[1][5] == initial[1][1]-initial[1][2])
    caPCheck (caseLabel+": independently measured full bounds have source support and no furniture/output penetration") (caPVerify initial[2] assetSizes sourceBounds)
    if rowMode do caPRequire (caseLabel+": actual row/balance workload forms native book groups") (initial[2][2].count > 0)
    local baselineA = initial
    for trial = 1 to caPFixedTrials do
    (
        local measured = caPMeasure setup "Generate" "fixed seed repeat" trial 7231L
        caPCheck (caseLabel+": fixed seed full pose IDs groups stats trial "+(trial as string)) (caPSame baselineA[2][1] measured[2][1] and caPSameGroups baselineA[2][2] measured[2][2] and caPSameStats baselineA[1] measured[1])
        caPCheck (caseLabel+": fixed seed independent physical bounds trial "+(trial as string)) (caPVerify measured[2] assetSizes sourceBounds)
    )
    local baselineB = undefined
    for trial = 1 to caPAlternateTrials do
    (
        local seed = if mod trial 2 == 1 then 9349L else 7231L
        caPSetSeed setup seed
        local measured = caPMeasure setup "Generate" "alternating seed reroll" trial seed
        if seed == 9349L and baselineB == undefined do baselineB = measured
        local expected = if seed == 7231L then baselineA else baselineB
        caPCheck (caseLabel+": alternating seed full pose IDs groups stats trial "+(trial as string)) (caPSame expected[2][1] measured[2][1] and caPSameGroups expected[2][2] measured[2][2] and caPSameStats expected[1] measured[1])
        caPCheck (caseLabel+": alternating seed independent physical bounds trial "+(trial as string)) (caPVerify measured[2] assetSizes sourceBounds)
    )
    caPRequire (caseLabel+": changing seed changes at least one actual pose or identity") (not (caPSame baselineA[2][1] baselineB[2][1]))
    caPBrowse setup
    caPSetSeed setup 7231L
    local committed = caPCapture setup, revision = (caSetupSummary setup)[3]
    for trial = 0 to caPFixedTrials do
    (
        local phase = if trial == 0 then "first preview after full generation" else "fixed seed repeat"
        local measured = caPMeasure setup "Preview" phase trial 7231L
        caPCheck (caseLabel+": fixed Preview solver stats match full Generate trial "+(trial as string)) (caPSameStats baselineA[1] measured[1])
        caPPreviewCheck setup baselineA[2] committed (caseLabel+": fixed Preview trial "+(trial as string))
        caPCheck (caseLabel+": Preview does not publish a revision trial "+(trial as string)) ((caSetupSummary setup)[3] == revision)
    )
    for trial = 1 to caPAlternateTrials do
    (
        local seed = if mod trial 2 == 1 then 9349L else 7231L
        caPSetSeed setup seed
        revision = (caSetupSummary setup)[3]
        local expected = if seed == 7231L then baselineA else baselineB
        local measured = caPMeasure setup "Preview" "alternating seed reroll" trial seed
        caPCheck (caseLabel+": alternating Preview solver stats trial "+(trial as string)) (caPSameStats expected[1] measured[1])
        caPPreviewCheck setup expected[2] committed (caseLabel+": alternating Preview trial "+(trial as string))
        caPCheck (caseLabel+": alternating Preview does not publish revision trial "+(trial as string)) ((caSetupSummary setup)[3] == revision)
    )
    local final = caPMeasure setup "CommitPreview" "fixed seed commit" 1 7231L
    caPCheck (caseLabel+": Commit reproduces complete observed seed A output IDs poses groups and stats") (caPSame baselineA[2][1] final[2][1] and caPSameGroups baselineA[2][2] final[2][2] and caPSameStats baselineA[1] final[1])
    caPCheck (caseLabel+": Commit independently measured physical result remains valid") (caPVerify final[2] assetSizes sourceBounds)
    caPCheck (caseLabel+": original furniture geometry bounds unchanged") (((caPBounds sourceNodes) as string) == (sourceBounds as string))
    caPCheck (caseLabel+": source furniture materials remain assigned") ((for node in sourceNodes where node.material == undefined collect node).count == 0)
    true
)
fn caPRun =
(
    if CA_TEST_ROOT == undefined or CA_TEST_OUTPUT == undefined do throw "Run only through the owned-profile Max test runner."
    if (maxVersion())[1] != 29000 do throw "Performance tests require Max 2027."
    caPRequire "matched current native version is 0.3.1" ((caVersion()) == "0.3.1")
    caPRequire "CSV integral formatter preserves Integer IntegerPtr and signed Integer64 identities" ((caPNumber 55224) == "55224" and (caPNumber 1024) == "1024" and (caPNumber 55224P) == "55224" and (caPNumber 4294967295P) == "4294967295" and (caPNumber 4294967295L) == "4294967295" and (caPNumber -8100984552319297358L) == "-8100984552319297358")
    if caPFixedTrials != 10 or caPAlternateTrials != 10 do throw "The controlled benchmark requires exactly ten trials per repeated schedule."
    CA_AUTO_SHOW_UI = false
    fileIn (CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeAssets.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeWorkflow.ms")
    caPProcess = (dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    caPWatch = dotNetObject "System.Diagnostics.Stopwatch"
    for fileName in #("metrics.csv","poses.csv","groups.csv","regions.csv","preview-bounds.csv","browsing.csv","performance-environment.txt") do
        if doesFileExist (CA_TEST_OUTPUT+fileName) do throw "Use a fresh owned output directory; preserve previous benchmark evidence."
    caPCSV "metrics.csv" #("serial","case","operation","phase","iteration","seed","computation","elapsed_ms","elapsed_ticks","requested","accepted","kept","candidates","underfilled","warnings","committed_outputs","committed_groups","regions","preview_boxes","working_before_bytes","working_after_bytes","private_before_bytes","private_after_bytes","process_lifetime_peak_working_before_bytes","process_lifetime_peak_working_after_bytes","prior_publications_in_case","revision_before","revision_after")
    caPCSV "poses.csv" #("serial","case","operation","phase","iteration","seed","placement_id","asset_id","region_id","anchor_x_mm","anchor_y_mm","anchor_z_mm","yaw_degrees","scale","locked","parent_stack_id","node_handle","bounds_min_x","bounds_min_y","bounds_min_z","bounds_max_x","bounds_max_y","bounds_max_z","tm_row1_x","tm_row1_y","tm_row1_z","tm_row2_x","tm_row2_y","tm_row2_z","tm_row3_x","tm_row3_y","tm_row3_z","tm_row4_x","tm_row4_y","tm_row4_z")
    caPCSV "groups.csv" #("serial","case","operation","phase","iteration","seed","group_id","kind","region_id","ordered_member_ids","front_x","front_y","front_z","gap_mm")
    caPCSV "regions.csv" #("serial","case","region_id","role","bounds_min_x","bounds_min_y","bounds_min_z","bounds_max_x","bounds_max_y","bounds_max_z","minimum_clearance_mm","open_above","excluded")
    caPCSV "preview-bounds.csv" #("serial","case","index","center_x_mm","center_y_mm","center_z_mm","half_x_mm","half_y_mm","half_z_mm","yaw_degrees")
    caPCSV "browsing.csv" #("case","iteration","elapsed_ms","elapsed_ticks","working_before_bytes","working_after_bytes","private_before_bytes","private_after_bytes","process_lifetime_peak_working_before_bytes","process_lifetime_peak_working_after_bytes")
    local metadata = createFile (CA_TEST_OUTPUT+"performance-environment.txt")
    format "Whole command measurements; full recapture/query rebuild; no warm cache or speedup claim.\n" to:metadata
    local timerClass = dotNetClass "System.Diagnostics.Stopwatch"
    local environmentClass = dotNetClass "System.Environment"
    format "MaxVersion=%\nNativeVersion=%\nNativeModulePaths=%\nPrivateINI=%\nOwnedPID=%\nCPUCount=%\nStopwatchFrequency=%\nStopwatchHighResolution=%\nRuntime=%\n" (maxVersion()) (caVersion()) (caModulePaths()) (getMAXIniFile()) (caPNumber caPProcess.Id) environmentClass.ProcessorCount (caPNumber timerClass.Frequency) timerClass.IsHighResolution (environmentClass.Version.ToString()) to:metadata
    for processName in #("3dsmax","3dsmaxbatch") do
        for foundProcess in ((dotNetClass "System.Diagnostics.Process").GetProcessesByName processName) do
        (
            format "ObservedMaxProcess=% PID=%\n" processName foundProcess.Id to:metadata
            foundProcess.Dispose()
        )
    flush metadata; close metadata
    caPNote "POLICY: no forced GC, no Undo flush between timed operations; native publication/setting history accumulates and is reported by publication index; reset only between owned cases."
    caPNote "POLICY: root must run this process alone after all other QA processes finish; process-list evidence does not prove external CPU/GPU idleness."
    caPCaseRun "small TV ordinary books" 1 false 0.15
    caPCaseRun "medium open shelf book rows" 2 true 0.20
    caPRequire "exactly 86 serial complete solver commands were measured" (caPSerial == 86)
    true
)
try (caPRun()) catch
(
    caPFailures += 1
    caPNote ("EXCEPTION stage="+caPStage+" | "+(getCurrentException() as string))
    caPNote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
for dialog in #(caAssetUI,caArrangeUI) where dialog != undefined do try (destroyDialog dialog) catch ()
if caPProcess != undefined do try (caPProcess.Dispose()) catch ()
caPFinished = true
caPWrite()
