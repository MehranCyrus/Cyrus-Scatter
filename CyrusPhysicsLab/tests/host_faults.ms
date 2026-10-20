cplResetScene()
(
    units.SystemType=#meters;units.SystemScale=1
    local ground=box width:20 length:20 height:0.1 pos:[0,0,-0.1]
    local leaf=box width:0.1 length:0.05 height:0.004 pos:[5,5,0]
    local lab=CyrusPhysicsLab name:"PhysicsLab_Faults"
    lab.setReceiver ground;lab.addSource leaf;lab.brushRadius=.01;lab.configure()
    local baseline=cplRows lab.physicsDocument
    for mode=1 to 2 do
    (
        lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument
        cplInject lab.physicsDocument mode
        local done=false
        for i=1 to 500 while not done do done=cplTick lab.physicsDocument 8
        if cplRows lab.physicsDocument!=baseline do throw "Injected commit failure lost prior result."
        if findString (cplStats lab.physicsDocument) "Injected"==undefined do throw "Fault was not exercised."
        lab.stopBrush()
    )
    lab.emissionHeight=10;lab.configure();cplBudget lab.physicsDocument 60 65536 65536
    lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument
    for i=1 to 10 do cplTick lab.physicsDocument 8
    if findString (cplStats lab.physicsDocument) "\"timedOut\":true"==undefined do throw "Timeout was not retained."
    if cplRows lab.physicsDocument!=baseline do throw "Timeout silently committed."
    cplKeepCurrent lab.physicsDocument
    if findString (cplExport lab.physicsDocument) "\"settled\":false"==undefined do throw "Explicit unsettled status missing."
    cplExportFile lab.physicsDocument (CPLTestDir+"unsettled.json")
    cplClear lab.physicsDocument
    cplImportFile lab.physicsDocument (CPLTestDir+"unsettled.json")
    if findString (cplExport lab.physicsDocument) "\"settled\":false"==undefined do throw "Unsettled recipe status was lost."
    local report=createFile (CPLTestDir+"assertions.txt")
    format "PASS pre-commit / post-assignment faults, timeout retention, explicit Keep Current and unsettled file roundtrip\n" to:report
    close report
)
