-- Run only with the preserved 0.1.5 pair in an owned profile.
cplResetScene()
(
units.SystemType=#centimeters;units.SystemScale=1
local receiver=plane name:"Legacy_Plane" width:225.4415 length:142.2994 widthsegs:4 lengthsegs:4
local source=sphere name:"Legacy_Sphere" radius:1.5983 segments:32 pos:[300,0,0]
local lab=CyrusPhysicsLab name:"Legacy_BadProxy"
lab.setReceiver receiver;lab.addSource source proxy:receiver;lab.addCollider receiver
lab.brushRadius=.001;lab.startBrush()
cplSample lab.physicsDocument [0,0,0] [0,0,1] true
cplRelease lab.physicsDocument
cplFreeze lab.physicsDocument
for i=1 to 100 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;windows.processPostedMessages())
if (cplUIState lab.physicsDocument)[5]!=1 do throw "Legacy cached fixture did not publish one body"
saveMaxFile (CPLTestDir+"legacy-bad-proxy.max") quiet:true
cplExportFile lab.physicsDocument (CPLTestDir+"legacy-bad-proxy.json")
lab.startBrush();cplSample lab.physicsDocument [10,0,0] [0,0,1] true;cplRelease lab.physicsDocument
cplPause lab.physicsDocument
saveMaxFile (CPLTestDir+"legacy-bad-proxy-pending.max") quiet:true
(dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS old pair created cached and pending wrong-proxy scenes"
)
