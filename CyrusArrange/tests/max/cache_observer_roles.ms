/* Definitions loaded by the matched general cache harness.
   Never launches Max or auto-runs.
   Every invoked case resets an OWNED test scene; never use in an artist scene.
   Requires current caK helpers and book_row_fixtures.ms bounds definitions.
   Original plain boxes; independent known-Fill targets: main board7, child2.
*/
global caKRequire,caKCheck,caKNote,caKBounds,caKGeometry,caKMM,caKDependency,caKInfo,caKExpect
global caKCapture,caKSame,caKSameBoxes,caKSameStats,caKBoxes,caKPreviewMatches,caKBoxesOnSupport
global caBRWorldGeometryBounds
global caCreateSetup,caRegisterAsset,caSetupSummary,caSetArrangeSettings,caCategoryRules,caSetCategoryRules
global caSetCollisionScope,caSetGeometryCacheEnabled,caClearGeometryCache,caRegionRows,caPlacementSettings
global caGenerate,caPreview,caPreviewInfo,caCommitPreview
global caOLFixture,caOLRows,caOLEnvelopes,caOLTargets,caOLCeiling,caOLPhysical,caOLRun,caOLRejectCommit,caOLNoPublication
global caOLAssetDescendant,caOLObstacleDescendant,caOLRemovedChild
global caOLAssetEnabled,caOLAssetDisabled,caOLObstacleEnabled,caOLObstacleDisabled,caOLRemovedEnabled,caOLRemovedDisabled

-- #(setup,furnitureGroup,assetGroup,obstacleGroup,board,assetBase,parkedObstacle,assetID)
fn caOLFixture label reuse =
(
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0
    caSetGeometryCacheEnabled reuse
    local wood=standardMaterial name:(label+"_WOOD") diffuse:(color 130 90 55)
    local cover=standardMaterial name:(label+"_BOOK") diffuse:(color 45 75 110)
    local blocker=standardMaterial name:(label+"_BLOCKER") diffuse:(color 70 75 80)
    local board=box name:(label+"_BOARD") width:600 length:400 height:20 pos:[0,0,800]
    board.material=wood
    local furniture=group #(board) name:(label+"_FURNITURE")
    furniture.pivot=[0,0,0];setGroupOpen furniture true
    local assetBase=box name:(label+"_BOOK_BASE") width:40 length:60 height:100 pos:[2000,0,0]
    assetBase.material=cover
    local assetRoot=group #(assetBase) name:(label+"_ASSET")
    assetRoot.pivot=[2000,0,0];setGroupOpen assetRoot true
    local parked=box name:(label+"_PARKED_OBSTACLE") width:20 length:20 height:20 pos:[1500,-500,800]
    parked.material=blocker
    local obstacleRoot=group #(parked) name:(label+"_OBSTACLES")
    obstacleRoot.pivot=[0,0,0];setGroupOpen obstacleRoot true
    local setup=caCreateSetup #(furniture) 1
    setup.name=label+"_SETUP"
    local assetID=caRegisterAsset setup assetRoot "Original box book" 1 1 #(0.0) 1.0 1.0 1.0 false
    local settings=(caSetupSummary setup)[9]
    settings[1]=137L;settings[2]=0.08;settings[3]=5;settings[4]=5;settings[5]=0
    settings[6]=0;settings[7]=0;settings[8]=2;settings[9]=1;settings[10]=25;settings[11]=false
    caSetArrangeSettings setup settings
    local rules=caCategoryRules setup 1
    for row in rules do (row[2]=1;row[3]=if row[1]==1 then 3 else 0;row[4]=false)
    caSetCategoryRules setup 1 rules
    caSetCollisionScope setup #(obstacleRoot) false
    #(setup,furniture,assetRoot,obstacleRoot,board,assetBase,parked,assetID)
)
fn caOLRows node =
(
    local tm=node.transform
    #(copy tm.row1,copy tm.row2,copy tm.row3,copy tm.row4)
)
fn caOLEnvelopes snapshot =
(
    for row in snapshot[1] collect #((row[9]+row[10])*0.5,(row[10]-row[9])*0.5,row[5])
)
fn caOLTargets fixture =
(
    -- Known Fill-policy arithmetic, independently supplied with actual literal
    -- box geometry. This count oracle is not the physical/collision proof below.
    -- The saved category maximum3 is descriptive; it must not cap geometry Fill.
    local boards=caKGeometry fixture[2],parts=caKGeometry fixture[3],targets=#(),mainFound=false
    if boards.count<1 or boards.count>2 or parts.count<1 or parts.count>2 do throw "Observer literal geometry exceeds its one/two-box admission."
    local settings=(caSetupSummary fixture[1])[9]
    if settings[1]!=137L or abs(settings[2]-0.08)>0.0000001 or settings[3]!=5 or settings[4]!=5 or settings[5]!=0 or settings[6]!=0 or settings[7]!=0 or settings[8]!=2 or settings[10]!=25 or settings[11] do throw "Observer authored seed/Fill recipe differs from its explicit known-policy witness."
    local placement=caPlacementSettings fixture[1]
    if placement[2]!=1 or placement[7] or placement[8] do throw "Observer count oracle requires the original Fill mode without random/fit scaling."
    for node in (join (copy boards #noMap) parts) do
    (
        if classOf node.baseObject!=Box or node.modifiers.count!=0 do throw "Observer count oracle requires unmodified literal boxes."
        local tm=node.objectTransform
        if distance tm.row1 [1,0,0]>0.00001 or distance tm.row2 [0,1,0]>0.00001 or distance tm.row3 [0,0,1]>0.00001 do throw "Observer count oracle requires actual world-axis-aligned unit boxes."
    )
    local source=caBRWorldGeometryBounds fixture[3],factor=caKMM(),sourceSize=(source[2]-source[1])*factor
    if abs(sourceSize.x-40)>0.03 or abs(sourceSize.y-60)>0.03 do throw "Observer full source XY size differs from its literal40x60mm box."
    local slot=(((sqrt ((sourceSize.x as double)*(sourceSize.y as double)))+5.0)^2),density=0.08 as double
    for node in boards do
    (
        local bounds=caKBounds node,size=bounds[2]-bounds[1],main=(node==fixture[5])
        local expectedWidth=if main then 600 else 200,expectedDepth=if main then 400 else 200
        if abs(size.x-expectedWidth)>0.03 or abs(size.y-expectedDepth)>0.03 or size.z<=0 do throw "Observer physical board dimensions differ from their literal geometry."
        if main do mainFound=true
        local target=(ceil (((size.x as double)*(size.y as double)*density)/slot)) as integer
        if target!=(if main then 7 else 2) do throw "Observer independently calculated known-Fill target changed."
        append targets #(node,target)
    )
    if not mainFound do throw "Observer current receiver hierarchy lost its literal main board."
    targets
)
fn caOLCeiling fixture =
(
    local total=0
    for row in (caOLTargets fixture) do total+=row[2]
    total
)
-- Full physical source/obstacle meshes are independently measured, never native
-- region bounds. The book and furniture are authored axis-aligned closed boxes.
fn caOLPhysical fixture boxes =
(
    local factor=caKMM(),bounds=caBRWorldGeometryBounds fixture[3]
    local assetSize=(bounds[2]-bounds[1])*factor
    local furnitureNodes=caKGeometry fixture[2]
    local furniture=for node in furnitureNodes collect (caKBounds node)
    local obstacles=for node in (caKGeometry fixture[4]) collect (caKBounds node)
    local solids=copy furniture #noMap
    join solids obstacles
    local targets=caOLTargets fixture,ceiling=0
    for row in targets do ceiling+=row[2]
    local valid=boxes.count>0 and boxes.count<=ceiling
    local supportCounts=for board in furniture collect 0
    for envelope in boxes do
    (
        local lower=envelope[1]-envelope[2],upper=envelope[1]+envelope[2],supportIndex=0
        if abs(envelope[3])>0.00001 or distance (upper-lower) assetSize>0.03 do valid=false
        for index=1 to furniture.count do
        (
            local board=furniture[index]
            if abs(lower.z-board[2].z)<0.03 and lower.x>=board[1].x-0.03 and upper.x<=board[2].x+0.03 and lower.y>=board[1].y-0.03 and upper.y<=board[2].y+0.03 do supportIndex=index
        )
        if supportIndex==0 then valid=false
        else
        (
            supportCounts[supportIndex]+=1
            local target=undefined
            for row in targets where row[1]==furnitureNodes[supportIndex] do target=row[2]
            if target==undefined do throw "Observer physical support has no independently calculated Fill target."
            if supportCounts[supportIndex]>target do valid=false
        )
        for solid in solids do
        (
            local dx=amin #(upper.x,solid[2].x)-amax #(lower.x,solid[1].x)
            local dy=amin #(upper.y,solid[2].y)-amax #(lower.y,solid[1].y)
            local dz=amin #(upper.z,solid[2].z)-amax #(lower.z,solid[1].z)
            if dx>0.03 and dy>0.03 and dz>0.03 do valid=false
        )
    )
    for i=1 to boxes.count do for j=i+1 to boxes.count do
    (
        local a=boxes[i],b=boxes[j],loA=a[1]-a[2],hiA=a[1]+a[2],loB=b[1]-b[2],hiB=b[1]+b[2]
        if (amin #(hiA.x,hiB.x)-amax #(loA.x,loB.x))>0.03 and (amin #(hiA.y,hiB.y)-amax #(loA.y,loB.y))>0.03 and (amin #(hiA.z,hiB.z)-amax #(loA.z,loB.z))>0.03 do valid=false
    )
    caKRequire "observer-role independent full-size support/physical collision oracle" valid
    valid
)
fn caOLRun fixture operation reuse cold:false =
(
    local setup=fixture[1],result=undefined
    case operation of
    (
        "Generate":(result=caGenerate setup #())
        "Preview":(result=caPreview setup #())
        "CommitPreview":(result=caCommitPreview setup)
        default:throw "Unknown observer role operation."
    )
    local info=caKInfo setup
    local mode=if reuse then (if cold then #cold else #hit) else #disabled
    caKExpect info mode operation
    local snapshot=caKCapture setup
    local ceiling=caOLCeiling fixture
    local actualCount=if operation=="Preview" then (caKBoxes setup).count else snapshot[1].count
    caKRequire "observer-role current physical members give exact Fill demand and nonempty bounded honest output" (result[1]==ceiling and result[2]>0 and result[2]<=ceiling and result[2]==actualCount and result[5]==ceiling-result[2])
    if operation=="Preview" then caOLPhysical fixture (caKBoxes setup)
    else
    (
        local invalidRows=for row in snapshot[1] where row[2]!=fixture[8] or abs(row[5])>0.00001 or abs(row[6]-1)>0.00001 or row[8]!=0L collect row
        caKRequire "observer-role actual outputs preserve unit scale, no stacks, and exact asset identity" (invalidRows.count==0 and snapshot[2].count==0)
        caOLPhysical fixture (caOLEnvelopes snapshot)
    )
    #(result,snapshot,info)
)
fn caOLNoPublication fixture before revision label =
(
    caKCheck (label+": every real row/group/region/pose/handle and authored revision is unchanged") ((caSetupSummary fixture[1])[3]==revision and (caKSame before (caKCapture fixture[1]) handles:true compositionStats:false))
)
fn caOLRejectCommit fixture before revision sequence label =
(
    local rejected=false,errorText=""
    try(caCommitPreview fixture[1])catch(rejected=true;errorText=getCurrentException() as string)
    caKRequire (label+": stale Commit is rejected") rejected
    caOLNoPublication fixture before revision label
    local info=caKInfo fixture[1]
    caKCheck (label+": stale Commit cannot report a new successful publication") (info[3][12]==sequence or not info[3][5])
    caKNote (label+" expected stale rejection: "+errorText)
)
fn caOLAssetDescendant reuse:true =
(
    local f=caOLFixture "CA_OBSERVER_ASSET" reuse,setup=f[1]
    caOLRun f "Generate" reuse cold:true
    local before=caKCapture setup,revision=(caSetupSummary setup)[3]
    local child=box name:"CA_OBSERVER_ASSET_NEW_CHILD" width:40 length:60 height:20 pos:[2000,0,100]
    child.material=f[6].material
    attachNodesToGroup #(child) f[3]
    -- No authored setter, Analyze, Generate or Commit after attachment.
    local first=caOLRun f "Preview" reuse cold:true,firstBoxes=caKBoxes setup
    local invalidFirstHeights=for b in firstBoxes where abs(b[2].z*2-120)>0.03 collect b
    caKRequire "Preview-only asset child is captured as a real120mm book" ((caKGeometry f[3]).count==2 and firstBoxes.count>0 and invalidFirstHeights.count==0)
    caOLNoPublication f before revision "Preview-only asset child"
    local ticket=caKDependency setup,tm=caOLRows child,sequence=(caKInfo setup)[3][12]
    child.height=80
    local actual=caKBounds child,after=caKDependency setup
    caKRequire "asset edit changes only real descendant geometry to180mm full height" (abs(actual[1].z-100)<0.003 and abs(actual[2].z-180)<0.003 and child.parent==f[3] and (deepEqual (caOLRows child) tm strictCompare:true))
    caKCheck "new asset descendant remains observed after Preview returns" (after[2]==ticket[2] and after[3]==ticket[3] and after[4]>ticket[4])
    caKRequire "outside-command new asset geometry edit stales Preview" ((caPreviewInfo setup)[1] and not (caPreviewInfo setup)[2])
    caOLRejectCommit f before revision sequence "Preview-only asset descendant"
    local fresh=caOLRun f "Preview" reuse cold:true,freshBoxes=caKBoxes setup
    local invalidFreshHeights=for b in freshBoxes where abs(b[2].z*2-180)>0.03 collect b
    caKRequire "fresh Preview refreshes the actual full asset to180mm" (invalidFreshHeights.count==0 and not (caKSameBoxes firstBoxes freshBoxes))
    local repeated=caOLRun f "Preview" reuse
    caKCheck "repeated current asset Preview has identical full boxes and complete stats/work" ((caKSameBoxes freshBoxes (caKBoxes setup)) and (caKSameStats fresh[1] repeated[1]) and fresh[3][3][11]==repeated[3][3][11])
    caOLNoPublication f before revision "current asset Preview"
    caClearGeometryCache setup
    caKRequire "optional geometry clear leaves current asset Preview valid" ((caPreviewInfo setup)[2])
    local committed=caOLRun f "CommitPreview" reuse cold:true
    caKCheck "real committed full meshes match current180mm asset Preview" ((caKPreviewMatches freshBoxes committed[2]) and (caKSameStats fresh[1] committed[1]))
)
fn caOLObstacleDescendant reuse:true =
(
    local f=caOLFixture "CA_OBSERVER_OBSTACLE" reuse,setup=f[1]
    caOLRun f "Generate" reuse cold:true
    local before=caKCapture setup,revision=(caSetupSummary setup)[3]
    local child=box name:"CA_OBSERVER_OBSTACLE_NEW_CHILD" width:20 length:400 height:120 pos:[0,0,820]
    child.material=f[7].material
    attachNodesToGroup #(child) f[4]
    -- New obstacle never enters the support scope. No authored setter follows.
    local first=caOLRun f "Preview" reuse cold:true,firstBoxes=caKBoxes setup
    caKRequire "Preview-only new obstacle is in the real obstacle group" ((caKGeometry f[4]).count==2 and child.parent==f[4])
    caOLNoPublication f before revision "Preview-only obstacle child"
    local ticket=caKDependency setup,tm=caOLRows child,sequence=(caKInfo setup)[3][12]
    child.width=260
    local actual=caKBounds child,after=caKDependency setup
    caKRequire "obstacle same-TM edit expands the actual blocker to260mm leaving usable side zones" (distance actual[1] [-130,-200,820]<0.003 and distance actual[2] [130,200,940]<0.003 and child.parent==f[4] and (deepEqual (caOLRows child) tm strictCompare:true))
    caKCheck "new obstacle descendant remains observed after Preview returns" (after[2]==ticket[2] and after[3]==ticket[3] and after[4]>ticket[4])
    caKRequire "outside-command new obstacle geometry edit stales Preview" ((caPreviewInfo setup)[1] and not (caPreviewInfo setup)[2])
    caOLRejectCommit f before revision sequence "Preview-only obstacle descendant"
    local fresh=caOLRun f "Preview" reuse cold:true,freshBoxes=caKBoxes setup
    local repeated=caOLRun f "Preview" reuse
    caKCheck "repeated current obstacle Preview has exact full boxes and complete stats/work" ((caKSameBoxes freshBoxes (caKBoxes setup)) and (caKSameStats fresh[1] repeated[1]) and fresh[3][3][11]==repeated[3][3][11])
    caOLNoPublication f before revision "current obstacle Preview"
    caClearGeometryCache setup
    caKRequire "optional geometry clear leaves current obstacle Preview valid" ((caPreviewInfo setup)[2])
    local committed=caOLRun f "CommitPreview" reuse cold:true
    caKCheck "actual committed meshes match current Preview and avoid the grown independent obstacle" ((caKPreviewMatches freshBoxes committed[2]) and (caKSameStats fresh[1] committed[1]))
)
fn caOLRemovedChild reuse:true =
(
    local f=caOLFixture "CA_OBSERVER_REMOVED" reuse,setup=f[1]
    local child=box name:"CA_OBSERVER_PREVIOUSLY_PUBLISHED_CHILD" width:200 length:200 height:10 pos:[0,0,1000]
    child.material=f[5].material
    attachNodesToGroup #(child) f[2]
    caOLRun f "Generate" reuse cold:true
    caKRequire "initial removed-child publication has two distinct physical tops and geometry-derived7+2Fill demand" ((caOLCeiling f)==9 and (caRegionRows setup).count==2)
    -- Successful publication above deliberately registered the child in the
    -- old serialized descendant container, not just the transient current set.
    local before=caKCapture setup,revision=(caSetupSummary setup)[3]
    detachNodesFromGroup #(child)
    caKRequire "detached child remains outside current support group with geometry-derived7Fill demand" (isValidNode child and child.parent!=f[2] and (caKGeometry f[2]).count==1 and (caOLCeiling f)==7)
    local fresh=caOLRun f "Preview" reuse cold:true,boxes=caKBoxes setup
    caKRequire "Preview-only refresh uses only current real820mm board support" (caKBoxesOnSupport boxes (caKBounds f[5]))
    caOLNoPublication f before revision "removed-child Preview-only refresh"
    local ticket=caKDependency setup,tm=caOLRows child,sequence=(caKInfo setup)[3][12],old=caKBounds child
    child.height=50
    caKRequire "detached child really changed geometry outside current hierarchy" (abs((caKBounds child)[2].z-old[2].z-40)<0.003 and child.parent!=f[2] and (deepEqual (caOLRows child) tm strictCompare:true))
    caKCheck "old serialized descendants do not cause ghost current-input invalidation" (deepEqual (caKDependency setup) ticket strictCompare:true)
    caKCheck "unrelated removed-child edit leaves exact valid Preview and command sequence intact" ((caPreviewInfo setup)[2] and (caKSameBoxes boxes (caKBoxes setup)) and (caKInfo setup)[3][12]==sequence)
    caOLNoPublication f before revision "removed-child unrelated edit"
    -- Prove the membership filter did not suppress the genuine retained input.
    f[5].height=30
    local after=caKDependency setup
    caKRequire "remaining current board's real geometry change is still observed" (abs((caKBounds f[5])[2].z-830)<0.003 and after[2]==ticket[2] and after[3]==ticket[3] and after[4]>ticket[4] and not (caPreviewInfo setup)[2])
    caOLRejectCommit f before revision sequence "remaining input after removed-child refresh"
    local current=caOLRun f "Preview" reuse cold:true,currentBoxes=caKBoxes setup
    caKRequire "fresh retained-input Preview uses physical830mm top" (caKBoxesOnSupport currentBoxes (caKBounds f[5]))
    local committed=caOLRun f "CommitPreview" reuse
    caKCheck "real current output matches refreshed retained-input Preview" ((caKPreviewMatches currentBoxes committed[2]) and (caKSameStats current[1] committed[1]))
)
fn caOLAssetEnabled=(caOLAssetDescendant reuse:true)
fn caOLAssetDisabled=(caOLAssetDescendant reuse:false)
fn caOLObstacleEnabled=(caOLObstacleDescendant reuse:true)
fn caOLObstacleDisabled=(caOLObstacleDescendant reuse:false)
fn caOLRemovedEnabled=(caOLRemovedChild reuse:true)
fn caOLRemovedDisabled=(caOLRemovedChild reuse:false)
