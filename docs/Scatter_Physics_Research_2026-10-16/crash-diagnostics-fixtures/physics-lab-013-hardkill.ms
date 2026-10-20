fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-013-crash-common.ms"
(
 local lab=CPLCrashLab
 cplLogEvent lab.physicsDocument "qa.before_terminate_process" "Owned test only; abrupt exit code 77, no clean shutdown."
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-crash-info.json") (cplDiagnosticInfo())
 cplPrivateCrash 2
)
