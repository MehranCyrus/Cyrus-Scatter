cplResetScene()
(
 units.SystemType=#centimeters;units.SystemScale=1
 local receiver=plane width:225 length:142
 local model=sphere name:"Model_with_a_long_name_for_layout" radius:1.5983 segments:32 pos:[300,0,0]
 local proxy=sphere name:"Proxy_with_a_long_name_for_layout" radius:1.5983 segments:8 pos:[300,0,0]
 local lab=CyrusPhysicsLab name:"Layout_016"
 lab.setReceiver receiver;lab.addSource model proxy:proxy
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 global CPLUILab=lab.baseObject
 windows.processPostedMessages();lab.refreshBindings()
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 local info=cplDiagnosticInfo()
 if findString info "\"recording\":true"==undefined or findString info "\"watcher_alive\":true"==undefined do throw ("Crash diagnostics are not recording: "+info)
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"diagnostic-status.json") info
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS bound model/proxy labels, native control rectangles, font metrics, overlap checks and crash watcher; no screen pixels or OS input"
)
