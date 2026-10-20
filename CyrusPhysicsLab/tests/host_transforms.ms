cplResetScene()
(
    units.SystemType=#centimeters;units.SystemScale=1
    local ground=box width:2000 length:2000 height:10 pos:[0,0,-10]
    ground.scale=[-1,1,1]
    local source=box width:10 length:5 height:0.4 pos:[500,500,0] mapcoords:true
    source.scale=[1.3,0.7,1]
    source.rotation=eulerAngles 0 0 37
    source.objectOffsetPos=[2,3,1]
    local lab=CyrusPhysicsLab name:"PhysicsLab_Transforms" pos:[50,-20,0]
    lab.setReceiver ground;lab.addSource source;lab.brushRadius=.01;lab.scaleMinimum=1;lab.scaleMaximum=1
    local boundary=rectangle width:80 length:60 pos:[20,40,0]
    boundary.rotation=eulerAngles 0 0 25
    convertToSplineShape boundary
    for i=1 to numKnots boundary 1 do setKnotType boundary 1 i #corner
    updateShape boundary
    lab.areaBoundary=boundary;lab.areaCount=12
    lab.settleArea()
    local done=false
    for i=1 to 1000 while not done do done=cplTick lab.physicsDocument 8
    if findString (cplStats lab.physicsDocument) "\"rows\":12"==undefined do throw (cplStats lab.physicsDocument)
    cplExportFile lab.physicsDocument (CPLTestDir+"transforms.json")
    local vertices=(snapshotAsMesh lab).numverts
    if vertices!=96 do throw "Unexpected output geometry count."
    local saved=cplRows lab.physicsDocument
    saveMaxFile (CPLTestDir+"transforms.max") quiet:true
    loadMaxFile (CPLTestDir+"transforms.max") quiet:true
    lab=getNodeByName "PhysicsLab_Transforms"
    if cplRows lab.physicsDocument!=saved do throw "Transform/units roundtrip changed saved poses."
    local bad=false
    try(lab.addCollider lab)catch(bad=true)
    if not bad do throw "Self binding should be rejected."
    local report=createFile (CPLTestDir+"assertions.txt")
    format "PASS centimetres, source offset/rotation/nonuniform scale, mirrored receiver, transformed polygon, save/reopen and self-binding rejection\n" to:report
    close report
)
