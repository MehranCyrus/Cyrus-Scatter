/* Newly modeled test appliance; production capture/placement stays C++. */
global caDIPoints,caDIFaces,caDIMats
fn caDIFace a b c id=(append caDIFaces [a,b,c];append caDIMats id)
fn caDIPrimitiveBox low high id=
(
    local offset=caDIPoints.count
    for p in #([low.x,low.y,low.z],[high.x,low.y,low.z],[high.x,high.y,low.z],[low.x,high.y,low.z],[low.x,low.y,high.z],[high.x,low.y,high.z],[high.x,high.y,high.z],[low.x,high.y,high.z])do append caDIPoints p
    for f in #([1,3,2],[1,4,3],[5,6,7],[5,7,8],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,4,8],[3,8,7],[4,1,5],[4,5,8])do caDIFace(offset+f.x)(offset+f.y)(offset+f.z)id
)
fn caDIPrimitiveCylinder center radius width id axis:#y sides:64=
(
    local offset=caDIPoints.count
    for side in #(-1,1)do for i=0 to sides-1 do
    (
        local d=[radius*cos(360.0*i/sides),side*width*.5,radius*sin(360.0*i/sides)]
        if axis==#z do d=[d.x,-d.z,d.y]
        append caDIPoints(center+d)
    )
    local a=[0,-width*.5,0],b=[0,width*.5,0]
    if axis==#z do(a=[0,0,-width*.5];b=[0,0,width*.5])
    append caDIPoints(center+a);append caDIPoints(center+b)
    for i=1 to sides do
    (
        local j=if i==sides then 1 else i+1,a=offset+i,b=offset+j,c=offset+sides+j,d=offset+sides+i
        caDIFace a d c id;caDIFace a c b id;caDIFace(offset+2*sides+1)a b id;caDIFace(offset+2*sides+2)c d id
    )
)
fn caDIMakeAppliance=
(
    caDIPoints=#();caDIFaces=#();caDIMats=#()
    for x in #(-190,190)do for y in #(-200,200)do caDIPrimitiveBox [x-25,y-25,0] [x+25,y+25,30] 2
    caDIPrimitiveBox [-230,-250,30] [230,250,65] 1
    caDIPrimitiveBox [-230,-40,65] [230,250,440] 1
    caDIPrimitiveBox [-200,80,440] [200,235,560] 4
    caDIPrimitiveBox [-215,-60,330] [215,-40,425] 3
    caDIPrimitiveBox [-225,-250,65] [225,-50,80] 1
    caDIPrimitiveCylinder [0,-95,320] 45 80 1
    caDIPrimitiveBox [-15,-225,310] [15,-130,330] 2
    caDIPrimitiveCylinder [170,-180,180] 10 200 1 axis:#z
    caDIPrimitiveCylinder [170,-135,275] 10 90 1
    for x in #(-125,125)do caDIPrimitiveCylinder [x,-70,390] 20 30 2
    for x in #(-150,-90,-30,30,90,150)do caDIPrimitiveBox [x-12,-72,345] [x+12,-60,363] 5
    caDIPrimitiveBox [-225,-20,440] [-210,230,455] 1
    caDIPrimitiveBox [210,-20,440] [225,230,455] 1
    caDIPrimitiveBox [-210,-20,440] [210,-5,455] 1
    local node=mesh name:"DEVICE_Original_Appliance"vertices:caDIPoints faces:caDIFaces
    node.pos=[10000,10000,0]
    local materials=multiMaterial numsubs:5 name:"DEVICE_Appliance_Materials"
    materials[1]=standardMaterial name:"DEVICE_Brushed_Metal"diffuse:(color 160 165 170)specularLevel:70 glossiness:45
    materials[2]=standardMaterial name:"DEVICE_Rubber_Handles"diffuse:(color 22 25 28)
    materials[3]=standardMaterial name:"DEVICE_Control_Panel"diffuse:(color 45 50 60)
    materials[4]=standardMaterial name:"DEVICE_Water_Tank"diffuse:(color 55 110 130)specularLevel:70 glossiness:75
    materials[5]=standardMaterial name:"DEVICE_Buttons"diffuse:(color 195 75 40)
    node.material=materials
    for i=1 to caDIFaces.count do(setFaceMatID node i caDIMats[i];setFaceSmoothGroup node i 0)
    meshop.setMapSupport node 1 true;meshop.setNumMapVerts node 1 caDIPoints.count;meshop.setNumMapFaces node 1 caDIFaces.count
    for i=1 to caDIPoints.count do meshop.setMapVert node 1 i(caDIPoints[i]/560)
    for i=1 to caDIFaces.count do meshop.setMapFace node 1 i caDIFaces[i]
    update node;node
)
fn caDIBox name low high mat=
(
    local node=box name:name width:(high.x-low.x)length:(high.y-low.y)height:(high.z-low.z)pos:[(low.x+high.x)*.5,(low.y+high.y)*.5,low.z]
    node.material=mat;node
)
fn caDIMakeCabinet=
(
    local mat=standardMaterial name:"DEVICE_Cabinet_Material"diffuse:(color 145 110 80)
    local panels=#(caDIBox "DEVICE_Cabinet_Base" [-2630,-300,50] [-480,330,80] mat,
        caDIBox "DEVICE_Cabinet_Left" [-2630,-300,80] [-2600,330,800] mat,
        caDIBox "DEVICE_Cabinet_Right" [-510,-300,80] [-480,330,800] mat,
        caDIBox "DEVICE_Cabinet_Divider_A" [-2000,-300,80] [-1970,330,800] mat,
        caDIBox "DEVICE_Cabinet_Divider_B" [-1370,-300,80] [-1340,330,800] mat,
        caDIBox "DEVICE_Cabinet_Back" [-2630,300,80] [-480,330,800] mat)
    local blockers=#()
    for row in #(#(-2600,-2000,480),#(-1970,-1370,750),#(-1340,-510,480))do
    (
        append panels(caDIBox "DEVICE_Cabinet_Cap" [row[1],-300,row[3]] [row[2],300,row[3]+30] mat)
        local blocker=caDIBox "DEVICE_Above_Cap_Blocker" [row[1],-300,row[3]+30] [row[2],300,2000] mat
        blocker.renderable=false;append blockers blocker
    )
    #(panels,blockers)
)
