(
 local root=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/grip-fixtures/",combined=""
 for name in #("host_continuous_recover","host_old_pending") do
 (
  cplStage name
  fileIn (root+name+".ms")
  combined+=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
  combined+="\n"
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") combined
)
