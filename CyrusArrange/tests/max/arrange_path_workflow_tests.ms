/* Owned Max2027 path capture/publication; actual node geometry and independent world-curve oracle. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global caPHLog=#(),caPHChecks=0,caPHFailures=0,caPHFinished=false
fn caPHWrite = (local f=createFile(CA_TEST_OUTPUT+"result.txt"); format "% passes=% failures=%\n" (if caPHFinished then(if caPHFailures==0 then "SUCCESS" else "ERROR")else "RUNNING") caPHChecks caPHFailures to:f; for line in caPHLog do format "%\n" line to:f; close f)
fn caPHCheck label value = (if value then caPHChecks+=1 else caPHFailures+=1;append caPHLog((if value then "PASS " else "FAIL ")+label);caPHWrite();if not value do throw label;value)
fn caPHEqual a b = deepEqual a b strictCompare:true
fn caPHPose setup = for r in(caOutputRows setup)collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
fn caPHLine label = (local n=splineShape name:label;addNewSpline n;addKnot n 1 #corner #line [0,0,0];addKnot n 1 #corner #line [15000,0,0];updateShape n;n)
fn caPHBox label w d h point = box name:label width:w length:d height:h pos:point
fn caPHPrepare setup =
(
    local a=caPlacementSettings setup,p=(caPathSettings setup)[2]
    a[1]=413032L;a[2]=2;a[3]=3;a[5]=20;a[6]=10;a[7]=false;a[8]=false
    p[2]=2;p[3]=true;p[4]=0;p[5]=false;p[6]=1750;p[7]=3200;p[8]=5000;p[9]=true
    p[10]=3;p[11]=-1750;p[12]=3200;p[13]=5000;p[14]=true;p[15]=true;p[18]=0;p[19]=0
    #(a,p)
)
fn caPHBounds setup width:4000 depth:1800 height:1500 =
(
    local rows=caOutputRows setup,good=true
    for i=1 to rows.count do
    (
        local r=rows[i],node=r[9]
        if not isValidNode node then good=false
        else
        (
            local bounds=nodeGetBoundingBox node(matrix3 1)
            if abs(bounds[1].z)>0.03 or abs(bounds[2].z-height*r[6])>0.03 or node.material==undefined or node.material.name!="PH_Material" do good=false
            for j=1 to i-1 do
            (
                local b=nodeGetBoundingBox rows[j][9](matrix3 1)
                if bounds[1].x<b[2].x-0.03 and bounds[2].x>b[1].x+0.03 and bounds[1].y<b[2].y-0.03 and bounds[2].y>b[1].y+0.03 do good=false
            )
        )
    )
    good
)
-- Independent dense world-space polyline/inversion over known authored Bezier
-- controls transformed by Max's actual object transform. It is test code only.
fn caPHReference controls =
(
    local points=#(),prefix=#(0.0 as double),total=0.0 as double,count=4096
    for i=0 to count do
    (
        local t=(i as double)/(count as double),u=1.0-t
        local point=controls[1]*(u*u*u)+controls[2]*(3*u*u*t)+controls[3]*(3*u*t*t)+controls[4]*(t*t*t)
        append points point
        if i>0 do(total+=(distance points[i] point)as double;append prefix total)
    )
    #(points,prefix,total)
)
fn caPHReferenceFrame reference fraction =
(
    local points=reference[1],prefix=reference[2],target=reference[3]*fraction,lo=1,hi=prefix.count
    while lo<hi do(local mid=(floor((lo+hi)/2.0))as integer;if prefix[mid]<target then lo=mid+1 else hi=mid)
    local index=amax 2 lo,ratio=(target-prefix[index-1])/(prefix[index]-prefix[index-1])
    local point=points[index-1]+(points[index]-points[index-1])*ratio
    local tangent=normalize(points[index]-points[index-1]),left=normalize[-tangent.y,tangent.x,0]
    #(point,tangent,left)
)
fn caPHCurvedActual setup reference =
(
    local rows=caOutputRows setup,good=rows.count==6
    for i=1 to rows.count do
    (
        local slot=if i<=3 then i else i-3,reverse=i>3
        local fraction=if reverse then 1.0-(slot-0.5)/3.0 else (slot-0.5)/3.0
        local frame=caPHReferenceFrame reference fraction,side=if reverse then -1750 else 1750
        local target=frame[1]+frame[3]*side,node=rows[i][9],bounds=nodeGetBoundingBox node(matrix3 1)
        local actual=(bounds[1]+bounds[2])*0.5;actual.z=bounds[1].z
        if distance actual target>2.0 do good=false
        local x=node.transform[1],heading=atan2 x.y x.x,wanted=(atan2 frame[2].y frame[2].x)+(if reverse then 180 else 0)
        if abs(mod(heading-wanted+540)360-180)>0.1 do good=false
        if abs(bounds[1].z)>0.03 or abs(bounds[2].z-1500)>0.03 do good=false
    )
    good
)
fn caPHRun =
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1
    caPHCheck "Actual path host loads exact 0.3.2 native" (caVersion()=="0.3.2" and(maxVersion())[1]==29000)
    local curve=caPHLine "PH_Line",source=caPHBox "PH_Car" 4000 1800 1500 [40000,0,0]
    source.material=standardMaterial name:"PH_Material" diffuse:(color 80 140 180)
    local sourceBefore=source.transform as string,curveBefore=curve.transform as string
    local road=caPHBox "PH_Road" 20000 12000 20 [7500,0,-20],setup=caCreateArrangement();setup.name="PH_Setup"
    caBindPath setup curve 1;caBindReceivers setup #(road);caRegisterAssets setup #(source) 7
    caPHCheck "Path binding is real, discoverable and passive" ((caPathSettings setup)[1]==curve and(caOutputRows setup).count==0 and(caGeometryCacheInfo setup)[3]==undefined and(caSceneSetups #(curve))[1][2])
    local values=caPHPrepare setup,a=values[1],p=values[2]
    local result=caGenerateAlongPath setup a p false,rows=caOutputRows setup
    caPHCheck "Actual two-way path publishes three cars in each lane" (result[1]==6 and result[2]==6 and result[5]==0 and(caPathSettings setup)[3][1]==3 and(caPathSettings setup)[3][2]==3)
    local physical=caPHBounds setup
    for i=1 to rows.count do
    (
        local bounds=nodeGetBoundingBox rows[i][9](matrix3 1),center=(bounds[1]+bounds[2])*0.5
        local expectedX=if i<=3 then 2500+5000*(i-1) else 12500-5000*(i-4),expectedY=if i<=3 then 1750 else -1750
        if abs(center.x-expectedX)>0.03 or abs(center.y-expectedY)>0.03 or bounds[1].x<9.97 or bounds[2].x>14990.03 or bounds[1].y<expectedY-1590.03 or bounds[2].y>expectedY+1590.03 do physical=false
        if abs(mod(rows[i][5]+360)360-(if i<=3 then 0 else 180))>0.001 do physical=false
    )
    caPHCheck "Actual nodes satisfy base centers, opposite headings, road contact, caps, full lane bounds and pair nonoverlap" physical
    caPHCheck "Path/source transforms and original source size/material remain unchanged" ((source.transform as string)==sourceBefore and(curve.transform as string)==curveBefore and source.width==4000 and source.length==1800 and source.height==1500 and source.material.name=="PH_Material")
    local savedA=caPlacementSettings setup,savedP=(caPathSettings setup)[2],pose=caPHPose setup
    caGenerateAlongPath setup savedA savedP false
    caPHCheck "Repeated seed restores exact path IDs, poses and scales" (caPHEqual pose(caPHPose setup))
    a=caPlacementSettings setup;p=(caPathSettings setup)[2];a[7]=true;a[9]=0.8;a[10]=1.1;p[18]=100;p[19]=250
    caGenerateAlongPath setup a p false
    caPHCheck "Path variations publish six actual nonoverlapping cars at final scale" ((caOutputRows setup).count==6 and caPHBounds setup)
    local variationA=caPlacementSettings setup,variationP=(caPathSettings setup)[2],variationPose=caPHPose setup
    caGenerateAlongPath setup variationA variationP true
    caPHCheck "Fresh path Generate chooses a different saved nonnegative seed" ((caPlacementSettings setup)[1]>=0 and(caPlacementSettings setup)[1]!=variationA[1])
    max undo
    caPHCheck "One Undo restores path fields, amount/scale/seed and complete poses" (caPHEqual variationA(caPlacementSettings setup) and caPHEqual variationP((caPathSettings setup)[2]) and caPHEqual variationPose(caPHPose setup))
    max redo
    caPHCheck "Redo restores path-generated output" ((caOutputRows setup).count==6 and(caPathSettings setup)[2][18]==100)
    a=caPlacementSettings setup;p=(caPathSettings setup)[2];savedA=caPlacementSettings setup;savedP=(caPathSettings setup)[2];pose=caPHPose setup
    local revision=(caSetupSummary setup)[3],bad=for value in p collect value,failed=false
    bad[1]=2;try(caGenerateAlongPath setup a bad false)catch(failed=true)
    caPHCheck "Missing selected curve fails without partial settings/revision/output" (failed and(caSetupSummary setup)[3]==revision and caPHEqual savedA(caPlacementSettings setup) and caPHEqual savedP((caPathSettings setup)[2]) and caPHEqual pose(caPHPose setup))
    bad=for value in p collect value;bad[7]=-1;failed=false;try(caGenerateAlongPath setup a bad false)catch(failed=true)
    caPHCheck "Invalid lane width retains previous accepted path and output" (failed and caPHEqual pose(caPHPose setup))
    curve.pos.y+=100
    caPHCheck "Editing a real path reference dirties the arrangement" ((caSetupSummary setup)[6]!=0)
    caGenerateAlongPath setup a p false
    caPHCheck "Generate recaptures moved path geometry" ((caOutputRows setup).count==6 and not caPHEqual pose(caPHPose setup))
    pose=caPHPose setup;revision=(caSetupSummary setup)[3]
    undo "Delete owned test path" on(delete curve)
    failed=false;try(caGenerateAlongPath setup a p false)catch(failed=true)
    caPHCheck "Deleted path fails explicitly and retains previous output" (failed and(caPathSettings setup)[1]==undefined and(caSetupSummary setup)[3]==revision and caPHEqual pose(caPHPose setup))
    max undo;curve=getNodeByName "PH_Line"
    caPHCheck "Undo path deletion restores the actual source reference" (isValidNode curve and(caPathSettings setup)[1]==curve)
    local savedName=setup.name; savedA=caPlacementSettings setup;savedP=(caPathSettings setup)[2];pose=caPHPose setup
    caPHCheck "Schema7 actual Max save succeeds" (saveMaxFile(CA_TEST_OUTPUT+"path-native.max") quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"path-native.max") quiet:true useFileUnits:true
    setup=getNodeByName savedName;source=getNodeByName "PH_Car";curve=getNodeByName "PH_Line"
    caPHCheck "Save/reopen retains real path reference and all typed fields/poses" ((caPathSettings setup)[1]==curve and caPHEqual savedA(caPlacementSettings setup) and caPHEqual savedP((caPathSettings setup)[2]) and caPHEqual pose(caPHPose setup))
    local originals,copies
    caPHCheck "Setup-only native clone succeeds" (maxOps.cloneNodes #(setup) cloneType:#copy expandHierarchy:false actualNodeList:&originals newNodes:&copies)
    local clone=copies[findItem originals setup]
    caPHCheck "Cloned document retains path but claims no original output" ((caSetupSummary clone)[1]!=(caSetupSummary setup)[1] and(caPathSettings clone)[1]==curve and(caOutputRows clone).count==0)
    caGenerateAlongPath clone (caPlacementSettings clone) ((caPathSettings clone)[2]) false
    caPHCheck "Clone Generate is independent of original path outputs" ((caOutputRows clone).count==6 and caPHEqual pose(caPHPose setup))
    -- A new real transformed Bezier. Broad support avoids inspection-grid tests;
    -- actual road contact is still required by the native physical query.
    local bent=splineShape name:"PH_Curved",radius=50000.0,k=4.0*(sqrt 2.0-1.0)/3.0
    addNewSpline bent;addKnot bent 1 #bezierCorner #curve [radius,0,0] [radius,0,0] [radius,k*radius,0]
    addKnot bent 1 #bezierCorner #curve [0,radius,0] [k*radius,radius,0] [0,radius,0];updateShape bent
    bent.transform=(scaleMatrix[1.5,0.7,1])*(rotateZMatrix 25)*(transMatrix[20000,-10000,0])
    local broad=caPHBox "PH_Broad_Road" 240000 240000 20 [0,0,-20],curved=caCreateArrangement();curved.name="PH_Curved_Setup"
    caBindPath curved bent 1;caBindReceivers curved #(broad);caRegisterAssets curved #(source) 7
    values=caPHPrepare curved;a=values[1];p=values[2]
    caGenerateAlongPath curved a p false
    local controls=for point in #([radius,0,0],[radius,k*radius,0],[k*radius,radius,0],[0,radius,0])collect(point*bent.objectTransform)
    local reference=caPHReference controls
    caPHCheck "Actual rotated/nonuniform Bezier capture follows independently measured world arc distance and headings" (caPHCurvedActual curved reference)
    caPHCheck "Large road support uses physical query without requiring a user sample grid" ((caGeometryCacheInfo curved)[3][8]==0)
    local curvedPose=caPHPose curved
    caGenerateAlongPath curved a p false
    caPHCheck "Curved two-way repeat is exact" (caPHEqual curvedPose(caPHPose curved))
    p[2]=1;p[6]=0;p[9]=false;a[3]=1;p[4]=90
    caGenerateAlongPath curved a p false
    local one=(caOutputRows curved)[1],baseFrame=caPHReferenceFrame reference 0.5
    caPHCheck "Model-forward axis affects actual published orientation" ((caOutputRows curved).count==1 and abs(mod(one[5]-(atan2 baseFrame[2].y baseFrame[2].x)+90+540)360-180)<0.1)
    -- Path-only collision scope: no fabricated support surfaces.
    local free=caCreateArrangement();caBindPath free (caPHLine "PH_Free") 1;caRegisterAssets free #(source) 7;values=caPHPrepare free;a=values[1];p=values[2];p[2]=1
    caGenerateAlongPath free a p false
    caPHCheck "Path-only mode uses authored path height and full output collision validation" ((caOutputRows free).count==3 and(caReceiverNodes free).count==0)
    -- Required counts are global across both lanes and commit with generation.
    local mini=caPHBox "PH_Small_Car" 1000 800 900 [50000,0,0],mixed=caCreateArrangement()
    mixed.name="PH_Required_Path";mini.material=standardMaterial name:"PH_Small_Material"
    caBindPath mixed (caPHLine "PH_Required_Line") 1;caBindReceivers mixed #(getNodeByName "PH_Road");caRegisterAssets mixed #(source,mini) 7
    values=caPHPrepare mixed;a=values[1];p=values[2];local requiredID=(caAssetRows mixed)[1][1],requiredRows=#(#(requiredID,4))
    caGeneratePathMinimums mixed a p requiredRows false;rows=caOutputRows mixed
    local requiredCount=0,actualGood=rows.count==6
    for i=1 to rows.count do
    (
        local r=rows[i],bounds=nodeGetBoundingBox r[9](matrix3 1),center=(bounds[1]+bounds[2])*0.5,side=if center.y>0 then 1750 else -1750
        if r[2]==requiredID do requiredCount+=1
        if i<=4 and r[2]!=requiredID do actualGood=false
        if abs(bounds[1].z)>0.03 or r[6]!=1 or bounds[1].x<9.97 or bounds[2].x>14990.03 or bounds[1].y<side-1590.03 or bounds[2].y>side+1590.03 do actualGood=false
        if r[9].material==undefined do actualGood=false
        for j=1 to i-1 do(local b=nodeGetBoundingBox rows[j][9](matrix3 1);if bounds[1].x<b[2].x+19.97 and bounds[2].x>b[1].x-19.97 and bounds[1].y<b[2].y+19.97 and bounds[2].y>b[1].y-19.97 do actualGood=false)
    )
    caPHCheck "Required path source occupies at least four of six copies across 3+3 lanes" (requiredCount>=4 and(caPathSettings mixed)[3][1]==3 and(caPathSettings mixed)[3][2]==3 and caPHEqual requiredRows(caPropMinimums mixed))
    caPHCheck "Actual required large sources precede optional fill and retain scale contact lane bounds and gap" actualGood
    pose=caPHPose mixed;caGeneratePathMinimums mixed a p requiredRows false
    caPHCheck "Required mixed path seed repeats exact IDs poses and scales" (caPHEqual pose(caPHPose mixed))
    local firstPose=caPHPose mixed
    requiredRows=#(#(requiredID,5));caGeneratePathMinimums mixed a p requiredRows true;local nextPose=caPHPose mixed
    max undo
    caPHCheck "Required path Undo restores minimums with settings and complete output" ((caPropMinimums mixed)[1][2]==4 and caPHEqual firstPose(caPHPose mixed))
    max redo
    caPHCheck "Required path Redo restores accepted policy and complete output" ((caPropMinimums mixed)[1][2]==5 and caPHEqual nextPose(caPHPose mixed))
    pose=caPHPose mixed;savedA=caPlacementSettings mixed;savedP=(caPathSettings mixed)[2];revision=(caSetupSummary mixed)[3];failed=false
    try(caGeneratePathMinimums mixed savedA savedP #(#(requiredID,7)) true)catch(failed=true)
    caPHCheck "Excessive required path draft retains seed policy revision and every output" (failed and(caSetupSummary mixed)[3]==revision and caPHEqual savedA(caPlacementSettings mixed) and caPHEqual savedP((caPathSettings mixed)[2]) and caPHEqual pose(caPHPose mixed) and(caPropMinimums mixed)[1][2]==5)
    caClearPath mixed
    caPHCheck "Clear path preserves combined six-copy target and required policy" (caPathSettings mixed==undefined and(caPlacementSettings mixed)[3]==6 and(caPropMinimums mixed)[1][2]==5 and caPHEqual pose(caPHPose mixed))
    max undo
    caPHCheck "Undo Clear path restores actual 3+3 binding and global minimum" (caPathSettings mixed!=undefined and(caPathSettings mixed)[2][10]==3 and(caPlacementSettings mixed)[3]==3 and(caPropMinimums mixed)[1][2]==5)
    savedA=caPlacementSettings mixed;savedP=(caPathSettings mixed)[2];pose=caPHPose mixed
    saveMaxFile(CA_TEST_OUTPUT+"required-path.max") quiet:true;loadMaxFile(CA_TEST_OUTPUT+"required-path.max") quiet:true useFileUnits:true;mixed=getNodeByName "PH_Required_Path"
    caPHCheck "Schema7 required path policies reference settings and all poses survive reopen" (isValidNode((caPathSettings mixed)[1]) and caPHEqual savedA(caPlacementSettings mixed) and caPHEqual savedP((caPathSettings mixed)[2]) and caPHEqual pose(caPHPose mixed) and(caPropMinimums mixed)[1][2]==5)
    savedA[2]=1;savedP[8]=5000;savedP[13]=5000;caGeneratePathMinimums mixed savedA savedP (caPropMinimums mixed) false
    caClearPath mixed
    caPHCheck "Clearing spacing path uses the current six outputs instead of inactive Copies" (caPathSettings mixed==undefined and(caPlacementSettings mixed)[3]==6 and(caPropMinimums mixed)[1][2]==5)
    max undo
    caPHCheck "Undo spacing clear restores the actual spacing mode and path reference" (isValidNode((caPathSettings mixed)[1]) and(caPlacementSettings mixed)[2]==1)
    append caPHLog "LIMIT: primitive actual models; complete real-model/performance/gesture/inline UI campaign remains separate."
    true
)
try(caPHRun())catch(caPHFailures+=1;append caPHLog("EXCEPTION "+(getCurrentException()as string));append caPHLog("SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caPHLog(getCurrentExceptionStackTrace()as string))
caPHFinished=true;caPHWrite()
