-- Owned disposable scene only. No physical/UI automation.
cplResetScene()
cplStage "scene reset"
global CPLChecks=0
fn require condition message =
(
    CPLChecks+=1
    if not condition do throw message
)
fn finishSolve document =
(
    cplRelease document
    local done=false
    for i=1 to 1000 while not done do done=cplTick document 8
    require done "Solve did not finish"
    local stats=cplStats document
    require (findString stats "\"error\":\"\""!=undefined) stats
)
(
units.SystemType=#meters
units.SystemScale=1.0
local ground=box width:20 length:20 height:0.1 pos:[0,0,-0.1]
local source=box width:0.1 length:0.05 height:0.004 pos:[5,5,0] mapcoords:true
convertToMesh source
setFaceSmoothGroup source 1 4
local lab=CyrusPhysicsLab name:"PhysicsLab_OwnedTest"
lab.showViewportIcon=false;lab.applyViewportIcon() -- This witness checks the physical mesh without picking edges.
cplStage "node created"
lab.setReceiver ground
lab.addSource source
lab.brushRadius=0.01
lab.scaleMinimum=1
lab.scaleMaximum=1
lab.configure()
cplStage "bound and configured"
require (isValidNode lab) "Independent class creation failed"
require (cplExport lab.physicsDocument!=undefined) "Native storage unavailable"
lab.startBrush()
cplStage "painter started"
cplSample lab.physicsDocument [0,0,0] [0,0,1] true
cplSample lab.physicsDocument [0.4,0,0] [0,0,1] true
finishSolve lab.physicsDocument
cplStage "stroke settled"
local recipe=cplExport lab.physicsDocument
local stats=cplStats lab.physicsDocument
require (findString stats "\"rows\":6"!=undefined) ("Unexpected emission count: "+stats)
lab.stopBrush()
local realized=snapshotAsMesh lab
require (realized.numfaces==72) "Realized mesh does not match 6 source bodies"
require ((meshop.getNumMapVerts realized 1)==6*(meshop.getNumMapVerts (snapshotAsMesh source) 1)) "Source UVs were not retained"
require ((getFaceSmoothGroup realized 1)==4) "Source smoothing group was not retained"
saveMaxFile (CPLTestDir+"roundtrip.max") quiet:true
cplStage "scene saved"
local rowsBefore=cplExport lab.physicsDocument
lab.startBrush()
cplSample lab.physicsDocument [1,0,0] [0,0,1] true
cplCancel lab.physicsDocument
lab.stopBrush()
require (cplExport lab.physicsDocument==rowsBefore) "Cancel changed committed result"
cplClear lab.physicsDocument
require (findString (cplStats lab.physicsDocument) "\"rows\":0"!=undefined) "Clear failed"
max undo
require (cplExport lab.physicsDocument==rowsBefore) "Undo did not recover exact result"
max redo
require (findString (cplStats lab.physicsDocument) "\"rows\":0"!=undefined) "Redo failed"
cplImport lab.physicsDocument recipe
require (cplExport lab.physicsDocument==recipe) "Recipe roundtrip changed complete state"
local objectCountBefore=objects.count
local cloned=copy lab
require (objects.count==objectCountBefore+1) "Clone duplicated bound scene nodes"
cplStage "clone created"
require (cplExport cloned.physicsDocument==recipe) "Clone changed saved transforms"
cplClear cloned.physicsDocument
require (cplExport lab.physicsDocument==recipe) "Clone borrowed original document"
loadMaxFile (CPLTestDir+"roundtrip.max") quiet:true
cplStage "scene reloaded"
lab=getNodeByName "PhysicsLab_OwnedTest"
require (cplExport lab.physicsDocument==recipe) "Scene roundtrip changed complete state"
require ((snapshotAsMesh lab).numfaces==72) "Reopened geometry missing"
local report=createFile (CPLTestDir+"assertions.txt")
format "PASS % scripted assertions; no physical input\\n" CPLChecks to:report
format "%\\n" (cplStats lab.physicsDocument) to:report
close report
)
