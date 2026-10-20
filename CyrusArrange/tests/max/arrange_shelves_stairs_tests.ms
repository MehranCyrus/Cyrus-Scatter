/* Owned Max2027: actual prepared book meshes on shelves and arbitrary stair props.
   Factories are test geometry; production analysis/placement remains entirely C++. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI,caRWInputSpecs
global caSSLog=#(),caSSPasses=0,caSSFailures=0,caSSFinished=false
global caSSWrite,caSSCheck,caSSHash,caSSMesh,caSSBounds,caSSPlace,caSSPose,caSSExport,caSSPhysical,caSSRun
fn caSSWrite =
(
    local f=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caSSFinished then(if caSSFailures==0 then "SUCCESS" else "ERROR")else "RUNNING") caSSPasses caSSFailures to:f
    for line in caSSLog do format "%\n" line to:f
    close f
)
fn caSSCheck label value = (if value then caSSPasses+=1 else caSSFailures+=1;append caSSLog((if value then "PASS " else "FAIL ")+label);caSSWrite();if not value do throw label;value)
fn caSSHash path =
(
    local stream=(dotNetClass "System.IO.File").OpenRead path,algorithm=(dotNetClass "System.Security.Cryptography.SHA256").Create(),answer=undefined
    try(answer=toLower(substituteString((dotNetClass "System.BitConverter").ToString(algorithm.ComputeHash stream))"-"""))catch(stream.Close();algorithm.Dispose();throw())
    stream.Close();algorithm.Dispose();answer
)
fn caSSMesh node = (local value=undefined;in coordsys world(value=snapshotAsMesh node renderMesh:false);if value==undefined or value.numverts>250000 or value.numfaces>250000 do throw "Mesh admission";value)
fn caSSBounds meshValue =
(
    local low=[1e30,1e30,1e30],high=[-1e30,-1e30,-1e30]
    for i=1 to meshValue.numverts do(local p=getVert meshValue i;for a=1 to 3 do(low[a]=amin low[a] p[a];high[a]=amax high[a] p[a]))
    #(low,high)
)
fn caSSPlace node target =
(
    local m=caSSMesh node,b=caSSBounds m;delete m
    node.pos+=target-[(b[1].x+b[2].x)*0.5,(b[1].y+b[2].y)*0.5,b[1].z];node
)
fn caSSPose owner = for row in(caOutputRows owner)collect #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
fn caSSExport label receivers sources owner =
(
    -- Text uses double roundtrip precision. All vertices are actual WORLD snapshots.
    local f=createFile(CA_TEST_OUTPUT+label+"-meshes.txt"),rows=caOutputRows owner
    for kind in #("receiver","source","output") do
    (
        local nodes=case kind of("receiver":receivers;"source":sources;"output":for row in rows collect row[9])
        for i=1 to nodes.count do
        (
            local node=nodes[i],m=caSSMesh node
            format "mesh % % % %\n" kind i m.numverts m.numfaces to:f
            for v=1 to m.numverts do(local p=getVert m v;format "v % % %\n" (formattedPrint(p.x as double)format:".17g") (formattedPrint(p.y as double)format:".17g") (formattedPrint(p.z as double)format:".17g")to:f)
            for j=1 to m.numfaces do(local t=getFace m j;format "f % % % % %\n"(t.x as integer)(t.y as integer)(t.z as integer)(getFaceMatID m j)(getFaceSmoothGroup m j)to:f)
            if kind=="source" do
            (
                local assets=caAssetRows owner,b=caSSBounds m,a=(caAssetSupport owner assets[i][1])[1]+[(b[1].x+b[2].x)*.5,(b[1].y+b[2].y)*.5,b[1].z]
                format "anchor % % %\n" (formattedPrint(a.x as double)format:".17g") (formattedPrint(a.y as double)format:".17g") (formattedPrint(a.z as double)format:".17g")to:f
            )
            if kind=="output" do
            (
                local r=rows[i],assetRows=caAssetRows owner,index=0
                for n=1 to assetRows.count where assetRows[n][1]==r[2] do index=n
                format "pose % % % % % % % %\n" index r[1] (formattedPrint(r[4].x as double)format:".17g") (formattedPrint(r[4].y as double)format:".17g") (formattedPrint(r[4].z as double)format:".17g") (formattedPrint r[5] format:".17g") (formattedPrint r[6] format:".17g") r[8] to:f
            )
            format "end\n" to:f;delete m
        )
    )
    close f;true
)
fn caSSPhysical owner receivers sources allowedLevels edge gap =
(
    local rows=caOutputRows owner,valid=true,levels=#(),ranges=#(),refinedPairs=0,sourceMeshes=for node in sources collect(caSSMesh node),assetRows=caAssetRows owner
    for r in rows do
    (
        local node=r[9],m=caSSMesh node,b=caSSBounds m,index=0
        for i=1 to assetRows.count where assetRows[i][1]==r[2] do index=i
        if index==0 do throw "Output source identity missing"
        local original=sourceMeshes[index],ob=caSSBounds original,anchor=(caAssetSupport owner assetRows[index][1])[1]+[(ob[1].x+ob[2].x)*0.5,(ob[1].y+ob[2].y)*0.5,ob[1].z]
        if r[6]<0.8 or r[6]>1.1 or abs(b[1].z-r[4].z)>0.03 or m.numverts!=original.numverts or m.numfaces!=original.numfaces do valid=false
        for i=1 to original.numverts do
        (
            local p=((getVert original i)-anchor)*r[6],wanted=r[4]+[(cos r[5])*p.x-(sin r[5])*p.y,(sin r[5])*p.x+(cos r[5])*p.y,p.z]
            if distance wanted(getVert m i)>0.04 do valid=false
        )
        for i=1 to original.numfaces do
            if(getFace original i)!=(getFace m i)or(getFaceMatID original i)!=(getFaceMatID m i)or(getFaceSmoothGroup original i)!=(getFaceSmoothGroup m i)do valid=false
        -- Exact authored UV coordinates and mapping faces on the detailed book.
        if meshop.getMapSupport original 1 do
        (
            if not(meshop.getMapSupport m 1)or(meshop.getNumMapVerts m 1)!=(meshop.getNumMapVerts original 1)or(meshop.getNumMapFaces m 1)!=(meshop.getNumMapFaces original 1)then valid=false
            else
            (
                for i=1 to(meshop.getNumMapVerts original 1)do if(meshop.getMapVert original 1 i)!=(meshop.getMapVert m 1 i)do valid=false
                for i=1 to(meshop.getNumMapFaces original 1)do if(meshop.getMapFace original 1 i)!=(meshop.getMapFace m 1 i)do valid=false
            )
        )
        if node.material!=sources[index].material do valid=false
        local level=0
        for i=1 to allowedLevels.count where abs(b[1].z-allowedLevels[i])<0.03 do level=i
        if level==0 then valid=false else appendIfUnique levels level
        for other in ranges do
        (
            local dz=amax 0.0(amax(other[1].z-b[2].z)(b[1].z-other[2].z)),dx=amax 0.0(amax(other[1].x-b[2].x)(b[1].x-other[2].x)),dy=amax 0.0(amax(other[1].y-b[2].y)(b[1].y-other[2].y))
            if sqrt(dx*dx+dy*dy+dz*dz)<gap-0.04 do refinedPairs+=1
        )
        append ranges b;delete m
    )
    for m in sourceMeshes do delete m
    if refinedPairs>0 do(append caSSLog("PAIR_PROOF "+(refinedPairs as string)+" envelope pairs require independent actual-mesh separation proof");caSSWrite())
    #(valid,levels,refinedPairs)
)
fn caSSRun =
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1
    caSSCheck "Exact 0.3.2 native in owned Max2027" (caVersion()=="0.3.2"and(maxVersion())[1]==29000)
    fileIn(CA_TEST_ROOT+"tests/max/real_world_models_data.ms")
    local input=caRWInputSpecs[3],original=CA_TEST_OUTPUT+"Books-Input.max",mapFolder=CA_TEST_OUTPUT+"maps/"
    caSSCheck "Prepared library Max and metadata match immutable identities" (caSSHash input[2]==input[3] and caSSHash input[4]==input[5])
    caSSCheck "Disposable book model copy succeeds" (copyFile input[2] original and caSSHash original==input[3])
    makeDir mapFolder all:true
    local maps=true
    for row in input[8] do
    (
        if caSSHash row[1]!=row[3] or not(copyFile row[1](mapFolder+row[2]))or caSSHash(mapFolder+row[2])!=row[3] do maps=false
    )
    caSSCheck "All declared book maps are byte-identical private copies" (maps and input[8].count>=90)
    local merged=#()
    caSSCheck "Actual detailed book collection merges with unit conversion" (mergeMAXFile original #select #autoRenameDups #renameMtlDups #neverReparent quiet:true mergedNodes:&merged includeFullGroup:true ignoreFileUnits:false)
    local heads=for n in merged where isValidNode n and isGroupHead n collect n
    while heads.count>0 do(ungroup heads[1];heads=for n in merged where isValidNode n and isGroupHead n collect n)
    local selected=for n in merged where isValidNode n and n.name=="Books_01_Book_002" collect n
    caSSCheck "One complete prepared book is selected" (selected.count==1)
    local book=selected[1],m=caSSMesh book,b=caSSBounds m
    caSSCheck "Source has literal real dimensions and detailed topology" (m.numverts==1361 and m.numfaces==2672 and distance (b[1]) [249.79274,-111.70074,240.11911]<0.03 and distance (b[2]) [535.88428,98.53747,257.11234]<0.03)
    delete m
    delete(for n in merged where isValidNode n and n!=book collect n)
    local flat=copy book;flat.name="SS_Flat_Book";caSSPlace flat [12000,0,0]
    book.transform=book.transform*(rotateYMatrix 90);book.name="SS_Upright_Book";caSSPlace book [10000,0,0]
    local pending=#(book.material),seen=#()
    while pending.count>0 do
    (
        local item=pending[pending.count];deleteItem pending pending.count
        if item!=undefined and findItem seen item==0 do
        (
            if seen.count>=2048 do throw "Material graph admission"
            append seen item
            if isProperty item #filename and item.filename!="" do
            (
                local name=(getFilenameFile item.filename)+(getFilenameType item.filename),found=false
                for row in input[8] where toLower row[2]==toLower name do found=true
                if not found do throw "Unmanifested map dependency"
                item.filename=mapFolder+name
            )
            if(superClassOf item)==material do for i=1 to getNumSubMtls item do append pending(getSubMtl item i)
            for i=1 to getNumSubTexmaps item do append pending(getSubTexmap item i)
        )
    )
    local sourceTM=book.transform,flatTM=flat.transform,sourceBefore=caSSMesh book,flatBefore=caSSMesh flat
    local oak=standardMaterial name:"SS_Cabinet_Oak" diffuse:(color 125 89 56),receivers=#()
    for z in #(0,350,700,1050)do append receivers(box name:("SS_Shelf_"+(z as string))width:900 length:260 height:18 pos:[0,0,z]material:oak)
    append receivers(box name:"SS_Left_Wall" width:18 length:260 height:1068 pos:[-441,0,0]material:oak)
    append receivers(box name:"SS_Right_Wall" width:18 length:260 height:1068 pos:[441,0,0]material:oak)
    append receivers(box name:"SS_Back" width:864 length:18 height:1068 pos:[0,121,0]material:oak)
    append receivers(box name:"SS_Divider" width:18 length:242 height:1050 pos:[0,-9,18]material:oak)
    local cabinet=caCreateArrangement();cabinet.name="SS_Books_Arrangement";caBindReceivers cabinet receivers
    caRegisterAsset cabinet book "Prepared upright book" 10 8 #(0.0) 1.0 1.0 1.0 false
    local values=caPlacementSettings cabinet;values[1]=913032L;values[2]=2;values[3]=100;values[5]=2;values[6]=5;values[7]=true;values[8]=false;values[9]=0.8;values[10]=1.1
    local started=timestamp(),result=caGeneratePlacement cabinet values false,elapsed=timestamp()-started
    append caSSLog("PERFORMANCE shelves100 milliseconds="+(elapsed as string)+" result="+(result as string));caSSWrite()
    if result[2]!=100 do (caSSExport "shelves-underfill" receivers #(book) cabinet;saveMaxFile(CA_TEST_OUTPUT+"shelves-underfill.max")quiet:true)
    caSSCheck "100 real books publish across the cabinet without category restrictions" (result[1]==100 and result[2]==100 and result[5]==0 and(caOutputRows cabinet).count==100)
    local physical=caSSPhysical cabinet receivers #(book) #(18,368,718,1068) 5 2
    caSSCheck "Every book retains actual mesh UV material final scale and contact; pair proof is independent" physical[1]
    caSSCheck "Automatic support detection uses all shelf levels and interior compartments" (physical[2].count==4 and findItem physical[2]1>0 and findItem physical[2]2>0)
    caSSExport "shelves100" receivers #(book) cabinet
    caSSCheck "Independent shelf mesh export completes" true
    local pose=caSSPose cabinet,saved=caPlacementSettings cabinet
    caGeneratePlacement cabinet saved false
    caSSCheck "100-book repeated seed exactly preserves all logical poses" (deepEqual pose(caSSPose cabinet)strictCompare:true)
    local locked=(caOutputRows cabinet)[1];caSetLocked cabinet #(locked[1]) true
    -- Protect captures actual Max float transforms (including artist edits).
    -- Compare regeneration with that accepted pose, not a pre-lock double scale.
    locked=(caOutputRows cabinet)[1];pose=caSSPose cabinet
    local fresh=caGeneratePlacement cabinet saved true
    local lockedAgain=undefined
    for r in(caOutputRows cabinet)where r[1]==locked[1]do lockedAgain=r
    local protectedSame=lockedAgain!=undefined and(deepEqual #(lockedAgain[4],lockedAgain[5],lockedAgain[6])#(locked[4],locked[5],locked[6])strictCompare:true)and lockedAgain[7]
    append caSSLog("PROTECTION seed="+((caPlacementSettings cabinet)[1]as string)+" result="+(fresh as string)+" unchangedPose="+(protectedSame as string)+" count="+((caOutputRows cabinet).count as string))
    if lockedAgain!=undefined do append caSSLog("PROTECTION deltaMM="+((distance lockedAgain[4]locked[4])as string)+" yawDelta="+((lockedAgain[5]-locked[5])as string)+" scaleDelta="+((lockedAgain[6]-locked[6])as string))
    caSSWrite()
    if not protectedSame or(caOutputRows cabinet).count!=100 do(saveMaxFile(CA_TEST_OUTPUT+"protected-failure.max")quiet:true;caSSExport "protected-failure" receivers #(book) cabinet)
    caSSCheck "Fresh shelf variation preserves protected book pose and total quantity" (protectedSame and(caOutputRows cabinet).count==100)
    max undo
    caSSCheck "One Undo restores complete 100-book prior arrangement" (deepEqual pose(caSSPose cabinet)strictCompare:true)
    -- Arbitrary props on exact modeled treads, with an actual imported flat book.
    local stepMat=standardMaterial name:"SS_Concrete" diffuse:(color 145 145 140),steps=#()
    for i=0 to 5 do append steps(box name:("SS_Step_"+(i as string))width:400 length:1600 height:((i+1)*150)pos:[20000+i*400,0,0]material:stepMat)
    local fruit=sphere name:"SS_Fruit" radius:45 segments:12 pos:[14000,0,45]material:(standardMaterial name:"SS_Orange" diffuse:(color 230 110 20))
    local bin=cylinder name:"SS_Bin" radius:120 height:320 sides:16 pos:[15000,0,0]material:(standardMaterial name:"SS_Metal" diffuse:(color 65 75 90))
    local stair=caCreateArrangement();stair.name="SS_Stairs_Arrangement";caBindReceivers stair steps
    local flatID=caRegisterAsset stair flat "Detailed flat book" 1 8 #(0.0,90.0) 1.0 1.0 1.0 false
    caRegisterAsset stair fruit "Fruit" 4 8 #(0.0,90.0) 1.0 1.0 1.0 false
    local binID=caRegisterAsset stair bin "Bin" 10 8 #(0.0,90.0) 1.0 1.0 1.0 false
    local options=caPlacementSettings stair;options[1]=913033L;options[2]=2;options[3]=48;options[5]=10;options[6]=8;options[7]=true;options[8]=false;options[9]=0.8;options[10]=1.1
    local required=#(#(flatID,8),#(binID,4))
    started=timestamp();result=caGeneratePlacementMinimums stair options required false;elapsed=timestamp()-started
    append caSSLog("PERFORMANCE stairs48 milliseconds="+(elapsed as string)+" result="+(result as string));caSSWrite()
    caSSCheck "Required counts are saved atomically with actual generation" (deepEqual required(caPropMinimums stair)strictCompare:true)
    caSSCheck "Arbitrary stair props publish the requested quantity" (result[1]==48 and result[2]==48 and result[5]==0)
    physical=caSSPhysical stair steps #(flat,fruit,bin) #(150,300,450,600,750,900) 8 10
    caSSExport "stairs48" steps #(flat,fruit,bin) stair
    caSSCheck "Actual stair outputs preserve appearance full geometry scale and support; pair proof is independent" physical[1]
    local used=#();for row in(caOutputRows stair)do appendIfUnique used row[2]
    local flatCount=0,binCount=0
    for row in(caOutputRows stair)do(if row[2]==flatID do flatCount+=1;if row[2]==binID do binCount+=1)
    caSSCheck "Different arbitrary prop types use multiple automatically detected treads" (used.count==3 and physical[2].count==6)
    caSSCheck "Required detailed books and large bins keep their minimum counts before small fill" (flatCount>=8 and binCount>=4)
    local acceptedPose=caSSPose stair,acceptedSeed=(caPlacementSettings stair)[1],acceptedRevision=(caSetupSummary stair)[3],failed=false
    try(caGeneratePlacementMinimums stair options #(#(flatID,49),#(binID,4)) true)catch(failed=true)
    caSSCheck "Invalid minimum draft retains accepted policy, seed, revision and every output" (failed and deepEqual required(caPropMinimums stair)strictCompare:true and(caPlacementSettings stair)[1]==acceptedSeed and(caSetupSummary stair)[3]==acceptedRevision and deepEqual acceptedPose(caSSPose stair)strictCompare:true)
    caGeneratePlacementMinimums stair options required false
    caSSCheck "Required-source layout repeats its exact seed" (deepEqual acceptedPose(caSSPose stair)strictCompare:true)
    caSSExport "stairs48" steps #(flat,fruit,bin) stair
    caSSCheck "Independent stair mesh export completes" true
    local sourceAfter=caSSMesh book,flatAfter=caSSMesh flat,unchanged=true,currentBookTM=book.transform,currentFlatTM=flat.transform
    for i=1 to 4 do if distance currentBookTM[i]sourceTM[i]>0.000001 or distance currentFlatTM[i]flatTM[i]>0.000001 do unchanged=false
    if sourceBefore.numverts!=sourceAfter.numverts or flatBefore.numverts!=flatAfter.numverts then unchanged=false
    else
    (
        for i=1 to sourceBefore.numverts do if distance(getVert sourceBefore i)(getVert sourceAfter i)>0.00001 do unchanged=false
        for i=1 to flatBefore.numverts do if distance(getVert flatBefore i)(getVert flatAfter i)>0.00001 do unchanged=false
    )
    delete sourceBefore;delete sourceAfter;delete flatBefore;delete flatAfter
    caSSCheck "All generation leaves detailed original sources unchanged" unchanged
    local savedCabinet=caSSPose cabinet,savedStair=caSSPose stair
    caSSCheck "Combined actual shelves/stairs scene saves" (saveMaxFile(CA_TEST_OUTPUT+"CyrusArrange-Shelves-Stairs-032.max")quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"CyrusArrange-Shelves-Stairs-032.max")quiet:true useFileUnits:true
    cabinet=getNodeByName "SS_Books_Arrangement";stair=getNodeByName "SS_Stairs_Arrangement"
    caSSCheck "Schema7 save/reopen retains both complete real-model arrangements and required source counts" (deepEqual savedCabinet(caSSPose cabinet)strictCompare:true and deepEqual savedStair(caSSPose stair)strictCompare:true and deepEqual required(caPropMinimums stair)strictCompare:true)
    maps=caSSHash input[2]==input[3]and caSSHash input[4]==input[5]
    for row in input[8]do if caSSHash row[1]!=row[3]do maps=false
    caSSCheck "Original prepared Max, metadata and all maps remain byte-identical" maps
    append caSSLog "LIMIT: receiver cabinet/stairs and fruit/bin are newly modeled test geometry; the repeated book is the full imported prepared mesh. Renderer/picker gestures/final package remain separate."
    true
)
try(caSSRun())catch(caSSFailures+=1;append caSSLog("EXCEPTION "+(getCurrentException()as string));append caSSLog("SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caSSLog(getCurrentExceptionStackTrace()as string))
caSSFinished=true;caSSWrite()
