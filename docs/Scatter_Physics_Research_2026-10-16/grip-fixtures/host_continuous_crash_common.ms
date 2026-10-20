cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLCrashLab
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane name:"Crash_ground" width:5 length:5
 local source=box name:"Crash_source" width:.1 length:.05 height:.004 pos:[8,8,0]
 CPLCrashLab=CyrusPhysicsLab name:"Continuous_crash_recovery"
 CPLCrashLab.setReceiver ground;CPLCrashLab.addSource source;CPLCrashLab.brushRadius=.001;CPLCrashLab.stickiness=80
 saveMaxFile (CPLTestDir+"bindings.max") quiet:true
 CPLCrashLab.startBrush()
 for i=1 to 3 do (cplSample CPLCrashLab.physicsDocument [(i*.3),0,0] [0,0,1] true;cplRelease CPLCrashLab.physicsDocument;cplSynchronize CPLCrashLab.physicsDocument)
 cplPause CPLCrashLab.physicsDocument
 sleep .2
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-crash-info.json") (cplDiagnosticInfo())
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-crash-state.json") (cplStats CPLCrashLab.physicsDocument)
)
