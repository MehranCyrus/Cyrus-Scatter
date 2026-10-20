/* Test-only complete sedan/road factories. All coordinates are authored mm.
   Models are new fixture data; production placement remains C++. */
global caRCCarPoints,caRCCarFaces,caRCCarMats
global caRCControls=#([0,0,0],[14000,0,0],[16000,20000,0],[30000,20000,0])
fn caRCFrame t=
(
    local p=caRCControls,u=1.0-t
    local point=p[1]*(u*u*u)+p[2]*(3*u*u*t)+p[3]*(3*u*t*t)+p[4]*(t*t*t)
    local tangent=normalize((p[2]-p[1])*(3*u*u)+(p[3]-p[2])*(6*u*t)+(p[4]-p[3])*(3*t*t))
    #(point,tangent,normalize[-tangent.y,tangent.x,0])
)
fn caRCFace a b c materialID=(append caRCCarFaces [a,b,c];append caRCCarMats materialID)
fn caRCBox low high materialID=
(
    local offset=caRCCarPoints.count
    for p in #([low.x,low.y,low.z],[high.x,low.y,low.z],[high.x,high.y,low.z],[low.x,high.y,low.z],[low.x,low.y,high.z],[high.x,low.y,high.z],[high.x,high.y,high.z],[low.x,high.y,high.z])do append caRCCarPoints p
    for f in #([1,3,2],[1,4,3],[5,6,7],[5,7,8],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,4,8],[3,8,7],[4,1,5],[4,5,8])do caRCFace(offset+f.x)(offset+f.y)(offset+f.z)materialID
)
fn caRCCylinderY center radius width materialID sides:64=
(
    local offset=caRCCarPoints.count
    for side in #(-1,1)do for i=0 to sides-1 do append caRCCarPoints(center+[radius*cos(360.0*i/sides),side*width*.5,radius*sin(360.0*i/sides)])
    append caRCCarPoints(center+[0,-width*.5,0]);append caRCCarPoints(center+[0,width*.5,0])
    for i=1 to sides do
    (
        local j=if i==sides then 1 else i+1,a=offset+i,b=offset+j,c=offset+sides+j,d=offset+sides+i
        caRCFace a d c materialID;caRCFace a c b materialID
        caRCFace(offset+2*sides+1)a b materialID;caRCFace(offset+2*sides+2)c d materialID
    )
)
fn caRCMakeCar=
(
    caRCCarPoints=#();caRCCarFaces=#();caRCCarMats=#()
    local sections=#(#(-2250,750,300,650),#(-2000,950,250,850),#(-1300,950,250,980),#(1000,950,250,960),#(2000,900,300,780),#(2250,700,350,650))
    for s in sections do
    (
        local x=s[1],w=s[2],low=s[3],high=s[4]
        for yz in #([-.75*w,low,0],[.75*w,low,0],[w,low+100,0],[w,high-100,0],[.75*w,high,0],[-.75*w,high,0],[-w,high-100,0],[-w,low+100,0])do append caRCCarPoints [x,yz.x,yz.y]
    )
    for ring=0 to sections.count-2 do for i=1 to 8 do
    (
        local j=if i==8 then 1 else i+1,a=ring*8+i,b=ring*8+j,c=(ring+1)*8+j,d=(ring+1)*8+i
        caRCFace a b c 1;caRCFace a c d 1
    )
    append caRCCarPoints [-2250,0,475];append caRCCarPoints [2250,0,500]
    local rear=caRCCarPoints.count-1,front=caRCCarPoints.count
    for i=1 to 8 do(local j=if i==8 then 1 else i+1;caRCFace rear j i 1;caRCFace front(40+i)(40+j)1)
    -- Shaped glass cabin, then a thin painted roof. +X is vehicle front.
    local offset=caRCCarPoints.count
    join caRCCarPoints #([-1450,-760,930],[1200,-760,930],[650,-650,1475],[-800,-650,1475],[-1450,760,930],[1200,760,930],[650,650,1475],[-800,650,1475])
    for f in #([1,3,2],[1,4,3],[5,6,7],[5,7,8],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,4,8],[3,8,7],[4,1,5],[4,5,8])do caRCFace(offset+f.x)(offset+f.z)(offset+f.y)3
    caRCBox [-790,-650,1474] [640,650,1500] 1
    -- Four actual tyre contacts; axle center is x=100 rather than body x=0.
    for x in #(-1300,1500)do for y in #(-820,820)do
    (
        caRCCylinderY [x,y,320] 320 225 2
        caRCCylinderY [x,y,320] 190 240 4
    )
    for y in #(-600,600)do
    (
        caRCBox [2160,y-170,525] [2260,y+170,635] 5
        caRCBox [-2260,y-170,525] [-2160,y+170,635] 6
    )
    local node=mesh name:"ROAD_Original_Sedan"vertices:caRCCarPoints faces:caRCCarFaces
    node.pos=[80000,-10000,0]
    local paintSet=multiMaterial numsubs:6 name:"ROAD_Sedan_Materials"
    paintSet[1]=standardMaterial name:"ROAD_Paint"diffuse:(color 35 110 175)specularLevel:65 glossiness:65
    paintSet[2]=standardMaterial name:"ROAD_Tyres"diffuse:(color 20 22 24)
    paintSet[3]=standardMaterial name:"ROAD_Glass"diffuse:(color 25 45 60)specularLevel:90 glossiness:85
    paintSet[4]=standardMaterial name:"ROAD_Rims"diffuse:(color 160 170 180)specularLevel:80 glossiness:60
    paintSet[5]=standardMaterial name:"ROAD_Headlights"diffuse:(color 235 235 205)selfIllumAmount:30
    paintSet[6]=standardMaterial name:"ROAD_Taillights"diffuse:(color 180 25 20)selfIllumAmount:20
    node.material=paintSet
    for i=1 to caRCCarFaces.count do(setFaceMatID node i caRCCarMats[i];setFaceSmoothGroup node i(if caRCCarMats[i]==2 or caRCCarMats[i]==4 then 1 else 0))
    meshop.setMapSupport node 1 true;meshop.setNumMapVerts node 1 caRCCarPoints.count;meshop.setNumMapFaces node 1 caRCCarFaces.count
    for i=1 to caRCCarPoints.count do meshop.setMapVert node 1 i(caRCCarPoints[i]/4500)
    for i=1 to caRCCarFaces.count do meshop.setMapFace node 1 i caRCCarFaces[i]
    update node;node
)
fn caRCMakeBand name low high materialValue=
(
    local points=#(),faces=#(),segments=64
    for z in #(0,-200)do for i=0 to segments do
    (
        local frame=caRCFrame(i as float/segments)
        append points(frame[1]+frame[3]*low+[0,0,z]);append points(frame[1]+frame[3]*high+[0,0,z])
    )
    local base=2*(segments+1)
    for i=0 to segments-1 do
    (
        local a=2*i+1,b=a+1,c=a+3,d=a+2
        join faces #([a,c,b],[a,d,c],[a+base,b+base,c+base],[a+base,c+base,d+base],[a,a+base,d+base],[a,d+base,d],[b,c,c+base],[b,c+base,b+base])
    )
    join faces #([1,2,2+base],[1,2+base,1+base],[base-1,2*base-1,2*base],[base-1,2*base,base])
    local node=mesh name:name vertices:points faces:faces;node.material=materialValue;node
)
fn caRCMakeRoad=
(
    local asphalt=standardMaterial name:"ROAD_Asphalt"diffuse:(color 48 53 58),median=standardMaterial name:"ROAD_Center_Strip"diffuse:(color 195 170 70),shoulder=standardMaterial name:"ROAD_Shoulder"diffuse:(color 80 86 84)
    #(caRCMakeBand "ROAD_Right_Shoulder" -6000 -3350 shoulder,caRCMakeBand "ROAD_Right_Lane" -3350 -150 asphalt,caRCMakeBand "ROAD_Median" -150 150 median,caRCMakeBand "ROAD_Left_Lane" 150 3350 asphalt,caRCMakeBand "ROAD_Left_Shoulder" 3350 6000 shoulder)
)
fn caRCMakeCurve=
(
    local p=caRCControls,node=splineShape name:"ROAD_Centerline"
    addNewSpline node;addKnot node 1 #bezier #curve p[1]p[1]p[2];addKnot node 1 #bezier #curve p[4]p[3]p[4];updateShape node;node
)
