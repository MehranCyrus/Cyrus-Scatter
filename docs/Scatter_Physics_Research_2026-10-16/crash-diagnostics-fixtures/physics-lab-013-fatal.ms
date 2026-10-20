fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-013-crash-common.ms"
(
 local lab=CPLCrashLab
 cplLogEvent lab.physicsDocument "qa.before_forced_access_violation" "Owned test only; next private probe instruction writes null."
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-crash-info.json") (cplDiagnosticInfo())
 cplPrivateCrash 1
)
