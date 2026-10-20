cplResetScene()
global CPLChecks=0
fn require condition message = (CPLChecks+=1;if not condition do throw message)
fn finishSolve document =
(
    local done=false
    for i=1 to 5000 while not done do done=cplTick document 8
    require done "Solve did not finish"
    local stats=cplStats document
    require (findString stats "\"error\":\"\""!=undefined) stats
)
(
units.SystemType=#meters
units.SystemScale=1
local ground=box width:20 length:20 height:0.1 pos:[0,0,-0.1]
local leaf=box width:0.1 length:0.05 height:0.004 pos:[10,10,0]
local lab=CyrusPhysicsLab name:"PhysicsLab_Extended"
lab.setReceiver ground
lab.addSource leaf
lab.brushRadius=0.01
lab.scaleMinimum=1
lab.scaleMaximum=1
lab.bodyLimit=1000
lab.configure()
cplStage "area"
local polygon=#([-1,-1,0],[1,-1,0],[1,1,0],[-1,1,0])
cplArea lab.physicsDocument lab polygon 100
finishSolve lab.physicsDocument
local initial=cplRows lab.physicsDocument
require (findString (cplStats lab.physicsDocument) "\"rows\":100"!=undefined) "Area result count"
cplStage "idle"
local beforeStats=cplStats lab.physicsDocument
for i=1 to 50 do (cplTick lab.physicsDocument 2;redrawViews())
require (cplStats lab.physicsDocument==beforeStats) "Idle rebuilt or recooked Physics"
require (cplRows lab.physicsDocument==initial) "Idle changed saved transforms"
cplStage "append"
lab.startBrush()
cplSample lab.physicsDocument [3,0,0] [0,0,1] true
cplRelease lab.physicsDocument
finishSolve lab.physicsDocument
lab.stopBrush()
local appended=cplRows lab.physicsDocument
require (findString appended (substring initial 1 (initial.count-1))==1) "Append moved completed bodies"
require (findString (cplStats lab.physicsDocument) "\"rows\":101"!=undefined) "Append count"
cplStage "rebuild"
cplRebuild lab.physicsDocument lab
finishSolve lab.physicsDocument
require (findString (cplStats lab.physicsDocument) "\"rows\":101"!=undefined) "Rebuild correspondence"
local rebuildRows=cplRows lab.physicsDocument
cplErase lab.physicsDocument [3,0,0] 0.2
require (findString (cplStats lab.physicsDocument) "\"rows\":100"!=undefined) "Erase body count"
max undo
require (cplRows lab.physicsDocument==rebuildRows) "Erase Undo did not restore full transforms"
cplStage "admission"
lab.bodyLimit=101
lab.configure()
lab.startBrush()
local failed=false
try(cplSample lab.physicsDocument [4,0,0] [0,0,1] true)catch(failed=true)
require failed "Body admission should reject"
lab.stopBrush()
require (cplRows lab.physicsDocument==rebuildRows) "Failed stroke lost committed result"
lab.bodyLimit=1000
lab.configure()
cplStage "underfill"
failed=false
try(cplArea lab.physicsDocument lab #([100,100,0],[101,100,0],[101,101,0],[100,101,0]) 20)catch(failed=true)
require failed "Underfill should reject"
require (cplRows lab.physicsDocument==rebuildRows) "Underfill replaced committed result"
cplStage "source change"
leaf.width=0.2
failed=false
try(lab.startBrush())catch(failed=true)
require failed "Source change should require a deliberate new result"
require (cplRows lab.physicsDocument==rebuildRows) "Source change damaged saved result"
leaf.width=0.1
cplStage "delete owner"
lab.startBrush()
cplSample lab.physicsDocument [4,0,0] [0,0,1] true
local document=lab.physicsDocument
delete lab
require (findString (cplStats document) "\"active\":false"!=undefined) "Deleted owner left a solve alive"
local report=createFile (CPLTestDir+"assertions.txt")
format "PASS % extended scripted assertions; physical input not tested\n" CPLChecks to:report
close report
)
