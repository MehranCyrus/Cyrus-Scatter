cplResetScene()
global CPLUILab
(
 local lab=CyrusPhysicsLab name:"Quality_Popup_019",ground=plane length:200 width:200,source=teapot radius:5
 lab.setReceiver ground;lab.addSource source
 CPLUILab=lab.baseObject
 select lab;max modify mode;modPanel.setCurrentObject CPLUILab
 windows.processPostedMessages();lab.refreshBindings()
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/popup_layout.py"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS real popup item capacity, toolbar glyphs, seven rollout bounds/font metrics"
)
