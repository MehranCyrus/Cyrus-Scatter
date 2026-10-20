/* Owned Max2027: real connected concave mesh, conservative collision refinement.
   Analytic source factories and independent measurements are test code only. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global caCCLog=#(),caCCPasses=0,caCCFailures=0,caCCFinished=false
fn caCCWrite = (local f=createFile(CA_TEST_OUTPUT+"result.txt");format "% passes=% failures=%\n" (if caCCFinished then(if caCCFailures==0 then "SUCCESS" else "ERROR")else "RUNNING") caCCPasses caCCFailures to:f;for line in caCCLog do format "%\n" line to:f;close f)
fn caCCCheck label value = (if value then caCCPasses+=1 else caCCFailures+=1;append caCCLog((if value then "PASS " else "FAIL ")+label);caCCWrite();if not value do throw label;value)
fn caCCPose owner = for r in(caOutputRows owner)collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
fn caCCEqual a b = deepEqual a b strictCompare:true
fn caCCArch =
(
    local profile=#([-50,0,0],[-35,0,0],[-35,0,80],[35,0,80],[35,0,0],[50,0,0],[50,0,100],[-50,0,100],[-35,0,100],[35,0,100]),points=#(),faces=#()
    for y in #(-20,20)do for p in profile do append points ([p.x,y,p.z]*10)
    for t in #([1,2,3],[1,3,9],[1,9,8],[5,6,7],[5,7,4],[4,7,10],[3,4,10],[3,10,9])do(append faces t;append faces [t.z+10,t.y+10,t.x+10])
    local outline=#(1,2,3,4,5,6,7,10,9,8)
    for i=1 to outline.count do(local a=outline[i],b=outline[if i==outline.count then 1 else i+1];append faces [a,a+10,b+10];append faces [a,b+10,b])
    local node=mesh name:"CC_Original_Arch" vertices:points faces:faces;node.pos=[4000,2000,0];node.material=standardMaterial name:"CC_Arch_Material" diffuse:(color 110 60 30);node
)
fn caCCSettings owner quantity = (local a=caPlacementSettings owner;a[1]=932032L;a[2]=2;a[3]=quantity;a[5]=0;a[6]=0;a[7]=false;a[8]=false;a)
fn caCCBounds node = nodeGetBoundingBox node(matrix3 1)
fn caCCExport label receivers sources owner =
(
    local f=createFile(CA_TEST_OUTPUT+label+"-meshes.txt"),rows=caOutputRows owner
    for kind in #("receiver","source","output")do
    (
        local nodes=case kind of("receiver":receivers;"source":sources;"output":for r in rows collect r[9])
        for i=1 to nodes.count do
        (
            local m=undefined;in coordsys world(m=snapshotAsMesh nodes[i] renderMesh:false)
            format "mesh % % % %\n" kind i m.numverts m.numfaces to:f
            for j=1 to m.numverts do(local p=getVert m j;format "v % % %\n" (formattedPrint(p.x as double)format:".17g") (formattedPrint(p.y as double)format:".17g") (formattedPrint(p.z as double)format:".17g")to:f)
            for j=1 to m.numfaces do(local t=getFace m j;format "f % % % % %\n" (t.x as integer)(t.y as integer)(t.z as integer)(getFaceMatID m j)(getFaceSmoothGroup m j)to:f)
            if kind=="output" do(local r=rows[i],assets=caAssetRows owner,index=0;for n=1 to assets.count where assets[n][1]==r[2] do index=n;format "pose % % % % % % % %\n" index r[1](formattedPrint(r[4].x as double)format:".17g")(formattedPrint(r[4].y as double)format:".17g")(formattedPrint(r[4].z as double)format:".17g")(formattedPrint r[5]format:".17g")(formattedPrint r[6]format:".17g")r[8]to:f)
            format "end\n" to:f;delete m
        )
    );close f;true
)
fn caCCInsideGap bounds center = (bounds[1].x>=center.x-350.03 and bounds[2].x<=center.x+350.03 and bounds[1].y>=center.y-200.03 and bounds[2].y<=center.y+200.03 and abs(bounds[1].z)<0.03 and bounds[2].z<=800.03)
fn caCCRun =
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1
    caCCCheck "Exact native in an owned Max2027 process" (caVersion()=="0.3.2" and(maxVersion())[1]==29000)
    local arch=caCCArch(),device=box name:"CC_Original_Device" width:200 length:200 height:500 pos:[6000,2000,0]
    device.material=standardMaterial name:"CC_Device_Material" diffuse:(color 30 70 130)
    local archTM=arch.transform as string,deviceTM=device.transform as string,sourceMesh=snapshotAsMesh arch
    caCCCheck "Actual source is a connected 20-vertex 36-face concave arch" (sourceMesh.numverts==20 and sourceMesh.numfaces==36);delete sourceMesh
    local floor=box name:"CC_Floor" width:1000 length:400 height:20 pos:[0,0,-20],owner=caCreateArrangement();owner.name="CC_Nested"
    caBindReceivers owner #(floor);caRegisterAssets owner #(arch) 7
    caGeneratePlacement owner(caCCSettings owner 1) false
    local archRow=(caOutputRows owner)[1],archID=archRow[2];caSetLocked owner #(archRow[1]) true
    caCCCheck "Complete original-size arch is protected on the real board" ((caOutputRows owner).count==1 and(caOutputRows owner)[1][7] and(caOutputRows owner)[1][6]==1)
    caRegisterAssets owner #(device) 7;local deviceID=(caAssetRows owner)[2][1],minimums=#(#(archID,1),#(deviceID,1)),values=caCCSettings owner 2
    local start=timeStamp(),result=caGeneratePlacementMinimums owner values minimums false,rows=caOutputRows owner,deviceRow=undefined
    append caCCLog("PERFORMANCE nested milliseconds="+((timeStamp()-start)as string)+" result="+(result as string));caCCWrite()
    for r in rows where r[2]==deviceID do deviceRow=r
    caCCCheck "Original-size device fits inside a protected concave prop instead of being box-rejected" (rows.count==2 and result[5]==0 and deviceRow!=undefined and deviceRow[6]==1 and caCCInsideGap (caCCBounds deviceRow[9]) ([0,0,0]))
    local archBounds=caCCBounds rows[1][9],deviceBounds=caCCBounds deviceRow[9]
    caCCCheck "Actual output bounds overlap while real leg beam and support constraints pass" (deviceBounds[1].x>archBounds[1].x and deviceBounds[2].x<archBounds[2].x and deviceBounds[2].z<archBounds[2].z and caCCInsideGap deviceBounds [0,0,0])
    local pose=caCCPose owner;caGeneratePlacementMinimums owner values minimums false
    caCCCheck "Compound placement repeats exact native identities poses and scales" (caCCEqual pose(caCCPose owner))
    caGeneratePlacementMinimums owner values minimums true;max undo
    caCCCheck "One Undo restores seed minimum policy and the complete nested result" ((caPlacementSettings owner)[1]==values[1] and caCCEqual pose(caCCPose owner) and caCCEqual minimums(caPropMinimums owner))
    caCCExport "nested" #(floor) #(arch,device) owner
    -- A genuine overlap must still reject even after an earlier successful refinement.
    deviceRow=undefined;for r in(caOutputRows owner)where r[2]==deviceID do deviceRow=r
    caSetLocked owner #(deviceRow[1]) true
    local deviceCenter=(deviceBounds[1]+deviceBounds[2])*0.5,blocker=box name:"CC_True_Blocker" width:50 length:50 height:100 pos:[deviceCenter.x,deviceCenter.y,100]
    caSetCollisionScope owner #(blocker) false;pose=caCCPose owner;local revision=(caSetupSummary owner)[3],seed=(caPlacementSettings owner)[1],failed=false
    try(caGeneratePlacementMinimums owner(caPlacementSettings owner)minimums true)catch(failed=true)
    caCCCheck "True protected mesh overlap fails without publishing settings or output" (failed and(caSetupSummary owner)[3]==revision and(caPlacementSettings owner)[1]==seed and caCCEqual pose(caCCPose owner))
    caSetCollisionScope owner #() false;caGeneratePlacementMinimums owner(caPlacementSettings owner)minimums false
    caCCCheck "Removing the actual obstruction restores validated protected output" ((caOutputRows owner).count==2)
    local staticFloor=box name:"CC_Static_Floor" width:1000 length:400 height:20 pos:[2500,0,-20],obstacle=box name:"CC_Static_Device" width:200 length:200 height:500 pos:[2500,0,0],staticOwner=caCreateArrangement()
    staticOwner.name="CC_Static";caBindReceivers staticOwner #(staticFloor);caSetCollisionScope staticOwner #(obstacle) false;caRegisterAssets staticOwner #(arch) 7
    values=caCCSettings staticOwner 1;result=caGeneratePlacement staticOwner values false
    caCCCheck "Static obstacle inside the arch gap permits full-size concave source placement" (result[2]==1 and(caOutputRows staticOwner)[1][6]==1)
    caCCExport "static" #(staticFloor,obstacle) #(arch) staticOwner
    obstacle.pos.x=2075;result=caGeneratePlacement staticOwner values false
    caCCCheck "Moving the same static obstacle into an actual leg leaves the required copy unfilled" (result[1]==1 and result[2]==0 and result[5]==1)
    obstacle.pos.x=2500;caGeneratePlacement staticOwner values false
    local curve=splineShape name:"CC_Path";addNewSpline curve;addKnot curve 1 #corner #line [0,-2000,0];addKnot curve 1 #corner #line [10000,-2000,0];updateShape curve
    local pathOwner=caCreateArrangement();pathOwner.name="CC_Path_Setup";caBindPath pathOwner curve 1;caRegisterAssets pathOwner #(arch,device) 7
    values=caCCSettings pathOwner 1;local pathValues=(caPathSettings pathOwner)[2];pathValues[2]=2;pathValues[6]=0;pathValues[7]=2000;pathValues[9]=true;pathValues[10]=1;pathValues[11]=0;pathValues[12]=2000;pathValues[14]=true
    local pathAssets=caAssetRows pathOwner,pathMinimums=#(#(pathAssets[1][1],1),#(pathAssets[2][1],1))
    result=caGeneratePathMinimums pathOwner values pathValues pathMinimums false
    caCCCheck "Path-only pair validation permits a real nested source gap at shared base centers" (result[2]==2 and result[5]==0)
    caCCExport "path" #() #(arch,device) pathOwner
    local meshAfter=snapshotAsMesh arch
    local materialGood=true;for r in(caOutputRows owner)do if r[9].material!=(if r[2]==archID then arch.material else device.material)do materialGood=false
    caCCCheck "Every actual output retains source material and complete topology" (materialGood and(caOutputRows staticOwner)[1][9].material==arch.material and meshAfter.numverts==20 and meshAfter.numfaces==36);delete meshAfter
    caCCCheck "Source transforms geometry and materials remain unchanged" ((arch.transform as string)==archTM and(device.transform as string)==deviceTM and arch.material.name=="CC_Arch_Material" and device.width==200 and device.height==500)
    local names=#(owner.name,staticOwner.name,pathOwner.name),poses=for s in #(owner,staticOwner,pathOwner)collect(caCCPose s)
    caCCCheck "Actual compound-collision scene saves" (saveMaxFile(CA_TEST_OUTPUT+"CyrusArrange-Compound-Collisions-032.max") quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"CyrusArrange-Compound-Collisions-032.max") quiet:true useFileUnits:true
    local reopened=for n in names collect(getNodeByName n),same=true
    for i=1 to reopened.count do if not caCCEqual poses[i](caCCPose reopened[i])do same=false
    caCCCheck "Reopen restores all actual output and policies without persisting proxy pointers" (same and(caPropMinimums reopened[1]).count==2 and(caPropMinimums reopened[3]).count==2)
    for s in reopened do caGeneratePlacement s(caPlacementSettings s)false
    same=true;for i=1 to reopened.count do if not caCCEqual poses[i](caCCPose reopened[i])do same=false
    caCCCheck "Fresh source proxies regenerate identically after reopening" same
    append caCCLog "LIMIT: original modeled connected arch and box devices; conservative band envelopes can still reject coarse in-band shapes. Independent full source/support/lane campaign remains separate."
)
try(caCCRun())catch(caCCFailures+=1;append caCCLog("EXCEPTION "+(getCurrentException()as string));append caCCLog("SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caCCLog(getCurrentExceptionStackTrace()as string))
caCCFinished=true;caCCWrite()
