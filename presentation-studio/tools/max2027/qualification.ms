-- Owned fixture only. Run in the isolated host created by host-workflow.py.
-- NEVER run this fixture in an artist's Max session: it resets the disposable scene.
(
    if (maxVersion())[1] < 29000 or (maxVersion())[1] >= 30000 do throw "Qualification requires Max 2027."
    if MCPFixtureDir==undefined do throw "Private host scope is required."
    global CyrusCameraFixtureLog
    try(close CyrusCameraFixtureLog)catch()
    gc light:false
    resetMaxFile #noPrompt
    units.SystemType=#centimeters;units.SystemScale=1
    frameRate=30;renderWidth=1920;renderHeight=1080;renderPixelAspect=1.2
    animationRange=interval 10 70
    local rig=Dummy name:"Owned camera parent" pos:[100,200,0]
    local freeCam=FreeCamera name:"Owned \"garden\" camera" pos:[0,-1800,700]
    freeCam.parent=rig
    animate on (
        at time 10 (freeCam.position=[0,-1800,700];freeCam.rotation=eulerAngles 70 0 -15;freeCam.fov=50;rig.position=[100,200,0];rig.rotation=eulerAngles 0 0 0)
        at time 35 (freeCam.position=[100,-1500,550];freeCam.rotation=eulerAngles 78 6 5;freeCam.fov=70;rig.position=[120,200,50];rig.rotation=eulerAngles 0 0 10)
        at time 70 (freeCam.position=[2400,-400,600];freeCam.rotation=eulerAngles 80 -5 30;freeCam.fov=44;rig.position=[200,500,100];rig.rotation=eulerAngles 0 0 20)
    )
    local targetCam=TargetCamera name:"Owned target camera" pos:[0,-1800,700], target=TargetObject pos:[0,0,100]
    targetCam.target=target
    animate on (
        at time 10 (targetCam.position=[0,-1800,700];target.position=[0,0,100])
        at time 70 (targetCam.position=[1200,-1000,600];target.position=[500,100,200])
    )
    local physicalCam=Physical name:"Owned physical camera" targeted:false pos:[0,-1800,700]
    physicalCam.rotation=eulerAngles 72 4 0
    physicalCam.specify_focus=1
    animate on (
        at time 10 (physicalCam.focal_length_mm=28;physicalCam.zoom_factor=1;physicalCam.focus_distance=1000)
        at time 70 (physicalCam.position=[300,-1200,500];physicalCam.focal_length_mm=45;physicalCam.zoom_factor=1.15;physicalCam.focus_distance=3000)
    )
    local path=circle radius:900 pos:[0,0,600]
    local pathCam=FreeCamera name:"Owned constrained camera"
    pathCam.position.controller=Path_Constraint()
    pathCam.position.controller.appendTarget path 100
    animate on (at time 10 pathCam.position.controller.percent=0;at time 70 pathCam.position.controller.percent=65)
    pathCam.rotation=eulerAngles 70 0 0
    -- Independent evaluated matrix cyrusFixtureReference, not the exporter's quaternion conversion.
    global CyrusCameraFixtureNumber,CyrusCameraFixtureVector
    fn CyrusCameraFixtureNumber value = ((dotNetObject "System.Double" value).ToString "R" (dotNetClass "System.Globalization.CultureInfo").InvariantCulture)
    fn CyrusCameraFixtureVector value = "["+(CyrusCameraFixtureNumber value.x)+","+(CyrusCameraFixtureNumber value.y)+","+(CyrusCameraFixtureNumber value.z)+"]"
    fn cyrusFixtureReference camera output divisions:4 = (
        local f=createFile output
        format "{\"samples\":[" to:f
        for i=0 to (60*divisions) do (
            at time (10+i/(divisions as double)) (
                local tm=camera.transform
                if i>0 do format "," to:f
                format "{\"time\":%,\"positionMax\":%,\"rightMax\":%,\"upMax\":%,\"backMax\":%,\"horizontalFov\":%}" (CyrusCameraFixtureNumber (i/(30.0*divisions))) (CyrusCameraFixtureVector tm.row4) (CyrusCameraFixtureVector tm.row1) (CyrusCameraFixtureVector tm.row2) (CyrusCameraFixtureVector tm.row3) (CyrusCameraFixtureNumber camera.fov) to:f
            )
        )
        format "]}" to:f;close f
    )
    -- Freeze current time, selection, scene animation keys and render settings around exports.
    sliderTime=27;select rig
    local beforeTime=currentTime, beforeSelection=selection as array, beforeKeys=numKeys freeCam.position.controller
    CyrusCameraFixtureLog=createFile (MCPFixtureDir+"host-checks.txt")
    local log=CyrusCameraFixtureLog
    for spec in #(#(freeCam,"free"),#(targetCam,"target"),#(physicalCam,"physical"),#(pathCam,"path")) do (
        local output=MCPFixtureDir+spec[2]+".json"
        CyrusExportCameraAnimation spec[1] output 10 70 samplesPerFrame:4
        cyrusFixtureReference spec[1] (MCPFixtureDir+spec[2]+"-reference.json")
        cyrusFixtureReference spec[1] (MCPFixtureDir+spec[2]+"-subframe-reference.json") divisions:8
        format "PASS export %\n" spec[2] to:log
    )
    if currentTime!=beforeTime or selection.count!=beforeSelection.count or selection[1]!=beforeSelection[1] or numKeys freeCam.position.controller!=beforeKeys do throw "Export changed scene state."
    format "PASS time, selection and animation keys retained\n" to:log
    -- Overwrite uses atomic replacement; a rejected successor keeps the complete prior file.
    local old=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"free.json")
    CyrusExportCameraAnimation freeCam (MCPFixtureDir+"free.json") 10 70 samplesPerFrame:4
    if (dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"free.json")!=old do throw "Repeat export differs."
    local rejected=false
    freeCam.orthoProjection=true
    try(CyrusExportCameraAnimation freeCam (MCPFixtureDir+"free.json") 10 70)catch(rejected=true)
    freeCam.orthoProjection=false
    if not rejected or (dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"free.json")!=old do throw "Failed export replaced a complete file."
    format "PASS atomic overwrite and orthographic failure retention\n" to:log
    for property in #(#horizontal_shift,#vertical_shift,#horizontal_tilt_correction,#vertical_tilt_correction) do (
        setProperty physicalCam property 0.2;rejected=false
        try(CyrusExportCameraAnimation physicalCam (MCPFixtureDir+"rejected.json") 10 70)catch(rejected=true)
        setProperty physicalCam property 0
        if not rejected do throw "Shift/tilt should reject."
    )
    format "PASS unsupported shift and tilt rejected\n" to:log
    rejected=false
    try(CyrusExportCameraAnimation freeCam (MCPFixtureDir+"rejected.json") 0 10000)catch(rejected=true)
    if not rejected do throw "Unbounded sample count should reject."
    format "PASS sample bound rejected\n" to:log
    rejected=false
    try(CyrusExportCameraAnimation rig (MCPFixtureDir+"rejected.json") 10 70)catch(rejected=true)
    if not rejected do throw "Non-camera should reject."
    rig.scale=[2,1,1];rejected=false
    try(CyrusExportCameraAnimation freeCam (MCPFixtureDir+"rejected.json") 10 70)catch(rejected=true)
    rig.scale=[1,1,1]
    if not rejected do throw "Nonuniform rig should reject."
    format "PASS invalid camera and nonuniform rig rejected\n" to:log
    local thread=(dotNetClass "System.Threading.Thread").CurrentThread, culture=thread.CurrentCulture
    thread.CurrentCulture=dotNetObject "System.Globalization.CultureInfo" "de-DE"
    try(CyrusExportCameraAnimation freeCam (MCPFixtureDir+"locale.json") 10 70 samplesPerFrame:4)catch(thread.CurrentCulture=culture;throw())
    thread.CurrentCulture=culture
    if (dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"locale.json")!=old do throw "Locale changed the numeric JSON."
    format "PASS decimal-comma locale produces identical JSON\n" to:log
    -- Unit conversion is independent of the display-unit preference.
    units.SystemType=#meters;units.SystemScale=1
    CyrusExportCameraAnimation freeCam (MCPFixtureDir+"metres.json") 10 70 samplesPerFrame:1
    format "PASS metre system units export\n" to:log
    units.SystemType=#centimeters;units.SystemScale=1
    close log
    saveMaxFile (MCPFixtureDir+"owned-camera-fixture.max") quiet:true
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"qualification-complete.txt") "PASS"
)
