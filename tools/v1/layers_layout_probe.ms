-- Private qualification only; no artist scene/session.
resetMaxFile #noPrompt
global CyrusLayoutProbeA,CyrusLayoutProbeB,CyrusLayoutProbeRoot
rollout CyrusLayoutProbeFieldsA "Source objects" width:146 (
    spinner countSpin "Count:" pos:[6,12] width:126 range:[0,100000,100] type:#integer
    checkbox onCheck "Keep on surface" pos:[6,44] width:126
)
rollout CyrusLayoutProbeFieldsB "Randomize XYZ" width:146 (
    spinner xSpin "X:" pos:[6,12] width:126 range:[-360,360,0]
    spinner ySpin "Y:" pos:[6,44] width:126 range:[-360,360,0]
    spinner zSpin "Z:" pos:[6,76] width:126 range:[-360,360,360]
)
rollout CyrusLayoutProbeA "Grass | 100 placed" width:162 height:350 (
    checkbox visibleCheck "Visible in viewport" pos:[6,8] width:146 checked:true
    subrollout sections "" pos:[0,36] width:160 height:306 scrollBar:#asNeeded
    on CyrusLayoutProbeA open do (
        addSubRollout sections CyrusLayoutProbeFieldsA rolledUp:true
        addSubRollout sections CyrusLayoutProbeFieldsB rolledUp:true
    )
)
rollout CyrusLayoutProbeB "Flowers | 50 placed" width:162 height:180 (
    spinner countSpin "Count:" pos:[6,12] width:146 range:[0,100000,50] type:#integer
)
plugin simpleObject CyrusLayerLayoutProbe name:"Cyrus Layer Layout Probe" classID:#(0x6aaa31f2,0x11bab803) category:"Cyrus Tests" (
    rollout main "Layers — fixed native viewport" width:#cmdPanel height:620 (
        button addButton "Add layer" pos:[8,8] width:146
        subrollout layers "" pos:[0,42] width:170 height:564 scrollBar:#asNeeded
        on main open do (
            layers.width=main.width
            addSubRollout layers CyrusLayoutProbeA rolledUp:false
            addSubRollout layers CyrusLayoutProbeB rolledUp:false
        )
    )
    on buildMesh do (setNumVerts mesh 0;setNumFaces mesh 0)
    tool create (on mousePoint click do #stop)
)
CyrusLayoutProbeRoot=CyrusLayerLayoutProbe()
select CyrusLayoutProbeRoot
max modify mode
modPanel.setCurrentObject CyrusLayoutProbeRoot
windows.processPostedMessages()
global CyrusLayoutProbeBefore=windows.getWindowPos CyrusLayoutProbeRoot.main.hwnd
for i=1 to 20 do (
    CyrusLayoutProbeFieldsA.open=not CyrusLayoutProbeFieldsA.open
    CyrusLayoutProbeFieldsB.open=not CyrusLayoutProbeFieldsB.open
    windows.processPostedMessages()
    local rect=windows.getWindowPos CyrusLayoutProbeRoot.main.hwnd
    if rect.w!=CyrusLayoutProbeBefore.w or rect.h!=CyrusLayoutProbeBefore.h do throw "Native fixed host resized while toggling sections"
)
CyrusLayoutProbeFieldsA.open=true
CyrusLayoutProbeFieldsB.open=true
global CyrusLayoutProbeResult=createFile (BLDir+"native-layout-probe.txt")
format "PASS fixed host after 40 section toggles\nroot:%\nlayer:%\nfields:%\n" CyrusLayoutProbeBefore (windows.getWindowPos CyrusLayoutProbeA.hwnd) (windows.getWindowPos CyrusLayoutProbeFieldsA.hwnd) to:CyrusLayoutProbeResult
close CyrusLayoutProbeResult
