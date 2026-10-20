/* Exact-pair owned Max2027 native API/physical test. Does not qualify the new Modify UI. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global caFxBox,caFxMM
global caGWLog=#(),caGWPasses=0,caGWFailures=0
fn caGWCheck label value =
(
    if value then caGWPasses+=1 else caGWFailures+=1
    append caGWLog ((if value then "PASS " else "FAIL ")+label)
    if not value do throw ("Geometry workflow: "+label)
    value
)
fn caGWPose rows = (for r in rows collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8]))
fn caGWEqual a b = deepEqual a b strictCompare:true
fn caGWGrid setup = (local a=(caSetupSummary setup)[9];a[10]=50;caSetArrangeSettings setup a)
/* Draft addition to existing native geometry workflow; no new shipped file. */
fn caGWNeutralRegions owner =
(
    local rows=caRegionRows owner,neutral=rows.count>0
    for row in rows do
        if row[2]!="" or row[3]!="" or row[4]!=1 or row[9]!=2047 or row[10]!=1 or not row[11] or row[12] or row[13]!=[0,-1,0]do neutral=false
    neutral
)
fn caGWAcceptedGrid owner = ((caSetupSummary owner)[9][10])
fn caGWNeutralSampling =
(
    local board=caFxBox "GW_Neutral_Receiver" [120,120,20] [40000,0,0]
    local large=caFxBox "GW_Neutral_Large" [60,60,40] [42000,0,0]
    local small=caFxBox "GW_Neutral_Small" [6,6,10] [42200,0,0]
    local originals=#(copy board.transform,copy large.transform,copy small.transform)
    local owner=caCreateSetup #(board)1;owner.name="GW_Neutral_LockedGrid"
    caSetCollisionScope owner #()false
    local largeID=caRegisterAsset owner large "Neutral large prop"7 31 #(0.0)1.0 1.0 1.0 false
    local values=caPlacementSettings owner
    values[1]=412034L;values[2]=2;values[3]=1;values[5]=2;values[6]=5
    values[7]=false;values[8]=false;values[9]=1;values[10]=1
    local result=caGeneratePlacement owner values false,rows=caOutputRows owner
    caGWCheck "Neutral large-only Generate actually chooses10mm sampling"(result[1]==1 and result[2]==1 and result[5]==0 and rows.count==1 and(caGWAcceptedGrid owner)==10 and caGWNeutralRegions owner)
    local protectedID=rows[1][1]
    caSetLocked owner #(protectedID)true
    local protected=(caGWPose(caOutputRows owner))[1],protectedRegion=protected[3]
    local smallID=caRegisterAsset owner small "Neutral small prop"7 31 #(0.0)1.0 1.0 1.0 false
    caGWCheck "Adding the smaller source leaves every region semantic field at its neutral default"(caGWNeutralRegions owner and protected[7]and(caCompositionRows owner).count==0)
    -- Real counterfactual command, same receiver and complete source palette.
    -- A120x120mm board is below the15625XY budget at1mm, so the area floor
    -- cannot accidentally make the two automatic grids equal.
    local counter=caCreateSetup #(board)1;counter.name="GW_Neutral_AutoCounterfactual"
    caSetCollisionScope counter #()false
    caRegisterAsset counter large "Neutral large prop"7 31 #(0.0)1.0 1.0 1.0 false
    local counterSmall=caRegisterAsset counter small "Neutral small prop"7 31 #(0.0)1.0 1.0 1.0 false
    local counterValues=caPlacementSettings counter
    counterValues[1]=412034L;counterValues[2]=2;counterValues[3]=1;counterValues[5]=2;counterValues[6]=5
    counterValues[7]=false;counterValues[8]=false;counterValues[9]=1;counterValues[10]=1
    local counterResult=caGeneratePlacementMinimums counter counterValues #(#(counterSmall,1))false false
    caGWCheck "Actual neutral unlocked counterfactual selects1mm with the same receiver and source palette"(counterResult[2]==1 and(caOutputRows counter)[1][2]==counterSmall and(caGWAcceptedGrid counter)==1 and(caGWAcceptedGrid counter)!=(caGWAcceptedGrid owner)and caGWNeutralRegions counter)
    values=caPlacementSettings owner;values[3]=2
    result=caGeneratePlacementMinimums owner values #(#(smallID,1))false false
    local after=undefined
    rows=caOutputRows owner
    for row in(caGWPose rows)do if row[1]==protectedID do after=row
    caGWCheck "Locked-only automatic Generate retains10mm with no nondefault region metadata"(result[1]==2 and result[2]==2 and result[5]==0 and(caGWAcceptedGrid owner)==10 and caGWNeutralRegions owner)
    caGWCheck "Locked-only retention preserves every protected ID pose scale region lock and parent field"(after!=undefined and caGWEqual protected after and(caCompositionRows owner).count==0)
    local smallCount=0,physical=true
    for row in rows do
    (
        if row[2]==smallID do smallCount+=1
        local b=nodeGetBoundingBox row[9](matrix3 1)
        if abs(b[1].z-20)>0.03 or b[1].x<39944.97 or b[2].x>40055.03 or b[1].y< -55.03 or b[2].y>55.03 or row[6]!=1 do physical=false
    )
    caGWCheck "Retained-grid generation places the required small prop with complete original-size board footprints"(smallCount>=1 and physical)
    local blocker=caFxBox "GW_Neutral_CurrentBlocker" [10,10,10](protected[4]+[0,0,10])
    caSetCollisionScope owner #(blocker)false
    local accepted=caPlacementSettings owner,acceptedRows=caGWPose(caOutputRows owner),revision=(caSetupSummary owner)[3],handles=#(),regions=caRegionRows owner,rejected=false
    for row in(caOutputRows owner)do append handles(getHandleByAnim row[9])
    try(caGeneratePlacementMinimums owner accepted #(#(smallID,1))false false)catch(rejected=true)
    local afterHandles=#()
    for row in(caOutputRows owner)do append afterHandles(getHandleByAnim row[9])
    caGWCheck "A current real obstacle rejects the retained protected pose without committing seed settings regions outputs or handles"(rejected and(caSetupSummary owner)[3]==revision and caGWEqual accepted(caPlacementSettings owner)and caGWEqual regions(caRegionRows owner)and caGWEqual acceptedRows(caGWPose(caOutputRows owner))and caGWEqual handles afterHandles)
    caSetCollisionScope owner #()false
    delete blocker
    caSetLocked owner #(protectedID)false
    local noLocks=true
    for row in(caOutputRows owner)do if row[7]do noLocks=false
    caGWCheck "Explicit unlock releases the only sampling pin and region semantics remain neutral"(noLocks and caGWNeutralRegions owner)
    result=caGeneratePlacementMinimums owner(caPlacementSettings owner)#(#(smallID,1))false false
    local freshRegions=true
    for row in(caOutputRows owner)do if row[3]==protectedRegion do freshRegions=false
    caGWCheck "Neutral unlocked automatic Generate regrids to the witnessed1mm and allocates fresh region identity"(result[1]==2 and result[2]==2 and result[5]==0 and(caGWAcceptedGrid owner)==1 and freshRegions and caGWNeutralRegions owner)
    caGWCheck "Grid retention rejection and release preserve original receiver and source geometry transforms"(caGWEqual originals #(board.transform,large.transform,small.transform)and board.width==120 and board.length==120 and board.height==20 and large.width==60 and large.length==60 and large.height==40 and small.width==6 and small.length==6 and small.height==10)
    append caGWLog "SAMPLING_WITNESS neutral=true largeOnlyMM=10 actualSmallPaletteMM=1 protectedMM=10 releasedMM=1; real physical obstacle rejected atomically. No automatic+chosen export is present; existing raw selective coverage remains separate."
    true
)

try
(
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1
    fileIn (CA_TEST_ROOT+"tests/max/fixtures.ms")
    caGWCheck "Actual native version is 0.3.2" (caVersion()=="0.3.2")
    local board=caFxBox "GW_Receiver" [6000,1200,20] [0,0,0]
    local source=caFxBox "GW_Book" [30,100,200] [10000,0,0]
    source.material=standardMaterial name:"GW_Source_Material" diffuse:(color 100 150 200)
    local originalTM=source.transform as string
    local setup=caCreateSetup #(board) 1;setup.name="GW_Books_Arrangement";caGWGrid setup
    -- Kitchenware tag / Kitchen-only mask must not block use on any receiver.
    caRegisterAsset setup source "Repeated geometry" 10 8 #(0.0) 1.0 1.0 1.0 false
    local values=caPlacementSettings setup
    caGWCheck "Native placement settings expose ten bounded fields" (values.count==10)
    values[1]=412032L;values[2]=2;values[3]=100;values[5]=0;values[6]=5
    values[7]=true;values[8]=false;values[9]=0.8;values[10]=1.1
    local result=undefined
    undo "Generate native quantity" on (result=caGeneratePlacement setup values false)
    local rows=caOutputRows setup
    caGWCheck "One source generates 100 copies without semantic caps" (result[1]==100 and result[2]==100 and result[5]==0 and rows.count==100)
    caGWCheck "Source transform and dimensions remain unchanged" ((source.transform as string)==originalTM and source.width==30 and source.length==100 and source.height==200)
    local physical=true, varied=false, materials=true
    for i=1 to rows.count do
    (
        local r=rows[i],p=r[4],s=r[6]
        if s<0.8 or s>1.1 or abs(p.z-20)>0.03 or r[5]!=0 then physical=false
        if abs(s-rows[1][6])>0.01 do varied=true
        if p.x-15*s < -2995.03 or p.x+15*s > 2995.03 or p.y-50*s < -595.03 or p.y+50*s > 595.03 do physical=false
        if not isValidNode r[9] then physical=false
        else
        (
            local bounds=nodeGetBoundingBox r[9] (matrix3 1)
            if abs(bounds[1].z-20)>0.03 or abs((bounds[2].z-bounds[1].z)-200*s)>0.03 then physical=false
            if r[9].material==undefined or r[9].material.name!="GW_Source_Material" do materials=false
        )
        for j=1 to i-1 do
        (
            local q=rows[j]
            if abs(p.x-q[4].x)<15*(s+q[6])-0.03 and abs(p.y-q[4].y)<50*(s+q[6])-0.03 do physical=false
        )
    )
    caGWCheck "Actual 100 output meshes satisfy scale, contact, full footprint and pair nonoverlap" physical
    caGWCheck "Random sizes actually differ" varied
    caGWCheck "Actual generated objects preserve source material" materials
    local signature=caGWPose rows
    result=caGeneratePlacement setup values false
    caGWCheck "Same seed repeats complete native poses and scales" (caGWEqual signature (caGWPose(caOutputRows setup)))
    local saved=caPlacementSettings setup
    undo "New native variation" on (result=caGeneratePlacement setup saved true)
    local newSettings=caPlacementSettings setup
    caGWCheck "Generate chooses a new nonnegative seed" (newSettings[1]>=0 and newSettings[1]!=saved[1])
    max undo
    caGWCheck "Undo restores settings and complete placements together" (caGWEqual saved (caPlacementSettings setup) and caGWEqual signature (caGWPose(caOutputRows setup)))
    max redo
    caGWCheck "Redo restores new settings" (caGWEqual newSettings (caPlacementSettings setup))
    local beforeRevision=(caSetupSummary setup)[3],beforeRows=caGWPose(caOutputRows setup)
    local invalid=for v in newSettings collect v;invalid[3]=-1
    local rejected=false
    try(caGeneratePlacement setup invalid false)catch(rejected=true)
    caGWCheck "Invalid draft retains prior seed, revision and output" (rejected and (caSetupSummary setup)[3]==beforeRevision and caGWEqual beforeRows (caGWPose(caOutputRows setup)) and caGWEqual newSettings (caPlacementSettings setup))
    local filename=CA_TEST_OUTPUT+"Geometry-Workflow-032.max"
    saveMaxFile filename quiet:true
    loadMaxFile filename quiet:true useFileUnits:true
    setup=getNodeByName "GW_Books_Arrangement"
    caGWCheck "Actual Max schema7 save/reopen retains all quantity and scale fields" (isValidNode setup and caGWEqual newSettings (caPlacementSettings setup))
    caGWCheck "Actual Max save/reopen retains all poses" (caGWEqual beforeRows (caGWPose(caOutputRows setup)))
    local floorNode=caFxBox "GW_Cabinet_Floor" [600,400,20] [20000,0,0]
    local roof=caFxBox "GW_Cabinet_Roof" [600,400,20] [20000,0,300]
    local device=caFxBox "GW_Device" [100,100,450] [22000,0,0]
    local deviceTM=device.transform as string
    local cabinet=caCreateSetup #(floorNode) 1;caGWGrid cabinet
    caSetCollisionScope cabinet #(roof) false
    caRegisterAsset cabinet device "Oversized device" 10 8 #(0.0) 1.0 1.0 1.0 false
    local options=caPlacementSettings cabinet
    options[1]=412033L;options[2]=2;options[3]=1;options[5]=0;options[6]=5
    options[7]=false;options[8]=false;options[9]=0.5;options[10]=1.1
    result=caGeneratePlacement cabinet options false
    caGWCheck "450mm device correctly fails at original size beneath 280mm clearance" (result[1]==1 and result[2]==0 and result[5]==1)
    options[8]=true;result=caGeneratePlacement cabinet options false
    local devices=caOutputRows cabinet
    caGWCheck "Fit scaling publishes one valid device" (result[2]==1 and devices.count==1)
    local scale=devices[1][6],actual=nodeGetBoundingBox devices[1][9] (matrix3 1)
    caGWCheck "Actual fitted device is supported and clears the real roof" (scale>=0.5 and scale<0.623 and abs(actual[1].z-20)<0.03 and actual[2].z<=300.03)
    caGWCheck "Fit never alters original device geometry or transform" (device.height==450 and (device.transform as string)==deviceTM)
    options[9]=0.7;result=caGeneratePlacement cabinet options false
    caGWCheck "Fit respects minimum scale and reports unfilled" (result[1]==1 and result[2]==0 and result[5]==1)
    caGWNeutralSampling()
)
catch(append caGWLog ("ERROR "+(getCurrentException() as string));caGWFailures+=1)
(
local report=createFile(CA_TEST_OUTPUT+"result.txt")
format "% passes=% failures=%\n" (if caGWFailures==0 then "SUCCESS" else "ERROR") caGWPasses caGWFailures to:report
for line in caGWLog do format "%\n" line to:report
close report
)
