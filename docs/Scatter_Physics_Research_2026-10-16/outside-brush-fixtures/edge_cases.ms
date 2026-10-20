-- Test-only: existing delivered 0.1.2, actual Painter TestHit/canvas callbacks.
-- No OS input, no changes to product code or artist scenes.
cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-011/" "CyrusPhysicsProbe.dlx"
global CPLOutsideChecks=0
global CPLOutsideLog=undefined
fn outsideRequire value message = (CPLOutsideChecks+=1;if not value do throw message)
fn outsidePump ms = (local deadline=timeStamp()+ms;while timeStamp()<deadline do (windows.processPostedMessages();sleep .01))
fn outsideWrite name value = ((dotNetClass "System.IO.File").WriteAllText (CPLTestDir+name) value)
fn outsideCapture lab name =
(
    outsideWrite (name+"-stats.json") (cplStats lab.physicsDocument)
    cplExportFile lab.physicsDocument (CPLTestDir+name+"-state.json")
    lab.syncUI()
    outsideWrite (name+"-ui.txt") lab.brushHeader.statusLabel.text
)
fn outsideFinish lab =
(
    local done=false
    for i=1 to 1000 while not done do
    (
        done=cplTick lab.physicsDocument 8
        if (cplUIState lab.physicsDocument)[4] do done=true
        windows.processPostedMessages()
    )
    outsideRequire done ("Unbounded pending stroke: "+cplStats lab.physicsDocument)
    lab.syncUI()
)
fn outsideSample lab name path finish:false cancel:false =
(
    local hits=-1
    local exception=""
    try (hits=if finish then cplPrivatePaintPath lab.physicsDocument path cancel else cplPrivatePaintContinue lab.physicsDocument path)
    catch(exception=getCurrentException())
    format "%\t%\t%\t%\t%\t%\n" name path finish cancel hits (substituteString exception "\n" " ") to:CPLOutsideLog
    outsideCapture lab name
    #(hits,exception)
)
fn outsideFixture name radius =
(
    cplResetScene()
    units.SystemType=#millimeters;units.SystemScale=1
    viewport.setLayout #layout_1;viewport.setType #view_top
    local ground=plane name:(name+"_receiver") width:5000 length:5000 widthsegs:4 lengthsegs:4
    local source=sphere name:(name+"_Sphere32") radius:32.788 segments:32 pos:[8000,8000,1000]
    hide source
    -- Frame the entire test path so off-surface samples remain inside the viewport.
    local frame=plane name:"Disposable_view_framing" width:12000 length:9000 widthsegs:1 lengthsegs:1
    select frame;max zoomext sel all;hide frame
    local lab=CyrusPhysicsLab name:name
    lab.brushRadius=radius;lab.birthSpacing=.2;lab.emissionHeight=.1
    lab.scaleMinimum=1;lab.scaleMaximum=1;lab.randomSeed=42
    select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
    lab.brushHeader.open=true;lab.objectsUI.open=true;lab.brushUI.open=true
    outsidePump 250
    lab.objectsUI.receiverPick.picked ground;lab.objectsUI.sourcePick.picked source
    outsidePump 100
    outsideRequire lab.brushHeader.startButton.enabled "Fixture Start disabled"
    lab.brushHeader.startButton.pressed()
    outsideRequire ((cplUIState lab.physicsDocument)[1]) ("Fixture Start failed: "+lab.uiError)
    local baseline=outsideSample lab (name+"-baseline-path") #([-1500,-1500,0],[-1100,-1500,0]) finish:true
    outsideRequire (baseline[1]==2 and baseline[2]=="") "Baseline Painter hits failed"
    outsideFinish lab
    outsideRequire ((cplUIState lab.physicsDocument)[5]>=2 and not (cplUIState lab.physicsDocument)[4]) ("Baseline failed to settle: "+cplStats lab.physicsDocument)
    outsideCapture lab (name+"-before")
    lab
)
(
    CPLOutsideLog=createFile (CPLTestDir+"paths.tsv")
    format "name\tworld_path_mm\tfinish\tcancel\tsdk_hits\texception\n" to:CPLOutsideLog
    local lab=undefined
    local baseline=undefined
    local stepResult=undefined
    local beforePreview=0

    cplStage "all outside"
    lab=outsideFixture "all-outside" .01
    baseline=cplRows lab.physicsDocument
    stepResult=outsideSample lab "all-outside-path" #([3000,0,0],[3500,500,0],[3000,1000,0]) finish:true
    outsideRequire (stepResult[1]==0 and stepResult[2]=="") "Outside-only path hit receiver or threw"
    outsideFinish lab
    outsideCapture lab "all-outside-after"
    outsideRequire (cplRows lab.physicsDocument==baseline) "Outside-only gesture changed saved poses"
    lab.brushHeader.stopButton.pressed()

    cplStage "leave and reenter"
    lab=outsideFixture "leave-reenter" .01
    baseline=cplRows lab.physicsDocument
    stepResult=outsideSample lab "leave-reenter-inside1" #([-1500,0,0],[-1100,0,0])
    outsideRequire (stepResult[1]==2 and stepResult[2]=="") "Initial segment failed"
    beforePreview=(cplUIState lab.physicsDocument)[6]
    stepResult=outsideSample lab "leave-reenter-gap" #([3000,0,0],[3000,1000,0])
    outsideRequire (stepResult[1]==0 and stepResult[2]=="") "Gap path hit receiver or threw"
    outsideRequire ((cplUIState lab.physicsDocument)[6]==beforePreview) "Miss samples changed pending body count"
    stepResult=outsideSample lab "leave-reenter-inside2" #([1100,1000,0],[1500,1000,0]) finish:true
    outsideRequire (stepResult[1]==2 and stepResult[2]=="") "Reentry segment failed"
    outsideFinish lab
    outsideCapture lab "leave-reenter-after"
    outsideRequire (findString (cplRows lab.physicsDocument) (substring baseline 1 (baseline.count-1))==1) "Reentry changed saved poses"
    max undo
    outsideCapture lab "leave-reenter-undo"
    outsideRequire (cplRows lab.physicsDocument==baseline) "Reentry Undo did not restore baseline"
    lab.brushHeader.stopButton.pressed()

    cplStage "release outside"
    lab=outsideFixture "release-outside" .01
    stepResult=outsideSample lab "release-outside-inside" #([-600,0,0],[-200,0,0])
    outsideRequire (stepResult[1]==2 and stepResult[2]=="") "Release-outside initial segment failed"
    beforePreview=(cplUIState lab.physicsDocument)[6]
    stepResult=outsideSample lab "release-outside-path" #([3000,0,0],[3500,1000,0]) finish:true
    outsideRequire (stepResult[1]==0 and stepResult[2]=="") "Release-outside missed incorrectly"
    outsideFinish lab
    outsideCapture lab "release-outside-after"
    outsideRequire ((cplUIState lab.physicsDocument)[5]>=2+beforePreview) "Release outside lost valid emissions"
    lab.brushHeader.stopButton.pressed()

    cplStage "start outside then enter"
    lab=outsideFixture "start-outside" .01
    stepResult=outsideSample lab "start-outside-miss" #([3000,0,0],[3000,1000,0])
    outsideRequire (stepResult[1]==0 and stepResult[2]=="") "Starting outside failed"
    outsideRequire ((cplUIState lab.physicsDocument)[6]==0) "Starting outside emitted bodies"
    stepResult=outsideSample lab "start-outside-enter" #([0,0,0],[400,0,0]) finish:true
    outsideRequire (stepResult[1]==2 and stepResult[2]=="") "Starting outside prevented entry"
    outsideFinish lab
    outsideCapture lab "start-outside-after"
    lab.brushHeader.stopButton.pressed()

    cplStage "outside centre overlapping radius"
    lab=outsideFixture "outside-overlap" .25
    baseline=cplRows lab.physicsDocument
    stepResult=outsideSample lab "outside-overlap-path" #([2600,0,0],[2600,500,0]) finish:true
    outsideRequire (stepResult[1]==0 and stepResult[2]=="") "Outside centre/overlapping radius failed"
    outsideFinish lab
    outsideCapture lab "outside-overlap-after"
    outsideRequire (cplRows lab.physicsDocument==baseline) "Outside centre emitted through radius overlap"
    lab.brushHeader.stopButton.pressed()

    cplStage "inside centre overlapping edge"
    lab=outsideFixture "edge-footprint" .25
    baseline=cplRows lab.physicsDocument
    stepResult=outsideSample lab "edge-footprint-safe" #([-800,1000,0],[-400,1000,0])
    outsideRequire (stepResult[1]==2 and stepResult[2]=="") "Safe segment before edge failed"
    outsideRequire ((cplUIState lab.physicsDocument)[6]>=2) "Missing preview before edge"
    stepResult=outsideSample lab "edge-footprint-edge" #([2450,1000,0]) finish:true
    outsideFinish lab
    outsideCapture lab "edge-footprint-after"
    -- Record observed edge behavior without defining the current abort as desirable.
    outsideRequire (findString (cplRows lab.physicsDocument) (substring baseline 1 (baseline.count-1))==1) "Edge action changed prior saved poses"
    -- Recovery: same active Painter; a new actual stroke should succeed after an abort.
    stepResult=outsideSample lab "edge-footprint-recovery" #([-1000,0,0],[-600,0,0]) finish:true
    outsideRequire (stepResult[1]==2 and stepResult[2]=="") "Could not recover after edge action"
    outsideFinish lab
    outsideCapture lab "edge-footprint-recovered"
    lab.brushHeader.stopButton.pressed()

    cplStage "cancel outside"
    lab=outsideFixture "cancel-outside" .01
    baseline=cplRows lab.physicsDocument
    stepResult=outsideSample lab "cancel-outside-inside" #([-600,0,0],[-200,0,0])
    outsideRequire (stepResult[1]==2 and stepResult[2]=="") "Cancel-outside initial segment failed"
    stepResult=outsideSample lab "cancel-outside-cancel" #([3000,0,0]) finish:true cancel:true
    outsideRequire (stepResult[1]==0 and stepResult[2]=="") "Cancel outside failed"
    outsideCapture lab "cancel-outside-after"
    outsideRequire (cplRows lab.physicsDocument==baseline and (cplUIState lab.physicsDocument)[6]==0) "Cancel outside changed saved poses or retained preview"
    lab.brushHeader.stopButton.pressed()
    close CPLOutsideLog
    outsideWrite "assertions.txt" ("PASS "+(CPLOutsideChecks as string)+" scripted assertions; seven scenarios; actual Painter TestHit and canvas callbacks; no physical mouse input.\n")
)
