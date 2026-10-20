cplResetScene()
(
    units.SystemType=#meters
    units.SystemScale=1
    local ground=box name:"Street" width:6 length:6 height:0.1 pos:[0,0,-0.1]
    ground.material=standardMaterial name:"Street grey" diffuse:(color 68 72 77)
    local curb=box name:"Curb" width:0.12 length:4 height:0.16 pos:[-1,0,0]
    curb.material=standardMaterial name:"Concrete" diffuse:(color 125 128 130)
    local lab=CyrusPhysicsLab name:"Standalone_Physics_Leaves"
    local colours=#((color 112 48 18),(color 161 86 22),(color 96 106 34))
    for variant=1 to 3 do
    (
        local vertices=#([-.05,0,0],[-.035,-.07,.001],[0,-.1,0],[.035,-.07,.001],[.05,0,0],[.025,.07,-.001],[0,.1,0],[-.025,.07,-.001],[0,0,.003])
        local faces=for i=1 to 8 collect [9,i,(if i==8 then 1 else i+1)]
        local leaf=mesh name:("Leaf_Source_"+variant as string) vertices:vertices faces:faces pos:[5+variant,5,0]
        leaf.material=standardMaterial name:("Leaf colour "+variant as string) diffuse:colours[variant] twoSided:true
        lab.addSource leaf
    )
    lab.setReceiver ground
    lab.addCollider curb
    lab.bodyLimit=1000
    lab.emissionHeight=0.4
    lab.scaleMinimum=0.7
    lab.scaleMaximum=1.15
    lab.configure()
    cplArea lab.physicsDocument lab #([-.85,-1,0],[.85,-1,0],[.85,1,0],[-.85,1,0]) 60
    local done=false
    for i=1 to 4000 while not done do done=cplTick lab.physicsDocument 8
    if cplBusy lab.physicsDocument do throw "Demonstration did not finish settling."
    local stats=cplStats lab.physicsDocument
    if findString stats "\"rows\":60"==undefined do throw stats
    cplExportFile lab.physicsDocument (CPLTestDir+"demo-recipe.json")
    local camera=Targetcamera name:"Demo_Camera" pos:[1.8,-2,1.6] target:(Targetobject pos:[0,0,0.03]) fov:50
    OmniLight name:"Demo_Light" pos:[1,-1,4] multiplier:1.1
    ambientLight=color 35 35 35
    renderers.current=Default_Scanline_Renderer()
    render camera:camera outputfile:(CPLTestDir+"demo.png") vfb:false outputwidth:1000 outputheight:750
    saveMaxFile (CPLTestDir+"PhysicsLab_Leaves_Max2027.max") quiet:true
    local report=createFile (CPLTestDir+"assertions.txt")
    format "%\n" stats to:report
    close report
)
