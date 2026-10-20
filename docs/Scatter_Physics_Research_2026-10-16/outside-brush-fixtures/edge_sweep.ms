-- Additional test-only boundary sweep; reuse unchanged helpers from first receipt.
global CPLOutsideOriginal=(dotNetClass "System.IO.File").ReadAllText @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-012-outside-01/fixture.ms"
global CPLOutsideCut=findString CPLOutsideOriginal "(\n    CPLOutsideLog=createFile"
if CPLOutsideCut==undefined do throw "Could not isolate test helper definitions"
execute (substring CPLOutsideOriginal 1 (CPLOutsideCut-1))
(
    CPLOutsideLog=createFile (CPLTestDir+"paths.tsv")
    format "name\tworld_path_mm\tfinish\tcancel\tsdk_hits\texception\n" to:CPLOutsideLog
    local lab=outsideFixture "edge-sweep" .25
    local baseline=cplRows lab.physicsDocument
    local first=outsideSample lab "edge-sweep-safe" #([-800,1000,0],[-400,1000,0])
    outsideRequire (first[1]==2 and first[2]=="") "Safe preview before edge sweep failed"
    outsideRequire ((cplUIState lab.physicsDocument)[6]>=2) "Missing safe pending bodies"
    -- Centre x=2450mm remains 50mm inside; radius is 250mm.
    local edge=outsideSample lab "edge-sweep-path" #([2450,1000,0],[2450,1800,0],[2450,-1800,0]) finish:true
    outsideCapture lab "edge-sweep-after"
    outsideRequire (cplRows lab.physicsDocument==baseline) "Edge failure changed previously saved bodies"
    outsideRequire (edge[2]!="") "Extended edge sweep did not exercise a rejected footprint"
    outsideRequire (findString (cplStats lab.physicsDocument) "Brush footprint leaves the receiver"!=undefined) "Missing native edge reason"
    outsideRequire ((cplUIState lab.physicsDocument)[6]==0 and not (cplUIState lab.physicsDocument)[2]) "Edge failure retained pending stroke"
    outsideRequire ((cplUIState lab.physicsDocument)[1]) "Edge failure ended Painter unexpectedly"
    local recovered=outsideSample lab "edge-sweep-recovery" #([-1000,0,0],[-600,0,0]) finish:true
    outsideRequire (recovered[1]==2 and recovered[2]=="") "New stroke failed after boundary rejection"
    outsideFinish lab
    outsideCapture lab "edge-sweep-recovered"
    outsideRequire ((cplUIState lab.physicsDocument)[5]>2 and not (cplUIState lab.physicsDocument)[4]) "Recovery did not settle"
    lab.brushHeader.stopButton.pressed()
    close CPLOutsideLog
    outsideWrite "assertions.txt" ("PASS "+(CPLOutsideChecks as string)+" extended edge/recovery assertions; existing ordinary 0.1.2 unchanged.\n")
)
