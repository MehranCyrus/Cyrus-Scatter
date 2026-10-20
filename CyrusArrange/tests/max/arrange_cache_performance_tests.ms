/* Root-run cache performance harness. It resets and populates its disposable scene.
   Helpers originated from source SHA256 d6bb76648c09767db7c42c0fca4b6fd1742a3abab954e4d35c43961abbc931a7.
   Current full-pose/group/stat/physical checks are qualified by matching run receipts. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caCreateBookRowFixtures, caBRWorldGeometryBounds
global caShowAdvancedArrangeUI, caArrangeUI, caShowAssetUI, caAssetUI
global caPLog = #(), caPPasses = 0, caPFailures = 0, caPFinished = false
global caPStage = "initialization", caPSerial = 0, caPCase = "", caPPublished = 0
global caPProcess, caPWatch, caPFixedTrials = 10, caPAlternateTrials = 10
global caPWrite, caPNote, caPStep, caPCheck, caPRequire, caPNumber, caPCSV
global caPMemory, caPFind, caPCapture, caPSame, caPSameGroups, caPSameStats
global caPGeometry, caPBounds, caPVerify, caPVerifyGroups, caPRecordSnapshot
global caPIdText, caCompositionStats
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
    #(poses,caCompositionRows setup,caCompositionStats setup)
)
fn caPSame first second handles:false =
(
    local same = first.count == second.count
    for index = 1 to first.count while same do
    (
        local row = first[index], other = second[index]
        for field in #(1,2,3,5,6,7,8) where row[field] != other[field] do same = false
        for axis = 1 to 3 where row[4][axis] != other[4][axis] do same = false
        for field in #(9,10,14) where distance row[field] other[field] > 0.002 do same = false
        for field in #(11,12,13) where distance row[field] other[field] > 0.00001 do same = false
        if handles and row[15] != other[15] do same = false
    )
    same
)
fn caPSameGroups first second =
(
    deepEqual first second strictCompare:true
)
fn caPSameStats first second =
(
    local same = first.count == 6 and second.count == 6
    if same do
    (
        for i = 1 to 5 where first[i] != second[i] do same = false
        if not (deepEqual first[6] second[6] strictCompare:true) do same = false
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
-- Explicit bounded decimal IDs: no array printer or PrintAllElements state.
fn caPIdText ids =
(
    if (classOf ids)!=Array or ids.count<2 or ids.count>4 do throw "Benchmark row requires2..4 exact member IDs."
    local text="#("
    for index=1 to ids.count do
    (
        local id=ids[index]
        if ((classOf id)!=Integer and (classOf id)!=Integer64) or id==0 do throw "Expected nonzero exact member ID."
        if index>1 do text+=", "
        text+=(caPNumber id)
    )
    text+")"
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
        caPCSV "groups.csv" #(caPSerial,caPCase,operation,phase,iteration,seed,row[1],row[2],row[3],(caPIdText row[4]),row[5].x,row[5].y,row[5].z,row[6])
)
fn caPRecordRegions setup =
(
    for row in (caRegionRows setup) do
        caPCSV "regions.csv" #(caPSerial,caPCase,row[1],row[4],row[5].x,row[5].y,row[5].z,row[6].x,row[6].y,row[6].z,row[7],row[8],row[12])
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
    caPCheck (label+": preview retains every committed pose group and actual node handle") (caPSame committed[1] current[1] handles:true and caPSameGroups committed[2] current[2] and (deepEqual committed[3] current[3] strictCompare:true))
)

/* Cache benchmark. Root-controlled Max2027 owned process only.
   Resets scenes. Never fileIn in an artist scene. No launch is performed here.
   Requires the full frozen helper prefix; assemble_draft.py creates one script.
   Native cache schema1 proves reuse; timings alone never establish a hit.
   120 paired measurements + 4 seed baselines + 20 explicit priming/context commands.
*/
global CA_CACHE_REVERSE_ORDER
global caGeometryCacheInfo, caGeometryDependencyInfo, caClearGeometryCache, caClearAllGeometryCaches
global caSetGeometryCacheEnabled, caGeometryCacheEnabled
global caVersion, caModulePaths, caCreateSetup, caSetupSummary, caSetArrangeSettings
global caCategoryRules, caSetCategoryRules, caRegisterAsset, caSetAssetBookRow
global caSetCompositionSettings, caCompositionRows, caOutputRows, caRegionRows
global caGenerate, caPreview, caPreviewInfo, caPreviewBounds, caCommitPreview
global caQOriginalEnabled=undefined, caQMeasured=0, caQPreviousSequence=0L
global caQInfo, caQCacheCheck, caQRecordCache, caQMeasure, caQCase, caQRun

fn caQInfo setup =
(
    local info=caGeometryCacheInfo setup
    if info.count!=5 or info[1]!=1 or info[3]==undefined or info[3].count!=12 or info[4].count!=8 or info[5].count!=12 do throw "Missing cache schema1 diagnostics."
    local names=#("lookupStamp","furnitureCapture","inspect","registryBind","obstacleCapture","queryBuild","assetRefresh","solve","visualCapture","publish","finalValidate","total")
    for field=7 to 12 do
        if ((classOf info[3][field])!=Integer and (classOf info[3][field])!=Integer64) or info[3][field]<0 do throw "Native work/sequence must be exact nonnegative integers."
    for i=1 to names.count do
        if info[5][i].count!=2 or info[5][i][1]!=names[i] or ((classOf info[5][i][2])!=Integer and (classOf info[5][i][2])!=Integer64) or info[5][i][2]<0 do throw "Native phase order/type changed."
    if info[4][3].count!=4 or info[4][4].count!=4 do throw "Cache footprint shape changed."
    for field in #(1,2,5,6,7,8) do
        if ((classOf info[4][field])!=Integer and (classOf info[4][field])!=Integer64) or info[4][field]<0 do throw "Native total must be exact nonnegative integer."
    for row in #(info[4][3],info[4][4]) do for value in row do
        if ((classOf value)!=Integer and (classOf value)!=Integer64) or value<0 do throw "Native footprint must be exact nonnegative integer."
    info
)
fn caQCacheCheck info condition operation =
(
    local last=info[3], totals=info[4]
    local valid=info[2] and last[1]==(if operation=="CommitPreview" then "commitPreview" else (toLower operation)) and last[4] and last[11]>0 and last[12]>caQPreviousSequence
    valid=valid and last[5]==(operation!="Preview") and last[7]>0 and last[9]>0
    if condition=="warm" or condition=="preparation" then
    (
        valid=valid and last[2]=="hit" and last[3]=="none" and last[6] and last[8]==0 and last[10]==0
        for index in #(2,3,5,6) where info[5][index][2]!=0 do valid=false
    )
    else valid=valid and last[2]=="cold" and not last[6] and last[8]==last[7] and last[10]==last[9]
    valid=valid and totals[1]>0 and totals[3][1]>0 and totals[3][1]<=4 and totals[3][2]>0 and totals[3][2]<=268435456 and totals[3][3]<=1000000 and totals[3][4]<=1000000
    caQPreviousSequence=last[12]
    caPRequire (caPCase+": explicit native cache work/disposition "+condition+" "+operation) valid
)
fn caQRecordCache setup info =
(
    local last=info[3], totals=info[4], dependency=caGeometryDependencyInfo setup
    if dependency.count!=5 or dependency[1]!=1 or not dependency[5] do throw "Missing reusable dependency ticket."
    local values=#(caPSerial,info[2])
    for value in last do append values value
    append values totals[1]; append values totals[2]
    for row in #(totals[3],totals[4]) do for value in row do append values value
    for index in #(5,6,7,8) do append values totals[index]
    for index=2 to 4 do append values dependency[index]
    append values (sliderTime as Integer)
    caPCSV "cache-commands.csv" values
    for row in info[5] do caPCSV "cache-phases.csv" #(caPSerial,row[1],row[2])
)
fn caQMeasure setup operation condition iteration seed position expected assetSizes sourceBounds =
(
    if condition=="cold" or condition=="baseline" do caClearGeometryCache setup
    caPSerial+=1
    if condition=="cold" or condition=="warm" do caQMeasured+=1
    local phase=if condition=="baseline" then "baseline" else (if condition=="preparation" then "preparation" else "paired")
    caPStep (caPCase+" | "+operation+" | "+condition+" | pair "+(iteration as string)+" | seed "+(caPNumber seed))
    local committed=caPCapture setup, revisionBefore=(caSetupSummary setup)[3]
    local before=caPMemory(), result=undefined, publishedBefore=caPPublished
    caPWatch.Reset(); caPWatch.Start()
    case operation of
    (
        "Generate": (result=caGenerate setup #())
        "Preview": (result=caPreview setup #())
        "CommitPreview": (result=caCommitPreview setup)
        default: (caPWatch.Stop(); throw "Unknown command.")
    )
    caPWatch.Stop()
    local elapsed=caPWatch.Elapsed.TotalMilliseconds, ticks=caPWatch.ElapsedTicks
    -- This getter is passive; read it before oracle/export work or any other command.
    local info=caQInfo setup, after=caPMemory(), snapshot=caPCapture setup
    caQCacheCheck info condition operation
    if operation!="Preview" do caPPublished+=1
    local previewCount=if operation=="Preview" then (caPreviewInfo setup)[3] else 0
    caPCSV "metrics.csv" #(caPSerial,caPCase,operation,phase,iteration,seed,"geometry_query_cache_enabled",elapsed,ticks,result[1],result[2],result[3],result[4],result[5],result[6].count,snapshot[1].count,snapshot[2].count,(caRegionRows setup).count,previewCount,before[1],after[1],before[2],after[2],before[3],after[3],publishedBefore,revisionBefore,(caSetupSummary setup)[3],condition,position,CA_CACHE_REVERSE_ORDER)
    caQRecordCache setup info
    caPRecordSnapshot operation phase iteration seed snapshot
    caPRecordRegions setup
    local composition=snapshot[3]
    caPRequire (caPCase+": complete published native composition statistics are available") (composition.count==6 and composition[1])
    for index=2 to 6 do
        if ((classOf composition[index])!=Integer and (classOf composition[index])!=Integer64) or composition[index]<0 do throw "Composition counters must be exact nonnegative integers."
    caPCSV "composition-stats.csv" #(caPSerial,caPCase,operation,phase,iteration,seed,composition[1],composition[2],composition[3],composition[4],composition[5],composition[6])
    for index=1 to result[6].count do caPCSV "warnings.csv" #(caPSerial,index,result[6][index] as string)
    caPRequire (caPCase+": positive accepted result and exact target accounting") (result[2]>0 and result[1]>=result[2] and result[5]==result[1]-result[2])
    caPRequire (caPCase+": actual full geometry support and no output/furniture penetration") (caPVerify snapshot assetSizes sourceBounds)
    if expected!=undefined do
    (
        caPRequire (caPCase+": native full result stats/warnings match seed baseline") (caPSameStats expected[1] result)
        caPRequire (caPCase+": complete native composition statistics match seed baseline") (deepEqual expected[2][3] composition strictCompare:true)
        if operation=="Preview" then
        (
            caPPreviewCheck setup expected[2] committed (caPCase+": "+condition+" Preview pair "+(iteration as string))
            caPRequire (caPCase+": Preview retains exact committed revision") ((caSetupSummary setup)[3]==revisionBefore)
        )
        else caPRequire (caPCase+": full placement IDs/poses/group relationships match seed baseline") (caPSame expected[2][1] snapshot[1] and caPSameGroups expected[2][2] snapshot[2])
    )
    #(result,snapshot,info[3][11])
)
fn caQCase label category rowMode densityValue =
(
    caPCase=label; caPPublished=0
    caPStep (label+" | fresh owned fixture; same-time paired cache commands")
    resetMaxFile #noPrompt
    units.SystemType=#millimeters; units.SystemScale=1; sliderTime=0
    caClearAllGeometryCaches()
    local fixture=caCreateBookRowFixtures(), furniture=if category==1 then fixture[3] else fixture[4]
    local sourceNodes=caPGeometry furniture, sourceBounds=caPBounds sourceNodes
    local setup=caCreateSetup #(furniture) category, assetSizes=#()
    setup.name="CA_CACHE_PERFORMANCE_"+label
    for index=1 to sourceBounds.count do
    (
        local bounds=sourceBounds[index]
        caPCSV "sources.csv" #(label,index,bounds[1].x,bounds[1].y,bounds[1].z,bounds[2].x,bounds[2].y,bounds[2].z)
    )
    for book in fixture[1] do
    (
        local bounds=caBRWorldGeometryBounds book[1], id=caRegisterAsset setup book[1] book[2] 1 3 #(0.0) 1.0 1.0 1.0 false
        local size=bounds[2]-bounds[1]
        append assetSizes #(id,size)
        caPCSV "assets.csv" #(label,id,size.x,size.y,size.z)
        if rowMode do caSetAssetBookRow setup id 3
    )
    local settings=(caSetupSummary setup)[9]
    settings[1]=7231L; settings[2]=densityValue; settings[3]=20; settings[4]=12; settings[5]=0.35
    settings[6]=0; settings[7]=0.2; settings[8]=2; settings[9]=category; settings[10]=25; settings[11]=false
    caSetArrangeSettings setup settings
    local rules=caCategoryRules setup category
    for row in rules do row[3]=if row[1]==1 then 500 else 0
    caSetCategoryRules setup category rules
    if rowMode do caSetCompositionSettings setup #(true,2,4,3.0,0.5)
    caPNote ("CONFIG case="+label+" settings="+(settings as string)+" asset_sizes="+(assetSizes as string)+" rowMode="+(rowMode as string))
    local baselineA=caQMeasure setup "Generate" "baseline" 0 7231L 0 undefined assetSizes sourceBounds
    caPSetSeed setup 9349L
    local baselineB=caQMeasure setup "Generate" "baseline" 0 9349L 0 undefined assetSizes sourceBounds
    caPRequire (label+": seed reroll changes an actual pose or identity") (not (caPSame baselineA[2][1] baselineB[2][1]))
    if rowMode do caPRequire (label+": native individually generated book-row workload is nonvacuous") (baselineA[2][2].count>0 and baselineB[2][2].count>0)
    for pair=1 to 10 do
    (
        local seed=if mod pair 2==1 then 9349L else 7231L
        local expected=if seed==7231L then baselineA else baselineB
        caPSetSeed setup seed
        -- Equal previous pose/group validation work; exported separately, excluded
        -- from paired timings. The prior command already retained same-time geometry.
        caQMeasure setup "Generate" "preparation" pair seed 0 expected assetSizes sourceBounds
        local coldFirst=(mod pair 2)==1
        if CA_CACHE_REVERSE_ORDER do coldFirst=not coldFirst
        local order=if coldFirst then #("cold","warm") else #("warm","cold")
        local firstWork=undefined
        for position=1 to 2 do
        (
            local condition=order[position]
            local generated=caQMeasure setup "Generate" condition pair seed position expected assetSizes sourceBounds
            local previewed=caQMeasure setup "Preview" condition pair seed position expected assetSizes sourceBounds
            local committed=caQMeasure setup "CommitPreview" condition pair seed position expected assetSizes sourceBounds
            local solverWork=#(generated[3],previewed[3],committed[3])
            if firstWork==undefined then firstWork=solverWork
            else caPRequire (label+": identical per-pair solver work at equal previous state") (deepEqual firstWork solverWork strictCompare:true)
        )
    )
    caPRequire (label+": furniture geometry unchanged") (deepEqual (caPBounds sourceNodes) sourceBounds strictCompare:true)
    caPRequire (label+": furniture source materials remain assigned") ((for node in sourceNodes where node.material==undefined collect node).count==0)
    true
)
fn caQRun =
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Owned root/output required."
    if (maxVersion())[1]!=29000 do throw "Max 2027 required."
    if CA_CACHE_REVERSE_ORDER==undefined do CA_CACHE_REVERSE_ORDER=false
    caPRequire "matched native candidate is 0.3.2" ((caVersion())=="0.3.2")
    caPRequire "exact Integer/IntegerPtr/Integer64 formatter" ((caPNumber 55224)=="55224" and (caPNumber 4294967295P)=="4294967295" and (caPNumber -8100984552319297358L)=="-8100984552319297358")
    -- These self-checks run outside all timed samples and are only qualified
    -- when Max executes the promoted harness. Element25 must not be hidden.
    local warningA=for index=1 to 25 collect ("warning_"+(index as string))
    local warningB=deepCopy warningA
    caPRequire "full warning arrays compare equal before tail mutation" (caPSameStats #(1L,1L,0L,1L,0L,warningA) #(1L,1L,0L,1L,0L,warningB))
    warningB[25]="changed warning after element20"
    caPRequire "warning difference beyond20 elements is detected" (not (caPSameStats #(1L,1L,0L,1L,0L,warningA) #(1L,1L,0L,1L,0L,warningB)))
    caPRequire "group IDs export exact signed64 decimals without array printing" ((caPIdText #(4294967295L,-8100984552319297358L))=="#(4294967295, -8100984552319297358)")
    CA_AUTO_SHOW_UI=false
    fileIn (CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    caPProcess=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    caPWatch=dotNetObject "System.Diagnostics.Stopwatch"
    caQOriginalEnabled=caGeometryCacheEnabled(); caSetGeometryCacheEnabled true
    for name in #("metrics.csv","poses.csv","groups.csv","regions.csv","composition-stats.csv","preview-bounds.csv","warnings.csv","sources.csv","assets.csv","cache-commands.csv","cache-phases.csv","performance-environment.txt") do
        if doesFileExist (CA_TEST_OUTPUT+name) do throw "Fresh owned output directory required; preserve prior evidence."
    caPCSV "metrics.csv" #("serial","case","operation","phase","iteration","seed","computation","elapsed_ms","elapsed_ticks","requested","accepted","kept","candidates","underfilled","warnings","committed_outputs","committed_groups","regions","preview_boxes","working_before_bytes","working_after_bytes","private_before_bytes","private_after_bytes","process_lifetime_peak_working_before_bytes","process_lifetime_peak_working_after_bytes","prior_publications_in_case","revision_before","revision_after","condition","position","reverse_order")
    caPCSV "poses.csv" #("serial","case","operation","phase","iteration","seed","placement_id","asset_id","region_id","anchor_x_mm","anchor_y_mm","anchor_z_mm","yaw_degrees","scale","locked","parent_stack_id","node_handle","bounds_min_x","bounds_min_y","bounds_min_z","bounds_max_x","bounds_max_y","bounds_max_z","tm_row1_x","tm_row1_y","tm_row1_z","tm_row2_x","tm_row2_y","tm_row2_z","tm_row3_x","tm_row3_y","tm_row3_z","tm_row4_x","tm_row4_y","tm_row4_z")
    caPCSV "groups.csv" #("serial","case","operation","phase","iteration","seed","group_id","kind","region_id","ordered_member_ids","front_x","front_y","front_z","gap_mm")
    caPCSV "regions.csv" #("serial","case","region_id","role","bounds_min_x","bounds_min_y","bounds_min_z","bounds_max_x","bounds_max_y","bounds_max_z","minimum_clearance_mm","open_above","excluded")
    caPCSV "composition-stats.csv" #("serial","case","operation","phase","iteration","seed","available","row_attempts","rows_formed","row_failures","balance_anchor_attempts","rows_moved")
    caPCSV "preview-bounds.csv" #("serial","case","index","center_x_mm","center_y_mm","center_z_mm","half_x_mm","half_y_mm","half_z_mm","yaw_degrees")
    caPCSV "warnings.csv" #("serial","index","warning")
    caPCSV "sources.csv" #("case","source_index","min_x_mm","min_y_mm","min_z_mm","max_x_mm","max_y_mm","max_z_mm")
    caPCSV "assets.csv" #("case","asset_id","size_x_mm","size_y_mm","size_z_mm")
    caPCSV "cache-commands.csv" #("serial","enabled","operation","disposition","reason","completed","published","lookup_validated","inspection_work_original","inspection_work_executed","query_build_work_original","query_build_work_executed","solver_work","command_sequence","resident","retired_borrowed","live_entries","live_bytes","live_triangles","live_cells","peak_entries","peak_bytes","peak_triangles","peak_cells","entry_metadata_live_bytes","entry_metadata_peak_bytes","fixed_service_inline_bytes","fixed_control_object_bytes","document_instance","scene_epoch","geometry_epoch","time_ticks")
    caPCSV "cache-phases.csv" #("serial","phase","nanoseconds")
    local metadata=createFile (CA_TEST_OUTPUT+"performance-environment.txt"),timer=dotNetClass "System.Diagnostics.Stopwatch",env=dotNetClass "System.Environment"
    format "Cache preparation/command benchmark; no renderer/FPS/general-scene claim.\n" to:metadata
    format "MaxVersion=%\nNativeVersion=%\nNativeModulePaths=%\nPrivateINI=%\nOwnedPID=%\nCPUCount=%\nStopwatchFrequency=%\nStopwatchHighResolution=%\nReverseOrder=%\nRuntime=%\n" (maxVersion()) (caVersion()) (caModulePaths()) (getMAXIniFile()) (caPNumber caPProcess.Id) env.ProcessorCount (caPNumber timer.Frequency) timer.IsHighResolution CA_CACHE_REVERSE_ORDER (env.Version.ToString()) to:metadata
    for processName in #("3dsmax","3dsmaxbatch") do for process in ((dotNetClass "System.Diagnostics.Process").GetProcessesByName processName) do
    (
        format "ObservedMaxProcess=% PID=%\n" processName (caPNumber process.Id) to:metadata
        process.Dispose()
    )
    flush metadata;close metadata
    caPNote "POLICY: Each pair exports a separate warm-hit Generate to equalize previous state; preparation excluded from paired summaries. Clear-before-cold outside timer; enabled-warm is proven by native hit/work fields. No forcedGC/Undo flush between samples. Publication history accumulates and is exported; fresh scene per case."
    caPNote "POLICY: Root schedules this process alone after correctness; second fresh run reverses pair order. No idle-machine assertion follows from process inventory."
    caQCase "small TV ordinary books" 1 false 0.15
    caQCase "medium open shelf book rows" 2 true 0.20
    caPRequire "exact120 paired commands plus4 seed baselines plus20 explicit context commands" (caQMeasured==120 and caPSerial==144)
    true
)
try (caQRun()) catch
(
    caPFailures+=1
    caPNote ("EXCEPTION stage="+caPStage+" | "+(getCurrentException() as string))
    caPNote ("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
    caPNote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
if caQOriginalEnabled!=undefined do try (caSetGeometryCacheEnabled caQOriginalEnabled) catch ()
if caPProcess!=undefined do try (caPProcess.Dispose()) catch ()
caPFinished=true
caPWrite()
