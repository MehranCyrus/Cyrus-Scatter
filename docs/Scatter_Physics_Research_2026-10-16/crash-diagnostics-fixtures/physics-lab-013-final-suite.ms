(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/host_regression.ms"
 local standard=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"standard-assertions.txt") standard
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-013-lifecycle.ms"
 local lifecycle=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"lifecycle-assertions.txt") lifecycle
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") (standard+"\n"+lifecycle)
)
