/* Candidate boundary harness. Runtime qualification pending. Disposable Max2027 only.
   Root-controlled isolated runner only. No autorunning harness is fileIn'd. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caCreateBookRowFixtures, caBRWorldGeometryBounds
global caCreateSetup, caSetupSummary, caSetArrangeSettings, caCategoryRules, caSetCategoryRules
global caRegisterAsset, caAssetRows, caSetAssetBookRow, caSetCompositionSettings, caCompositionRows, caCompositionStats
global caAnalyzeSetup, caRegionRows, caSetCollisionScope, caGenerate, caOutputRows, caTick
global caGeometryCacheInfo, caGeometryDependencyInfo, caGeometryCacheEnabled, caSetGeometryCacheEnabled
global caInspect, caRegion
global caClearGeometryCache, caClearAllGeometryCaches
global caBoundaryLog=#(), caBoundaryPasses=0, caBoundaryFailures=0, caBoundaryFinished=false, caBoundaryOriginalEnabled=undefined
global caBoundaryWrite, caBoundaryNote, caBoundaryCheck, caBoundaryRequire, caBoundaryCase, caBoundaryFind, caBoundaryMM, caBoundaryGeometry, caBoundaryBounds
global caBoundaryInteger, caBoundaryDependency, caBoundaryInfo, caBoundaryExpect, caBoundaryCapture, caBoundarySamePoses, caBoundarySameGroups, caBoundarySameStats, caBoundarySameRegions, caBoundarySame
global caBoundaryBake, caBoundaryMoved, caBoundaryTag, caBoundaryFixture, caBoundaryWarp, caBoundaryPhysical, caBoundaryRun, caBoundaryAfterEdit
global caBoundaryWSM, caBoundaryTopology, caBoundaryFullClone, caBoundaryMerge, caBoundaryOwnerDelete, caBoundaryFromNodes, caBoundaryDisjoint, caBoundaryBootstrap
global caBoundaryOwnerAttribute, caBoundaryPlainOutputs, caBoundaryDetachedLive
global caPreview, caBoundaryDocumentValue, caBoundaryNativeCycle, caBoundaryOwnerHierarchy

global caBoundaryBakeControls
global caBoundaryMatrixEqual, caBoundaryClassIDEqual, caBoundaryClassIDControls, caBoundaryWarpBasis, caBoundaryWarpLog

fn caBoundaryMatrixEqual a b=
(
    local first=#(a.row1,a.row2,a.row3,a.row4),second=#(b.row1,b.row2,b.row3,b.row4),same=true
    for row=1 to 4 while same do for axis=1 to 3 while same do
        if first[row][axis]!=second[row][axis] do same=false
    same
)

fn caBoundaryWrite =
(
    if CA_TEST_OUTPUT != undefined do
    (
        local out=createFile (CA_TEST_OUTPUT+"result.txt")
        format "% passes=% failures=%\n" (if caBoundaryFinished then (if caBoundaryFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caBoundaryPasses caBoundaryFailures to:out
        for line in caBoundaryLog do format "%\n" line to:out
        flush out;close out
    )
    true
)
fn caBoundaryNote value=(append caBoundaryLog value;caBoundaryWrite();true)
fn caBoundaryCheck label value=(if value then (caBoundaryPasses+=1;caBoundaryNote ("PASS "+label)) else (caBoundaryFailures+=1;caBoundaryNote ("FAIL "+label));value)
fn caBoundaryRequire label value=(caBoundaryCheck label value;if not value do throw ("Prerequisite: "+label);true)
fn caBoundaryCase label action=
(
    caBoundaryNote ("STAGE "+label)
    try (action()) catch
    (
        caBoundaryFailures+=1
        caBoundaryNote ("EXCEPTION "+label+": "+(getCurrentException() as string))
        caBoundaryNote ("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
        caBoundaryNote ("STACK "+(getCurrentExceptionStackTrace() as string))
    )
)
fn caBoundaryFind rows id=(local found=undefined;for row in rows while found==undefined do if row[1]==id do found=row;found)
fn caBoundaryMM = (1.0/(units.decodeValue "1mm"))
fn caBoundaryGeometry root=
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
fn caBoundaryBounds node=(local b=nodeGetBoundingBox node (matrix3 1),factor=caBoundaryMM();#(b[1]*factor,b[2]*factor))

-- Only this adapter knows the proposed schema. Missing diagnostics are a failure.
-- Totals are GLOBAL; they are never treated as per-document freshness proof.
fn caBoundaryInteger value=((classOf value)==Integer or (classOf value)==Integer64)
fn caBoundaryDependency setup=
(
    local value=caGeometryDependencyInfo setup
    if value.count!=5 or value[1]!=1 or not value[5] do throw "Unexpected/nonreusable dependency ticket."
    for i=2 to 4 do if not (caBoundaryInteger value[i]) or value[i]<=0 do throw "Dependency ticket requires exact positive integer identities."
    value
)
fn caBoundaryInfo setup=
(
    local value=caGeometryCacheInfo setup
    if value.count!=5 or value[1]!=1 or value[4].count!=8 or value[5].count!=12 do throw "Unexpected cache schema1 diagnostics."
    if value[3]!=undefined do
    (
        if value[3].count!=12 do throw "Unexpected cache last-command shape."
        for i=7 to 12 do if not (caBoundaryInteger value[3][i]) or value[3][i]<0 do throw "Cache work/sequence must use exact nonnegative native integers."
    )
    if value[4][3].count!=4 or value[4][4].count!=4 do throw "Unexpected global cache footprint shape."
    for i in #(1,2,5,6,7,8) do if not (caBoundaryInteger value[4][i]) or value[4][i]<0 do throw "Cache totals must use exact nonnegative native integers."
    for row in #(value[4][3],value[4][4]) do for n in row do if not (caBoundaryInteger n) or n<0 do throw "Cache footprint must use exact nonnegative native integers."
    local names=#("lookupStamp","furnitureCapture","inspect","registryBind","obstacleCapture","queryBuild","assetRefresh","solve","visualCapture","publish","finalValidate","total")
    for i=1 to names.count do
        if value[5][i].count!=2 or value[5][i][1]!=names[i] or not (caBoundaryInteger value[5][i][2]) or value[5][i][2]<0 do throw "Unexpected native phase name/order/exact integer value."
    if value[4][3][1]>4 or value[4][3][2]>268435456 or value[4][3][3]>1000000 or value[4][3][4]>1000000 do throw "Global retained-entry accounting exceeded agreed cap."
    value
)
fn caBoundaryExpect info mode operation=
(
    local last=info[3]
    caBoundaryRequire (operation+": native last-command diagnostics exist") (last!=undefined)
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
    caBoundaryCheck (operation+": native diagnostic disposition/work is "+(mode as string)) valid
    caBoundaryNote ("CACHE "+(info as string))
    valid
)

-- Full real poses, mesh bounds and TM rows. Node handles compare only where
-- publication is forbidden; successful Generate may replace all output nodes.
fn caBoundaryCapture setup=
(
    local poses=#(),factor=caBoundaryMM()
    for row in (caOutputRows setup) do
    (
        if row.count!=9 or not isValidNode row[9] do throw "Missing/invalid real output binding."
        local bounds=caBoundaryBounds row[9],tm=row[9].transform
        append poses #(row[1],row[2],row[3],copy row[4],row[5],row[6],row[7],row[8],bounds[1],bounds[2],copy tm.row1,copy tm.row2,copy tm.row3,(copy tm.row4)*factor,getHandleByAnim row[9])
    )
    #(poses,caCompositionRows setup,caRegionRows setup,caCompositionStats setup)
)
fn caBoundarySamePoses first second handles:false=
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
fn caBoundarySameGroups first second=
(
    -- Entire native records: ordered membership IDs, front and gap included.
    deepEqual first second strictCompare:true
)
fn caBoundarySameStats a b=
(
    a.count==6 and b.count==6 and (deepEqual a b strictCompare:true)
)
fn caBoundarySameRegions first second=
(
    local same=first.count==second.count
    for a in first while same do
    (
        local b=caBoundaryFind second a[1]
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
fn caBoundarySame a b handles:false compositionStats:true=
(
    (caBoundarySamePoses a[1] b[1] handles:handles) and (caBoundarySameGroups a[2] b[2]) and (caBoundarySameRegions a[3] b[3]) and
    (not compositionStats or (deepEqual #(a[4]) #(b[4]) strictCompare:true))
)

-- Direct snapshotAsMesh evaluates source geometry including WSM and stores
-- independent WORLD vertices. No scene snapshot node is created or deleted.
-- Raw meshop.getVert on the Mesh VALUE without node: reads those stored values;
-- only convert system units to mm. Optional setup enables passive-state guards.
-- Returns #(worldMinMM,worldMaxMM,worldVerticesMM,triangleCount,flatTopBounds).
fn caBoundaryBake source setup:undefined=
(
    if not isValidNode source do throw "Missing evaluated geometry source."
    local nodesBefore=for node in objects collect getHandleByAnim node
    local prior=if setup!=undefined then #(caBoundaryDependency setup,caSetupSummary setup,caBoundaryInfo setup) else undefined
    local meshValue=undefined,result=undefined,errorText=undefined
    try
    (
        in coordsys world
        (
            meshValue=snapshotAsMesh source renderMesh:false
            if meshValue==undefined do throw "Snapshot did not produce actual evaluated triangle geometry."
            if meshValue.numverts<1 or meshValue.numverts>10000 or meshValue.numfaces>20000 do throw "Disposable evaluated mesh exceeds fixture bound."
            local factor=caBoundaryMM(),points=#(),lower=[1e30,1e30,1e30],upper=[-1e30,-1e30,-1e30]
            for i=1 to meshValue.numverts do
            (
                local p=(meshop.getVert meshValue i)*factor
                append points p
                for axis=1 to 3 do (lower[axis]=amin #(lower[axis],p[axis]);upper[axis]=amax #(upper[axis],p[axis]))
            )
            local topLower=[1e30,1e30,1e30],topUpper=[-1e30,-1e30,-1e30],topCount=0
            for p in points where abs(p.z-upper.z)<0.01 do
            (
                topCount+=1
                for axis=1 to 3 do (topLower[axis]=amin #(topLower[axis],p[axis]);topUpper[axis]=amax #(topUpper[axis],p[axis]))
            )
            if topCount<4 or topUpper.x-topLower.x<0.1 or topUpper.y-topLower.y<0.1 do throw "Fixture no longer has the required flat rectangular top."
            result=#(lower,upper,points,meshValue.numfaces,#(topLower,topUpper))
        )
    )
    catch (errorText=getCurrentException() as string)
    if meshValue!=undefined do delete meshValue
    local nodesAfter=for node in objects collect getHandleByAnim node
    caBoundaryRequire "read-only geometry oracle creates/deletes no scene nodes" (deepEqual nodesBefore nodesAfter strictCompare:true)
    if setup!=undefined do
    (
        local after=#(caBoundaryDependency setup,caSetupSummary setup,caBoundaryInfo setup)
        caBoundaryRequire "read-only geometry oracle preserves complete dependency ticket" (deepEqual prior[1] after[1] strictCompare:true)
        caBoundaryRequire "read-only geometry oracle preserves revision/dirty/Live and complete authored summary" (deepEqual prior[2] after[2] strictCompare:true)
        caBoundaryRequire "read-only geometry oracle preserves native cache diagnostics and retained accounting" (deepEqual prior[3] after[3] strictCompare:true)
    )
    if errorText!=undefined do throw errorText
    result
)
fn caBoundaryMoved before after delta=
(
    local same=before[3].count==after[3].count and before[4]==after[4]
    if same do for i=1 to before[3].count while same do if distance (before[3][i]+delta) after[3][i]>0.03 do same=false
    same
)
fn caBoundaryTag node prefix role=(setUserProp node "CA_CacheBoundaryRole" (prefix+":"+role);node)

-- #(setup,furnitureGroup,board,obstacle,bookRows,#(#(assetID,sourceRoot),...),#(warps),prefix)
fn caBoundaryFixture reset:true prefix:"A" offset:[0,0,0]=
(
    if reset do resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0f
    local books=(caCreateBookRowFixtures includeFurniture:false)[1]
    local board=box name:("CA_BOUND_"+prefix+"_BOARD") width:700 length:350 height:30 widthsegs:1 lengthsegs:1 heightsegs:1 pos:(offset+[0,0,500])
    local furniture=group #(board) name:("CA_BOUND_"+prefix+"_FURNITURE")
    furniture.pivot=offset
    local obstacle=box name:("CA_BOUND_"+prefix+"_OBSTACLE") width:80 length:80 height:250 pos:(offset+[240,80,530])
    local setup=caCreateSetup #(furniture) 1
    setup.name="CA_BOUND_"+prefix+"_SETUP"
    caBoundaryTag setup prefix "Setup";caBoundaryTag furniture prefix "Furniture";caBoundaryTag board prefix "Board";caBoundaryTag obstacle prefix "Obstacle"
    local assets=#()
    for i=1 to books.count do
    (
        books[i][1].name="CA_BOUND_"+prefix+"_BOOK_"+(i as string)
        caBoundaryTag books[i][1] prefix ("Book"+(i as string))
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
    local physical=caBoundaryBake board setup:setup
    caBoundaryRequire "independent baked box has exact analytic millimetre world bounds" (distance physical[1] (offset+[-350,-175,500])<0.003 and distance physical[2] (offset+[350,175,530])<0.003)
    caAnalyzeSetup setup
    #(setup,furniture,board,obstacle,books,assets,#(),prefix)
)
fn caBoundaryWarp fixture source role strength rotationValue=
(
    local warp=spaceDisplace name:("CA_BOUND_"+fixture[8]+"_"+role) strength:strength decay:0 maptype:0 width:10000 length:10000 height:10000 pos:[0,0,0]
    warp.lumCenterEnable=false
    if (classOf rotationValue)==Matrix3 then
        in coordsys world (warp.transform=rotationValue)
    else warp.rotation=rotationValue
    caBoundaryTag warp fixture[8] role
    bindSpaceWarp source warp
    append fixture[7] warp
    warp
)

-- SDK dispmod.cpp: planar normal is local+Z, transformed by the warp frame.
-- Explicit basis avoids assuming the sign of an Euler-to-controller conversion.
fn caBoundaryWarpBasis warp=
(
    local tm=warp.objectTransform,tolerance=0.00001
    distance tm.row1 [0,0,-1]<tolerance and distance tm.row2 [0,1,0]<tolerance and distance tm.row3 [1,0,0]<tolerance and distance tm.row4 [0,0,0]<tolerance and (dot (cross tm.row1 tm.row2) tm.row3)>0.99999
)
fn caBoundaryWarpLog label warp source before after expected=
(
    local limit=amin #(before[3].count,after[3].count,16)
    local deltas=for i=1 to limit collect (after[3][i]-before[3][i])
    caBoundaryNote ("WARP_DIAGNOSTIC "+label+" strength="+(warp.strength as string)+" mapType="+(warp.mapType as string)+" decay="+(warp.decay as string)+" expected="+(expected as string)+" before="+(before[1] as string)+","+(before[2] as string)+" after="+(after[1] as string)+","+(after[2] as string)+" vertices="+(before[3].count as string)+","+(after[3].count as string)+" first16Deltas="+(deltas as string))
    caBoundaryNote ("WARP_FRAME "+label+" NodeTM="+(warp.transform as string)+" ObjectTM="+(warp.objectTransform as string)+" sourceNodeTM="+(source.transform as string))
)

-- This oracle is valid for these axis-aligned uniformly displaced fixtures only.
-- It uses every modeled output's actual world bounds and the baked support top,
-- plus the actual baked obstacle; it never copies the native region AABB.
fn caBoundaryPhysical fixture state=
(
    local support=caBoundaryBake fixture[3] setup:fixture[1],obstacle=caBoundaryBake fixture[4] setup:fixture[1]
    local top=support[5],sizes=#(),valid=state[1].count>0
    for asset in fixture[6] do
    (
        local bounds=caBRWorldGeometryBounds asset[2]
        append sizes #(asset[1],(bounds[2]-bounds[1])*caBoundaryMM())
    )
    for row in state[1] do
    (
        local asset=caBoundaryFind sizes row[2]
        if asset==undefined then valid=false else if distance (row[10]-row[9]) (asset[2]*row[6])>0.03 do valid=false
        if abs(row[9].z-top[2].z)>0.03 or row[9].x<top[1].x-0.03 or row[10].x>top[2].x+0.03 or row[9].y<top[1].y-0.03 or row[10].y>top[2].y+0.03 do valid=false
        if row[5]!=0 or row[6]!=1 do valid=false
        if (amin #(row[10].x,obstacle[2].x)-amax #(row[9].x,obstacle[1].x))>0.03 and (amin #(row[10].y,obstacle[2].y)-amax #(row[9].y,obstacle[1].y))>0.03 and (amin #(row[10].z,obstacle[2].z)-amax #(row[9].z,obstacle[1].z))>0.03 do valid=false
    )
    for i=1 to state[1].count do for j=i+1 to state[1].count do
    (
        local a=state[1][i],b=state[1][j]
        if (amin #(a[10].x,b[10].x)-amax #(a[9].x,b[9].x))>0.03 and (amin #(a[10].y,b[10].y)-amax #(a[9].y,b[9].y))>0.03 and (amin #(a[10].z,b[10].z)-amax #(a[9].z,b[9].z))>0.03 do valid=false
    )
    caBoundaryCheck "actual outputs retain physical source dimensions and contact the evaluated support without overlaps" valid
    valid
)
fn caBoundaryRun fixture mode requireRows:false=
(
    caBoundaryNote ("BEGIN Generate "+fixture[8]+" expected="+(mode as string))
    local result=caGenerate fixture[1] #(),info=caBoundaryInfo fixture[1],state=caBoundaryCapture fixture[1]
    caBoundaryExpect info mode "generate"
    caBoundaryPhysical fixture state
    caBoundaryRequire "fixture produces real outputs" (state[1].count>0)
    if requireRows do caBoundaryRequire "unmodified baseline produces native book-row relationships" (state[2].count>0)
    #(result,state,info)
)
fn caBoundaryAfterEdit fixture label=
(
    caBoundaryNote ("PAIR "+label)
    -- Do not clear before the first command: its miss must come from the input
    -- change. Then compare against a separately forced cold command and a hit.
    -- Independent inspector regression for both supported source roles. These
    -- calls publish only the standalone inspector snapshot, never scene output.
    for source in #(fixture[3],fixture[4]) do
    (
        local world=caBoundaryBake source setup:fixture[1]
        local inspected=caInspect #(source) 25 0 5
        caBoundaryRequire (label+": standalone inspector matches actual world mesh bounds and triangle count for "+source.name) (inspected.count==16 and inspected[3]==world[4] and distance inspected[9] world[1]<0.003 and distance inspected[10] world[2]<0.003)
    )
    local changed=caBoundaryRun fixture #cold
    caClearGeometryCache fixture[1]
    local forced=caBoundaryRun fixture #cold,hit=caBoundaryRun fixture #hit
    caBoundaryCheck (label+": changed/forced-cold/hit native poses and groups are exact") ((caBoundarySame changed[2] forced[2]) and (caBoundarySame forced[2] hit[2]))
    caBoundaryCheck (label+": targets candidates and warnings match changed/forced-cold/hit") ((caBoundarySameStats changed[1] forced[1]) and (caBoundarySameStats forced[1] hit[1]))
    -- The changed command validates the previous logical placements/groups.
    -- Only forced/hit begin with the same already-published logical state.
    caBoundaryCheck (label+": identical-state forced-cold/hit solver work matches") (forced[3][3][11]==hit[3][3][11])
    caBoundaryNote ("SOLVER_WORK changed="+(changed[3][3][11] as string)+" forced="+(forced[3][3][11] as string)+" hit="+(hit[3][3][11] as string))
    #(changed,forced,hit)
)

fn caBoundaryWSM=
(
    local f=caBoundaryFixture(),base=caBoundaryBake f[3] setup:f[1],nodeTM=copy f[3].transform
    caClearAllGeometryCaches();caBoundaryRun f #cold requireRows:true;caBoundaryRun f #hit requireRows:true
    local warp=caBoundaryWarp f f[3] "FurnitureWarp" 40 (quat 0 0 0 1)
    local raised=caBoundaryBake f[3] setup:f[1]
    caBoundaryRequire "real planar WSM moves every board vertex +40mm in Z while preserving NodeTM" ((caBoundaryMoved base raised [0,0,40]) and (caBoundaryMatrixEqual f[3].transform nodeTM))
    caBoundaryNote ("WSM_GEOMETRY base="+(base[1] as string)+","+(base[2] as string)+" raised="+(raised[1] as string)+","+(raised[2] as string)+" NodeTM="+(nodeTM as string)+" ObjectTM="+(f[3].objectTransform as string))
    caBoundaryAfterEdit f "bind actual furniture space warp"
    warp.strength=80
    caBoundaryRequire "editing only the warp strength changes evaluated vertices" (caBoundaryMoved raised (caBoundaryBake f[3] setup:f[1]) [0,0,40])
    caBoundaryAfterEdit f "furniture warp parameter change"
    local beforeRotation=caBoundaryBake f[3] setup:f[1],beforeWarpTM=copy warp.objectTransform
    in coordsys world (warp.transform=matrix3 [0,0,-1] [0,1,0] [1,0,0] [0,0,0])
    local rotated=caBoundaryBake f[3] setup:f[1]
    caBoundaryNote ("WARP_EDIT furniture beforeWarpTM="+(beforeWarpTM as string)+" afterWarpTM="+(warp.objectTransform as string)+" beforeEditBounds="+(beforeRotation[1] as string)+","+(beforeRotation[2] as string))
    caBoundaryWarpLog "furniture explicit+X" warp f[3] base rotated [80,0,0]
    caBoundaryRequire "furniture warp has the explicit right-handed local+Z-to-world+X basis" (caBoundaryWarpBasis warp)
    caBoundaryRequire "editing only the warp transform moves evaluated mesh along rotated world normal" ((caBoundaryMoved base rotated [80,0,0]) and (caBoundaryMatrixEqual f[3].transform nodeTM))
    caBoundaryAfterEdit f "furniture warp transform change"
    local oldObstacle=caBoundaryBake f[4] setup:f[1]
    local obstacleWarp=caBoundaryWarp f f[4] "ObstacleWarp" 60 (matrix3 [0,0,-1] [0,1,0] [1,0,0] [0,0,0])
    local movedObstacle=caBoundaryBake f[4] setup:f[1]
    caBoundaryWarpLog "obstacle initial explicit+X" obstacleWarp f[4] oldObstacle movedObstacle [60,0,0]
    caBoundaryRequire "obstacle warp has the explicit right-handed local+Z-to-world+X basis" (caBoundaryWarpBasis obstacleWarp)
    caBoundaryRequire "bound explicit obstacle has a real evaluated +60mm X deformation" (caBoundaryMoved oldObstacle movedObstacle [60,0,0])
    caBoundaryAfterEdit f "obstacle WSM bind"
    obstacleWarp.strength = -100
    local negativeObstacle=caBoundaryBake f[4] setup:f[1]
    caBoundaryWarpLog "obstacle negative strength" obstacleWarp f[4] oldObstacle negativeObstacle [-100,0,0]
    caBoundaryRequire "editing only obstacle warp changes real collision geometry" (caBoundaryMoved oldObstacle negativeObstacle [-100,0,0])
    caBoundaryAfterEdit f "obstacle warp parameter change"
    local beforeUnbind=caBoundaryBake f[3] setup:f[1]
    caBoundaryRequire "binding is represented by a real source stack entry" (f[3].modifiers.count==1)
    deleteModifier f[3] 1
    caBoundaryRequire "unbinding restores actual original furniture mesh" ((caBoundaryMoved base (caBoundaryBake f[3] setup:f[1]) [0,0,0]) and not (caBoundaryMoved beforeUnbind (caBoundaryBake f[3] setup:f[1]) [0,0,0]))
    caBoundaryAfterEdit f "remove actual WSM binding"
)

fn caBoundaryTopology=
(
    local f=caBoundaryFixture(),before=caBoundaryBake f[3] setup:f[1],nodeTM=copy f[3].transform
    caClearAllGeometryCaches();caBoundaryRun f #cold requireRows:true;caBoundaryRun f #hit requireRows:true
    f[3].baseObject.widthsegs=4;f[3].baseObject.lengthsegs=3
    local divided=caBoundaryBake f[3] setup:f[1]
    caBoundaryRequire "retessellation changes actual face count with unchanged independent support bounds" (divided[4]>before[4] and distance divided[1] before[1]<0.003 and distance divided[2] before[2]<0.003)
    caBoundaryAfterEdit f "primitive topology change"
    local modifierValue=xform()
    addModifier f[3] modifierValue
    modifierValue.gizmo.position=[0,0,25]
    caBoundaryRequire "OSM gizmo shifts every actual mesh vertex while NodeTM stays fixed" ((caBoundaryMoved divided (caBoundaryBake f[3] setup:f[1]) [0,0,25]) and (caBoundaryMatrixEqual f[3].transform nodeTM))
    caBoundaryAfterEdit f "new object-space modifier and deformation"
    local first=caBoundaryBake f[3] setup:f[1]
    modifierValue.gizmo.position=[0,0,65]
    caBoundaryRequire "existing modifier parameter has a real +40mm geometry change" (caBoundaryMoved first (caBoundaryBake f[3] setup:f[1]) [0,0,40])
    caBoundaryAfterEdit f "existing object-space modifier parameter change"
    deleteModifier f[3] modifierValue
    caBoundaryRequire "removing OSM restores actual retessellated source mesh" (caBoundaryMoved divided (caBoundaryBake f[3] setup:f[1]) [0,0,0])
    caBoundaryAfterEdit f "object-space modifier removal"
)

fn caBoundaryFromNodes nodes prefix=
(
    local roles=#("Setup","Furniture","Board","Obstacle","Book1","Book2","Book3"),found=#()
    for role in roles do
    (
        local matches=for node in nodes where isValidNode node and (getUserProp node "CA_CacheBoundaryRole")==(prefix+":"+role) collect node
        if matches.count!=1 do throw ("Expected exactly one remapped fixture role: "+role)
        append found matches[1]
    )
    local rows=caAssetRows found[1],assets=#(),warps=#()
    if rows.count!=3 do throw "Expected three remapped native assets."
    for i=1 to 3 do append assets #(rows[i][1],found[i+4])
    for node in nodes where isValidNode node do
        if (getUserProp node "CA_CacheBoundaryRole")==prefix+":FurnitureWarp" or (getUserProp node "CA_CacheBoundaryRole")==prefix+":ObstacleWarp" do append warps node
    #(found[1],found[2],found[3],found[4],#(),assets,warps,prefix)
)
fn caBoundaryDisjoint a b=
(
    local same=true
    for first in (caOutputRows a) do for second in (caOutputRows b) where first[9]==second[9] do same=false
    same
)
fn caBoundaryFullClone=
(
    local f=caBoundaryFixture(),base=caBoundaryBake f[3] setup:f[1]
    local warp=caBoundaryWarp f f[3] "FurnitureWarp" 40 (quat 0 0 0 1)
    caBoundaryRequire "whole-clone fixture has a real WSM deformation" (caBoundaryMoved base (caBoundaryBake f[3] setup:f[1]) [0,0,40])
    caClearAllGeometryCaches();caBoundaryRun f #cold
    local original=caBoundaryRun f #hit,ticket=caBoundaryDependency f[1],all=#(f[1],f[2],f[4],warp)
    for asset in f[6] do append all asset[2]
    for row in caOutputRows f[1] do append all row[9]
    local originals,copies
    caBoundaryRequire "real full system clone includes the bound space-warp node" (maxOps.cloneNodes all cloneType:#copy expandHierarchy:true actualNodeList:&originals newNodes:&copies)
    local cloned=caBoundaryFromNodes copies f[8],cloneTicket=caBoundaryDependency cloned[1]
    caBoundaryRequire "clone owns a new transient native instance, namespace and empty diagnostics" (cloneTicket[2]!=ticket[2] and (caSetupSummary cloned[1])[1]!=(caSetupSummary f[1])[1] and (caBoundaryInfo cloned[1])[3]==undefined)
    caBoundaryRequire "clone includes a distinct copied warp dependency" (cloned[7].count==1 and cloned[7][1]!=warp)
    caBoundaryCheck "clone initially retains copied real output records and remapped nodes" ((caBoundarySame original[2] (caBoundaryCapture cloned[1]) compositionStats:false) and (caBoundaryDisjoint f[1] cloned[1]))
    local cloneCold=caBoundaryRun cloned #cold,cloneHit=caBoundaryRun cloned #hit
    caBoundaryCheck "WSM clone cold/hit are exact and equal the original logical result" ((caBoundarySame cloneCold[2] cloneHit[2]) and (caBoundarySame original[2] cloneCold[2] compositionStats:false))
    cloned[7][1].strength=90
    caBoundaryRequire "copied warp changes only copied evaluated source geometry" ((caBoundaryMoved base (caBoundaryBake cloned[3] setup:cloned[1]) [0,0,90]) and (caBoundaryMoved base (caBoundaryBake f[3] setup:f[1]) [0,0,40]))
    caBoundaryAfterEdit cloned "cloned WSM dependency edit"
    caBoundaryCheck "cloned warp edit/publication preserves all original real output bindings" (caBoundarySame original[2] (caBoundaryCapture f[1]) handles:true)
    caBoundaryRun f #hit
)

fn caBoundaryMerge=
(
    local f=caBoundaryFixture(),warp=caBoundaryWarp f f[3] "FurnitureWarp" 40 (quat 0 0 0 1)
    caClearAllGeometryCaches();caBoundaryRun f #cold
    local original=caBoundaryRun f #hit,ticket=caBoundaryDependency f[1],path=CA_TEST_OUTPUT+"cache-boundaries-merge.max"
    caBoundaryRequire "save owned WSM scene for actual merge" (saveMaxFile path quiet:true useNewFile:false)
    local mergedNodes=#()
    caBoundaryRequire "merge actual complete scene without replacing existing owner" (mergeMAXFile path #autoRenameDups #renameMtlDups #neverReparent quiet:true mergedNodes:&mergedNodes)
    caBoundaryRequire "merge reports real incoming nodes" (mergedNodes.count>0)
    local merged=caBoundaryFromNodes mergedNodes f[8],mergedTicket=caBoundaryDependency merged[1],existingTicket=caBoundaryDependency f[1]
    caBoundaryCheck "merge advances global scene epoch for the preexisting owner" (existingTicket[3]!=ticket[3])
    caBoundaryRequire "merge allocates a distinct transient instance and leaves no serialized cache diagnostic" (mergedTicket[2]!=ticket[2] and (caBoundaryInfo merged[1])[3]==undefined)
    caBoundaryCheck "duplicate saved namespace is resolved and imported output references are disjoint" ((caSetupSummary merged[1])[1]!=(caSetupSummary f[1])[1] and (caBoundaryDisjoint f[1] merged[1]))
    caBoundaryCheck "merged native ordered records and real copied geometry are retained before update" (caBoundarySame original[2] (caBoundaryCapture merged[1]) compositionStats:false)
    local mergedCold=caBoundaryRun merged #cold,mergedHit=caBoundaryRun merged #hit
    caBoundaryCheck "merged owner first cold and next hit preserve saved exact logical poses and groups" ((caBoundarySame mergedCold[2] mergedHit[2]) and (caBoundarySame original[2] mergedCold[2] compositionStats:false))
    caBoundaryCheck "merged solve never replaces the preexisting owner's nodes" (caBoundarySame original[2] (caBoundaryCapture f[1]) handles:true)
    local existingCold=caBoundaryRun f #cold
    caBoundaryCheck "preexisting owner cannot reuse geometry across merge scene epoch" (caBoundarySame original[2] existingCold[2])
    caBoundaryRun f #hit
    local sourceBefore=caBoundaryBake f[3] setup:f[1],incomingBefore=caBoundaryBake merged[3] setup:merged[1]
    caBoundaryRequire "merged scene retains an independent bound warp" (merged[7].count==1 and merged[7][1]!=warp)
    merged[7][1].strength=75
    caBoundaryRequire "merged warp only deforms the merged input" ((caBoundaryMoved incomingBefore (caBoundaryBake merged[3] setup:merged[1]) [0,0,35]) and (caBoundaryMoved sourceBefore (caBoundaryBake f[3] setup:f[1]) [0,0,0]))
    caBoundaryAfterEdit merged "merged WSM dependency edit"
    caBoundaryRun f #hit
)

fn caBoundaryOwnerDelete=
(
    local victim=caBoundaryFixture prefix:"Victim",control=caBoundaryFixture reset:false prefix:"Control" offset:[2000,0,0]
    caClearAllGeometryCaches();caBoundaryRun victim #cold;caBoundaryRun control #cold
    local previous=caBoundaryRun victim #hit,controlPrevious=caBoundaryRun control #hit
    local oldTicket=caBoundaryDependency victim[1],oldNodes=for row in caOutputRows victim[1] collect row[9]
    local before=(caBoundaryInfo control[1])[4]
    caBoundaryRequire "exact isolated baseline retains two live entries" (before[1]==2 and before[2]==0 and before[3][1]==2)
    undo "Cache boundary delete owned setup" on (delete victim[1])
    caTick() -- safe main-thread drain, Manual setups; no getter-side drain.
    local after=(caBoundaryInfo control[1])[4],nodesRemain=true
    for node in oldNodes where not isValidNode node do nodesRemain=false
    caBoundaryCheck "owner deletion releases its cached numeric entry even while Undo can retain the document" (after[1]==1 and after[2]==0 and after[3][1]==1 and after[3][2]<before[3][2] and after[5]<before[5])
    caBoundaryCheck "owner deletion retains ordinary output nodes and the other setup's exact bindings" (nodesRemain and (caBoundarySame controlPrevious[2] (caBoundaryCapture control[1]) handles:true))
    caBoundaryNote ("OWNER_RELEASE before="+(before as string)+" after="+(after as string))
    -- No Generate/other Undo-producing command is inserted before this Undo.
    max undo
    victim[1]=getNodeByName "CA_BOUND_Victim_SETUP" exact:true
    caBoundaryRequire "Undo restores deleted owner and previous real bindings" (isValidNode victim[1] and (caBoundarySame previous[2] (caBoundaryCapture victim[1]) handles:true compositionStats:false))
    local restoredTicket=caBoundaryDependency victim[1]
    caBoundaryCheck "Undo cannot restore an old reusable ticket" (restoredTicket[3]!=oldTicket[3] or restoredTicket[4]!=oldTicket[4])
    local restored=caBoundaryRun victim #cold
    caBoundaryCheck "restored owner first cold solve keeps original exact logical poses/groups" (caBoundarySame previous[2] restored[2] compositionStats:false)
    caBoundaryRun victim #hit
    local extra=caCreateSetup #(victim[2]) 1
    caBoundaryCheck "fresh owner never recycles the removed owner's transient instance" ((caBoundaryDependency extra)[2]!=oldTicket[2])
    caClearAllGeometryCaches()
    local cleared=(caBoundaryInfo control[1])[4]
    caBoundaryCheck "explicit final safe clear releases every retained numeric entry and its entry metadata" (cleared[1]==0 and cleared[2]==0 and cleared[3][1]==0 and cleared[3][2]==0 and cleared[5]==0)
)


-- Generic custAttributes virtual arrays include actual native owner CAs; no public
-- ca* detach-setup primitive currently calls host::remove_document.
-- Keep the actual attribute wrapper alive alongside its normal Undo record.
-- Class identity is the exact unsigned32 PartA/PartB pair. The documented
-- MAXWrapper property promises numbers, not a particular MAXScript integer width.
-- Never admit a float via truncation, or substitute an attribute name for its ID.
fn caBoundaryClassIDEqual actual expectedA expectedB label=
(
    caBoundaryNote ("NATIVE_CLASSID "+label+" actual="+(actual as string)+" containerType="+((classOf actual) as string))
    if (classOf actual)!=Array do return false
    if actual.count!=2 do return false
    caBoundaryNote ("NATIVE_CLASSID_TYPES "+label+" partA="+((classOf actual[1]) as string)+" partB="+((classOf actual[2]) as string)+" expectedTypes="+((classOf expectedA) as string)+","+((classOf expectedB) as string))
    if not (caBoundaryInteger actual[1]) or not (caBoundaryInteger actual[2]) do return false
    local first=actual[1] as Integer64,second=actual[2] as Integer64
    if first<0L or first>4294967295L or second<0L or second>4294967295L do return false
    first==(expectedA as Integer64) and second==(expectedB as Integer64)
)
fn caBoundaryClassIDControls=
(
    caBoundaryRequire "class ID oracle accepts exact integral32 components" (caBoundaryClassIDEqual #(0x6a4387d2,0x4fa90372) 0x6a4387d2 0x4fa90372 "control Integer")
    caBoundaryRequire "class ID oracle accepts the same exact integral64 components" (caBoundaryClassIDEqual #((0x6a4387d2 as Integer64),(0x4fa90372 as Integer64)) 0x6a4387d2 0x4fa90372 "control Integer64")
    caBoundaryRequire "class ID oracle rejects a changed PartA" (not (caBoundaryClassIDEqual #(0x6a4387d1,0x4fa90372) 0x6a4387d2 0x4fa90372 "control wrong PartA"))
    caBoundaryRequire "class ID oracle rejects a changed PartB" (not (caBoundaryClassIDEqual #(0x6a4387d2,0x4fa90371) 0x6a4387d2 0x4fa90372 "control wrong PartB"))
    caBoundaryRequire "class ID oracle rejects swapped components" (not (caBoundaryClassIDEqual #(0x4fa90372,0x6a4387d2) 0x6a4387d2 0x4fa90372 "control swapped"))
    caBoundaryRequire "class ID oracle rejects lossy float coercion" (not (caBoundaryClassIDEqual #((0x6a4387d2 as Float),0x4fa90372) 0x6a4387d2 0x4fa90372 "control float"))
    caBoundaryRequire "class ID oracle rejects a non-pair" (not (caBoundaryClassIDEqual #(0x6a4387d2,0x4fa90372,0) 0x6a4387d2 0x4fa90372 "control count"))
)
fn caBoundaryOwnerAttribute setup=
(
    local attributesValue=setup.custAttributes
    caBoundaryRequire "native owner collection belongs to the actual setup node" (attributesValue.owner==setup)
    local count=attributesValue.count,found=undefined
    if count<1 or count>32 do throw "Unexpected owned fixture's node-level custom attributes."
    for i=1 to count do
    (
        local attributeValue=attributesValue[i]
        if caBoundaryClassIDEqual attributeValue.classID 0x6a4387d2 0x4fa90372 ("owner index="+(i as string)) do
        (
            if found!=undefined do throw "Duplicate native Arrange owner attributes."
            found=#(i,attributeValue)
        )
    )
    if found==undefined do throw "Actual native Arrange owner attribute not found."
    found
)
fn caBoundaryPlainOutputs rows=
(
    -- Stored native row metadata is not used as fresh detached-document state.
    -- Only live scene node handles, world mesh bounds and matrix components.
    for row in rows collect
    (
        local node=row[9]
        if not isValidNode node do throw "A detached setup's original ordinary output disappeared."
        local bounds=caBoundaryBounds node,tm=node.transform
        local components=for basis in #(tm.row1,tm.row2,tm.row3,tm.row4) collect #(basis.x,basis.y,basis.z)
        #(getHandleByAnim node,bounds[1],bounds[2],components)
    )
)
fn caBoundaryDetachedLive=
(
    local f=caBoundaryFixture prefix:"DetachedLive",setup=f[1]
    local settings=(caSetupSummary setup)[9]
    settings[11]=true;caSetArrangeSettings setup settings
    caClearAllGeometryCaches();caBoundaryRun f #cold
    caBoundaryRequire "detached-owner fixture is authored Live and explicitly generated" ((caSetupSummary setup)[7] and (caSetupSummary setup)[6]==0)
    -- Prove an ordinary relevant Live update works before detaching its owner.
    local revision=(caSetupSummary setup)[3],bounds=caBoundaryBounds f[3]
    with undo off (f[3].width+=20)
    caBoundaryRequire "Live precondition edits real furniture bounds" (abs((caBoundaryBounds f[3])[2].x-bounds[2].x-10)<0.003)
    local liveTick=caTick()
    caBoundaryRequire "ordinary attached Live service publishes this relevant edit" ((caSetupSummary setup)[3]>revision and (caSetupSummary setup)[6]==0)
    caBoundaryPhysical f (caBoundaryCapture setup)
    local before=caBoundaryCapture setup,summary=caSetupSummary setup,rows=caOutputRows setup
    local plain=caBoundaryPlainOutputs rows,objectCount=objects.count,ticket=caBoundaryDependency setup
    local attribute=caBoundaryOwnerAttribute setup,attributeCount=setup.custAttributes.count
    caBoundaryRequire "fixture has real previously published outputs" (rows.count>0)
    undo "Cache boundary detach actual native setup attribute" on
    (
        deleteItem setup.custAttributes attribute[1]
    )
    caBoundaryRequire "native attribute was really removed while its scene node survives" (isValidNode setup and setup.custAttributes.count==attributeCount-1)
    local rejected=false,detachError=""
    try (caSetupSummary setup) catch (rejected=true;detachError=getCurrentException() as string)
    caBoundaryRequire "public setup lookup rejects the actual detached owner" rejected
    caBoundaryCheck "native-attribute detach preserves ordinary output meshes and scene objects" ((deepEqual plain (caBoundaryPlainOutputs rows) strictCompare:true) and objects.count==objectCount)
    -- There is no intervening safe service call: this edit reaches the still
    -- retained Document before its first ordinary detached-owner service drain.
    -- Undo off keeps the next max undo aimed at the named attribute deletion.
    local oldWidth=f[3].width
    with undo off (f[3].width+=40)
    caBoundaryRequire "detached-owner case makes a real relevant upstream edit" (abs(f[3].width-oldWidth-40)<0.003)
    local detachedTick=caTick(),secondTick=caTick()
    caBoundaryCheck "detached retained document schedules no Live Generate attempt" (detachedTick==0 and secondTick==0)
    caBoundaryCheck "detached Live ticks create no ghost output/replacement meshes" ((deepEqual plain (caBoundaryPlainOutputs rows) strictCompare:true) and objects.count==objectCount)
    rejected=false
    try (caSetupSummary setup) catch (rejected=true)
    caBoundaryCheck "ordinary service does not silently reattach the removed owner attribute" (rejected and setup.custAttributes.count==attributeCount-1)
    caBoundaryNote ("DETACHED_LIVE attachedTick="+(liveTick as string)+" firstDetachedTick="+(detachedTick as string)+" secondDetachedTick="+(secondTick as string)+" originalRevision="+(summary[3] as string)+" priorTicket="+(ticket as string)+" lookupError="+detachError)
    -- No Undo-producing operation has run since deleting the attribute. Do not
    -- flush history or force GC; the retained native document is the test case.
    max undo
    local restored=caSetupSummary setup
    caBoundaryRequire "Undo restores the actual same native owner association" (setup.custAttributes.count==attributeCount and restored[1]==summary[1] and (caBoundaryDependency setup)[2]==ticket[2])
    caBoundaryCheck "detached service never advanced the retained document revision" (restored[3]==summary[3])
    caBoundaryCheck "Undo restores complete old IDs/groups/poses and ordinary output bindings" (caBoundarySame before (caBoundaryCapture setup) handles:true compositionStats:false)
    caBoundaryRequire "Undo-off source edit remains a real pending geometry change" (abs(f[3].width-oldWidth-40)<0.003)
    local generated=caBoundaryRun f #cold
    caBoundaryCheck "explicit Generate recovers the legitimate restored owner" ((caSetupSummary setup)[3]>summary[3] and (caSetupSummary setup)[6]==0)
    -- Fresh explicit Generate re-arms Live; detached documents are skipped,
    -- restored real owners remain functional through the ordinary service.
    revision=(caSetupSummary setup)[3]
    with undo off (f[3].width+=20)
    caTick()
    caBoundaryCheck "restored explicitly generated owner resumes relevant Live updates" ((caSetupSummary setup)[3]>revision and (caSetupSummary setup)[6]==0)
    caBoundaryPhysical f (caBoundaryCapture setup)
)


fn caBoundaryDocumentValue setup=
(
    local attribute=caBoundaryOwnerAttribute setup
    caBoundaryRequire "actual native owner has its one Document reference" ((refs.getNumRefs attribute[2])==1)
    local value=refs.getReference attribute[2] 1
    caBoundaryRequire "read-only reference lookup returns the actual native Document class" (value!=undefined and (caBoundaryClassIDEqual value.classID 0x6a4387d1 0x4fa90372 "actual Document"))
    value
)
fn caBoundaryNativeCycle=
(
    local f=caBoundaryFixture prefix:"NativeCycle",setup=f[1]
    caClearAllGeometryCaches();caBoundaryRun f #cold;caBoundaryRun f #hit
    local documentValue=caBoundaryDocumentValue setup
    -- Executable SDK avg_dlx.cpp4181-4195: the first argument is candidate,
    -- the second is Document. True maps to TestForLoop==REF_FAIL.
    caBoundaryRequire "ordinary furniture has no candidate-to-Document dependency loop" (not (refs.dependencyLoopTest f[2] documentValue))
    caBoundaryRequire "actual owner-to-Document oracle detects its existing reference path" (refs.dependencyLoopTest setup documentValue)
    local before=caBoundaryCapture setup,revision=(caSetupSummary setup)[3],child=undefined,caseError=undefined
    try
    (
        -- No authored command is issued after this new child exists. A normal
        -- node-reference CA builds a real candidate->setup->Document path;
        -- refs.getReference is read-only and no refs.set/replace API is used.
        child=box name:"CA_BOUND_REAL_NATIVE_CYCLE" width:180 length:220 height:20 pos:[0,0,800]
        local definition=attributes CA_CacheBoundaryOwnerReference
        (
            parameters main
            (
                ownerTarget type:#node
            )
        )
        local count=custAttributes.count child baseObject:false
        custAttributes.add child definition baseObject:false
        caBoundaryRequire "real custom node-reference attribute was installed on the independent child" ((custAttributes.count child baseObject:false)==count+1)
        local holder=custAttributes.get child (count+1) baseObject:false
        holder.ownerTarget=setup
        caBoundaryRequire "the actual typed node parameter retains the real setup target" (holder.ownerTarget==setup)
        caBoundaryRequire "independent CA child has a real candidate-to-Document loop oracle" (refs.dependencyLoopTest child documentValue)
        attachNodesToGroup #(child) f[2]
        local actualChildren=for node in f[2].children collect node
        caBoundaryRequire "cycle candidate was really attached while setup remains outside source hierarchy" (child.parent==f[2] and (isGroupMember child) and (caBoundaryGeometry f[2]).count==2 and (findItem actualChildren setup)==0 and setup.parent!=f[2])
        caBoundaryRequire "attached candidate still has the real nonhierarchical native loop oracle" (refs.dependencyLoopTest child documentValue)
        local objectsBefore=objects.count,rejected=false,errorText=""
        caBoundaryNote "BEGIN Preview with a real CA node-reference cycle candidate"
        try (caPreview setup #()) catch (rejected=true;errorText=getCurrentException() as string)
        caBoundaryCheck "Preview rejects the actual native reference-cycle candidate" (rejected and (findString (toLower errorText) "reference cycle")!=undefined)
        caBoundaryCheck "native cycle rejection preserves previous publication/revision/ordinary nodes" ((caSetupSummary setup)[3]==revision and (caBoundarySame before (caBoundaryCapture setup) handles:true compositionStats:false) and objects.count==objectsBefore)
        local info=caBoundaryInfo setup
        caBoundaryCheck "native cycle rejection records no completed/published Preview" (info[3]!=undefined and not info[3][4] and not info[3][5])
        caBoundaryNote ("NATIVE_CYCLE error="+errorText)
        caBoundaryRequire "real cycle was refused before the recovery control" rejected
    )
    catch (caseError=getCurrentException() as string)
    -- Destroy only the newly authored disposable input, even after a failed
    -- fixture prerequisite. Never replace native Document reference slots.
    if isValidNode child do delete child
    if caseError!=undefined do throw caseError
    caBoundaryRequire "cycle fixture cleanup restores original actual furniture membership" ((caBoundaryGeometry f[2]).count==1 and not (refs.dependencyLoopTest f[2] documentValue))
    caPreview setup #()
    caBoundaryExpect (caBoundaryInfo setup) #cold "Preview"
    caBoundaryCheck "normal Preview succeeds after real cycle input cleanup without publishing" ((caSetupSummary setup)[3]==revision and (caBoundarySame before (caBoundaryCapture setup) handles:true compositionStats:false))
)
fn caBoundaryOwnerHierarchy=
(
    local f=caBoundaryFixture prefix:"OwnerHierarchy",setup=f[1]
    caClearAllGeometryCaches();caBoundaryRun f #cold
    local before=caBoundaryCapture setup,revision=(caSetupSummary setup)[3],caseError=undefined,previousOpen=isOpenGroupHead f[2]
    try
    (
        attachNodesToGroup #(setup) f[2]
        caBoundaryRequire "actual native owner is really nested under its input group" (setup.parent==f[2] and (isGroupMember setup))
        local count=objects.count,rejected=false,errorText=""
        caBoundaryNote "BEGIN Preview with actual setup nested inside furniture input"
        try (caPreview setup #()) catch (rejected=true;errorText=getCurrentException() as string)
        caBoundaryCheck "explicit owner/ancestor hierarchy guard rejects the nested setup" (rejected and (findString (toLower errorText) "ancestors")!=undefined)
        caBoundaryCheck "owner hierarchy rejection preserves all real previous publication" ((caSetupSummary setup)[3]==revision and (caBoundarySame before (caBoundaryCapture setup) handles:true compositionStats:false) and objects.count==count)
        caBoundaryNote ("OWNER_HIERARCHY error="+errorText)
        caBoundaryRequire "nested owner was refused before hierarchy recovery" rejected
    )
    catch (caseError=getCurrentException() as string)
    if isValidNode setup and setup.parent==f[2] do
    (
        setGroupOpen f[2] true
        detachNodesFromGroup #(setup)
    )
    setGroupOpen f[2] previousOpen
    if caseError!=undefined do throw caseError
    caBoundaryRequire "setup cleanup really restores the owner outside input hierarchy" (setup.parent!=f[2] and not (isGroupMember setup))
    caPreview setup #()
    caBoundaryExpect (caBoundaryInfo setup) #cold "Preview"
    caBoundaryCheck "normal Preview recovers after explicit hierarchy repair" ((caSetupSummary setup)[3]==revision and (caBoundarySame before (caBoundaryCapture setup) handles:true compositionStats:false))
)

-- Analytic controls for the test oracle itself. No plugin geometry or native
-- region result supplies these expected coordinates. Each case has a flat top.
fn caBoundaryBakeControls=
(
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0f
    local source=undefined,caseError=undefined
    try
    (
        in coordsys world
        (
            with undo off (source=box name:"CA_BOUND_ORACLE_CONTROL" width:80 length:40 height:20 widthsegs:1 lengthsegs:1 heightsegs:1 pos:[120,-230,500])
            local moved=caBoundaryBake source
            caBoundaryRequire "oracle translated box has literal world bounds without doubled translation" (distance moved[1] [80,-250,500]<0.003 and distance moved[2] [160,-210,520]<0.003 and moved[3].count==8 and moved[4]==12)
            -- Explicit quarter turn: an80x40 rectangle becomes40x80 in XY.
            source.transform=matrix3 [0,1,0] [-1,0,0] [0,0,1] [120,-230,500]
            local turned=caBoundaryBake source
            caBoundaryRequire "oracle quarter-turned box matches independent literal world bounds" (distance turned[1] [100,-270,500]<0.003 and distance turned[2] [140,-190,520]<0.003)
            source.pivot=[170,-200,510]
            caBoundaryRequire "oracle fixture has a genuinely shifted pivot and object offset" (distance source.pivot [170,-200,510]<0.003 and not (caBoundaryMatrixEqual source.transform source.objectTransform))
            local pivoted=caBoundaryBake source
            caBoundaryRequire "oracle shifted pivot preserves every actual world vertex and literal bounds" ((caBoundaryMoved turned pivoted [0,0,0]) and distance pivoted[1] [100,-270,500]<0.003 and distance pivoted[2] [140,-190,520]<0.003)
            local callerFrame=matrix3 [0,1,0] [-1,0,0] [0,0,1] [-300,70,25],fromFrame=undefined
            in coordsys callerFrame (fromFrame=caBoundaryBake source)
            caBoundaryRequire "oracle ignores caller coordinate frame while retaining complete world geometry" ((caBoundaryMoved pivoted fromFrame [0,0,0]) and distance fromFrame[1] [100,-270,500]<0.003 and distance fromFrame[2] [140,-190,520]<0.003)
            caBoundaryNote ("ORACLE_CONTROL translated="+(moved[1] as string)+","+(moved[2] as string)+" rotatedPivoted="+(pivoted[1] as string)+","+(pivoted[2] as string))
        )
    )
    catch (caseError=getCurrentException() as string)
    if isValidNode source do with undo off (delete source)
    if caseError!=undefined do throw caseError
    caBoundaryRequire "oracle controls leave no disposable scene nodes behind" (objects.count==0)
)

fn caBoundaryBootstrap=
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Runner-owned project/output paths required."
    if (maxVersion())[1]!=29000 do throw "Boundary harness requires Max2027 only."
    caBoundaryRequire "native cache API is available" (caGeometryCacheInfo!=undefined and caGeometryDependencyInfo!=undefined and caSetGeometryCacheEnabled!=undefined and caClearAllGeometryCaches!=undefined)
    CA_AUTO_SHOW_UI=false
    fileIn (CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    caBoundaryOriginalEnabled=caGeometryCacheEnabled()
    caSetGeometryCacheEnabled true
    caBoundaryCase "exact numeric native class ID controls" caBoundaryClassIDControls
    caBoundaryCase "independent world mesh oracle coordinate controls" caBoundaryBakeControls
    caBoundaryCase "actual world-space furniture and obstacle deformation" caBoundaryWSM
    caBoundaryCase "primitive topology and real object-space modifier edits" caBoundaryTopology
    caBoundaryCase "full clone remaps bound WSM dependency without sharing transient cache" caBoundaryFullClone
    caBoundaryCase "actual scene merge and independent WSM dependencies" caBoundaryMerge
    caBoundaryCase "owner deletion releases numeric entries across retained Undo lifetime" caBoundaryOwnerDelete
    caBoundaryCase "detached Undo-retained Live owner cannot schedule ghost publication" caBoundaryDetachedLive
    caBoundaryCase "real native dependency loop oracle and guarded Preview" caBoundaryNativeCycle
    caBoundaryCase "explicit setup-inside-input hierarchy guard" caBoundaryOwnerHierarchy
)
try (caBoundaryBootstrap()) catch
(
    caBoundaryFailures+=1;caBoundaryNote ("EXCEPTION bootstrap: "+(getCurrentException() as string))
    caBoundaryNote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
if caBoundaryOriginalEnabled!=undefined do try (caClearAllGeometryCaches();caSetGeometryCacheEnabled caBoundaryOriginalEnabled) catch (caBoundaryFailures+=1;caBoundaryNote ("EXCEPTION cleanup: "+(getCurrentException() as string)))
caBoundaryFinished=true
caBoundaryWrite()
