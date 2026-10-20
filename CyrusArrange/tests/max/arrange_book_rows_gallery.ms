/* 0.1.2 visual qualification. Owned Max2027 batch only; resets scene.
   Requires runner CA_TEST_ROOT / CA_TEST_OUTPUT. No output transform is authored.
   Run only with the matching native pair through the isolated test runner.
*/
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI, CA_BOOKROW_RENDER
global caCreateBookRowFixtures, caBRTVConsole, caBROpenShelf, caBRbox, caBRgroup, caBRWorldGeometryBounds
global caCreateSetup, caSetupSummary, caRegisterAsset, caSetArrangeSettings, caAnalyzeSetup
global caRegionRows, caSetRegionRules, caGenerate, caOutputRows, caSetCollisionScope
global caCategoryRules, caSetCategoryRules, caSetCompositionSettings, caCompositionRows
global caCompositionStats, caSetAssetBookRow, caAssetBookRow, caAssetRows, caSetLocked
global caBVLog=#(), caBVPasses=0, caBVFailures=0, caBVFinished=false, caBVContext="initialization"
global caBVWrite, caBVNote, caBVCheck, caBVRequire, caBVNum, caBVLayer, caBVAssign, caBVHideSource
global caBVFind, caBVSnapshot, caBVSame, caBVMetric, caBVConfigure, caBVCategoryCaps
global caBVSurfaces, caBVBooks, caBVVerify, caBVTallPlant, caBVBalanceConsole
global caBVText, caBVCamera, caBVFace, caBVRender, caBVGenerate, caBVStage
global caBVMetrics=#(), caBVSetups=#(), caBVSourceLayer, caBVChosenSeed=0

fn caBVNum value = (dotNetClass "System.Convert").ToString value (dotNetClass "System.Globalization.CultureInfo").InvariantCulture
fn caBVWrite =
(
    local out=createFile (CA_TEST_OUTPUT+"result.txt")
    local state=if caBVFinished then (if caBVFailures==0 then "SUCCESS" else "ERROR") else "RUNNING"
    format "% passes=% failures=%\n" state caBVPasses caBVFailures to:out
    for message in caBVLog do format "%\n" message to:out
    flush out;close out
)
fn caBVNote message = (append caBVLog message;caBVWrite();true)
fn caBVStage message = (caBVContext=message;caBVNote ("STAGE "+message))
fn caBVCheck label condition =
(
    if condition then (caBVPasses+=1;caBVNote ("PASS "+label)) else (caBVFailures+=1;caBVNote ("FAIL "+label))
    condition
)
fn caBVRequire label condition = (caBVCheck label condition;if not condition do throw ("Prerequisite: "+label);true)
fn caBVLayer label =
(
    local layer=LayerManager.getLayerFromName label
    if layer==undefined do layer=LayerManager.newLayerFromName label
    layer
)
fn caBVAssign nodes layer =
(
    for node in nodes where isValidNode node do
    (
        layer.addNode node
        local children=for child in node.children collect child
        if children.count>0 do caBVAssign children layer
    )
    true
)
fn caBVHideSource node =
(
    node.renderable=false
    for child in node.children do caBVHideSource child
    true
)
fn caBVFind rows id =
(
    local found=undefined
    for row in rows while found==undefined do if row[1]==id do found=row
    found
)
fn caBVSnapshot setup =
(
    -- Owned numeric boxes; a later native Generate deletes prior output nodes.
    local captured=#()
    for row in (caOutputRows setup) do
    (
        if not isValidNode row[9] do throw "Cannot snapshot a missing generated node."
        local bounds=nodeGetBoundingBox row[9] (matrix3 1)
        append captured #(row[1],row[2],row[3],copy bounds[1],copy bounds[2],row[6],row[7],row[8],copy row[4],row[5])
    )
    captured
)
fn caBVSame first second =
(
    local same=first.count==second.count
    for row in first while same do
    (
        local other=caBVFind second row[1]
        if other==undefined then same=false
        else
        (
            for index in #(1,2,3,6,7,8,10) where row[index]!=other[index] do same=false
            if distance row[4] other[4]>0.02 or distance row[5] other[5]>0.02 or distance row[9] other[9]>0.02 do same=false
        )
    )
    same
)
fn caBVMetric snapshot left right supportZ =
(
    -- Independent world-AABB front profile: all authored yaws are exactly zero.
    -- Region front is -Y; native lateral therefore equals world +X.
    local heights=for index=1 to 16 collect 0.0
    local width=(right-left)/16.0
    for bin=1 to 16 do
    (
        local lower=left+(bin-1)*width, upper=left+bin*width
        for row in snapshot where row[5].x>lower and row[4].x<upper do heights[bin]=amax #(heights[bin],row[5].z-supportZ)
    )
    local total=0.0, moment=0.0
    for bin=1 to 16 do (total+=heights[bin];moment+=heights[bin]*(-0.9375+0.125*(bin-1)))
    if total>0 then abs(moment)/total else 0.0
)
fn caBVConfigure setup seed density =
(
    local settings=(caSetupSummary setup)[9]
    settings[1]=seed;settings[2]=density;settings[3]=20;settings[4]=10
    settings[5]=0;settings[6]=0;settings[7]=0;settings[8]=2;settings[10]=25;settings[11]=false
    caSetArrangeSettings setup settings
    caSetCollisionScope setup #() false
)
fn caBVCategoryCaps setup books plants =
(
    local category=((caSetupSummary setup)[9])[9]
    local rules=caCategoryRules setup category
    for row in rules do
    (
        row[2]=1.0;row[4]=false
        row[3]=case row[1] of (1 : books; 3 : plants; default : 0)
    )
    caSetCategoryRules setup category rules
)
fn caBVSurfaces setup label heights mask =
(
    caAnalyzeSetup setup
    local active=#()
    for row in (caRegionRows setup) do
    (
        local enabled=false
        for height in heights where abs(row[5].z-height)<0.02 and abs(row[6].z-height)<0.02 do enabled=true
        caSetRegionRules setup row[1] (label+" support") label 3 mask 1.0 false (not enabled) [0,-1,0]
        if enabled do append active row
    )
    if active.count==0 do throw ("No intended supports: "+label)
    active
)
fn caBVBooks setup sources =
(
    local ids=#()
    for source in sources do
    (
        local id=caRegisterAsset setup source[1] source[2] 1 3 #(0.0) 1.0 1.0 1.0 false
        caSetAssetBookRow setup id 3 -- Public tag3 = authored local -Y spine.
        append ids id
    )
    ids
)
fn caBVGenerate setup label =
(
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    process.Refresh();local before=caBVNum process.WorkingSet64
    local stopwatch=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
    local result=caGenerate setup #()
    stopwatch.Stop();process.Refresh()
    append caBVMetrics #(label,caBVNum stopwatch.Elapsed.TotalMilliseconds,before,caBVNum process.WorkingSet64,caBVNum process.PeakWorkingSet64,caBVNum result[2],caBVNum result[4])
    process.Dispose()
    result
)
fn caBVVerify setup label offset kind heights =
(
    local groups=caCompositionRows setup, outputs=caOutputRows setup, members=#()
    local separate=true, gap=true, face=true, scale=true, fit=true
    for group in groups do
    (
        if group[2]!=1 or group[4].count!=3 do separate=false
        local previous=undefined, front=undefined
        for id in group[4] do
        (
            if (findItem members id)!=0 do separate=false
            append members id
            local row=caBVFind outputs id
            if row==undefined then separate=false
            else if not isValidNode row[9] then separate=false
            else
            (
                local bounds=nodeGetBoundingBox row[9] (matrix3 1)
                if previous!=undefined do if abs(bounds[1].x-previous[2].x-3)>0.03 do gap=false
                if front!=undefined do if abs(bounds[1].y-front)>0.03 do face=false
                if abs(row[6]-1)>0.00001 or abs(row[5])>0.00001 or row[8]!=0L do scale=false
                local contact=false
                for height in heights where abs(bounds[1].z-height)<0.03 do contact=true
                if not contact do fit=false
                local low=bounds[1]-offset, high=bounds[2]-offset
                local halfX=if kind==#tv then (if low.z>599 then 900 else 870) else 570
                local frontY=if kind==#tv then -225 else -175
                local rearY=if kind==#tv then (if low.z>599 then 225 else 213) else 163
                if low.x < -halfX-0.03 or high.x > halfX+0.03 or low.y < frontY-0.03 or high.y > rearY+0.03 do fit=false
                if kind==#shelf or low.z<599 do
                (
                    local divider=if kind==#tv then 12 else 10
                    if high.x > -divider+0.03 and low.x < divider-0.03 do fit=false
                )
                previous=bounds;front=bounds[1].y
            )
        )
    )
    caBVCheck (label+" actual native rows are nonempty") (groups.count>0)
    caBVCheck (label+" rows have three distinct real placement members") separate
    caBVCheck (label+" measured internal gap3 under external spacing20") gap
    caBVCheck (label+" authored negative-Y spine envelopes front-align") face
    caBVCheck (label+" fixed-size scale1 yaw0 and no stack-parent substitution") scale
    caBVCheck (label+" full world boxes obey independent shelf/divider/height bounds") fit
    caBVNote ("COUNTS "+label+" placements="+(outputs.count as string)+" rows="+(groups.count as string))
)
fn caBVTallPlant base =
(
    local clay=standardMaterial name:"CA_BV_Plant_Clay" diffuse:(color 141 77 49)
    local green=standardMaterial name:"CA_BV_Plant_Leaves" diffuse:(color 63 91 56) twoSided:true
    local soil=standardMaterial name:"CA_BV_Plant_Soil" diffuse:(color 48 40 32)
    local parts=#()
    local pot=cylinder name:"CA_BV_Plant_Pot" radius:40 height:100 sides:32 pos:base
    pot.material=clay;append parts pot
    local ground=cylinder name:"CA_BV_Plant_Soil" radius:35 height:5 sides:32 pos:(base+[0,0,95])
    ground.material=soil;append parts ground
    local stem=cylinder name:"CA_BV_Plant_Stem" radius:3 height:260 sides:12 pos:(base+[0,0,100])
    stem.material=green;append parts stem
    local vertices=#([0,0,400],[30,0,360],[0,0,330],[-30,0,360],[0,0,320],[0,30,280],[0,0,250],[0,-30,280])
    for index=1 to vertices.count do vertices[index]+=base
    local leaves=mesh name:"CA_BV_Plant_OriginalLeaves" vertices:vertices faces:#([1,2,3],[1,3,4],[5,6,7],[5,7,8])
    leaves.material=green;append parts leaves
    caBRgroup parts "Gallery_TallPlant_80x80x400" base
)
fn caBVBalanceConsole offset =
(
    local oak=standardMaterial name:"CA_BV_Balance_Oak" diffuse:(color 132 94 57)
    local metal=standardMaterial name:"CA_BV_Balance_Metal" diffuse:(color 45 51 51)
    local parts=#()
    append parts (caBRbox "Balance_Top" [1000,400,30] (offset+[0,0,570]) oak)
    for side in #(-470,470) do append parts (caBRbox "Balance_Leg" [30,360,570] (offset+[side,0,0]) metal)
    caBRgroup parts "Balance_Console_1000x400x600" offset
)
fn caBVText label caption position size material =
(
    local node=text name:label text:caption font:"Arial" size:size alignment:1 pos:position
    addModifier node (Extrude amount:0.75)
    node.material=material;node.renderable=true;node.castShadows=false
    node
)
fn caBVCamera label position aim fov =
(
    local target=targetObject name:(label+"_Target") pos:aim
    local camera=targetCamera name:label pos:position target:target fov:fov
    caBVAssign #(target,camera) (caBVLayer "CA_BV_90_CAMERAS")
    camera
)
fn caBVFace label camera =
(
    local basis=copy camera.transform
    basis.row4=label.transform.row4
    label.transform=basis
)
fn caBVRender camera label width height =
(
    caBVStage ("actual Scanline render "+label)
    renderWidth=width;renderHeight=height
    local path=CA_TEST_OUTPUT+"CyrusArrange-BookRows-"+label+".png"
    local start=timeStamp()
    local renderedImage=render camera:camera outputFile:path vfb:false
    close renderedImage
    caBVCheck ("actual image written "+label) (doesFileExist path)
    caBVNote ("RENDER "+label+" ms="+((timeStamp()-start) as string))
)

try
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Owned runner paths required before resetting scene."
    caBVRequire "host is3dsMax2027" ((maxVersion())[1]==29000)
    CA_AUTO_SHOW_UI=false
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1
    fileIn (CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    local fixture=caCreateBookRowFixtures offsetMM:[0,12000,0] includeFurniture:false
    local sources=fixture[1]
    caBVSourceLayer=caBVLayer "CA_BV_99_ORIGINAL_SOURCE_LIBRARY"
    for source in sources do
    (
        local bounds=caBRWorldGeometryBounds source[1]
        caBVCheck ("original full-size book "+source[2]) (distance (bounds[2]-bounds[1]) [source[4],source[5],source[3]]<0.02)
        caBVAssign #(source[1]) caBVSourceLayer
    )
    local tallSource=caBVTallPlant [1000,12000,0]
    caBVAssign #(tallSource) caBVSourceLayer
    for source in sources do caBVHideSource source[1]
    caBVHideSource tallSource
    caBVSourceLayer.isHidden=true

    caBVStage "generate actual TV console and shelf rows"
    local tvOffset=[-1900,400,0], shelfOffset=[1600,650,0], balanceOffset=[0,-1500,0]
    local furniture=#(caBRTVConsole tvOffset,caBROpenShelf shelfOffset)
    local heights=#(#(30,309,600),#(30,364,704,1044,1384))
    for category=1 to 2 do
    (
        local label=if category==1 then "TV" else "SHELF"
        local setup=caCreateSetup #(furniture[category]) category
        setup.name="CA_BV_SETUP_"+label
        caBVBooks setup sources
        caBVConfigure setup (if category==1 then 181 else 282) (if category==1 then 0.04 else 0.08)
        caBVCategoryCaps setup 6 0
        caBVSurfaces setup label heights[category] 1
        caSetCompositionSettings setup #(true,3,3,3,0)
        caBVGenerate setup label
        local first=caBVSnapshot setup, signature=(caCompositionRows setup) as string
        caBVGenerate setup (label+"_REPEAT")
        caBVCheck (label+" repeat exact native IDs/poses/row records") (caBVSame first (caBVSnapshot setup) and signature==((caCompositionRows setup) as string))
        caBVVerify setup label (if category==1 then tvOffset else shelfOffset) (if category==1 then #tv else #shelf) heights[category]
        local layer=caBVLayer ("CA_BV_"+label)
        caBVAssign #(setup,furniture[category]) layer
        local props=#()
        for row in (caOutputRows setup) do append props row[9]
        caBVAssign props layer
        append caBVSetups setup
    )

    caBVStage "bounded joint native seed search for locked tall prop and measurable row movement"
    local balanceFurniture=caBVBalanceConsole balanceOffset
    local balanceSetup=caCreateSetup #(balanceFurniture) 1
    balanceSetup.name="CA_BV_SETUP_BALANCE"
    local balanceIDs=caBVBooks balanceSetup sources
    local plantID=caRegisterAsset balanceSetup tallSource "Original tall botanical80x80x400" 3 3 #(0.0) 1.0 1.0 1.0 false
    local active=caBVSurfaces balanceSetup "BALANCE" #(600) 5
    caBVRequire "comparison has one independently bounded support" (active.count==1)
    local extent=active[1], left=extent[5].x, right=extent[6].x, supportZ=extent[5].z
    local area=(right-left)*(extent[6].y-extent[5].y), averageSlot=0.0
    for asset in (caAssetRows balanceSetup) do averageSlot+=(sqrt(asset[4].x*asset[4].y)+20)^2
    averageSlot/=4.0
    local density=3.5*averageSlot/area
    local before=#(), after=#(), beforeScore=0.0, afterScore=0.0, lockedID=0L, savedSignature=""
    for seed=1 to 32 while caBVChosenSeed==0 do
    (
        local oldIDs=#()
        for row in (caOutputRows balanceSetup) do append oldIDs row[1]
        if oldIDs.count>0 do caSetLocked balanceSetup oldIDs false
        caSetCompositionSettings balanceSetup #(false,3,3,3,0)
        caBVCategoryCaps balanceSetup 0 1
        caBVConfigure balanceSetup seed 0.001
        caBVGenerate balanceSetup ("SEARCH_PLANT_"+(seed as string))
        local plantRows=caOutputRows balanceSetup
        if plantRows.count==1 and plantRows[1][4].x < balanceOffset.x-180 do
        (
            lockedID=plantRows[1][1]
            caSetLocked balanceSetup #(lockedID) true
            caBVCategoryCaps balanceSetup 3 1
            caBVConfigure balanceSetup seed density
            caSetCompositionSettings balanceSetup #(true,3,3,3,0)
            caBVGenerate balanceSetup ("SEARCH_OFF_"+(seed as string))
            local offGroups=caCompositionRows balanceSetup
            if offGroups.count==1 and (caOutputRows balanceSetup).count==4 do
            (
                before=caBVSnapshot balanceSetup;beforeScore=caBVMetric before left right supportZ
                savedSignature=offGroups as string
                caSetCompositionSettings balanceSetup #(true,3,3,3,1)
                caBVGenerate balanceSetup ("SEARCH_ON_"+(seed as string))
                after=caBVSnapshot balanceSetup;afterScore=caBVMetric after left right supportZ
                local stats=caCompositionStats balanceSetup
                if stats[1] and stats[6]>0 and afterScore < beforeScore-0.00001 do caBVChosenSeed=seed
            )
        )
        caBVNote ("SEARCH seed="+(seed as string)+" chosen="+(caBVChosenSeed as string))
    )
    caBVRequire "within32seeds actual native row movement improves independent height metric" (caBVChosenSeed>0)
    local fixedBefore=caBVFind before lockedID, fixedAfter=caBVFind after lockedID
    caBVCheck "actual generated tall prop is locked and unchanged" (fixedBefore!=undefined and fixedAfter!=undefined and fixedAfter[7] and distance fixedBefore[9] fixedAfter[9]<0.02)
    caBVCheck "same row identities survive off/on generation" (savedSignature==((caCompositionRows balanceSetup) as string))
    local physical=true, changed=false
    for row in before do
    (
        local other=caBVFind after row[1]
        if other==undefined then physical=false
        else
        (
            if row[2]!=other[2] or row[6]!=1 or other[6]!=1 or row[10]!=other[10] or distance (row[5]-row[4]) (other[5]-other[4])>0.03 do physical=false
            if row[1]!=lockedID and distance row[9] other[9]>0.03 do changed=true
        )
    )
    caBVCheck "off/on retain identical models dimensions scales and yaws" physical
    caBVCheck "measured improvement comes from native book-row translation" changed
    caBVNote ("BALANCE seed="+(caBVChosenSeed as string)+" region="+(caBVNum extent[1])+" assetIDs="+(balanceIDs as string)+" plantAsset="+(caBVNum plantID)+" lockedPlacement="+(caBVNum lockedID)+" density="+(caBVNum density)+" off="+(caBVNum beforeScore)+" on="+(caBVNum afterScore))
    local balanceLayer=caBVLayer "CA_BV_BALANCE"
    caBVAssign #(balanceSetup,balanceFurniture) balanceLayer
    append caBVSetups balanceSetup

    caBVStage "original stage cameras lights and annotations"
    local stage=caBVLayer "CA_BV_80_STAGE"
    local floorMaterial=standardMaterial name:"CA_BV_CharcoalStage" diffuse:(color 37 44 47)
    local typeMaterial=standardMaterial name:"CA_BV_IvoryType" diffuse:(color 225 218 195) selfIllumAmount:35 twoSided:true
    local ground=box name:"CA_BV_STAGE" width:6400 length:5000 height:50 pos:[0,0,-55]
    ground.material=floorMaterial;stage.addNode ground
    local overview=caBVCamera "CA_BV_CAMERA_OVERVIEW" [0,-8400,5300] [0,0,850] 45
    local tvCamera=caBVCamera "CA_BV_CAMERA_TV" [-1900,-2000,1350] [-1900,400,480] 46
    local shelfCamera=caBVCamera "CA_BV_CAMERA_SHELF" [1600,-1750,1800] [1600,650,900] 44
    local balanceCamera=caBVCamera "CA_BV_CAMERA_BALANCE" [0,-3400,1550] [0,-1500,800] 45
    local title=caBVText "CA_BV_TITLE" "CYRUS ARRANGE / INDIVIDUAL BOOK ROWS" [0,1550,2300] 155 typeMaterial
    caBVFace title overview
    local subtitle=caBVText "CA_BV_SUBTITLE" "ORIGINAL MODELS / NATIVE RELATIONSHIPS / PHYSICAL SCALE1" [0,1540,2110] 53 typeMaterial
    caBVFace subtitle overview
    local caption=caBVText "CA_BV_BALANCE_CAPTION" "ROW HEIGHT BALANCE" [0,-1500,1210] 46 typeMaterial
    caBVFace caption balanceCamera
    caBVAssign #(title,subtitle,caption) stage
    caBVCheck "titles use renderable camera-facing Matrix3 basis" ((dot (normalize title.transform.row3) (normalize (overview.position-title.position)))>0.97)
    local key=omniLight name:"CA_BV_KEY" pos:[-2500,-3500,6500] multiplier:0.85 color:(color 255 238 214)
    key.baseObject.castShadows=true;key.shadowGenerator=raytraceShadow()
    local fill=omniLight name:"CA_BV_FILL" pos:[3000,-1000,5500] multiplier:0.4 color:(color 215 230 255)
    local rim=omniLight name:"CA_BV_RIM" pos:[0,2500,5000] multiplier:0.3 color:(color 255 244 221)
    caBVAssign #(key,fill,rim) (caBVLayer "CA_BV_91_LIGHTS")
    ambientLight=color 30 30 30;backgroundColor=color 23 29 33
    renderers.current=Default_Scanline_Renderer()
    if CA_BOOKROW_RENDER==undefined do CA_BOOKROW_RENDER=true
    viewport.setCamera overview
    select balanceSetup

    -- Reproduce each actual native state; never restore poses by assigning TMs.
    caSetCompositionSettings balanceSetup #(true,3,3,3,0)
    caBVGenerate balanceSetup "FINAL_OFF"
    caBVCheck "final OFF reproduces measured native poses" (caBVSame before (caBVSnapshot balanceSetup))
    local finalProps=#()
    for row in (caOutputRows balanceSetup) do append finalProps row[9]
    caBVAssign finalProps balanceLayer
    caption.text="ROW HEIGHT BALANCE OFF / B="+(formattedPrint beforeScore format:".4f")
    local offScene=CA_TEST_OUTPUT+"CyrusArrange-BookRows-Balance-Off.max"
    renderWidth=2400;renderHeight=1500
    saveMaxFile offScene quiet:true
    caBVCheck "owned OFF max saved" (doesFileExist offScene)
    if CA_BOOKROW_RENDER do
    (
        caBVRender overview "Overview-Off" 2400 1500
        caBVRender balanceCamera "Balance-Off" 1800 1100
        caBVRender tvCamera "TV-Rows" 1800 1100
        caBVRender shelfCamera "Shelf-Rows" 1500 1500
    )
    caSetCompositionSettings balanceSetup #(true,3,3,3,1)
    caBVGenerate balanceSetup "FINAL_ON"
    caBVCheck "final ON reproduces measured native poses" (caBVSame after (caBVSnapshot balanceSetup))
    finalProps=#()
    for row in (caOutputRows balanceSetup) do append finalProps row[9]
    caBVAssign finalProps balanceLayer
    caption.text="ROW HEIGHT BALANCE ON / B="+(formattedPrint afterScore format:".4f")
    local onScene=CA_TEST_OUTPUT+"CyrusArrange-BookRows-Balance-On.max"
    renderWidth=2400;renderHeight=1500
    saveMaxFile onScene quiet:true
    caBVCheck "owned ON max saved" (doesFileExist onScene)
    if CA_BOOKROW_RENDER do
    (
        caBVRender overview "Overview-On" 2400 1500
        caBVRender balanceCamera "Balance-On" 1800 1100
    )
    local metrics=createFile (CA_TEST_OUTPUT+"book-row-performance.csv")
    format "stage,generate_stopwatch_ms,before_working_set_bytes,after_working_set_bytes,after_peak_working_set_bytes,placements,candidates\n" to:metrics
    for row in caBVMetrics do for column=1 to row.count do
    (
        format "%" row[column] to:metrics
        if column==row.count then format "\n" to:metrics else format "," to:metrics
    )
    flush metrics;close metrics
    caBVNote "SCOPE command wall time includes native recapture/query rebuild/solve/material publication/Undo; process memory includes Max and prior scenes/history. Independent16bin metric uses real world boxes; no postposing or image edits."
)
catch
(
    local message=getCurrentException() as string, stack=getCurrentExceptionStackTrace() as string
    caBVFailures+=1;caBVNote ("ERROR_CONTEXT "+caBVContext);caBVNote ("ERROR "+message);caBVNote ("STACK "+stack)
    local exception=createFile (CA_TEST_OUTPUT+"book-row-gallery-exception.txt")
    format "context=%\nexception=%\nstack=%\n" caBVContext message stack to:exception
    flush exception;close exception
)
caBVFinished=true
caBVWrite()
