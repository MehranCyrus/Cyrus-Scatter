(
 local paths=#(@"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/host_continuous.ms",@"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/grip-fixtures/host_grip.ms")
 local combined=""
 for path in paths do
 (
  fileIn path
  combined+=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
  combined+="\n"
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") combined
)
