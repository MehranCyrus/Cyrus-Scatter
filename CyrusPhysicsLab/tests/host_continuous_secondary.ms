(
 local root=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/",combined=""
 for fixture in #("host_ui_layout","host_continuous_lifecycle","host_transforms","host_continuous_rebuild","host_previous_scene","host_proxy_previous_scene") do
 (
  cplStage fixture
  fileIn (root+fixture+".ms")
  local value=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
  (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+fixture+"-assertions.txt") value
  combined+=value+"\n"
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") combined
)
