(
 local root=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/",combined=""
 for item in #(#("CyrusPhysicsLab/tests/host_continuous.ms","continuous"),#("docs/Scatter_Physics_Research_2026-10-16/settling-fixtures/host_collision.ms","collision"),#("docs/Scatter_Physics_Research_2026-10-16/grip-fixtures/host_grip.ms","terrain")) do
 (
  cplStage item[2]
  fileIn (root+item[1])
  local report=if item[2]=="collision" then "collision-assertions.txt" else "assertions.txt"
  local value=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+report)
  (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+item[2]+"-installed-assertions.txt") value
  combined+=value+"\n"
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") combined
)
