-- Independent fixtures in one owned host; fail the complete run on any error.
(
 local root=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/"
 local fixtures=#("host_ui_layout","host_proxy_ui","host_brush_ui","host_timeout_ui","host","host_extended","host_transforms","host_previous_scene","host_proxy_previous_scene","demo")
 local combined=""
 for name in fixtures do
 (
  cplStage ("begin "+name)
  fileIn (root+name+".ms")
  local result=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
  (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+name+"-assertions.txt") result
  combined+=name+": "+result+"\n"
  cplStage ("passed "+name)
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") combined
)
