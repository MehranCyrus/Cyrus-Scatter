/* Cache host correctness harness; receipts bind each executed source version.
   Root-controlled disposable Max2027 process only. Resets/loads owned scenes.
   Cache API schema1; acceptance is recorded by exact build/host receipts.
   No latency threshold, time-based hit inference, script timer or fault hook. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caGeometryCacheInfo, caGeometryDependencyInfo, caClearGeometryCache, caClearAllGeometryCaches
global caSetGeometryCacheEnabled, caGeometryCacheEnabled
global caCreateBookRowFixtures, caBRWorldGeometryBounds
global caCreateSetup, caSetupSummary, caSetArrangeSettings, caCategoryRules, caSetCategoryRules
global caRegisterAsset, caAssetRows, caSetAssetBookRow, caSetCompositionSettings, caCompositionSettings, caCompositionRows, caCompositionStats
global caAnalyzeSetup, caRegionRows, caSetRegionRules, caSetCollisionScope, caGenerate, caOutputRows, caSetLocked, caTick
global caPreview, caPreviewInfo, caPreviewBounds, caCommitPreview
global caShowAdvancedArrangeUI, caArrangeUI, caShowAssetUI, caAssetUI
global caKLog=#(), caKPasses=0, caKFailures=0, caKFinished=false, caKOriginalEnabled=undefined, caKObserverProven=false
global caKWrite, caKNote, caKCheck, caKRequire, caKCase, caKFind, caKMM, caKGeometry, caKBounds
global caKInteger, caKDependency, caKInfo, caKExpect, caKCapture, caKSamePoses, caKSameGroups, caKSameStats, caKSameRegions, caKSame
global caKPhysical, caKBoxes, caKSameBoxes, caKPreviewMatches, caKRun, caKPair, caKFixture
global caKDisabledAndHit, caKPreviewCase, caKRecipeAndBrowse, caKGeometryChanges, caKAssetAndOutput
global caKTimeUnits, caKHistory, caKLoadClone, caKFailure, caKLoadedFixture, caKBootstrap
global caKBoxesOnSupport, caKPreviewOnlyChild, caKPreviewOnlyChildDisabled
global caOLAssetEnabled, caOLAssetDisabled, caOLObstacleEnabled, caOLObstacleDisabled, caOLRemovedEnabled, caOLRemovedDisabled

global caKMatrixEqual

fn caKMatrixEqual a b=
(
    local first=#(a.row1,a.row2,a.row3,a.row4),second=#(b.row1,b.row2,b.row3,b.row4),same=true
    for row=1 to 4 while same do for axis=1 to 3 while same do
        if first[row][axis]!=second[row][axis] do same=false
    same
)

fn caKWrite =
(
    if CA_TEST_OUTPUT != undefined do
    (
        local out=createFile (CA_TEST_OUTPUT+"result.txt")
        format "% passes=% failures=%\n" (if caKFinished then (if caKFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caKPasses caKFailures to:out
        for line in caKLog do format "%\n" line to:out
        flush out;close out
    )
    true
)
fn caKNote value=(append caKLog value;caKWrite();true)
fn caKCheck label value=(if value then (caKPasses+=1;caKNote ("PASS "+label)) else (caKFailures+=1;caKNote ("FAIL "+label));value)
fn caKRequire label value=(caKCheck label value;if not value do throw ("Prerequisite: "+label);true)
fn caKCase label action=
(
    caKNote ("STAGE "+label)
    try (action()) catch
    (
        caKFailures+=1
        caKNote ("EXCEPTION "+label+": "+(getCurrentException() as string))
        caKNote ("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
        caKNote ("STACK "+(getCurrentExceptionStackTrace() as string))
    )
)
fn caKFind rows id=(local found=undefined;for row in rows while found==undefined do if row[1]==id do found=row;found)
fn caKMM = (1.0/(units.decodeValue "1mm"))
fn caKGeometry root=
(
    local pending=#(root),found=#()
    while pending.count>0 do
    (
        local node=pending[pending.count];deleteItem pending pending.count
        if not isValidNode node do throw "Missing independent fixture source."
        for child in node.children do append pending child
        if not (isGroupHead node) and (superClassOf node)==GeometryClass do append found node
        if found.count+pending.count>4096 do throw "Fixture hierarchy exceeded bound."
    )
    found
)
fn caKBounds node=(local b=nodeGetBoundingBox node (matrix3 1),factor=caKMM();#(b[1]*factor,b[2]*factor))

-- Only this adapter knows the proposed schema. Missing diagnostics are a failure.
-- Totals are GLOBAL; they are never treated as per-document freshness proof.
fn caKInteger value=((classOf value)==Integer or (classOf value)==Integer64)
fn caKDependency setup=
(
    local value=caGeometryDependencyInfo setup
    if value.count!=5 or value[1]!=1 or not value[5] do throw "Unexpected/nonreusable dependency ticket."
    for i=2 to 4 do if not (caKInteger value[i]) or value[i]<=0 do throw "Dependency ticket requires exact positive integer identities."
    value
)
fn caKInfo setup=
(
    local value=caGeometryCacheInfo setup
    if value.count!=5 or value[1]!=1 or value[4].count!=8 or value[5].count!=12 do throw "Unexpected cache schema1 diagnostics."
    if value[3]!=undefined do
    (
        if value[3].count!=12 do throw "Unexpected cache last-command shape."
        for i=7 to 12 do if not (caKInteger value[3][i]) or value[3][i]<0 do throw "Cache work/sequence must use exact nonnegative native integers."
    )
    if value[4][3].count!=4 or value[4][4].count!=4 do throw "Unexpected global cache footprint shape."
    for i in #(1,2,5,6,7,8) do if not (caKInteger value[4][i]) or value[4][i]<0 do throw "Cache totals must use exact nonnegative native integers."
    for row in #(value[4][3],value[4][4]) do for n in row do if not (caKInteger n) or n<0 do throw "Cache footprint must use exact nonnegative native integers."
    local names=#("lookupStamp","furnitureCapture","inspect","registryBind","obstacleCapture","queryBuild","assetRefresh","solve","visualCapture","publish","finalValidate","total")
    for i=1 to names.count do
        if value[5][i].count!=2 or value[5][i][1]!=names[i] or not (caKInteger value[5][i][2]) or value[5][i][2]<0 do throw "Unexpected native phase name/order/exact integer value."
    if value[4][3][1]>4 or value[4][3][2]>268435456 or value[4][3][3]>1000000 or value[4][3][4]>1000000 do throw "Global retained-entry accounting exceeded agreed cap."
    value
)
fn caKExpect info mode operation=
(
    local last=info[3]
    caKRequire (operation+": native last-command diagnostics exist") (last!=undefined)
    local disposition=last[2],valid=(toLower last[1])==(toLower operation) and last[4] and last[11]>0 and last[12]>0
    if operation=="Preview" then valid=valid and not last[5] else valid=valid and last[5]
    if mode==#hit then
    (
        valid=valid and info[2] and disposition=="hit" and last[6] and last[7]>0 and last[9]>0 and last[8]==0 and last[10]==0
        for phase in #(2,3,5,6) where info[5][phase][2]!=0 do valid=false
    )
    else if mode==#disabled then valid=valid and not info[2] and (disposition=="cold" or disposition=="coldNotRetained") and last[8]>0 and last[10]>0
    else if mode==#cold then valid=valid and info[2] and disposition=="cold" and last[8]>0 and last[10]>0
    else if mode==#either then
    (
        if disposition=="hit" then valid=valid and last[6] and last[8]==0 and last[10]==0
        else valid=valid and (disposition=="cold" or disposition=="coldNotRetained") and last[8]>0 and last[10]>0
    )
    else throw "Unknown expected cache disposition."
    caKCheck (operation+": native diagnostic disposition/work is "+(mode as string)) valid
    caKNote ("CACHE "+(info as string))
    valid
)

-- Full real poses, mesh bounds and TM rows. Node handles compare only where
-- publication is forbidden; successful Generate may replace all output nodes.
fn caKCapture setup=
(
    local poses=#(),factor=caKMM()
    for row in (caOutputRows setup) do
    (
        if row.count!=9 or not isValidNode row[9] do throw "Missing/invalid real output binding."
        local bounds=caKBounds row[9],tm=row[9].transform
        append poses #(row[1],row[2],row[3],copy row[4],row[5],row[6],row[7],row[8],bounds[1],bounds[2],copy tm.row1,copy tm.row2,copy tm.row3,(copy tm.row4)*factor,getHandleByAnim row[9])
    )
    #(poses,caCompositionRows setup,caRegionRows setup,caCompositionStats setup)
)
fn caKSamePoses first second handles:false=
(
    local same=first.count==second.count
    for i=1 to first.count while same do
    (
        local a=first[i],b=second[i]
        for field in #(1,2,3,5,6,7,8) where a[field]!=b[field] do same=false
        -- Returned native poses must be identical. Only independently measured
        -- world mesh bounds / host TM values use physical precision tolerances.
        for axis=1 to 3 where a[4][axis]!=b[4][axis] do same=false
        for field in #(9,10,14) where distance a[field] b[field]>0.003 do same=false
        for field in #(11,12,13) where distance a[field] b[field]>0.00001 do same=false
        if handles and a[15]!=b[15] do same=false
    )
    same
)
fn caKSameGroups first second=
(
    -- Entire native records: ordered membership IDs, front and gap included.
    deepEqual first second strictCompare:true
)
fn caKSameStats a b=
(
    a.count==6 and b.count==6 and (deepEqual a b strictCompare:true)
)
fn caKSameRegions first second=
(
    local same=first.count==second.count
    for a in first while same do
    (
        local b=caKFind second a[1]
        if b==undefined then same=false
        else
        (
            for i in #(1,2,3,4,7,8,9,11,12) where a[i]!=b[i] do same=false
            for i in #(5,6,13) where distance a[i] b[i]>0.003 do same=false
            if abs(a[10]-b[10])>0.00001 do same=false
        )
    )
    same
)
fn caKSame a b handles:false compositionStats:true=
(
    (caKSamePoses a[1] b[1] handles:handles) and (caKSameGroups a[2] b[2]) and (caKSameRegions a[3] b[3]) and
    (not compositionStats or (deepEqual #(a[4]) #(b[4]) strictCompare:true))
)
fn caKBoxes setup=(for row in (caPreviewBounds setup) collect #(copy row[1],copy row[2],row[3]))
fn caKSameBoxes a b=
(
    local same=a.count==b.count
    for i=1 to a.count while same do if distance a[i][1] b[i][1]>0.003 or distance a[i][2] b[i][2]>0.003 or abs(a[i][3]-b[i][3])>0.00001 do same=false
    same
)
fn caKPreviewMatches boxes snapshot=
(
    local same=boxes.count==snapshot[1].count
    for i=1 to boxes.count while same do
    (
        local p=snapshot[1][i]
        if distance boxes[i][1] ((p[9]+p[10])*0.5)>0.03 or distance boxes[i][2] ((p[10]-p[9])*0.5)>0.03 or abs(boxes[i][3]-p[5])>0.00001 do same=false
    )
    same
)

-- Independent axis-aligned BOX-fixture oracle, not a native region-bound echo.
-- It reads actual recursive source geometry after edits and current unit scale.
fn caKPhysical fixture snapshot=
(
    local furniture=for node in (caKGeometry fixture[2]) collect (caKBounds node)
    local solids=(copy furniture #noMap),assetSizes=#(),valid=snapshot[1].count>0,used=#()
    if isValidNode fixture[4] do append solids (caKBounds fixture[4])
    for asset in fixture[6] do
    (
        local b=caBRWorldGeometryBounds asset[2],factor=caKMM()
        append assetSizes #(asset[1],(b[2]-b[1])*factor)
    )
    for row in snapshot[1] do
    (
        local asset=caKFind assetSizes row[2],supported=false
        if asset==undefined then valid=false else if distance (row[10]-row[9]) (asset[2]*row[6])>0.03 do valid=false
        if abs(row[5])>0.00001 or abs(row[6]-1)>0.00001 or row[8]!=0L or distance row[14] row[4]>0.003 do valid=false
        for board in furniture do if abs(row[9].z-board[2].z)<0.03 and row[9].x>=board[1].x-0.03 and row[10].x<=board[2].x+0.03 and row[9].y>=board[1].y-0.03 and row[10].y<=board[2].y+0.03 do supported=true
        if not supported do valid=false
        for bounds in solids do
        (
            local overlap=[amin #(row[10].x,bounds[2].x)-amax #(row[9].x,bounds[1].x),amin #(row[10].y,bounds[2].y)-amax #(row[9].y,bounds[1].y),amin #(row[10].z,bounds[2].z)-amax #(row[9].z,bounds[1].z)]
            if overlap.x>0.03 and overlap.y>0.03 and overlap.z>0.03 do valid=false
        )
    )
    for i=1 to snapshot[1].count do for j=i+1 to snapshot[1].count do
    (
        local a=snapshot[1][i],b=snapshot[1][j]
        if (amin #(a[10].x,b[10].x)-amax #(a[9].x,b[9].x))>0.03 and (amin #(a[10].y,b[10].y)-amax #(a[9].y,b[9].y))>0.03 and (amin #(a[10].z,b[10].z)-amax #(a[9].z,b[9].z))>0.03 do valid=false
    )
    for groupRow in snapshot[2] do
    (
        if groupRow[2]!=1 or groupRow[4].count!=3 or distance groupRow[5] [0,-1,0]>0.00001 do valid=false
        local previous=undefined
        for id in groupRow[4] do
        (
            local member=caKFind snapshot[1] id
            if member==undefined then valid=false
            else
            (
                if (findItem used id)!=0 or member[3]!=groupRow[3] do valid=false
                append used id
                if previous!=undefined do if abs(member[9].x-previous[10].x-groupRow[6])>0.03 or abs(member[9].y-previous[9].y)>0.03 or abs(member[9].z-previous[9].z)>0.03 do valid=false
                previous=member
            )
        )
    )
    caKCheck "actual complete mesh boxes retain source dimensions/support/collision and coherent rows" valid
    valid
)

-- #(setup,group,#(left,right),obstacle,bookFixtureRows,#(#(assetID,sourceRoot),...))
fn caKFixture analyze:true=
(
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0f
    local books=(caCreateBookRowFixtures includeFurniture:false)[1]
    local left=box name:"CA_CACHE_LEFT" width:700 length:350 height:30 pos:[-600,0,500]
    local right=box name:"CA_CACHE_RIGHT" width:700 length:350 height:30 pos:[600,0,500]
    local furniture=group #(left,right) name:"CA_CACHE_FURNITURE"
    furniture.pivot=[0,0,0]
    local obstacle=box name:"CA_CACHE_OBSTACLE" width:140 length:140 height:250 pos:[600,0,530]
    local setup=caCreateSetup #(furniture) 1
    setup.name="CA_CACHE_SETUP"
    local assets=#()
    for i=1 to books.count do
    (
        books[i][1].name="CA_CACHE_BOOK_"+(i as string)
        local id=caRegisterAsset setup books[i][1] books[i][2] 1 3 #(0.0) 1 1 1 false
        caSetAssetBookRow setup id 3
        append assets #(id,books[i][1])
    )
    local settings=(caSetupSummary setup)[9]
    settings[1]=137;settings[2]=0.08;settings[3]=20;settings[4]=10;settings[5]=0;settings[6]=0;settings[7]=0;settings[8]=2;settings[10]=25;settings[11]=false
    caSetArrangeSettings setup settings
    local rules=caCategoryRules setup 1
    for row in rules do (row[2]=1;row[3]=if row[1]==1 then 8 else 0;row[4]=false)
    caSetCategoryRules setup 1 rules
    caSetCollisionScope setup #(obstacle) false
    caSetCompositionSettings setup #(true,3,3,3,0)
    if analyze do caAnalyzeSetup setup
    #(setup,furniture,#(left,right),obstacle,books,assets)
)
fn caKRun fixture operation mode=
(
    caKNote ("BEGIN "+operation+" expected="+(mode as string))
    local setup=fixture[1],result=undefined
    case operation of
    (
        "Generate": (result=caGenerate setup #())
        "Preview": (result=caPreview setup #())
        "CommitPreview": (result=caCommitPreview setup)
        default: throw "Unknown cache test operation."
    )
    local info=caKInfo setup
    caKExpect info mode operation
    local snapshot=caKCapture setup
    if operation!="Preview" do caKPhysical fixture snapshot
    #(result,snapshot,info)
)
fn caKPair fixture label=
(
    caKNote ("PAIR "+label)
    -- Publish the current context first. Initial/new-recipe solves can validate
    -- different previous placements/groups and legitimately charge other work.
    caKNote ("PAIR_CONTEXT Generate before measured cold/hit: "+label)
    caKRun fixture "Generate" #either
    caClearGeometryCache fixture[1]
    local cold=caKRun fixture "Generate" #cold
    local hit=caKRun fixture "Generate" #hit
    caKCheck (label+": full cold/hit poses groups regions and composition stats") (caKSame cold[2] hit[2])
    caKCheck (label+": cold/hit targets warnings candidates and solver work") ((caKSameStats cold[1] hit[1]) and cold[3][3][11]==hit[3][3][11])
    #(cold,hit)
)

fn caKDisabledAndHit=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled false
    local ticket=caKDependency setup
    local disabled=caKRun f "Generate" #disabled
    local disabledAgain=caKRun f "Generate" #disabled
    caKCheck "disabled repeat preserves complete logical result" ((caKSame disabled[2] disabledAgain[2]) and (caKSameStats disabled[1] disabledAgain[1]))
    caKRequire "disabled Generate/publication/repeat do not alter geometry epoch" (deepEqual ticket (caKDependency setup) strictCompare:true)
    local settings=(caSetupSummary setup)[9]
    settings[1]=138;caSetArrangeSettings setup settings
    caKRun f "Generate" #disabled
    caKRequire "disabled recipe edit/publication preserves geometry epoch" (deepEqual ticket (caKDependency setup) strictCompare:true)
    select setup;caGeometryCacheInfo setup;caSetupSummary setup
    caKRequire "disabled passive getters/selection preserve dependency ticket" (deepEqual ticket (caKDependency setup) strictCompare:true)
    settings[1]=137;caSetArrangeSettings setup settings
    f[3][1].width+=40
    caKRequire "genuine upstream geometry notification advances nonrestored epoch" ((caKDependency setup)[4]>ticket[4])
    f[3][1].width-=40
    local changedTicket=caKDependency setup
    disabled=caKRun f "Generate" #disabled
    caKRequire "disabled rebuilt publication preserves its current upstream epoch" (deepEqual changedTicket (caKDependency setup) strictCompare:true)
    caKRequire "small original fixture contains generated row relationships" (disabled[2][2].count>0)
    caKObserverProven=true
    caSetGeometryCacheEnabled true
    local pair=caKPair f "enabled same-time Generate"
    caKCheck "enabling reuse changes no logical disabled result" ((caKSame disabled[2] pair[1][2]) and (caKSameStats disabled[1] pair[1][1]))
    local before=caKCapture setup,summary=caSetupSummary setup
    caClearAllGeometryCaches()
    caKCheck "explicit clear changes no authored/publication state" ((deepEqual summary (caSetupSummary setup) strictCompare:true) and (caKSame before (caKCapture setup) handles:true))
    local totals=(caKInfo setup)[4]
    caKCheck "synchronous clear releases all unborrowed entry accounting" (totals[1]==0 and totals[2]==0 and totals[3][1]==0 and totals[3][2]==0 and totals[5]==0)
)
fn caKPreviewCase=
(
    local f=caKFixture analyze:false,setup=f[1]
    caSetGeometryCacheEnabled true;caClearAllGeometryCaches()
    local summary=caSetupSummary setup,objectCount=objects.count
    caKRequire "first Preview starts with an empty persistent registry" ((caRegionRows setup).count==0)
    local cold=caKRun f "Preview" #cold,boxes=caKBoxes setup
    local hit=caKRun f "Preview" #hit
    caKCheck "first-ever cold/hit Preview boxes and solve stats agree" ((caKSameBoxes boxes (caKBoxes setup)) and (caKSameStats cold[1] hit[1]) and cold[3][3][11]==hit[3][3][11])
    caKCheck "Preview does not publish registry/groups/nodes or change revision" ((deepEqual summary (caSetupSummary setup) strictCompare:true) and objects.count==objectCount and (caOutputRows setup).count==0 and (caCompositionRows setup).count==0)
    local preview=caPreviewInfo setup
    caClearGeometryCache setup
    caKCheck "geometry clear preserves a valid staged Preview" ((deepEqual preview (caPreviewInfo setup) strictCompare:true) and (caPreviewInfo setup)[2] and (deepEqual summary (caSetupSummary setup) strictCompare:true))
    local committed=caKRun f "CommitPreview" #cold
    caKCheck "cold Commit reproduces first staged boxes and statistics" ((caKPreviewMatches boxes committed[2]) and (caKSameStats cold[1] committed[1]) and cold[3][3][11]==committed[3][3][11])
    local p=caKRun f "Preview" #hit
    caKCheck "later Preview keeps exact committed node handles" (caKSame committed[2] p[2] handles:true)
    caClearGeometryCache setup
    local again=caKRun f "CommitPreview" #cold
    caKCheck "established-ID Preview/forced-cold Commit preserves complete IDs/order/groups" ((caKSame committed[2] again[2]) and (caKSameStats committed[1] again[1]))
)

-- Independent axis-aligned preview envelope check for this procedural board.
fn caKBoxesOnSupport boxes support=
(
    local valid=boxes.count>0
    for box in boxes do
    (
        local lower=box[1]-box[2],upper=box[1]+box[2]
        if box[3]!=0 or abs(lower.z-support[2].z)>0.03 or lower.x<support[1].x-0.03 or upper.x>support[2].x+0.03 or lower.y<support[1].y-0.03 or upper.y>support[2].y+0.03 do valid=false
    )
    valid
)
fn caKPreviewOnlyChild reuse:true=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled true
    caKPair f "Preview-only hierarchy baseline"
    -- Author exclusions BEFORE attaching the new child. Any authored commit
    -- could refresh persistent expanded bindings and hide the intended gap.
    local oldRegions=caRegionRows setup
    caKRequire "Preview-only fixture initially has two persistent board regions" (oldRegions.count==2)
    for region in oldRegions do caSetRegionRules setup region[1] region[2] region[3] region[4] region[9] region[10] region[11] true region[13]
    caSetGeometryCacheEnabled reuse
    local coldMode=if reuse then #cold else #disabled,repeatMode=if reuse then #hit else #disabled
    local before=caKCapture setup,revision=(caSetupSummary setup)[3]
    local oldGeometryCount=(caKGeometry f[2]).count
    local child=box name:"CA_CACHE_PREVIEW_ONLY_CHILD" width:400 length:350 height:20 pos:[0,0,800]
    attachNodesToGroup #(child) f[2]
    caKRequire "new procedural support is a real newly attached group child" (child.parent==f[2] and (caKGeometry f[2]).count==oldGeometryCount+1)
    local firstSupport=caKBounds child
    caKRequire "new support has independent analytic world bounds and useful area" (distance firstSupport[1] [-200,-175,800]<0.003 and distance firstSupport[2] [200,175,820]<0.003)
    caKNote ("BEGIN Preview-only new child reuse="+(reuse as string)+"; no Generate/Analyze/Commit/authored setter after attachment")
    local first=caKRun f "Preview" coldMode,firstBoxes=caKBoxes setup
    caKRequire "Preview is valid and actually places on the newly observed child's support" ((caPreviewInfo setup)[1] and (caPreviewInfo setup)[2] and (caKBoxesOnSupport firstBoxes firstSupport))
    caKCheck "Preview publishes no new persistent regions, nodes, rows or revision" ((caRegionRows setup).count==oldRegions.count and (caSetupSummary setup)[3]==revision and (caKSame before (caKCapture setup) handles:true compositionStats:false))
    local ticket=caKDependency setup,childTM=copy child.transform,sequence=(caKInfo setup)[3][12]
    -- This executes AFTER Preview returned. Observation must survive the
    -- command-local scope and cover a descendant discovered only by Preview.
    -- A group-head notification forwarding the geometry edit is not assumed.
    child.height=80
    local currentSupport=caKBounds child,afterEdit=caKDependency setup
    caKRequire "outside-command descendant edit changes actual geometry without NodeTM or hierarchy changes" (abs(currentSupport[2].z-firstSupport[2].z-60)<0.003 and child.parent==f[2] and (caKMatrixEqual child.transform childTM) and (caKGeometry f[2]).count==oldGeometryCount+1)
    caKCheck "Preview-only discovered descendant remains persistently observed after command return" (afterEdit[2]==ticket[2] and afterEdit[3]==ticket[3] and afterEdit[4]>ticket[4])
    local stale=caPreviewInfo setup
    caKCheck "outside-command child geometry edit stales the previously valid Preview" (stale[1] and not stale[2] and stale[4]!="")
    local rejected=false,errorText=""
    caKNote "BEGIN stale Preview Commit after outside-command new-child geometry edit"
    try (caCommitPreview setup) catch (rejected=true;errorText=getCurrentException() as string)
    caKCheck "Commit refuses the old Preview after the newly discovered child changes" rejected
    caKCheck "refused stale Commit retains exact original nodes/IDs/groups/poses and revision" ((caSetupSummary setup)[3]==revision and (caKSame before (caKCapture setup) handles:true compositionStats:false))
    caKCheck "stale Commit cannot report a successful native publication" ((caKInfo setup)[3][12]==sequence or not (caKInfo setup)[3][5])
    caKNote ("PREVIEW_ONLY_CHILD beforeTicket="+(ticket as string)+" afterTicket="+(afterEdit as string)+" oldSupport="+(firstSupport as string)+" currentSupport="+(currentSupport as string)+" staleInfo="+(stale as string)+" commitError="+errorText)
    caKRequire "stale Commit precondition rejected before independent fresh solve" rejected
    -- The same child is still unpublished in the persistent registry here.
    -- A fresh Preview must build current geometry. Its repeat may reuse only
    -- when enabled; disabled mode must independently rebuild the same result.
    local fresh=caKRun f "Preview" coldMode,freshBoxes=caKBoxes setup
    caKRequire "fresh Preview uses the edited child's actual 880mm support instead of cached 820mm support" ((caKBoxesOnSupport freshBoxes currentSupport) and not (caKSameBoxes firstBoxes freshBoxes))
    local repeat=caKRun f "Preview" repeatMode
    caKCheck "fresh Preview and unchanged repeat boxes, complete solve stats and equal-state work agree" ((caKSameBoxes freshBoxes (caKBoxes setup)) and (caKSameStats fresh[1] repeat[1]) and fresh[3][3][11]==repeat[3][3][11])
    caKCheck "fresh Preview still leaves original real publication and revision intact" ((caSetupSummary setup)[3]==revision and (caKSame before (caKCapture setup) handles:true compositionStats:false))
    caClearGeometryCache setup
    caKRequire "clearing optional geometry preserves the fresh valid Preview" ((caPreviewInfo setup)[2])
    local committed=caKRun f "CommitPreview" coldMode
    caKCheck "cold Commit matches current fresh Preview envelopes/stats" ((caKPreviewMatches freshBoxes committed[2]) and (caKSameStats fresh[1] committed[1]))
    local actualBoxes=for row in committed[2][1] collect #((row[9]+row[10])*0.5,(row[10]-row[9])*0.5,row[5])
    caKCheck "all actual committed full meshes contact the edited newly added support" (caKBoxesOnSupport actualBoxes currentSupport)
    caSetGeometryCacheEnabled true
    caKPair f "current geometry after Preview-only descendant lifecycle"
)
fn caKPreviewOnlyChildDisabled=(caKPreviewOnlyChild reuse:false)

fn caKRecipeAndBrowse=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled true
    local pair=caKPair f "initial recipe state",original=pair[2][2]
    caShowAdvancedArrangeUI setup:setup;caShowAssetUI setup
    setDialogPos caArrangeUI [-10000,-10000];setDialogPos caAssetUI [-10000,-10000]
    local summary=caSetupSummary setup,info=caKInfo setup
    for i=1 to 5 do
    (
        select setup
        caKRequire "actual passive workflow/asset UI refresh" (caArrangeUI.onRefresh() and caAssetUI.onRefresh())
        caGeometryCacheInfo setup
    )
    caKCheck "passive selection/UI/getter neither solves nor touches counters/revision/nodes" ((deepEqual summary (caSetupSummary setup) strictCompare:true) and (deepEqual info (caKInfo setup) strictCompare:true) and (caKSame original (caKCapture setup) handles:true))
    caKRequire "actual Reroll handler succeeds" (caArrangeUI.onGenerate reroll:true)
    caKExpect (caKInfo setup) #hit "Generate"
    local rerolled=caKCapture setup,rerollWork=(caKInfo setup)[3][11]
    -- UI Reroll began with the preceding seed's logical result. This Preview
    -- does not publish: it gives complete result/work from the current state,
    -- matching the previous placements/groups used by the following cold solve.
    local currentContext=caKRun f "Preview" #hit
    caKCheck "current-state Preview preserves the actual UI Reroll's exact publication" (caKSame rerolled currentContext[2] handles:true)
    caClearGeometryCache setup
    local cold=caKRun f "Generate" #cold
    caKCheck "UI Reroll and forced-cold solve share exact seeded result" (caKSame rerolled cold[2])
    caKCheck "Reroll current-state Preview and forced-cold complete results agree" (caKSameStats currentContext[1] cold[1])
    caKCheck "Reroll equal-previous-state Preview and forced-cold solver work agree" (currentContext[3][3][11]==cold[3][3][11])
    caKNote ("UI_REROLL_WORK changedSeed="+(rerollWork as string)+" currentPreview="+(currentContext[3][3][11] as string)+" forcedCold="+(cold[3][3][11] as string))
    caArrangeUI.seedText.text="137"
    caKRequire "actual UI Apply/Generate restores original seed" (caArrangeUI.onGenerate reroll:false)
    caKExpect (caKInfo setup) #hit "Generate"
    caKCheck "UI seed restoration reproduces original complete records" (caKSame original (caKCapture setup))
    destroyDialog caAssetUI;destroyDialog caArrangeUI
    local region=(caRegionRows setup)[1]
    caSetRegionRules setup region[1] "Current authored policy" "Shelf A" 3 1 0.8 false false [0,-1,0]
    caKRun f "Generate" #hit
    caKPair f "current regional semantics, not cached metadata"
    local outsider=box name:"CA_CACHE_UNRELATED" width:30 length:30 height:30 pos:[5000,5000,0]
    outsider.width=50;outsider.pos+=[0,20,0]
    local before=caKCapture setup,rev=(caSetupSummary setup)[3],sequence=(caKInfo setup)[3][12]
    caTick()
    caKCheck "unrelated edits and Manual tick do not solve" ((caSetupSummary setup)[3]==rev and (caKInfo setup)[3][12]==sequence and (caKSame before (caKCapture setup) handles:true))
    caKRun f "Generate" #hit
)
fn caKGeometryChanges=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled true;caKPair f "geometry edit baseline"
    local old=caKBounds f[3][1]
    f[3][1].width+=80
    caKCheck "furniture edit changes independent source geometry" ((caKBounds f[3][1])[2].x>old[2].x+39)
    caKRun f "Generate" #cold;caKPair f "edited furniture"
    f[4].width+=40;f[4].pos+=[0,30,0]
    caKRun f "Generate" #cold;caKPair f "edited independent obstacle"
    old=caKBounds f[3][1]
    f[3][1].objectOffsetPos+=[25,0,0]
    caKCheck "object offset changes actual mesh without relying on node TM" (abs((caKBounds f[3][1])[1].x-old[1].x-25)<0.03)
    caKRun f "Generate" #cold;caKPair f "object-offset capture"
    f[2].transform=scaleMatrix [-1.2,0.9,1.1]
    caKRun f "Generate" #cold;caKPair f "mirrored nonuniform group ObjectTM"
    local extra=box name:"CA_CACHE_ADDED_SUPPORT" width:180 length:220 height:20 pos:[0,0,800]
    attachNodesToGroup #(extra) f[2]
    caKRequire "new support is really inside captured group" ((caKGeometry f[2]).count==3)
    caKRun f "Generate" #cold;caKPair f "new group member"
    -- Max2027 requires detach inputs to be members of an OPEN group.
    -- Restore this owned fixture's prior open state on success or script error.
    local previousOpen=isOpenGroupHead f[2],detachError=undefined
    try
    (
        setGroupOpen f[2] true
        caKRequire "detach fixture really has an open group/member" ((isOpenGroupHead f[2]) and (isOpenGroupMember extra) and extra.parent==f[2])
        detachNodesFromGroup #(extra)
    )
    catch (detachError=getCurrentException() as string)
    setGroupOpen f[2] previousOpen
    if detachError!=undefined do throw detachError
    caKRequire "detached support is really outside captured group" (isValidNode extra and not (isGroupMember extra) and extra.parent!=f[2] and (caKGeometry f[2]).count==2 and (findItem (caKGeometry f[2]) extra)==0)
    caKRun f "Generate" #cold;caKPair f "removed group member"
)
fn caKAssetAndOutput=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled true;caKPair f "asset/output baseline"
    local before=caKCapture setup
    for book in f[5] do (local tm=copy book[1].transform;tm.row3=tm.row3*1.1;book[1].transform=tm)
    -- Conservative furniture/query miss from combined asset subscriptions is
    -- allowed initially; actual asset recapture is mandatory under either path.
    local changed=caKRun f "Generate" #either
    caKCheck "genuine asset edits alter measured output dimensions" (not (caKSame before changed[2]))
    caKPair f "freshly recaptured bound asset geometry"
    local original=caKCapture setup,sequence=(caKInfo setup)[3][12],revision=(caSetupSummary setup)[3]
    local moved=(caOutputRows setup)[1][9]
    moved.pos+=[7,0,0]
    caTick()
    caKCheck "output-only transform remains artist-owned until explicit command" ((caSetupSummary setup)[3]==revision and (caKInfo setup)[3][12]==sequence)
    local repaired=caKRun f "Generate" #hit
    caKCheck "unlocked broken row is regenerated using reusable geometry" (caKSame original repaired[2])
    local victim=(caOutputRows setup)[1][9]
    delete victim
    caKRun f "Generate" #hit
    local groupRow=(caCompositionRows setup)[1]
    caSetLocked setup #(groupRow[4][1]) true
    caKRun f "Generate" #hit
    caKPair f "whole-row locks still validate on both paths"
)
fn caKTimeUnits=
(
    local f=caKFixture()
    caSetGeometryCacheEnabled true;caKPair f "time/unit baseline"
    sliderTime=1f
    caKRun f "Generate" #cold;caKPair f "same-time at a different static frame"
    sliderTime=0f
    caKRun f "Generate" #cold
    local board=f[3][1],start=copy board.pos
    with animate on (at time 0f board.pos=start;at time 10f board.pos=start+[0,0,40])
    caKRun f "Generate" #cold
    local before=caKBounds board
    sliderTime=10f
    caKCheck "relevant animation changes independently measured support height" (abs((caKBounds board)[2].z-before[2].z-40)<0.03)
    caKRun f "Generate" #cold;caKPair f "animated current time"
    units.SystemScale=2
    caKRun f "Generate" #cold;caKPair f "system-unit conversion uses fresh actual mm geometry"
    units.SystemScale=1
    caKRun f "Generate" #cold
)
fn caKHistory=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled true;caKPair f "history baseline"
    local before=caKCapture setup
    undo "Cache fixture width and output successor" on (f[3][1].width+=40;caKRun f "Generate" #cold)
    local after=caKCapture setup
    max undo
    caKCheck "Undo restores complete real previous references and records" (caKSame before (caKCapture setup) handles:true compositionStats:false)
    -- Do not Generate between Undo and Redo: that would destroy the Redo branch.
    max redo
    caKCheck "Redo restores complete real successor references and records" (caKSame after (caKCapture setup) handles:true compositionStats:false)
    local rebuilt=caKRun f "Generate" #cold
    caKCheck "Redo cannot resurrect reusable geometry" (caKSame after rebuilt[2])
    before=caKCapture setup
    undo "Second input successor for independent Undo-cold proof" on (f[3][2].width+=40;caKRun f "Generate" #cold)
    max undo
    rebuilt=caKRun f "Generate" #cold
    caKCheck "Undo independently forces cold without changing restored logical state" (caKSame before rebuilt[2])
)
fn caKLoadedFixture=
(
    local setup=getNodeByName "CA_CACHE_SETUP" exact:true
    local roots=#()
    for i=1 to 3 do append roots (getNodeByName ("CA_CACHE_BOOK_"+(i as string)) exact:true)
    local rows=caAssetRows setup,assets=#()
    for i=1 to rows.count do append assets #(rows[i][1],roots[i])
    #(setup,getNodeByName "CA_CACHE_FURNITURE" exact:true,#(getNodeByName "CA_CACHE_LEFT" exact:true,getNodeByName "CA_CACHE_RIGHT" exact:true),getNodeByName "CA_CACHE_OBSTACLE" exact:true,#(),assets)
)
fn caKLoadClone=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled true;caKPair f "save/load baseline"
    local before=caKCapture setup,guid=(caSetupSummary setup)[1]
    local path=CA_TEST_OUTPUT+"cache-correctness-schema4.max"
    caKRequire "save owned scene" (saveMaxFile path quiet:true)
    caKRequire "load owned scene" (loadMaxFile path quiet:true useFileUnits:true)
    f=caKLoadedFixture();setup=f[1]
    caKCheck "load restores no previous transient cache diagnostic" ((caKInfo setup)[3]==undefined)
    caKCheck "load preserves native identities and real saved geometry" ((caSetupSummary setup)[1]==guid and (caKSame before (caKCapture setup) compositionStats:false))
    local loaded=caKRun f "Generate" #cold
    caKCheck "load first solve is cold with unchanged logical result" (caKSame before loaded[2] compositionStats:false)
    local all=#(setup,f[2],f[4])
    for asset in f[6] do append all asset[2]
    for row in (caOutputRows setup) do append all row[9]
    local originals,copies
    caKRequire "actual zero-offset whole-system clone" (maxOps.cloneNodes all cloneType:#copy expandHierarchy:true actualNodeList:&originals newNodes:&copies)
    local index=findItem originals setup
    caKRequire "clone has remapped owner" (index>0)
    local clone=copies[index],assets=#(),boards=#()
    for asset in f[6] do append assets #(asset[1],copies[findItem originals asset[2]])
    for board in f[3] do append boards copies[findItem originals board]
    local cloneFixture=#(clone,copies[findItem originals f[2]],boards,copies[findItem originals f[4]],#(),assets)
    caKCheck "clone has a distinct native namespace and no inherited cache metrics" ((caSetupSummary clone)[1]!=guid and (caKInfo clone)[3]==undefined)
    local cloned=caKRun cloneFixture "Generate" #cold
    caKCheck "clone cold solve preserves copied ordered records without sharing geometry token" (caKSame loaded[2] cloned[2] compositionStats:false)
    caKCheck "clone solve preserves original system's real output references" (caKSame loaded[2] (caKCapture setup) handles:true compositionStats:false)
)
fn caKFailure=
(
    local f=caKFixture(),setup=f[1]
    caSetGeometryCacheEnabled true;caKPair f "missing source failure baseline"
    local before=caKCapture setup,sequence=(caKInfo setup)[3][12]
    delete f[6][1][2]
    local rejected=false
    caKNote "BEGIN required source deletion failure"
    try (caGenerate setup #()) catch (rejected=true;caKNote ("EXPECTED_FAILURE "+(getCurrentException() as string)))
    local info=caKInfo setup
    caKCheck "cache cannot conceal missing required asset source" rejected
    caKCheck "failed successor records a fresh unsuccessful diagnostic" (info[3]!=undefined and info[3][12]>sequence and not info[3][4] and not info[3][5])
    caKCheck "missing-source failure retains real previous nodes/groups/poses" (caKSame before (caKCapture setup) handles:true compositionStats:false)
)

fn caKBootstrap=
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Runner-owned project/output paths required."
    if (maxVersion())[1]!=29000 do throw "Cache host checks require Max2027 only."
    caKRequire "native cache diagnostic/dependency/toggle/clear API exists" (caGeometryCacheInfo!=undefined and caGeometryDependencyInfo!=undefined and caClearGeometryCache!=undefined and caClearAllGeometryCaches!=undefined and caSetGeometryCacheEnabled!=undefined and caGeometryCacheEnabled!=undefined)
    CA_AUTO_SHOW_UI=false
    fileIn (CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    fileIn (CA_TEST_ROOT+"tests/max/cache_observer_roles.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeAssets.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeWorkflow.ms")
    caKOriginalEnabled=caGeometryCacheEnabled()
    caKRequire "fresh host defaults validated geometry reuse on" caKOriginalEnabled
    caKCase "disabled baseline / enabled cold-hit / explicit clear" caKDisabledAndHit
    caKRequire "disabled observer preconditions passed before remaining hit cases" caKObserverProven
    caKCase "first Preview / hit Preview / clear-valid-preview / cold Commit" caKPreviewCase
    caKCase "Preview-only new child remains observed while reuse is disabled" caKPreviewOnlyChildDisabled
    caKCase "Preview-only newly discovered child remains observed outside commands" caKPreviewOnlyChild
    caKCase "Preview-only asset descendant, reuse enabled" caOLAssetEnabled
    caKCase "Preview-only asset descendant, reuse disabled" caOLAssetDisabled
    caKCase "Preview-only obstacle descendant, reuse enabled" caOLObstacleEnabled
    caKCase "Preview-only obstacle descendant, reuse disabled" caOLObstacleDisabled
    caKCase "removed descendant current-membership refresh, reuse enabled" caOLRemovedEnabled
    caKCase "removed descendant current-membership refresh, reuse disabled" caOLRemovedDisabled
    caKCase "actual recipe UI reroll / passive UI / current policies / unrelated input" caKRecipeAndBrowse
    caKCase "real furniture/obstacle/ObjectTM/object-offset/hierarchy changes" caKGeometryChanges
    caKCase "asset recapture / owned output edits/deletion / complete locks" caKAssetAndOutput
    caKCase "static time / relevant animation / physical system units" caKTimeUnits
    caKCase "Undo and Redo invalidate outside restored history" caKHistory
    caKCase "load and full clone never inherit transient cache identity" caKLoadClone
    caKCase "required-source failure cannot use stale cached assets" caKFailure
)
try (caKBootstrap()) catch
(
    caKFailures+=1;caKNote ("EXCEPTION bootstrap: "+(getCurrentException() as string))
    caKNote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
try (destroyDialog caAssetUI) catch ()
try (destroyDialog caArrangeUI) catch ()
if caKOriginalEnabled!=undefined do try (caClearAllGeometryCaches();caSetGeometryCacheEnabled caKOriginalEnabled) catch (caKFailures+=1;caKNote ("EXCEPTION cleanup: "+(getCurrentException() as string)))
caKFinished=true
caKWrite()
