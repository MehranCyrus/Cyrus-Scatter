fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/host_workflow.ms"
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/host_stack.ms"
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/host_recovery.ms"
cplResetScene()
global CPLUILab
(
 local lab=CyrusPhysicsLab name:"Popup_020",ground=plane width:8 length:8,source=teapot radius:.2 pos:[10,0,0]
 lab.setReceiver ground;lab.addSource source;bShow lab
 CPLUILab=lab.baseObject
 for factor in #(1.0,1.5) do
 (
  cplStage ("UI scale "+(factor as string))
  CustomControlsOptions.UIUserScaleFactor=factor
  lab.refreshBindings()
  python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
  python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/popup_layout.py"
  copyFile (CPLTestDir+"ui-layout.json") (CPLTestDir+"ui-layout-"+(factor as string)+".json")
  copyFile (CPLTestDir+"popup-layout.json") (CPLTestDir+"popup-layout-"+(factor as string)+".json")
 )
)

CustomControlsOptions.UIUserScaleFactor=1.0
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/host_mountain_only.ms"
