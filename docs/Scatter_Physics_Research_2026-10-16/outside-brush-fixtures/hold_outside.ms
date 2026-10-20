-- Test-only follow-up: solver progress/limit while brush is held off receiver,
-- and actual Undo for an entirely off-surface gesture.
global CPLOutsideOriginal=(dotNetClass "System.IO.File").ReadAllText @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-012-outside-01/fixture.ms"
global CPLOutsideCut=findString CPLOutsideOriginal "(\n    CPLOutsideLog=createFile"
if CPLOutsideCut==undefined do throw "Could not isolate test helper definitions"
execute (substring CPLOutsideOriginal 1 (CPLOutsideCut-1))
(
    CPLOutsideLog=createFile (CPLTestDir+"paths.tsv")
    format "name\tworld_path_mm\tfinish\tcancel\tsdk_hits\texception\n" to:CPLOutsideLog
    local lab=outsideFixture "hold-outside" .01
    local baseline=cplRows lab.physicsDocument
    local result=outsideSample lab "hold-outside-inside" #([-600,0,0],[-200,0,0])
    outsideRequire (result[1]==2 and result[2]=="") "Hold initial segment failed"
    local previewCount=(cplUIState lab.physicsDocument)[6]
    result=outsideSample lab "hold-outside-miss" #([3000,0,0],[3000,1000,0])
    outsideRequire (result[1]==0 and result[2]=="") "Hold outside missed incorrectly"
    for i=1 to 30 do cplTick lab.physicsDocument 8
    outsideCapture lab "hold-outside-240steps"
    outsideRequire ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==previewCount) "Short outside hold lost its pending stroke"
    outsideRequire (cplRows lab.physicsDocument==baseline) "Short outside hold published without release"
    result=outsideSample lab "hold-outside-reenter" #([1100,1000,0],[1500,1000,0]) finish:true
    outsideRequire (result[1]==2 and result[2]=="") "Timed outside hold prevented reentry"
    outsideFinish lab
    outsideCapture lab "hold-outside-after"
    outsideRequire ((cplUIState lab.physicsDocument)[5]>2 and not (cplUIState lab.physicsDocument)[4]) "Timed hold failed to settle after release"
    lab.brushHeader.stopButton.pressed()

    cplStage "held off-surface past existing step budget"
    lab=outsideFixture "hold-limit" .01
    baseline=cplRows lab.physicsDocument
    result=outsideSample lab "hold-limit-inside" #([-600,0,0],[-200,0,0])
    outsideRequire (result[1]==2 and result[2]=="") "Long hold initial segment failed"
    result=outsideSample lab "hold-limit-miss" #([3000,0,0])
    outsideRequire (result[1]==0 and result[2]=="") "Long hold outside missed incorrectly"
    -- Accelerated fixed solver steps, not a claim about wall-clock dragging.
    for i=1 to 500 while (cplUIState lab.physicsDocument)[2] do cplTick lab.physicsDocument 8
    outsideCapture lab "hold-limit-after"
    outsideRequire (cplRows lab.physicsDocument==baseline) "Held-stroke budget changed saved poses"
    outsideRequire (not (cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==0) "Held-stroke budget failed to bound pending work"
    outsideRequire (findString (cplStats lab.physicsDocument) "Settle timeout"!=undefined) "Held-stroke budget missing reason"
    result=outsideSample lab "hold-limit-recovery" #([1000,0,0],[1400,0,0]) finish:true
    outsideRequire (result[1]==2 and result[2]=="") "Could not recover from held-stroke limit"
    outsideFinish lab
    outsideCapture lab "hold-limit-recovered"
    lab.brushHeader.stopButton.pressed()

    cplStage "empty off-surface gesture Undo"
    lab=outsideFixture "empty-undo" .01
    baseline=cplRows lab.physicsDocument
    result=outsideSample lab "empty-undo-miss" #([3000,0,0],[3000,1000,0]) finish:true
    outsideRequire (result[1]==0 and result[2]=="") "Empty gesture failed"
    outsideFinish lab
    outsideCapture lab "empty-undo-after"
    max undo
    outsideCapture lab "empty-undo-undo1"
    outsideRequire (cplRows lab.physicsDocument==baseline) "First empty-gesture Undo changed baseline"
    max undo
    outsideCapture lab "empty-undo-undo2"
    outsideRequire ((cplUIState lab.physicsDocument)[5]==0) "Second Undo did not remove baseline brush gesture"
    lab.brushHeader.stopButton.pressed()
    close CPLOutsideLog
    outsideWrite "assertions.txt" ("PASS "+(CPLOutsideChecks as string)+" off-surface hold/budget/empty-Undo assertions; product unchanged.\n")
)
