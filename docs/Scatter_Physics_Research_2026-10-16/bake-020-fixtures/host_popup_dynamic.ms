cplDiagnosticInfo()
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
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
  local list=lab.objectsUI.sourceList,rect=list.GetItemRectangle 0,x=rect.X+5,y=(rect.Y+rect.Height/2) as integer
  bNeed (lab.objectsUI.checkboxAt x y==0) "Scaled checkbox glyph not hittable"
  lab.objectsUI.checkPointerDown (x+40) y;lab.objectsUI.checkPointerUp (x+40) y
  bNeed ((cplSourceOptions lab.physicsDocument 1)[1]) "Scaled text click toggled source"
  lab.objectsUI.checkPointerDown x y;lab.objectsUI.checkPointerUp x y
  bNeed (not (cplSourceOptions lab.physicsDocument 1)[1]) "Scaled checkbox failed to disable"
  lab.objectsUI.checkPointerDown x y;lab.objectsUI.checkPointerUp x y
  bNeed ((cplSourceOptions lab.physicsDocument 1)[1]) "Scaled checkbox failed to enable"
  python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
  python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/popup_layout.py"
  copyFile (CPLTestDir+"ui-layout.json") (CPLTestDir+"ui-layout-"+(factor as string)+".json")
  copyFile (CPLTestDir+"popup-layout.json") (CPLTestDir+"popup-layout-"+(factor as string)+".json")
 )
)

bWrite "scaled-checkbox-count.txt" (BChecks as string)
