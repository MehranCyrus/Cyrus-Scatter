/* Original five-category gallery. Dedicated, disposable Max 2027 batch only.
   Run through tools/run_max_tests.py; never fileIn in an artist session.
   Factories, generated geometry and measurements are all native/MAXScript.
   The separate arrange_gallery_render.ms loads this saved owned scene.
*/
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI, CA_GALLERY_SCENE
global caFxTVConsole, caFxOpenShelf, caFxBox, caCreateAccessoryFixtures
global caFECurvedCoffeeTable, caFERoundDiningTable, caFELKitchenCounter
global caCreateSetup, caSetupSummary, caRegisterAsset, caSetArrangeSettings
global caAnalyzeSetup, caRegionRows, caSetRegionRules, caGenerate, caOutputRows, caSetCollisionScope
global caGLog = #(), caGPasses = 0, caGFailures = 0, caGFinished = false
global caGWrite, caGRecord, caGCheck, caGRequire, caGEqualRows, caGMask
global caGLayer, caGAssign, caGLabel, caGCamera, caGBoxCorners, caGMemory, caGNumber
global caGEllipsePolygon, caGInsideL, caGVerify, caGSurfaceRules, caGSetup
global caGSetups = #(), caGMetrics = #()
global caGContext = "initialization", caGStep

fn caGWrite =
(
    local state = if caGFinished then (if caGFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
    for fileName in #("result.txt","gallery-progress.txt") do
    (
        local out = createFile (CA_TEST_OUTPUT+fileName)
        format "% passes=% failures=%\n" state caGPasses caGFailures to:out
        for line in caGLog do format "%\n" line to:out
        flush out
        close out
    )
    true
)
fn caGRecord message = (append caGLog message; caGWrite(); true)
fn caGStep message = (caGContext = message; caGRecord ("STAGE "+message))
fn caGCheck label condition =
(
    if condition then (caGPasses += 1; caGRecord ("PASS "+label))
    else (caGFailures += 1; caGRecord ("FAIL "+label))
    condition
)
fn caGRequire label condition =
(
    caGCheck label condition
    if not condition do throw ("Gallery prerequisite failed: "+label)
    true
)
fn caGEqualRows a b =
(
    local same = a.count == b.count
    for i = 1 to a.count while same do
    (
        for j in #(1,2,3,7,8) where a[i][j] != b[i][j] do same = false
        if distance a[i][4] b[i][4] > 0.001 or abs(a[i][5]-b[i][5]) > 0.000001 or abs(a[i][6]-b[i][6]) > 0.000001 do same = false
    )
    same
)
fn caGMask categories =
(
    local mask = 0
    for category in categories do mask = bit.or mask (bit.shift 1 (category-1))
    mask
)
fn caGNumber value = (dotNetClass "System.Convert").ToString value (dotNetClass "System.Globalization.CultureInfo").InvariantCulture
fn caGMemory process =
(
    process.Refresh()
    #((caGNumber process.WorkingSet64),(caGNumber process.PeakWorkingSet64))
)
fn caGLayer label =
(
    local layer = LayerManager.getLayerFromName label
    if layer == undefined do layer = LayerManager.newLayerFromName label
    layer
)
fn caGAssign nodes layer =
(
    for node in nodes where isValidNode node do
    (
        caGContext = "assign gallery layer to "+node.name
        layer.addNode node
        local children = for child in node.children collect child
        if children.count > 0 do caGAssign children layer
    )
    true
)
fn caGLabel caption location sizeMM material =
(
    local node = text name:("CA_GALLERY_LABEL_"+caption) text:caption font:"Arial" size:sizeMM alignment:1 pos:location
    addModifier node (Extrude amount:1.5)
    node.material = material
    node.renderable = true
    node.castShadows = false
    node
)
fn caGCamera label positionMM targetMM fovDegrees =
(
    local aim = targetObject name:(label+"_TARGET") pos:targetMM
    local camera = targetCamera name:label pos:positionMM target:aim fov:fovDegrees
    caGAssign #(camera,aim) (caGLayer "CA_GALLERY_90_CAMERAS")
    camera
)
fn caGBoxCorners node =
(
    local bounds = nodeGetBoundingBox node (matrix3 1)
    -- World axes equal the generated full-bounds axes for authored quarter turns.
    #([bounds[1].x,bounds[1].y,0],[bounds[2].x,bounds[1].y,0],
      [bounds[2].x,bounds[2].y,0],[bounds[1].x,bounds[2].y,0])
)
fn caGEllipsePolygon point center radiusX radiusY =
(
    local p = point-center
    local inside = (p.x*p.x/(radiusX*radiusX)+p.y*p.y/(radiusY*radiusY)) <= 1.000001
    -- Independently check the ACTUAL 96-sided fixture outline as well as its
    -- analytic enclosing ellipse/circle. Neither check calls a native fit helper.
    for edge = 0 to 95 while inside do
    (
        local a = [radiusX*cos(360.0*edge/96),radiusY*sin(360.0*edge/96),0]
        local b = [radiusX*cos(360.0*(edge+1)/96),radiusY*sin(360.0*(edge+1)/96),0]
        if ((b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x)) < -0.02 do inside = false
    )
    inside
)
fn caGInsideL point =
(
    local epsilon = 0.02
    ((point.x >= -1500-epsilon and point.x <= 1500+epsilon and point.y >= -325-epsilon and point.y <= 325+epsilon) or
     (point.x >= -1500-epsilon and point.x <= -850+epsilon and point.y >= 325-epsilon and point.y <= 1550+epsilon))
)
/* BUILD-ONLY proposal. Embedded into the existing gallery fixture on adoption.
   Actual referenced triangle base band; no native contact/region/fit API.
   World Mesh-value convention follows the evaluated cache-boundary oracle.
   XY clipping uses Double arrays; .02mm is a geometric boundary allowance. */
global caGXYOrder,caGTurn,caGArea,caGHull,caGBottomHull,caGClipAxis,caGRectHit,caGRectContains,caGBaseEllipse,caGBaseInside,caGBaseControls
global caGSortWork=0
fn caGXYOrder a b =
(
    caGSortWork+=1
    if caGSortWork>100000 do throw "Gallery base sort work exceeds admission."
    if a[1]<b[1] then -1 else if a[1]>b[1] then 1 else if a[2]<b[2] then -1 else if a[2]>b[2] then 1 else 0
)
fn caGTurn a b c = ((b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1]))
fn caGArea polygon =
(
    local value=0.0 as double
    if polygon.count>=3 do for index=2 to polygon.count-1 do value+=caGTurn polygon[1] polygon[index] polygon[index+1]
    (abs value)*0.5
)
fn caGHull points =
(
    if points.count<3 or points.count>4096 do throw "Gallery referenced contact-point admission failed."
    caGSortWork=0;qsort points caGXYOrder
    local unique=#(),hull=#()
    for p in points do if unique.count==0 then append unique p else
        if p[1]!=unique[unique.count][1] or p[2]!=unique[unique.count][2] do append unique p
    if unique.count<3 do throw "Gallery projected contact has no area."
    for pass=1 to 2 do
    (
        local chain=#()
        for index=1 to unique.count do
        (
            local p=unique[if pass==1 then index else unique.count-index+1]
            while chain.count>=2 and (caGTurn chain[chain.count-1] chain[chain.count] p)<=0 do deleteItem chain chain.count
            append chain p
        )
        if chain.count>0 do deleteItem chain chain.count
        join hull chain
    )
    if hull.count<3 or hull.count>256 or (caGArea hull)<=0 do throw "Gallery contact hull is degenerate or exceeds admission."
    hull
)
-- Returns #(Double XY hull, actual minimum Z, complete Double bounds,
--           evaluated vertex count, evaluated face count, ignored degenerate faces).
fn caGBottomHull node =
(
    if not isValidNode node or isGroupHead node do throw "Gallery base oracle requires one actual generated mesh."
    local value=undefined,result=undefined,errorText=undefined
    try
    (
        in coordsys world (value=snapshotAsMesh node renderMesh:false)
        if value==undefined or value.numverts<3 or value.numverts>10000 or value.numfaces<1 or value.numfaces>20000 do throw "Gallery evaluated mesh admission failed."
        local factor=(1.0/(units.decodeValue "1mm")) as double,vertices=#(),low=#(1e30 as double,1e30 as double,1e30 as double),high=#(-1e30 as double,-1e30 as double,-1e30 as double)
        for index=1 to value.numverts do
        (
            local raw=meshop.getVert value index,p=#((raw.x as double)*factor,(raw.y as double)*factor,(raw.z as double)*factor)
            for axis=1 to 3 do
            (
                if p[axis]!=p[axis] or abs(p[axis])>1e9 do throw "Gallery base oracle found a nonfinite/out-of-range vertex."
                low[axis]=amin #(low[axis],p[axis]);high[axis]=amax #(high[axis],p[axis])
            )
            append vertices p
        )
        local floor=low[3],plane=floor+0.5,points=#(),touch=false,degenerate=0
        for index=1 to value.numfaces do
        (
            local face=getFace value index,ids=#(face.x as integer,face.y as integer,face.z as integer)
            for id in ids do if id<1 or id>vertices.count do throw "Gallery face references an invalid vertex."
            local a=vertices[ids[1]],b=vertices[ids[2]],c=vertices[ids[3]]
            local ux=b[1]-a[1],uy=b[2]-a[2],uz=b[3]-a[3],vx=c[1]-a[1],vy=c[2]-a[2],vz=c[3]-a[3]
            local nx=uy*vz-uz*vy,ny=uz*vx-ux*vz,nz=ux*vy-uy*vx
            if nx*nx+ny*ny+nz*nz==0 then degenerate+=1 else
            (
                local minimum=amin #(a[3],b[3],c[3])
                if minimum<=floor+0.002 do touch=true
                if minimum<=plane do
                (
                    local triangle=#(a,b,c),previous=c,inside=previous[3]<=plane
                    for current in triangle do
                    (
                        local other=current[3]<=plane
                        if inside!=other do
                        (
                            local fraction=(plane-previous[3])/(current[3]-previous[3])
                            append points #(previous[1]+(current[1]-previous[1])*fraction,previous[2]+(current[2]-previous[2])*fraction)
                        )
                        if other do append points #(current[1],current[2])
                        if points.count>4096 do throw "Gallery referenced contact-point admission failed."
                        previous=current;inside=other
                    )
                )
            )
        )
        if not touch do throw "Gallery mesh minimum has no referenced nondegenerate contact."
        result=#(caGHull points,floor,#(low,high),value.numverts,value.numfaces,degenerate)
    )
    catch (errorText=getCurrentException() as string)
    if value!=undefined do delete value
    if errorText!=undefined do throw errorText
    result
)
-- Axis clipping forces the intersected coordinate to the exact Double boundary.
-- This avoids a false positive area for an edge merely touching a forbidden box.
fn caGClipAxis polygon axis boundary less =
(
    if polygon.count>512 do throw "Gallery clipping polygon admission failed."
    local out=#()
    if polygon.count>0 do
    (
        local previous=polygon[polygon.count],previousSide=if less then boundary-previous[axis] else previous[axis]-boundary
        for current in polygon do
        (
            local currentSide=if less then boundary-current[axis] else current[axis]-boundary
            if (previousSide>=0)!=(currentSide>=0) do
            (
                local fraction=previousSide/(previousSide-currentSide)
                local p=#(previous[1]+(current[1]-previous[1])*fraction,previous[2]+(current[2]-previous[2])*fraction)
                p[axis]=boundary;append out p
            )
            if currentSide>=0 do append out current
            previous=current;previousSide=currentSide
        )
    )
    out
)
fn caGRectHit polygon x0 x1 y0 y1 =
(
    local clipped=caGClipAxis polygon 1 x0 false
    clipped=caGClipAxis clipped 1 x1 true
    clipped=caGClipAxis clipped 2 y0 false
    clipped=caGClipAxis clipped 2 y1 true
    (caGArea clipped)>0
)
fn caGRectContains polygon x0 x1 y0 y1 =
(
    local valid=true,epsilon=0.02 as double
    for p in polygon do if p[1]<x0-epsilon or p[1]>x1+epsilon or p[2]<y0-epsilon or p[2]>y1+epsilon do valid=false
    valid
)
fn caGBaseEllipse p radiusX radiusY =
(
    -- Same analytic/96-sided predicates as the original oracle, retaining
    -- Double scalar coordinates instead of rounding hull vertices to Point3.
    local inside=(p[1]*p[1]/(radiusX*radiusX)+p[2]*p[2]/(radiusY*radiusY))<=1.000001
    for edge=0 to 95 while inside do
    (
        local a=#((radiusX as double)*(cos(360.0*edge/96) as double),(radiusY as double)*(sin(360.0*edge/96) as double))
        local b=#((radiusX as double)*(cos(360.0*(edge+1)/96) as double),(radiusY as double)*(sin(360.0*(edge+1)/96) as double))
        if (caGTurn a b p)< -0.02 do inside=false
    )
    inside
)
fn caGBaseInside hull offset kind =
(
    local localHull=for p in hull collect #(p[1]-(offset.x as double),p[2]-(offset.y as double))
    case kind of
    (
        #coffee: (local valid=true;for p in localHull where not(caGBaseEllipse p (697.5 as double) (396.0 as double)) do valid=false;valid)
        #dining: (local valid=true;for p in localHull where not(caGBaseEllipse p (650.0 as double) (650.0 as double)) do valid=false;valid)
        #tv: (caGRectContains localHull -900 900 -225 225)
        #shelf: (caGRectContains localHull -570 570 -175 175)
        #kitchen:
        (
            -- L = outer rectangle minus concave notch. Real6mm sink-wall tops
            -- leave the unsupported interior206..794 by-194..194, at z935.
            -- Apply .02mm geometrically before exact positive-area intersection;
            -- no area/perimeter allowance can hide a crossed notch or hole.
            local epsilon=0.02 as double
            (caGRectContains localHull -1500 1500 -325 1550) and
            not(caGRectHit localHull (-850+epsilon) (1500+epsilon) (325+epsilon) (1550+epsilon)) and
            not(caGRectHit localHull (206+epsilon) (794-epsilon) (-194+epsilon) (194-epsilon))
        )
        default: throw "Gallery base support outline is unknown."
    )
)
fn caGBaseControls bowl =
(
    -- Oracle-only controls from an actual modeled source; no extra scatter
    -- solve or changed scene output is represented as a production pass.
    if not isValidNode bowl or bowl.children.count!=1 do throw "Literal bowl control source changed."
    local child=bowl.children[1],beforeTM=child.transform as string,beforeMaterial=child.material
    local base=caGBottomHull child,x0=1e30 as double,x1=-1e30 as double,y0=1e30 as double,y1=-1e30 as double
    for p in base[1] do (x0=amin #(x0,p[1]);x1=amax #(x1,p[1]);y0=amin #(y0,p[2]);y1=amax #(y1,p[2]))
    local cx=(x0+x1)*0.5,cy=(y0+y1)*0.5,centered=for p in base[1] collect #(p[1]-cx,p[2]-cy)
    local maximum=0.0 as double
    for p in centered do maximum=amax #(maximum,sqrt(p[1]*p[1]+p[2]*p[2]))
    caGRequire "actual bowl control retains literal32+5/6mm band and156mm upper body" (abs(maximum-(32.0+5.0/6))<=0.02 and abs(base[3][2][1]-base[3][1][1]-156)<=0.02 and abs(base[3][2][2]-base[3][1][2]-156)<=0.02)
    caGCheck "bowl oracle permits supported base with upper overhang on130mm board and25mm gap" (caGRectContains centered -40 40 -40 40)
    local shifted=for p in centered collect #(p[1]+50.0,p[2])
    caGCheck "bowl oracle rejects a shifted base outside the physical130mm board" (not(caGRectContains shifted -65 65 -65 65))
    local acrossNotch=#(#(-900.0 as double,300.0 as double),#(-900.0 as double,500.0 as double),#(-700.0 as double,300.0 as double))
    local allNotchVertices=true
    for p in acrossNotch where not(caGInsideL [p[1],p[2],0]) do allNotchVertices=false
    caGRequire "crossed-notch negative has every vertex on the original literal L" allNotchVertices
    caGCheck "L oracle rejects crossed concavity even when all vertices lie on the L" (not(caGBaseInside acrossNotch [0,0,0] #kitchen))
    local aroundHole=#(#(190.0 as double,-210.0 as double),#(810.0 as double,-210.0 as double),#(810.0 as double,210.0 as double),#(190.0 as double,210.0 as double))
    local allHoleVertices=true
    for p in aroundHole where p[1]>206 and p[1]<794 and p[2]> -194 and p[2]<194 do allHoleVertices=false
    caGRequire "crossed-hole negative has no vertex inside the actual literal sink void" allHoleVertices
    caGCheck "L oracle rejects an interior sink hole without a corner inside it" (not(caGBaseInside aroundHole [0,0,0] #kitchen))
    caGCheck "read-only bowl control preserves source transform and material root" ((child.transform as string)==beforeTM and child.material==beforeMaterial)
    true
)
global caGBaseDiagnostic
fn caGBaseDiagnostic label row base legacyRow baseFits offset =
(
    local out=openFile (CA_TEST_OUTPUT+"gallery-base-support.txt") mode:"a"
    if out==undefined do throw "Gallery base diagnostic output could not be opened."
    local errorText=undefined
    try
    (
        format "ROW setup=% output_id=% asset_id=% region_id=% parent_id=% lock=% legacy_fullbody=% referenced_base=%\n" label row[1] row[2] row[3] row[8] row[7] legacyRow baseFits to:out
        format "POSE yaw=% scale=% record_position=% actual_min_z_mm=% vertices=% faces=% ignored_degenerate_faces=%\n" (caGNumber row[5]) (caGNumber row[6]) row[4] (caGNumber base[2]) base[4] base[5] base[6] to:out
        format "NODE_TM %\nOBJECT_TM %\n" row[9].transform row[9].objectTransform to:out
        for corner=1 to 2 do format "COMPLETE_MESH_BOUND % % % %\n" corner (caGNumber base[3][corner][1]) (caGNumber base[3][corner][2]) (caGNumber base[3][corner][3]) to:out
        format "BASE_HULL points=% coordinates=world_mm; local fixture XY also recorded\n" base[1].count to:out
        for point=1 to base[1].count do
        (
            local p=base[1][point]
            format "BASE_POINT % % % local_xy % %\n" point (caGNumber p[1]) (caGNumber p[2]) (caGNumber (p[1]-(offset.x as double))) (caGNumber (p[2]-(offset.y as double))) to:out
        )
        flush out
    )
    catch (errorText=getCurrentException() as string)
    close out
    if errorText!=undefined do throw errorText
    caGRecord ("BASE_ROW "+label+" output="+(row[1] as string)+" asset="+(row[2] as string)+" legacy="+(legacyRow as string)+" referenced_base="+(baseFits as string))
    true
)
fn caGVerify label rows offset kind =
(
    local validNodes = true, fullScale = true, rotations = true, materials = true, geometry = true, legacyGeometry = true, supportHeight = true
    for row in rows do
    (
        if not isValidNode row[9] then validNodes = false
        else
        (
            if row[9].material == undefined do materials = false
            if abs(row[6]-1) > 0.000001 do fullScale = false
            local yaw = mod (row[5]+360.0) 360.0
            if amin #(abs(yaw),abs(yaw-90),abs(yaw-180),abs(yaw-270)) > 0.000001 do rotations = false
            local corners = caGBoxCorners row[9], legacyRow = true
            local base = caGBottomHull row[9]
            if kind == #coffee do
            (
                for p in corners where not (caGEllipsePolygon p offset 697.5 396) do legacyRow = false
                if row[8] == 0 and abs(row[4].z-420) > 0.02 do supportHeight = false
            )
            if kind == #dining do
            (
                for p in corners where not (caGEllipsePolygon p offset 650 650) do legacyRow = false
                if row[8] == 0 and abs(row[4].z-755) > 0.02 do supportHeight = false
            )
            if kind == #kitchen do
            (
                for p in corners where not (caGInsideL (p-offset)) do legacyRow = false
                local bounds = nodeGetBoundingBox row[9] (matrix3 1)
                local lower = bounds[1]-offset, upper = bounds[2]-offset
                -- Corner-only checks would miss an internal sink hole. Reject
                -- any positive-area overlap of the full prop bounds with it.
                if upper.x > 200.02 and lower.x < 799.98 and upper.y > -199.98 and lower.y < 199.98 do legacyRow = false
                if row[8] == 0 and abs(row[4].z-935) > 0.02 do supportHeight = false
            )
            if kind == #tv or kind == #shelf do
            (
                local halfX = if kind == #tv then 900 else 570
                local halfY = if kind == #tv then 225 else 175
                for p in corners where abs(p.x-offset.x) > halfX+0.02 or abs(p.y-offset.y) > halfY+0.02 do legacyRow = false
            )
            -- Preserve the complete historical full-body predicates above as
            -- per-row diagnostics. Support is measured from actual referenced
            -- evaluated triangles in the lowest0.5mm band, not caAssetSupport.
            local baseFits = caGBaseInside base[1] offset kind
            if not baseFits do geometry = false
            if not legacyRow do legacyGeometry = false
            if abs(base[2]-(row[4].z as double)) > 0.02 do supportHeight = false
            caGBaseDiagnostic label row base legacyRow baseFits offset
        )
    )
    caGCheck (label+" generated nodes retain materials") (validNodes and materials)
    caGCheck (label+" uses full-size props and authored quarter turns") (fullScale and rotations)
    caGRecord ("LEGACY_DIAGNOSTIC "+label+" complete-body support predicate="+(legacyGeometry as string)+"; original conditions retained per row in gallery-base-support.txt")
    caGCheck (label+" actual referenced bottom-band hull fits the literal support outline and avoids complete L/notch/sink voids") (validNodes and geometry)
    caGCheck (label+" base contacts use the intended top height") supportHeight
)
fn caGSurfaceRules setup label allowedHeights categories =
(
    caGStep (label+" native Analyze furniture")
    local categoryMask = caGMask categories
    local start = timeStamp()
    local count = caAnalyzeSetup setup
    local elapsed = timeStamp()-start
    local rows = caRegionRows setup
    caGRequire (label+" has measured native regions") (count > 0 and count == rows.count)
    local active = 0, excluded = 0
    for row in rows do
    (
        caGContext = label+" author surface "+(row[1] as string)
        local keep = false
        for height in allowedHeights where abs(row[5].z-height) < 0.05 and abs(row[6].z-height) < 0.05 do keep = true
        if keep then active += 1 else excluded += 1
        local role = if not keep then 1 else (if label == "02_OPEN_SHELF" or (label == "01_TV_CONSOLE" and row[5].z < 599) then 3 else 2)
        caSetRegionRules setup row[1] (label+" surface "+(row[1] as string)) label role categoryMask 1.0 true (not keep) [0,-1,0]
    )
    caGRequire (label+" keeps intended visible support") (active > 0)
    caGRecord ("SURFACES "+label+" active="+(active as string)+" excluded="+(excluded as string))
    #(elapsed,rows.count)
)
fn caGSetup label category fixture offset kind sourceRows chosenAssets density emptySpace seed allowedHeights =
(
    caGStep (label+" register and analyze")
    local setup = caCreateSetup #(fixture[1]) category
    setup.name = "CA_GALLERY_SETUP_"+label
    caGAssign #(setup,fixture[1]) (caGLayer ("CA_GALLERY_"+label+"_FURNITURE"))
    caGAssign fixture[2] (caGLayer ("CA_GALLERY_"+label+"_FURNITURE"))
    for index in chosenAssets do
    (
        local source = sourceRows[index]
        caGStep (label+" register accessory "+(index as string)+" / "+source[2])
        caRegisterAsset setup source[1] source[2] source[3] 31 #(0.0,90.0,180.0,270.0) 1.0 1.0 1.0 source[4]
    )
    local settings = (caSetupSummary setup)[9]
    settings[1] = seed; settings[2] = density; settings[3] = 22; settings[4] = 25
    settings[5] = if kind == #tv or kind == #shelf then 0.6 else 0.35
    settings[6] = 0; settings[7] = emptySpace; settings[8] = 2; settings[9] = category
    settings[10] = 30; settings[11] = false
    caSetArrangeSettings setup settings
    -- Exposed surfaces do not require robotic horizontal insertion. Static
    -- collision/containment stay active; no external obstacle scope is needed.
    caSetCollisionScope setup #() false
    local allowedCategories = #()
    for assetIndex in chosenAssets do append allowedCategories sourceRows[assetIndex][3]
    local analysis = caGSurfaceRules setup label allowedHeights allowedCategories
    caGStep (label+" first native generate")
    local process = (dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local memoryBefore = caGMemory process
    local stopwatch = (dotNetClass "System.Diagnostics.Stopwatch").StartNew()
    local start = timeStamp()
    local result = caGenerate setup #()
    local firstMS = timeStamp()-start
    stopwatch.Stop()
    local firstHighResMS = caGNumber stopwatch.Elapsed.TotalMilliseconds
    local firstTicks = caGNumber stopwatch.ElapsedTicks
    local memoryAfter = caGMemory process
    local first = caOutputRows setup
    caGRequire (label+" produces nonempty native placements") (first.count > 0 and result[2] == first.count)
    caGVerify label first offset kind
    caGStep (label+" repeat native generate")
    local repeatMemoryBefore = caGMemory process
    stopwatch.Restart()
    start = timeStamp()
    local repeatResult = caGenerate setup #()
    local repeatMS = timeStamp()-start
    stopwatch.Stop()
    local repeatHighResMS = caGNumber stopwatch.Elapsed.TotalMilliseconds
    local repeatTicks = caGNumber stopwatch.ElapsedTicks
    local repeatMemoryAfter = caGMemory process
    local second = caOutputRows setup
    caGCheck (label+" repeats deterministic IDs and complete poses") (caGEqualRows first second)
    caGCheck (label+" repeat statistics and actual output agree") (repeatResult[2] == second.count and result[1] == repeatResult[1] and result[4] == repeatResult[4])
    local props = for row in second collect row[9]
    caGAssign props (caGLayer ("CA_GALLERY_"+label+"_GENERATED_PROPS"))
    setup.renderable = false
    append caGSetups setup
    append caGMetrics #(label,chosenAssets.count,analysis[2],second.count,analysis[1],firstMS,repeatMS,(caGNumber result[1]),(caGNumber result[4]),(caGNumber result[5]),
        firstHighResMS,repeatHighResMS,firstTicks,repeatTicks,(caGNumber (dotNetClass "System.Diagnostics.Stopwatch").Frequency),
        memoryBefore[1],memoryBefore[2],memoryAfter[1],memoryAfter[2],repeatMemoryBefore[1],repeatMemoryBefore[2],repeatMemoryAfter[1],repeatMemoryAfter[2])
    caGRecord ("TIMING "+label+" analyze_ms="+(analysis[1] as string)+" first_generate_ms="+(firstMS as string)+" repeat_generate_ms="+(repeatMS as string)+" props="+(second.count as string)+" candidates="+(result[4] as string))
    caGRecord ("PROCESS_BYTES "+label+" before_ws="+memoryBefore[1]+" after_ws="+memoryAfter[1]+" before_peak="+memoryBefore[2]+" after_peak="+memoryAfter[2]+" repeat_after_ws="+repeatMemoryAfter[1]+" repeat_after_peak="+repeatMemoryAfter[2])
    process.Dispose()
    setup
)

try
(
    if CA_TEST_ROOT == undefined or CA_TEST_OUTPUT == undefined do throw "Owned gallery runner paths are required before resetting a scene."
    caGStep "owned scene reset and factory load"
    resetMaxFile #noPrompt
    units.SystemType = #millimeters; units.SystemScale = 1
    local baseDetail=createFile (CA_TEST_OUTPUT+"gallery-base-support.txt")
    format "Gallery support-only oracle: actual referenced bottom0.5mm band; Double XY; original.02mm boundary allowance.\nComplete-body collision/clearance stays active in the native solver and requires the separate seven independent release proof families; this file adds no general independent body collision proof.\nStack children retain the original gallery outline/contact scope; this is not a generic parent-top certificate.\n" to:baseDetail
    close baseDetail
    fileIn (CA_TEST_ROOT+"tests/max/fixtures.ms")
    fileIn (CA_TEST_ROOT+"tests/max/furniture_examples.ms")
    fileIn (CA_TEST_ROOT+"tests/max/asset_fixtures.ms")
    local sourceRows = caCreateAccessoryFixtures offsetMM:[0,14000,0]
    caGRequire "eleven detailed original accessory sources" (sourceRows.count == 11)
    caGStep "read-only actual bowl base and complete-notch/hole oracle controls"
    caGBaseControls sourceRows[8][1]
    local sourceLayer = caGLayer "CA_GALLERY_99_PARKED_SOURCE_LIBRARY"
    for node in objects where (getUserProp node "CyrusArrangeAssetFixture") == true do
    (
        sourceLayer.addNode node
        node.renderable = false
    )

    local tvOffset = [-4800,500,0], shelfOffset = [-2400,500,0], coffeeOffset = [0,-150,0]
    local diningOffset = [2400,-150,0], kitchenOffset = [5600,350,0]
    local tv = caFxTVConsole offsetMM:tvOffset grouped:true
    local shelf = caFxOpenShelf offsetMM:shelfOffset grouped:true
    local walnut = standardMaterial name:"CA_GALLERY_Walnut" diffuse:(color 104 73 51) specularLevel:28 glossiness:42
    local cream = standardMaterial name:"CA_GALLERY_ShelfIvory" diffuse:(color 202 191 168) specularLevel:20 glossiness:35
    local graphite = standardMaterial name:"CA_GALLERY_TVGraphite" diffuse:(color 28 34 37) specularLevel:45 glossiness:65
    local screen = standardMaterial name:"CA_GALLERY_TVScreen" diffuse:(color 37 66 72) specularLevel:30 glossiness:70 selfIllumAmount:8
    for node in tv[2] do node.material = walnut
    for node in shelf[2] do node.material = cream
    local displayNodes = #(
        caFxBox "GalleryTV_Frame" [820,32,460] (tvOffset+[0,170,630]),
        caFxBox "GalleryTV_Screen" [786,2,426] (tvOffset+[0,152,647]),
        caFxBox "GalleryTV_LeftFoot" [150,150,22] (tvOffset+[-250,100,600]),
        caFxBox "GalleryTV_RightFoot" [150,150,22] (tvOffset+[250,100,600]))
    for node in displayNodes do node.material = graphite
    displayNodes[2].material = screen
    local displayRoot = group displayNodes name:"CA_GALLERY_Original_TV_Display"
    tv[1] = group #(tv[1],displayRoot) name:"CA_GALLERY_Original_TV_Console_and_Display"
    join tv[2] displayNodes
    local coffee = caFECurvedCoffeeTable offsetMM:coffeeOffset
    local dining = caFERoundDiningTable offsetMM:diningOffset
    local kitchen = caFELKitchenCounter offsetMM:kitchenOffset
    caGSetup "01_TV_CONSOLE" 1 tv tvOffset #tv sourceRows #(1,2,3,4,5,6,7,9) 0.22 0.45 414 #(80,275,600)
    caGSetup "02_OPEN_SHELF" 2 shelf shelfOffset #shelf sourceRows #(1,2,3,4,5,6,7,8,9) 0.18 0.45 515 #(30,450,890,1330)
    caGSetup "03_CURVED_COFFEE" 3 coffee coffeeOffset #coffee sourceRows #(2,3,4,5,7,8,10,11) 0.24 0.55 616 #(420)
    caGSetup "04_ROUND_DINING" 5 dining diningOffset #dining sourceRows #(5,7,8,10,11) 0.18 0.60 717 #(755)
    caGSetup "05_L_KITCHEN" 4 kitchen kitchenOffset #kitchen sourceRows #(2,4,5,7,8,10,11) 0.16 0.55 818 #(935)
    caGRequire "five independent native setups" (caGSetups.count == 5)
    sourceLayer.isHidden = true

    caGStep "original gallery stage, labels, cameras and lighting"
    local stageLayer = caGLayer "CA_GALLERY_80_STAGE_AND_LABELS"
    local floorMat = standardMaterial name:"CA_GALLERY_CharcoalFloor" diffuse:(color 43 48 50) specularLevel:14 glossiness:28
    local plinthMat = standardMaterial name:"CA_GALLERY_DisplayPlinth" diffuse:(color 82 88 87) specularLevel:15 glossiness:32
    local labelMat = standardMaterial name:"CA_GALLERY_TypeIvory" diffuse:(color 220 214 194) selfIllumAmount:35 twoSided:true
    local ground = box name:"CA_GALLERY_Ground" width:15200 length:6000 height:40 pos:[700,500,-120]
    ground.material = floorMat
    stageLayer.addNode ground
    local platforms = #(#(tvOffset,[2200,1200,80]),#(shelfOffset,[1600,1200,80]),#(coffeeOffset,[1800,1450,80]),#(diningOffset,[1750,1650,80]),#(kitchenOffset+[0,600,0],[3500,2400,80]))
    for i = 1 to platforms.count do
    (
        local p = platforms[i]
        local base = box name:("CA_GALLERY_Plinth_"+(i as string)) width:p[2].x length:p[2].y height:p[2].z pos:(p[1]+[0,0,-80])
        base.material = plinthMat
        stageLayer.addNode base
    )
    local labelRows = #(#("01  TV CONSOLE",[-4800,-300,3]),#("02  OPEN SHELF",[-2400,-300,3]),#("03  CURVED COFFEE",[0,-1090,3]),#("04  ROUND DINING",[2400,-1200,3]),#("05  L KITCHEN + SINK",[5600,-780,3]))
    for row in labelRows do stageLayer.addNode (caGLabel row[1] row[2] 86 labelMat)
    local heading = caGLabel "CYRUS ARRANGE" [700,2150,2120] 255 labelMat
    local subheading = caGLabel "ORIGINAL GEOMETRY  /  NATIVE SCENE DRESSING" [700,2140,1970] 67 labelMat
    caGAssign #(heading,subheading) stageLayer
    local overview = caGCamera "CA_GALLERY_OVERVIEW" [700,-17000,10400] [700,350,650] 40
    -- Text is authored in its local XY plane. Matching the camera's basis
    -- keeps its Y axis upright and its +Z face directed toward the viewer.
    local headingMatrix = copy overview.transform
    headingMatrix.row4 = heading.transform.row4
    heading.transform = headingMatrix
    local subheadingMatrix = copy overview.transform
    subheadingMatrix.row4 = subheading.transform.row4
    subheading.transform = subheadingMatrix
    caGCheck "gallery titles have renderable camera-facing planes" (heading.renderable and subheading.renderable and labelMat.twoSided and
        (dot (normalize heading.transform.row3) (normalize (overview.position-heading.position))) > 0.98 and
        (dot (normalize subheading.transform.row3) (normalize (overview.position-subheading.position))) > 0.98)
    caGCamera "CA_GALLERY_TV_CAMERA" [-6300,-2100,1900] [-4800,500,560] 45
    caGCamera "CA_GALLERY_SHELF_CAMERA" [-4000,-2100,2100] [-2400,500,900] 44
    caGCamera "CA_GALLERY_COFFEE_CAMERA" [-1200,-2100,1900] [0,-150,340] 43
    caGCamera "CA_GALLERY_DINING_CAMERA" [1100,-2400,2400] [2400,-150,650] 43
    caGCamera "CA_GALLERY_KITCHEN_CAMERA" [2700,-3800,3400] [5400,800,700] 47
    local key = omniLight name:"CA_GALLERY_Key" pos:[-3500,-4500,7000] multiplier:0.80 color:(color 255 239 215)
    local fill = omniLight name:"CA_GALLERY_Fill" pos:[6500,-1000,6500] multiplier:0.35 color:(color 213 228 255)
    local rim = omniLight name:"CA_GALLERY_Rim" pos:[500,3500,6500] multiplier:0.25 color:(color 255 244 224)
    -- Max2027 light common properties require the base-object shadow switch;
    -- node-level castShadows controls the light node's own render visibility.
    key.baseObject.castShadows = true
    key.shadowGenerator = raytraceShadow()
    caGAssign #(key,fill,rim) (caGLayer "CA_GALLERY_91_LIGHTS")
    ambientLight = color 35 35 35
    backgroundColor = color 24 29 32
    renderers.current = Default_Scanline_Renderer()
    renderWidth = 2400; renderHeight = 1000
    local camera = getNodeByName "CA_GALLERY_OVERVIEW"
    viewport.setCamera camera
    select caGSetups[1]
    CA_GALLERY_SCENE = CA_TEST_OUTPUT+"CyrusArrange-Gallery.max"
    caGStep "save owned gallery scene and measured host timings"
    saveMaxFile CA_GALLERY_SCENE quiet:true
    local metrics = createFile (CA_TEST_OUTPUT+"gallery-performance.csv")
    format "category,registered_assets,measured_regions,placements,analysis_ms,first_generate_ms,repeat_generate_ms,requested,candidates,underfilled,first_stopwatch_ms,repeat_stopwatch_ms,first_stopwatch_ticks,repeat_stopwatch_ticks,stopwatch_frequency,first_before_working_set_bytes,first_before_peak_working_set_bytes,first_after_working_set_bytes,first_after_peak_working_set_bytes,repeat_before_working_set_bytes,repeat_before_peak_working_set_bytes,repeat_after_working_set_bytes,repeat_after_peak_working_set_bytes\n" to:metrics
    for row in caGMetrics do
        for column = 1 to row.count do
        (
            format "%" row[column] to:metrics
            if column == row.count then format "\n" to:metrics else format "," to:metrics
        )
    close metrics
    caGRecord "PERFORMANCE_SCOPE wall-clock Max timeStamp milliseconds plus System.Diagnostics.Stopwatch ticks/ms/frequency; Analyze includes host capture/native sampling, Generate includes capture/native solve/material publication/Undo. WorkingSet64/PeakWorkingSet64 are process-wide bytes before/after each Generate, including prior scene/Undo state; not isolated solver benchmarks or allocator attribution."
    caGCheck "owned gallery scene saved" (doesFileExist CA_GALLERY_SCENE)
)
catch
(
    local message = getCurrentException() as string
    local stack = getCurrentExceptionStackTrace() as string
    caGFailures += 1
    caGRecord ("ERROR_CONTEXT "+caGContext)
    caGRecord ("ERROR "+message)
    caGRecord ("STACK "+stack)
    local failure = createFile (CA_TEST_OUTPUT+"gallery-exception.txt")
    format "context=%\nexception=%\nstack=%\n" caGContext message stack to:failure
    flush failure
    close failure
)
caGFinished = true
caGWrite()
