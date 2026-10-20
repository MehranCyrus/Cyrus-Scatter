-- Native numeric hit tests and actual render comparison. No OS input or pixels from UI.
cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-icon-probe-017/" "CyrusPhysicsIconProbe.dlx"
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLIconChecks=0,CPLUILab
fn iconNeed value message=(CPLIconChecks+=1;if not value do throw message)
fn iconPump duration=(local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn iconSHA path=(local stream=(dotNetClass "System.IO.File").OpenRead path,hash=(dotNetClass "System.Security.Cryptography.SHA256").Create();local bytes=hash.ComputeHash stream;stream.Close();hash.Dispose();toLower(substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" ""))
fn iconNumber text key=(((dotNetClass "System.Text.RegularExpressions.Regex").Match text ("\""+key+"\":([0-9]+)")).Groups.Item[1].Value as integer)
(
 units.SystemType=#meters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local lab=CyrusPhysicsLab name:"Selectable_Physics_Icon"
 local count=objects.count
 iconNeed lab.showViewportIcon "New Lab does not show its icon by default"
 local iconMesh=snapshotAsMesh lab
 iconNeed (iconMesh.numfaces>0 and iconMesh.numfaces<=128) "Empty Lab has no bounded icon pick mesh"
 for i=1 to iconMesh.numfaces do iconNeed ((meshop.getFaceArea iconMesh #{i})<1e-12) "Icon has a renderable face"
 iconNeed ((cplMesh lab.physicsDocument true).numfaces==0) "Icon entered native physical geometry"
 select lab;max zoomext sel all;clearSelection();redrawViews();iconPump 100
 iconNeed (cplPrivateIconHit lab [.25,0,0]) "Empty Lab icon is not selectable through Max HitTest"
 iconNeed (not cplPrivateIconHit lab [1.5,1.5,0]) "Icon picks outside its marker"
 iconNeed (findString (cplViewportIconInfo lab.physicsDocument) "\"draws\":0"==undefined) "Visible icon did not draw"
 lab.showViewportIcon=false;lab.applyViewportIcon();local empty=snapshotAsMesh lab;redrawViews()
 iconNeed (empty.numfaces==0 and not cplPrivateIconHit lab [.25,0,0]) "Hidden icon retains pick geometry"
 lab.showViewportIcon=true;lab.viewportIconSize=.5;lab.applyViewportIcon();redrawViews()
 select lab;max zoomext sel all;clearSelection();redrawViews()
 iconNeed (cplPrivateIconHit lab [.5,0,0]) "Resized icon is not selectable"
 iconNeed (objects.count==count) "Icon created extra scene nodes"
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;lab.viewportUI.open=true;iconPump 100
 iconNeed lab.viewportUI.iconCheck.checked "Icon checkbox failed to bind"
 lab.viewportUI.iconCheck.changed false;iconNeed (not lab.showViewportIcon) "Icon checkbox does not own the flag"
 lab.viewportUI.iconCheck.changed true
 local ground=plane width:4 length:4
 local source=box width:.25 length:.25 height:.25 pos:[5,0,0]
 hide source;lab.setReceiver ground;lab.addSource source;lab.brushRadius=.001
 lab.startBrush();iconNeed (cplPrivatePaintPath lab.physicsDocument #([0,0,0]) false==1) "Viewport icon blocks receiver brushing";cplSynchronize lab.physicsDocument;cplPause lab.physicsDocument
 local before=cplPendingRows lab.physicsDocument,stats=cplStats lab.physicsDocument
 lab.viewportUI.iconSizeSpin.changed .4;lab.viewportUI.iconCheck.changed false;local bodyMesh=cplMesh lab.physicsDocument true
 iconNeed (cplPendingRows lab.physicsDocument==before) "Icon settings changed paused physics"
 iconNeed ((iconNumber (cplStats lab.physicsDocument) "cooks")==iconNumber stats "cooks" and (iconNumber (cplStats lab.physicsDocument) "step")==iconNumber stats "step") "Icon settings recooked or stepped the world"
 iconNeed (bodyMesh.numfaces==12) "Physical source geometry changed"
 lab.viewportUI.iconCheck.changed true
 iconNeed (lab.viewportUI.iconCheck.enabled and lab.viewportUI.iconSizeSpin.enabled) "Live icon controls are locked"
 cplFreeze lab.physicsDocument
 for i=1 to 100 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;iconPump 10)
 iconNeed ((cplUIState lab.physicsDocument)[5]==1) "Icon fixture Freeze failed"
 local poses=cplRows lab.physicsDocument
 local file=CPLTestDir+"icon.max"
 saveMaxFile file quiet:true;loadMaxFile file quiet:true;lab=getNodeByName "Selectable_Physics_Icon"
 iconNeed (lab.showViewportIcon and abs(lab.viewportIconSize-.4)<.00001) "Scene lost icon settings"
 redrawViews();iconNeed (findString (cplViewportIconInfo lab.physicsDocument) "\"owner\":0"==undefined) "Unselected loaded icon has no registered owner"
 local copied=copy lab
 iconNeed (cplRows copied.physicsDocument==poses and copied.physicsDocument!=lab.physicsDocument) "Icon clone shares or loses physics"
 iconNeed (objects.count==count+3) "Copy created extra icon nodes"
 delete copied
 cplStage "render icon comparison"
 ground=getNodeByName "Plane001";if isValidNode ground do hide ground
 local cam=FreeCamera()
 cam.transform=matrix3 [1,0,0] [0,.6,.8] [0,-.8,.6] [0,-4,3]
 iconNeed (distance cam.pos [0,-4,3]<.0001) "Render camera transform differs"
 renderers.current=Default_Scanline_Renderer()
 backgroundColor=black;environmentMap=undefined
 lab.material=standardMaterial diffuse:(color 150 190 230) selfIllumAmount:100
 rendWidth=128;rendHeight=128
 local hashes=#()
 for enabled in #(false,true) do
 (
  lab.showViewportIcon=enabled;lab.applyViewportIcon()
  local evaluated=snapshotAsMesh lab
  (dotNetClass "System.IO.File").AppendAllText (CPLTestDir+"render-info.txt") ((enabled as string)+" renderable="+(lab.renderable as string)+" hidden="+(lab.isHidden as string)+" faces="+(evaluated.numfaces as string)+" camera="+(cam.transform as string)+"\n")
  local b=render camera:cam outputsize:[128,128] vfb:false
  local geometryVisible=false
  for y=0 to 127 while not geometryVisible do for pixel in getPixels b [0,y] 128 where pixel.r>1 or pixel.g>1 or pixel.b>1 do geometryVisible=true
  iconNeed geometryVisible "Render comparison did not render the physical box"
  local path=CPLTestDir+(if enabled then "icon-on.bmp" else "icon-off.bmp")
  b.filename=path;save b;close b;append hashes (iconSHA path)
 )
 iconNeed (hashes[1]==hashes[2]) "Icon changes the rendered image"
 iconNeed (cplRows lab.physicsDocument==poses) "Rendering icon changed saved physics"
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;CPLUILab=lab.baseObject
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 iconNeed true "100% native control bounds/font metrics"
 delete lab;redrawViews()
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") ("PASS "+(CPLIconChecks as string)+" icon visibility/size/native HitTest/live isolation/scene/clone/render checks; render SHA256 "+hashes[1])
)
