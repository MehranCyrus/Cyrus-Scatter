/* Candidate atomic callback harness, runtime qualification pending. Root-owned disposable Max2027 host.
   Real nonpersistent nodeCreated callbacks; no runtime fault-injection API.
   Do not fileIn the production cache harness: it autoruns/reset its own cases. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caCreateBookRowFixtures, caBRWorldGeometryBounds
global caCreateSetup, caSetupSummary, caSetArrangeSettings, caRegisterAsset, caSetAssetBookRow
global caCategoryRules, caSetCategoryRules, caSetCompositionSettings, caCompositionRows, caOutputRows
global caSetCollisionScope, caGenerate, caTick
global caPlacementSettings, caGeneratePlacement, caCompositionSettings
global caGeometryCacheInfo, caGeometryDependencyInfo, caGeometryCacheEnabled, caSetGeometryCacheEnabled, caClearAllGeometryCaches
global caALog=#(), caAPasses=0, caAFailures=0, caAFinished=false, caAOriginalEnabled=undefined
global caASetup, caAGroup, caABoard, caAObstacle, caABooks, caAAssetLeaf, caANewInput
global caAID, caAMode, caAArmed=false, caAFired=0, caAInvocations=0, caAFiredHandle=0
global caACallbackError="", caAInnerError="", caAInnerRejected=false, caAActionCompleted=false
global caAInputBefore, caAInputDuring, caATicketDuring
global caAIDs=#(#CA_CacheAtomic_Furniture,#CA_CacheAtomic_Obstacle,#CA_CacheAtomic_Asset,#CA_CacheAtomic_NewChild,#CA_CacheAtomic_FurnitureUndoOff,#CA_CacheAtomic_Reentrant)
global caAWrite, caANote, caACheck, caARequire, caACleanup, caACase, caAMeasure, caAMutate, caAOnCreated
global caASnapshot, caAStable, caAObjects, caASameSet, caAFixture, caAPhysical, caARunCase, caABootstrap

fn caAWrite=
(
    if CA_TEST_OUTPUT!=undefined do
    (
        local out=createFile (CA_TEST_OUTPUT+"result.txt")
        format "% passes=% failures=%\n" (if caAFinished then (if caAFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caAPasses caAFailures to:out
        for line in caALog do format "%\n" line to:out
        flush out;close out
    )
    true
)
fn caANote text=(append caALog text;caAWrite();true)
fn caACheck label condition=(if condition then (caAPasses+=1;caANote ("PASS "+label)) else (caAFailures+=1;caANote ("FAIL "+label));condition)
fn caARequire label condition=(caACheck label condition;if not condition do throw ("Prerequisite: "+label);true)

-- MAXScript has try/catch, not a finally clause. Case/bootstrap wrappers call
-- this after both success and catch paths. Removal always includes exact owned ID.
fn caACleanup=
(
    caAArmed=false
    for callbackID in caAIDs do callbacks.removeScripts #nodeCreated id:callbackID
    local empty=true
    for callbackID in caAIDs do if (callbacks.show #nodeCreated id:callbackID asArray:true).count!=0 do empty=false
    if not empty do throw "An owned atomic callback survived exact-ID cleanup."
    true
)
fn caACase label mode reuse=
(
    caANote ("STAGE "+label+" reuse="+(reuse as string))
    try (caACleanup();caARunCase mode reuse) catch
    (
        caAFailures+=1
        caANote ("EXCEPTION "+label+": "+(getCurrentException() as string))
        caANote ("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
        caANote ("STACK "+(getCurrentExceptionStackTrace() as string))
    )
    try (caACheck "all owned callback IDs are removed" (caACleanup())) catch
    (
        caAFailures+=1;caANote ("CLEANUP_ERROR "+(getCurrentException() as string))
    )
)
fn caAMeasure=
(
    case caAMode of
    (
        #furniture: caABoard.width
        #furnitureUndoOff: caABoard.width
        #obstacle: caAObstacle.width
        #asset: caAAssetLeaf.height
        #newChild: caAGroup.children.count
        #reentrant: 0
        default: throw "Unknown callback mutation."
    )
)
fn caAMutate=
(
    case caAMode of
    (
        #furniture: (caABoard.width+=11)
        #furnitureUndoOff: (caABoard.width+=11)
        #obstacle: (caAObstacle.width+=11)
        #asset: (caAAssetLeaf.height+=11)
        #newChild:
        (
            -- This creates another notification, but the one-shot flag has
            -- already disarmed our callback before entry into this function.
            caANewInput=box name:"CA_ATOMIC_NEW_INPUT" width:180 length:180 height:20 pos:[0,0,800]
            attachNodesToGroup #(caANewInput) caAGroup
            caANewInput.width+=11
            if caANewInput.parent!=caAGroup do throw "New source child was not really attached."
        )
        #reentrant:
        (
            try (caGenerate caASetup #()) catch
            (
                caAInnerRejected=true
                caAInnerError=getCurrentException() as string
            )
        )
        default: throw "Unknown callback mutation."
    )
    caAActionCompleted=true
)
fn caAOnCreated=
(
    caAInvocations+=1
    if caAArmed do
    (
        caAArmed=false -- set before any operation that could create another node
        caAFired+=1
        try
        (
            local node=callbacks.notificationParam()
            if callbacks.notificationEvent()!=#nodeCreated or not isValidNode node do throw "nodeCreated did not provide a real current node."
            caAFiredHandle=getHandleByAnim node
            -- CreateObjectNode fires before native code assigns the generated
            -- tag/name/material, so do not filter on those unfinished fields.
            if caAMode==#furnitureUndoOff then (with undo off (caAMutate())) else caAMutate()
            caAInputDuring=caAMeasure()
            caATicketDuring=caGeometryDependencyInfo caASetup
        )
        catch (caACallbackError=getCurrentException() as string)
    )
    true
)
fn caASnapshot setup=
(
    local rows=#()
    for row in (caOutputRows setup) do
    (
        if row.count!=9 or not isValidNode row[9] do throw "Missing actual retained output node."
        local b=nodeGetBoundingBox row[9] (matrix3 1),tm=row[9].transform
        append rows #(row[1],row[2],row[3],copy row[4],row[5],row[6],row[7],row[8],copy b[1],copy b[2],copy tm.row1,copy tm.row2,copy tm.row3,copy tm.row4,getHandleByAnim row[9])
    )
    #(rows,caCompositionRows setup)
)
fn caAStable a b handles:true=
(
    local same=a[1].count==b[1].count and a[2].count==b[2].count
    for i=1 to a[1].count while same do
    (
        local x=a[1][i],y=b[1][i]
        for field in #(1,2,3,5,6,7,8) where x[field]!=y[field] do same=false
        for axis=1 to 3 where x[4][axis]!=y[4][axis] do same=false
        for field in #(9,10,14) where distance x[field] y[field]>0.003 do same=false
        for field in #(11,12,13) where distance x[field] y[field]>0.00001 do same=false
        if handles and x[15]!=y[15] do same=false
    )
    for i=1 to a[2].count while same do
    (
        local x=a[2][i],y=b[2][i]
        for field in #(1,2,3,6) where x[field]!=y[field] do same=false
        if not (deepEqual x[4] y[4] strictCompare:true) do same=false
        for axis=1 to 3 where x[5][axis]!=y[5][axis] do same=false
    )
    same
)
fn caAObjects=(for node in objects collect (getHandleByAnim node))
fn caASameSet a b=(local same=a.count==b.count;for id in a where (findItem b id)==0 do same=false;same)

fn caAFixture reuse=
(
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0f
    caABooks=(caCreateBookRowFixtures includeFurniture:false)[1]
    caABoard=box name:"CA_ATOMIC_TOP" width:1200 length:500 height:30 pos:[0,0,500]
    caAGroup=group #(caABoard) name:"CA_ATOMIC_FURNITURE"
    caAGroup.pivot=[0,0,0]
    caAObstacle=box name:"CA_ATOMIC_OBSTACLE" width:120 length:120 height:200 pos:[350,0,530]
    caASetup=caCreateSetup #(caAGroup) 1
    caASetup.name="CA_ATOMIC_SETUP"
    caAAssetLeaf=undefined
    for child in caABooks[1][1].children while caAAssetLeaf==undefined do if isProperty child #height do caAAssetLeaf=child
    caARequire "fixture contains a real editable accessory geometry child" (caAAssetLeaf!=undefined)
    for book in caABooks do
    (
        local id=caRegisterAsset caASetup book[1] book[2] 1 3 #(0.0) 1 1 1 false
        caSetAssetBookRow caASetup id 3
    )
    local settings=(caSetupSummary caASetup)[9]
    settings[1]=137;settings[2]=0.04;settings[3]=20;settings[4]=10;settings[5]=0;settings[6]=0;settings[7]=0;settings[8]=2;settings[10]=25;settings[11]=false
    caSetArrangeSettings caASetup settings
    local rules=caCategoryRules caASetup 1
    for row in rules do (row[2]=1;row[3]=if row[1]==1 then 8 else 0;row[4]=false)
    caSetCategoryRules caASetup 1 rules
    caSetCollisionScope caASetup #(caAObstacle) false
    -- Author a bounded count before explicitly restoring the raw row recipe.
    -- The ordinary placement command intentionally clears book_rows; its call
    -- must precede caSetCompositionSettings, as in the legacy-minimum fixture.
    -- Preserve this harness's exact raw settings/cell size after preconditioning.
    local placement=caPlacementSettings caASetup
    placement[1]=137L;placement[2]=2;placement[3]=6;placement[4]=0.04
    placement[5]=20;placement[6]=10;placement[7]=false;placement[8]=false;placement[9]=1.0;placement[10]=1.0
    caGeneratePlacement caASetup placement false
    caSetArrangeSettings caASetup settings
    caSetCompositionSettings caASetup #(true,3,3,3,0)
    caSetGeometryCacheEnabled reuse
    caClearAllGeometryCaches()
    caGenerate caASetup #()
    caGenerate caASetup #()
    local info=caGeometryCacheInfo caASetup
    local baselineRows=caOutputRows caASetup,baselineGroups=caCompositionRows caASetup
    local baselineSummary=caSetupSummary caASetup,baselinePlacement=caPlacementSettings caASetup,baselineRecipe=caCompositionSettings caASetup
    caANote ("BASELINE outputs="+(baselineRows.count as string)+" groups="+(baselineGroups.count as string)+" dirty="+(baselineSummary[6] as string)+" completed="+(info[3][4] as string)+" published="+(info[3][5] as string)+" amount="+(baselinePlacement as string)+" recipe="+(baselineRecipe as string)+" cache="+(info[3][2] as string))
    caARequire "baseline explicitly retains six-copy Quantity and its legal enabled raw row recipe" (baselinePlacement[2]==2 and baselinePlacement[3]==6 and not baselinePlacement[7] and not baselinePlacement[8] and baselineRecipe[1] and baselineRecipe[2]==3 and baselineRecipe[3]==3 and baselineRecipe[4]==3 and baselineRecipe[5]==0)
    caARequire "baseline has real generated row relationship and clean publication" ((caCompositionRows caASetup).count>0 and (caSetupSummary caASetup)[6]==0 and info[3][4] and info[3][5])
    caARequire "baseline has all six actual generated copies" (baselineRows.count==6)
    caARequire "baseline disposition proves intended reuse mode" (if reuse then (info[3][2]=="hit" and info[3][6] and info[3][7]>0 and info[3][9]>0 and info[3][8]==0 and info[3][10]==0) else (info[3][2]!="hit" and info[3][8]>0 and info[3][10]>0))
    caARequire "baseline real meshes fit independently measured fixture" (caAPhysical())
)

fn caAPhysical=
(
    local valid=true,output=caOutputRows caASetup,boards=#()
    for node in caAGroup.children where (superClassOf node)==GeometryClass do append boards (nodeGetBoundingBox node (matrix3 1))
    local obstacle=nodeGetBoundingBox caAObstacle (matrix3 1)
    for row in output do
    (
        local b=nodeGetBoundingBox row[9] (matrix3 1),supported=false
        for board in boards do if abs(b[1].z-board[2].z)<0.03 and b[1].x>=board[1].x-0.03 and b[2].x<=board[2].x+0.03 and b[1].y>=board[1].y-0.03 and b[2].y<=board[2].y+0.03 do supported=true
        if not supported do valid=false
        if (amin #(b[2].x,obstacle[2].x)-amax #(b[1].x,obstacle[1].x))>0.03 and (amin #(b[2].y,obstacle[2].y)-amax #(b[1].y,obstacle[1].y))>0.03 and (amin #(b[2].z,obstacle[2].z)-amax #(b[1].z,obstacle[1].z))>0.03 do valid=false
    )
    valid
)
fn caARunCase mode reuse=
(
    caAFixture reuse
    caAMode=mode
    caAID=case mode of (#furniture:#CA_CacheAtomic_Furniture;#obstacle:#CA_CacheAtomic_Obstacle;#asset:#CA_CacheAtomic_Asset;#newChild:#CA_CacheAtomic_NewChild;#furnitureUndoOff:#CA_CacheAtomic_FurnitureUndoOff;#reentrant:#CA_CacheAtomic_Reentrant)
    caARequire "callback ID belongs to exact owned ID list" ((findItem caAIDs caAID)>0)
    caAArmed=false;caAFired=0;caAInvocations=0;caAFiredHandle=0;caANewInput=undefined
    caACallbackError="";caAInnerError="";caAInnerRejected=false;caAActionCompleted=false;caAInputDuring=undefined;caATicketDuring=undefined
    caAInputBefore=caAMeasure()
    local before=caASnapshot caASetup,revision=(caSetupSummary caASetup)[3],ticket=caGeometryDependencyInfo caASetup
    local nodesBefore=caAObjects(),lastSequence=(caGeometryCacheInfo caASetup)[3][12]
    callbacks.addScript #nodeCreated caAOnCreated id:caAID persistent:false
    local registered=callbacks.show #nodeCreated id:caAID asArray:true
    caARequire "one owned function callback is registered nonpersistent" (registered.count==1 and not registered[1][3])
    caAArmed=true
    local rejected=false,outerError="",result=undefined
    caANote ("BEGIN publication callback mode="+(mode as string))
    try (result=caGenerate caASetup #()) catch (rejected=true;outerError=getCurrentException() as string)
    -- Guaranteed by caACase too if any statement above throws unexpectedly.
    caACleanup()
    caACheck "one-shot callback actually fires on a real newly created node" (caAFired==1 and caAFiredHandle!=0)
    caACheck "callback action completes without a harness exception" (caAActionCompleted and caACallbackError=="")
    if mode!=#reentrant do caACheck "callback performs a real input change" (if mode==#newChild then caAInputDuring==caAInputBefore+1 else caAInputDuring!=undefined and abs(caAInputDuring-caAInputBefore-11)<0.001)
    caANote ("CALLBACK invocations="+(caAInvocations as string)+" firedHandle="+(caAFiredHandle as string)+" inputBefore="+(caAInputBefore as string)+" inputDuring="+(caAInputDuring as string)+" inputAfter="+((caAMeasure()) as string)+" ticketDuring="+(caATicketDuring as string)+" outerError="+outerError+" innerError="+caAInnerError)
    local info=caGeometryCacheInfo caASetup,summary=caSetupSummary caASetup
    if mode==#reentrant then
    (
        caACheck "same-document nested Generate rejects its reentrancy guard" (caAInnerRejected and (findString (toLower caAInnerError) "already active")!=undefined)
        caACheck "handled nested Generate does not abort/corrupt outer success" (not rejected and result!=undefined and info[3][4] and info[3][5] and info[3][12]>lastSequence)
        caACheck "outer success preserves complete logical row result" (caAStable before (caASnapshot caASetup) handles:false)
        caACheck "only outer generation advances authored revision" (summary[3]==revision+1 and summary[6]==0)
        caACheck "reentrant rejection creates no upstream geometry edit" (deepEqual ticket (caGeometryDependencyInfo caASetup) strictCompare:true)
        local expected=#()
        for id in nodesBefore do
        (
            local oldOutput=false
            for row in before[1] where row[15]==id do oldOutput=true
            if not oldOutput do append expected id
        )
        local createdIsOwned=false
        for row in (caOutputRows caASetup) do (local id=getHandleByAnim row[9];append expected id;if id==caAFiredHandle do createdIsOwned=true)
        caACheck "successful outer publication owns the observed node with no extras" (createdIsOwned and caASameSet expected (caAObjects()) and caAPhysical())
    )
    else
    (
        caACheck "real upstream edit rejects stale successor before acceptance" (rejected and (findString (toLower outerError) "changed during")!=undefined)
        caACheck "failed publication preserves every previous output/group/pose/reference" (caAStable before (caASnapshot caASetup))
        caACheck "failed publication does not advance authored revision" (summary[3]==revision)
        caACheck "failed publication records completed=false/published=false" (info[3][12]>lastSequence and not info[3][4] and not info[3][5])
        caACheck "input dirtiness survives transaction cancellation" (summary[6]!=0 and summary[8]!="")
        caACheck "input epoch never rewinds through cancellation" ((caGeometryDependencyInfo caASetup)[4]>ticket[4])
        caACheck "first unaccepted output node is actually removed" (not isValidNode (getAnimByHandle caAFiredHandle))
        local allowed=copy nodesBefore #noMap
        if isValidNode caANewInput do append allowed (getHandleByAnim caANewInput)
        caACheck "no partial output nodes survive beside any retained real input" (caASameSet allowed (caAObjects()))
        if mode==#furnitureUndoOff do caACheck "Undo-off source edit really remains after Cancel" (abs(caABoard.width-caAInputBefore-11)<0.001)
        local actual=(caAMeasure()) as string
        caANote ("OBSERVATION normal callback source may restore or persist after Cancel; actual="+actual)
        -- Probe Manual tick before recovery: callback dirty work cannot be
        -- silently marked clean, auto-published, or lost with restored Lifecycle.
        caTick()
        caACheck "Manual service retains prior real outputs and pending edit" ((caSetupSummary caASetup)[6]!=0 and (caAStable before (caASnapshot caASetup)))
        caGenerate caASetup #()
        caACheck "explicit recovery publishes valid physical supports after callback removal" ((caSetupSummary caASetup)[6]==0 and caAPhysical())
    )
)
fn caABootstrap=
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Runner-owned project/output paths required."
    if (maxVersion())[1]!=29000 do throw "Atomic cache callback draft requires Max2027."
    if caGeometryCacheInfo==undefined or caGeometryDependencyInfo==undefined or caSetGeometryCacheEnabled==undefined do throw "Integrated candidate diagnostic/ticket/toggle API required."
    CA_AUTO_SHOW_UI=false
    fileIn (CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    caAOriginalEnabled=caGeometryCacheEnabled()
    for reuse in #(false,true) do
    (
        caACase "existing furniture edit during publication" #furniture reuse
        caACase "existing external obstacle edit during publication" #obstacle reuse
        caACase "existing asset descendant edit during publication" #asset reuse
        caACase "new furniture child attach/edit during publication" #newChild reuse
        caACase "Undo-off furniture edit survives failed publication" #furnitureUndoOff reuse
        caACase "same-document nested Generate rejects while outer succeeds" #reentrant reuse
    )
)
try (caABootstrap()) catch
(
    caAFailures+=1;caANote ("EXCEPTION bootstrap: "+(getCurrentException() as string))
    caANote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
try (caACheck "final exact-ID callback cleanup" (caACleanup())) catch (caAFailures+=1;caANote ("FINAL_CLEANUP_ERROR "+(getCurrentException() as string)))
if caAOriginalEnabled!=undefined do try (caClearAllGeometryCaches();caSetGeometryCacheEnabled caAOriginalEnabled) catch (caAFailures+=1;caANote ("RESTORE_TOGGLE_ERROR "+(getCurrentException() as string)))
caAFinished=true
caAWrite()
