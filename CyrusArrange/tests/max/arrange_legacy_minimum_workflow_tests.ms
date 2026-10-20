/* Owned normal Max2027: an old enabled row recipe must not block inline
   minimum copies. Actual native-hosted Modify handlers; no legacy popup,
   synthetic mounting, computer use, artist state or installer activity. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global CyrusArrange,caModifierUI,caModifierViewOwner
global caCreateBookRowFixtures,caBRcoffeeTable
global caLMLog=#(),caLMPasses=0,caLMFailures=0,caLMFinished=false
global caLMWrite,caLMNote,caLMCheck,caLMEqual,caLMProtectedExact,caLMPose,caLMState,caLMNodes,caLMFind
global caLMOpen,caLMNoPopups,caLMSourceSignature,caLMLiveMaterials,caLMCount,caLMMinimum
global caLMRowValid,caLMPhysical,caLMLegacy,caLMDraft,caLMReopen,caLMLine
global caLMSurface,caLMZeroMinimum,caLMPath,caLMRun

fn caLMWrite =
(
    local stream=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n"(if caLMFinished then(if caLMFailures==0 then "SUCCESS" else "ERROR")else "RUNNING")caLMPasses caLMFailures to:stream
    for line in caLMLog do format "%\n"line to:stream
    close stream
)
fn caLMNote line=(append caLMLog line;caLMWrite();true)
fn caLMCheck label value=
(
    if value then caLMPasses+=1 else caLMFailures+=1
    caLMNote((if value then "PASS " else "FAIL ")+label)
    if not value do throw("Legacy minimum workflow: "+label)
    value
)
fn caLMEqual a b=deepEqual a b strictCompare:true
-- Regeneration may publish protected records in stable-ID order rather than
-- the previous row's geometric order. Compare the complete eight-field pose
-- by its identity; never sort/relax the separately checked group member order.
fn caLMProtectedExact expected actual diagnose:true=
(
    local valid=expected.count==actual.count,seen=#(),reported=0
    if not valid and diagnose do caLMNote("PROTECTED_COUNT expected="+(expected.count as string)+" actual="+(actual.count as string))
    for before in expected do
    (
        local matches=0,after=undefined,unique=(findItem seen before[1])==0
        append seen before[1]
        for candidate in actual where candidate[1]==before[1]do(matches+=1;after=candidate)
        local same=unique and matches==1 and caLMEqual before after
        if not same do
        (
            valid=false
            if diagnose and reported<8 do
            (
                caLMNote("PROTECTED_ID "+(before[1]as string)+" expected_unique="+(unique as string)+" actual_matches="+(matches as string)+" before="+(before as string)+" after="+(after as string))
                reported+=1
            )
        )
    )
    valid
)
fn caLMPose owner=for row in(caOutputRows owner)collect #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
fn caLMNodes owner=for row in(caOutputRows owner)collect #(row[1],getHandleByAnim row[9])
fn caLMFind rows id=(for row in rows where row[1]==id do return row;undefined)
fn caLMState owner=
(
    local summary=caSetupSummary owner,path=caPathSettings owner
    local savedPath=if path==undefined then #()else #(path[1].name,path[2],path[3])
    #(summary[1],summary[3],caPlacementSettings owner,caCompositionSettings owner,caCompositionRows owner,caPropMinimums owner,caLMPose owner,savedPath)
)
fn caLMOpen owner=
(
    max modify mode
    modPanel.setPinStack false
    select owner
    local modifier=undefined
    for item in owner.modifiers where classOf item==CyrusArrange do modifier=item
    if modifier==undefined do throw "Missing native Cyrus Arrange modifier."
    modPanel.setCurrentObject modifier node:owner ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caModifierUI!=undefined and caModifierViewOwner!=undefined and caModifierUI.isDisplayed and caModifierUI.hwnd!=0 and windows.isWindow caModifierUI.hwnd and caModifierUI.currentSetup()==owner and caModifierUI.currentContext()==owner and modPanel.getCurrentObject()==modifier
)
fn caLMNoPopups=
(
    for name in #(#caHomeUI,#caHomePropsUI,#caArrangeUI,#caAssetUI,#caUI,#caRegionUI,#caCollisionUI,#caCompositionUI,#caRulesUI)do
    (
        local view=globalVars.get name
        if view!=undefined do if view.isDisplayed do return false
    )
    true
)
-- Complete original geometry/transform/material-name evidence; source handles
-- are separately checked within a live generation, never across file loading.
fn caLMSourceSignature roots=
(
    local pending=for root in roots collect root,rows=#()
    while pending.count>0 do
    (
        local node=pending[pending.count]
        deleteItem pending pending.count
        for child in node.children do append pending child
        local transformRows=for axis=1 to 4 collect node.transform[axis]
        local material=if node.material==undefined then #()else #(classOf node.material as string,node.material.name)
        if not(isGroupHead node)and(superClassOf node)==GeometryClass then
        (
            local mesh=snapshotAsMesh node
            append rows #(node.name,transformRows,material,(for i=1 to mesh.numverts collect getVert mesh i),(for i=1 to mesh.numfaces collect #(getFace mesh i,getFaceMatID mesh i,getFaceSmoothGroup mesh i)))
            delete mesh
        )
        else append rows #(node.name,transformRows,material)
    )
    rows
)
fn caLMLiveMaterials roots=
(
    local pending=for root in roots collect root,rows=#()
    while pending.count>0 do
    (
        local node=pending[pending.count]
        deleteItem pending pending.count
        for child in node.children do append pending child
        append rows #(node.name,getHandleByAnim node,(if node.material==undefined then 0 else getHandleByAnim node.material))
    )
    rows
)
fn caLMCount owner assetID=(local count=0;for row in(caOutputRows owner)where row[2]==assetID do count+=1;count)
fn caLMMinimum owner assetID=(for row in(caPropMinimums owner)where row[1]==assetID do return row[2];0)
fn caLMRowValid owner rowGroup=
(
    local rows=caOutputRows owner,previous=undefined,valid=rowGroup[4].count==3
    for id in rowGroup[4] do
    (
        local row=caLMFind rows id
        if row==undefined then valid=false
        else
        (
            local bounds=nodeGetBoundingBox row[9](matrix3 1)
            if not row[7] or abs(row[6]-1)>0.00001 do valid=false
            if previous!=undefined do if abs((bounds[1].x-previous[2].x)-rowGroup[6])>0.03 or abs(bounds[1].y-previous[1].y)>0.03 or abs(bounds[1].z-previous[1].z)>0.03 do valid=false
            previous=bounds
        )
    )
    valid and abs(rowGroup[6]-3)<0.00001
)
-- All authored yaws are0 and scales are1 in this regression. Therefore actual
-- output AABBs are complete horizontal footprints, with no rotated-box shortcut.
fn caLMPhysical owner center rowGroup:undefined=
(
    local rows=caOutputRows owner,valid=true
    for i=1 to rows.count do
    (
        local row=rows[i],bounds=nodeGetBoundingBox row[9](matrix3 1)
        if abs(row[5])>0.0001 or abs(row[6]-1)>0.00001 or abs(bounds[1].z-(center.z+730))>0.03 or row[9].material==undefined do valid=false
        if bounds[1].x<center.x-588.03 or bounds[2].x>center.x+588.03 or bounds[1].y<center.y-288.03 or bounds[2].y>center.y+288.03 do valid=false
        for j=1 to i-1 do
        (
            local other=nodeGetBoundingBox rows[j][9](matrix3 1)
            local dx=amax #(0.0,bounds[1].x-other[2].x,other[1].x-bounds[2].x),dy=amax #(0.0,bounds[1].y-other[2].y,other[1].y-bounds[2].y)
            local required=20.0
            if rowGroup!=undefined do if findItem rowGroup[4] row[1]>0 and findItem rowGroup[4] rows[j][1]>0 do required=rowGroup[6]
            if sqrt(dx*dx+dy*dy)<required-0.03 do valid=false
        )
    )
    valid
)
-- Establish an ordinary count, explicitly author the old raw recipe, then run
-- raw caGenerate. There are no minima and no hidden popup in this legal state.
fn caLMLegacy label center protectRow:false =
(
    local books=(caCreateBookRowFixtures offsetMM:center includeFurniture:false)[1]
    local table=caBRcoffeeTable center,book=books[1][1],owner=caCreateSetup #(table) 1
    owner.name=label
    local bookID=caRegisterAsset owner book (label+" book") 1 31 #(0.0) 1.0 1.0 1.0 false
    caSetAssetBookRow owner bookID 3
    caSetCollisionScope owner #()false
    local values=caPlacementSettings owner
    values[1]=7231L;values[2]=2;values[3]=6;values[5]=20;values[6]=12;values[7]=false;values[8]=false;values[9]=0.8;values[10]=1.1
    caGeneratePlacement owner values false
    caSetCompositionSettings owner #(true,3,3,3,1)
    caGenerate owner #()
    caLMCheck(label+": raw legacy recipe legally produces six actual books in two rows")((caOutputRows owner).count==6 and(caCompositionRows owner).count==2 and(caCompositionSettings owner)[1]and(caPropMinimums owner).count==0)
    if protectRow do
    (
        local group=(caCompositionRows owner)[1]
        caSetLocked owner #(group[4][2])true
        caLMCheck(label+": protecting the middle member closes the whole three-book row")(caLMRowValid owner group)
    )
    local decor=box name:(label+"_OptionalDecor")width:80 length:60 height:70 pos:(center+[0,2000,0])
    decor.material=standardMaterial name:(label+"_OptionalMaterial")diffuse:(color 190 140 70)
    -- Optional demand overwhelmingly chooses decor. A positive book minimum
    -- must reserve extra books rather than accidentally pass an all-book case.
    local decorID=caRegisterAsset owner decor (label+" optional decor")7 31 #(0.0)1000000.0 1.0 1.0 false
    #(owner,bookID,decorID,book,decor,table)
)
fn caLMDraft owner bookID copies minimum repeatSeed:true=
(
    if not(caLMOpen owner)do throw "Cannot mount real legacy Modify controls."
    local view=caModifierViewOwner,index=0
    local rows=caAssetRows owner
    for i=1 to rows.count where rows[i][1]==bookID do index=i
    if index==0 do throw "The required source is not listed in Modify."
    view.propControls.propList.selection=index
    view.dispatch #minimumSelection
    view.propControls.minimumCopies.value=minimum
    view.propControls.minimumCopies.changed minimum
    caModifierUI.amountMode.selection=1
    view.amountChanged 1
    caModifierUI.quantity.value=copies
    caModifierUI.keepSeed.checked=repeatSeed
    caModifierUI.keepSeed.changed repeatSeed
    view.scaleControls.randomScale.checked=false
    view.scaleControls.randomScale.changed false
    view.scaleControls.fitScale.checked=false
    view.scaleControls.fitScale.changed false
    view.scaleControls.minimumScale.value=80
    view.scaleControls.maximumScale.value=110
    true
)
fn caLMReopen owner filename=
(
    local name=owner.name,state=caLMState owner
    max create mode
    caLMCheck("Save "+filename+" preserves the accepted legacy/ordinary state")(saveMaxFile(CA_TEST_OUTPUT+filename)quiet:true)
    caLMCheck("Load "+filename+" succeeds")(loadMaxFile(CA_TEST_OUTPUT+filename)quiet:true useFileUnits:true)
    owner=getNodeByName name exact:true
    caLMCheck("Reopened "+filename+" retains accepted seed minimums groups poses and mode")(isValidNode owner and caLMEqual state(caLMState owner))
    owner
)
fn caLMLine label center=
(
    local curve=splineShape name:label
    addNewSpline curve
    addKnot curve 1 #corner #line (center+[-480,0,730])
    addKnot curve 1 #corner #line (center+[480,0,730])
    updateShape curve
    curve
)

fn caLMSurface=
(
    local fixture=caLMLegacy "LM_Surface" [0,0,0]protectRow:true
    local owner=fixture[1],bookID=fixture[2],decorID=fixture[3],bookName=fixture[4].name,decorName=fixture[5].name,tableName=fixture[6].name
    owner=caLMReopen owner "legacy-before-generate.max"
    local roots=#(getNodeByName bookName exact:true,getNodeByName decorName exact:true,getNodeByName tableName exact:true)
    local source=caLMSourceSignature roots,live=caLMLiveMaterials roots,before=caLMState owner,nodes=caLMNodes owner
    local protectedGroup=(caCompositionRows owner)[1],protectedPoses=for row in(caLMPose owner)where findItem protectedGroup[4] row[1]>0 collect row
    local commands=(caGeometryCacheInfo owner)[3]
    caLMCheck "Reopened enabled recipe and actual protected relationship mount in Modify"(caLMOpen owner and caLMRowValid owner protectedGroup)
    caLMCheck "Mounting the legacy arrangement is passive and opens no popup"(caLMEqual before(caLMState owner)and caLMEqual commands(caGeometryCacheInfo owner)[3]and caLMNoPopups())
    caLMDraft owner bookID 8 5 repeatSeed:false
    caLMCheck "Inline minimum and Copies drafts do not migrate or mutate legacy accepted state"(caLMEqual before(caLMState owner)and(caModifierUI.readMinimumDraft())[1][2]==5)
    local view=caModifierViewOwner
    view.scaleControls.randomScale.checked=true;view.scaleControls.randomScale.changed true
    view.scaleControls.minimumScale.value=120;view.scaleControls.maximumScale.value=80
    caLMCheck "Invalid scale draft fails the real Generate and exposes its error"(not caModifierUI.generateButton.pressed()and caModifierUI.errorMessage()!="")
    caLMCheck "Failed scale draft retains mode minimums seed revision exact output nodes and groups"(caLMEqual before(caLMState owner)and caLMEqual nodes(caLMNodes owner))
    caLMDraft owner bookID 4 5 repeatSeed:false
    caLMCheck "Excessive inline minimum fails without prematurely disabling the legacy recipe"(not caModifierUI.generateButton.pressed()and caLMEqual before(caLMState owner)and caLMEqual nodes(caLMNodes owner))
    caLMDraft owner bookID 8 5 repeatSeed:true
    caLMCheck "Real unified Generate accepts the legacy row and inline minimum transaction"(caModifierUI.generateButton.pressed())
    local accepted=caLMState owner,rows=caOutputRows owner,groups=caCompositionRows owner,stats=caCompositionStats owner
    caLMCheck "Successful Generate disables only the hidden row flag with one accepted revision"(not(caCompositionSettings owner)[1]and(caSetupSummary owner)[3]==before[2]+1 and(caCompositionSettings owner)[2]==3 and(caCompositionSettings owner)[3]==3 and(caCompositionSettings owner)[4]==3 and(caCompositionSettings owner)[5]==1)
    caLMCheck "Required book copies reserve room before heavily weighted optional decor"(rows.count==8 and caLMCount owner bookID==5 and caLMCount owner decorID==3 and caLMMinimum owner bookID==5 and findString caModifierUI.statusText.text "0 unfilled"!=undefined)
    local kept=for row in(caLMPose owner)where findItem protectedGroup[4] row[1]>0 collect row
    caLMCheck "Every protected book identity and pose remains exact with its original row descriptor"(caLMProtectedExact protectedPoses kept and groups.count==1 and caLMEqual groups[1]protectedGroup and caLMRowValid owner protectedGroup)
    caLMCheck "No hidden new book rows or height-balance probes execute"(stats[1]and stats[2]==0 and stats[3]==0 and stats[5]==0)
    caLMCheck "Complete output bounds obey support edge clearance and global or protected-row separation"(caLMPhysical owner [0,0,0]rowGroup:protectedGroup)
    caLMCheck "Original grouped book furniture and optional decor preserve full geometry and live material references"(caLMEqual source(caLMSourceSignature roots)and caLMEqual live(caLMLiveMaterials roots)and caLMNoPopups())
    commands=(caGeometryCacheInfo owner)[3][12]
    max undo
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caLMCheck "One Undo restores enabled legacy mode old policy seed revision groups and all poses"(caLMEqual before(caLMState owner))
    caLMCheck "Undo refreshes inline Copies and selected minimum without a new solve"(caModifierUI!=undefined and caModifierUI.quantity.value==6 and caModifierViewOwner.propControls.minimumCopies.value==0 and(caGeometryCacheInfo owner)[3][12]==commands)
    max redo
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caLMCheck "One Redo restores the complete accepted ordinary successor"(caLMEqual accepted(caLMState owner))
    caLMCheck "Redo refreshes the actual inline controls without solving"(caModifierUI!=undefined and caModifierUI.quantity.value==8 and caModifierViewOwner.propControls.minimumCopies.value==5 and(caGeometryCacheInfo owner)[3][12]==commands)
    owner=caLMReopen owner "legacy-minimum-accepted.max"
    accepted=caLMState owner
    caLMDraft owner bookID 8 5 repeatSeed:true
    caLMCheck "Reopened ordinary state hydrates its inline book minimum and preserves the protected row"(caLMMinimum owner bookID==5 and caModifierViewOwner.propControls.minimumCopies.value==5 and caLMRowValid owner protectedGroup)
    caLMCheck "Explicit repeat after reopen reproduces the exact accepted seed poses policy and protected relationship"(caModifierUI.generateButton.pressed()and caLMEqual accepted[3](caPlacementSettings owner)and caLMEqual accepted[5](caCompositionRows owner)and caLMEqual accepted[6](caPropMinimums owner)and caLMEqual accepted[7](caLMPose owner))
    local rawBefore=caLMState owner,rawNodes=caLMNodes owner,rejected=false
    try(caSetCompositionSettings owner #(true,3,3,3,1))catch(rejected=true)
    caLMCheck "Explicit raw row mode remains strict with accepted positive minima"(rejected and caLMEqual rawBefore(caLMState owner)and caLMEqual rawNodes(caLMNodes owner))
    owner
)
fn caLMZeroMinimum=
(
    local fixture=caLMLegacy "LM_ZeroMinimum" [4000,0,0],owner=fixture[1]
    -- This mode-only witness has one source. Competing optional demand is
    -- tested separately with a positive minimum in the surface/path cases.
    local optionalOriginal=caLMSourceSignature #(fixture[5])
    caRemoveAssets owner #(fixture[3])true
    caLMCheck "Zero-minimum raw witness explicitly retains a sole-book catalog and the original optional model"((caAssetRows owner).count==1 and(caAssetRows owner)[1][1]==fixture[2]and isValidNode fixture[5]and caLMEqual optionalOriginal(caLMSourceSignature #(fixture[5])))
    local legacy=caLMState owner
    caLMDraft owner fixture[2]6 0 repeatSeed:true
    caLMCheck "Zero-minimum unified Generate also selects ordinary geometry placement"(caModifierUI.generateButton.pressed()and not(caCompositionSettings owner)[1]and(caCompositionRows owner).count==0 and(caPropMinimums owner).count==0 and(caOutputRows owner).count==6)
    local stats=caCompositionStats owner
    caLMCheck "Zero-minimum ordinary mode executes no row recipe or balancing"(stats[1]and stats[2]==0 and stats[3]==0 and stats[5]==0 and caLMNoPopups())
    max undo
    caLMCheck "Zero-minimum Generate Undo restores the exact prior enabled raw rows"(caLMEqual legacy(caLMState owner))
    -- Raw explicit generation still honors the old recipe. It must not be
    -- globally disabled by load, validation, or the unified-command correction.
    caGenerate owner #()
    caLMCheck "Raw Generate still creates explicit legacy relationships without minima"((caCompositionSettings owner)[1]and(caCompositionRows owner).count==2 and(caPropMinimums owner).count==0 and(caOutputRows owner).count==6)
    true
)
fn caLMPath protectedFailure=
(
    local label=if protectedFailure then "LM_PathProtected" else "LM_Path",center=if protectedFailure then [12000,0,0]else [8000,0,0]
    local fixture=caLMLegacy label center protectRow:protectedFailure,owner=fixture[1],beforeBind=caLMState fixture[1]
    local curve=caLMLine(label+"_Line")center
    caLMCheck(label+": real Modify mounts before path binding")(caLMOpen owner)
    caLMCheck(label+": actual inline path binding commits the original spline")(caModifierViewOwner.dispatch #bindPath data:curve)
    caLMCheck(label+": binding a path alone preserves enabled recipe and accepted old outputs")((caCompositionSettings owner)[1]and caLMEqual beforeBind[7](caLMPose owner)and(caPathSettings owner)[1]==curve)
    caLMDraft owner fixture[2]6 5 repeatSeed:true
    local view=caModifierViewOwner
    view.pathControls.twoWay.checked=false;view.pathControls.twoWay.changed false
    view.pathControls.align.checked=true;view.pathControls.frontAxis.selection=1;view.pathControls.reverse.checked=false
    view.pathControls.offset.value=0;view.pathControls.limitWidth.checked=true;view.pathControls.limitWidth.changed true
    view.pathControls.laneWidth.value=300;view.pathControls.sideways.value=0;view.pathControls.along.value=0
    if protectedFailure then
    (
        local bound=caLMState owner,nodes=caLMNodes owner
        caModifierUI.keepSeed.checked=false;caModifierUI.keepSeed.changed false
        caLMCheck "Incompatible protected surface row fails the actual path Generate honestly"(not caModifierUI.generateButton.pressed()and findString (caModifierUI.errorMessage()) "Protected"!=undefined)
        caLMCheck "Failed path transition keeps old recipe minimums seed revision groups and exact output nodes"(caLMEqual bound(caLMState owner)and caLMEqual nodes(caLMNodes owner)and caLMNoPopups())
        max undo
        windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
        caLMCheck "A failed path Generate adds no Undo step ahead of the actual path binding"(caLMEqual beforeBind(caLMState owner)and caPathSettings owner==undefined)
    )
    else
    (
        caLMCheck "Actual path minimum command accepts and retires the inherited row recipe"(caModifierUI.generateButton.pressed()and not(caCompositionSettings owner)[1]and(caCompositionRows owner).count==0 and caLMMinimum owner fixture[2]==5 and(caOutputRows owner).count==6)
        caLMCheck "Path minimum reserves five books before the optional decor source"(caLMCount owner fixture[2]==5 and caLMCount owner fixture[3]==1 and caLMPhysical owner center)
        local accepted=caLMState owner
        owner=caLMReopen owner "legacy-path-minimum-accepted.max"
        caLMDraft owner fixture[2]6 5 repeatSeed:true
        caLMCheck "Reopened path repeats accepted settings minimums poses and path policy through actual Modify"(caModifierUI.generateButton.pressed()and caLMEqual accepted[3](caPlacementSettings owner)and caLMEqual accepted[6](caPropMinimums owner)and caLMEqual accepted[7](caLMPose owner)and caLMEqual accepted[8](caLMState owner)[8])
    )
    true
)
fn caLMRun=
(
    CA_AUTO_SHOW_UI=false
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms")do fileIn(CA_TEST_ROOT+"scripts/"+script)
    fileIn(CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    caLMCheck "Exact 0.3.2 native in an owned normal Max2027 host"((maxVersion())[1]==29000 and caVersion()=="0.3.2"and not maxOps.isInNonInteractiveMode())
    local comparatorRows=#(#(11L,1L,1,[0,0,0],0.0,1.0,true,0L),#(12L,1L,1,[1,0,0],0.0,1.0,true,0L))
    caLMCheck "Protected pose comparator accepts reordered records with exact per-ID values"(caLMProtectedExact comparatorRows #(comparatorRows[2],comparatorRows[1])diagnose:false)
    local moved=deepCopy comparatorRows
    moved[1][4]=moved[1][4]+[0.00001,0,0]
    caLMCheck "Protected pose comparator rejects even a small actual pose change"(not(caLMProtectedExact comparatorRows moved diagnose:false))
    caLMCheck "Protected pose comparator rejects duplicate or missing identities"(not(caLMProtectedExact comparatorRows #(comparatorRows[1],comparatorRows[1])diagnose:false))
    caLMSurface()
    caLMZeroMinimum()
    caLMPath false
    caLMPath true
    caLMCheck "All regression actions kept the single Modify workflow without a popup"(caLMNoPopups())
    caLMNote "LIMIT: legal raw legacy recipe is produced and saved by this exact pair; no claim of opening an independently released binary fixture, mouse gestures, rendered pixels or installer acceptance. Complete pose/bounds/state/material-source checks are regression evidence, not a replacement for independent full-mesh qualification."
    true
)
try(caLMRun())catch
(
    caLMFailures+=1
    caLMNote("EXCEPTION "+(getCurrentException()as string))
    caLMNote("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string))
    caLMNote("STACK "+(getCurrentExceptionStackTrace()as string))
)
caLMFinished=true
caLMWrite()
