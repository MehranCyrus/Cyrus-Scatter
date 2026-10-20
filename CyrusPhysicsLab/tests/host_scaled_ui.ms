(
 local root=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/"
 fileIn (root+"host_ui_layout.ms")
 local layout=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
 fileIn (root+"host_proxy_ui.ms")
 local proxy=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
 fileIn (root+"host_timeout_ui.ms")
 local timeout=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
 fileIn (root+"host_brush_ui.ms")
 local brush=(dotNetClass "System.IO.File").ReadAllText (CPLTestDir+"assertions.txt")
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") (layout+proxy+timeout+brush)
)
