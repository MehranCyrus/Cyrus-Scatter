cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLCrashLab
(
 units.SystemType=#millimeters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane width:5000 length:5000 widthsegs:4 lengthsegs:4
 local source=sphere radius:32.788 segments:32 pos:[8000,8000,1000]
 hide source
 CPLCrashLab=CyrusPhysicsLab name:"Owned_fatal_capture"
 CPLCrashLab.brushRadius=.01;CPLCrashLab.birthSpacing=.2;CPLCrashLab.emissionHeight=.1
 select ground;max zoomext sel all
 select CPLCrashLab;max modify mode;modPanel.setCurrentObject CPLCrashLab.baseObject
 CPLCrashLab.brushHeader.open=true;CPLCrashLab.objectsUI.open=true
 for i=1 to 25 do (windows.processPostedMessages();sleep .01)
 CPLCrashLab.objectsUI.receiverPick.picked ground;CPLCrashLab.objectsUI.sourcePick.picked source
 CPLCrashLab.brushHeader.startButton.pressed()
 cplPrivatePaintContinue CPLCrashLab.physicsDocument #([0,-500,0])
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-crash-info.json") (cplDiagnosticInfo())
)
