-- Exact ordinary 0.1.2; test driver permits a late callback after FALSE.
cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
(
 units.SystemType=#millimeters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane width:5000 length:5000 widthsegs:4 lengthsegs:4
 local source=sphere radius:32.788 segments:32 pos:[8000,8000,1000]
 hide source
 local lab=CyrusPhysicsLab name:"Old_callback_crash"
 lab.brushRadius=.01;lab.birthSpacing=.2;lab.emissionHeight=.1
 select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true
 for i=1 to 30 do (windows.processPostedMessages();sleep .01)
 lab.objectsUI.receiverPick.picked ground;lab.objectsUI.sourcePick.picked source
 lab.brushHeader.startButton.pressed()
 lab.brushHeader.stopButton.pressed()
 lab.brushHeader.startButton.pressed()
 cplPrivatePaintPath lab.physicsDocument #([0,0,0],[400,0,0]) false
 local first=cplPrivatePaintLate lab.physicsDocument #([800,0,0])
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-late.json") (cplStats lab.physicsDocument)
 cplStage ("First late return "+first as string)
 cplStage "About to deliver second late hit with cleared staged data"
 cplPrivatePaintLate lab.physicsDocument #([1000,0,0])
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"unexpected-return.txt") (cplStats lab.physicsDocument)
)
