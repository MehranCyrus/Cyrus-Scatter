-- Owned Max 2027 fixture. Uses actual rollout/Painter SDK callbacks, no OS input.
cplResetScene()
global CPLGripChecks=0
fn gripRequire value message = (CPLGripChecks+=1;if not value do throw message)
fn gripPump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn gripFreeze lab = (cplFreeze lab.physicsDocument;for i=1 to 150 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;gripPump 10);gripRequire (not (cplUIState lab.physicsDocument)[2]) ("Freeze failed: "+cplStats lab.physicsDocument))
fn gripHeight kind x y =
(
 case kind of
 (
  #slope: x*.7
  #hills: (.35*sin(x*103.132)*cos(y*80.214))
  #ridge: (1.-.65*abs(x)+.08*sin(y*171.887))
  #valley: (.45*abs(x)+.12*sin(y*114.592))
  #rough: (.35*sin(x*85.944)+.16*sin(x*286.479+y*171.887)+.08*cos(x*515.662-y*401.07))
  #terraces: (.18*floor((x+4)*2)+.05*sin(y*229.183))
  default: 0.
 )
)
fn gripTerrain kind scaleValue =
(
 local points=#(),triangles=#(),segments=24
 for y=0 to segments do for x=0 to segments do
 (
  local px=-4.+8.*x/segments,py=-4.+8.*y/segments
  append points ([px,py,gripHeight kind px py]*scaleValue)
 )
 for y=0 to segments-1 do for x=0 to segments-1 do
 (
  if not (kind==#hole and x>=10 and x<14 and y>=10 and y<14) do
  (
   local a=y*(segments+1)+x+1,b=a+1,c=a+segments+1,d=c+1
   append triangles [a,b,d];append triangles [a,d,c]
  )
 )
 mesh name:("Grip_"+kind as string) vertices:points faces:triangles
)
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
(
 local combined=""
 for kind in #(#slope,#hills,#ridge,#valley,#rough,#terraces,#hole) do
 (
  cplResetScene();units.SystemType=#meters;units.SystemScale=1
  viewport.setLayout #layout_1;viewport.setType #view_top
  local ground=gripTerrain kind 1.
  local source=box name:"Grip_leaf" width:.07 length:.05 height:.01 pos:[8,8,0]
  hide source
  local lab=CyrusPhysicsLab name:"Grip_lab"
  lab.brushRadius=.002;lab.emissionHeight=.15;lab.scaleMinimum=1;lab.scaleMaximum=1
  select ground;max zoomext sel all
  select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
  lab.brushHeader.open=true;lab.objectsUI.open=true;lab.collisionUI.open=true;gripPump 150
  lab.objectsUI.receiverPick.picked ground;lab.objectsUI.sourcePick.picked source
  lab.collisionUI.gripSpin.value=80;lab.collisionUI.gripSpin.changed 80
  lab.collisionUI.frictionSpin.value=.2;lab.collisionUI.frictionSpin.changed .2
  gripRequire (lab.stickiness==80 and lab.friction==.2) "New control did not own authored setting"
  cplStage ("terrain "+kind as string)
  lab.brushHeader.startButton.pressed()
  gripRequire ((cplUIState lab.physicsDocument)[1]) ("Start failed: "+lab.uiError)
  gripRequire (not lab.collisionUI.gripSpin.enabled) "Grip editable during pending world"
  local first=#([-1.6,-1,gripHeight kind -1.6 -1],[-1.4,-1,gripHeight kind -1.4 -1])
  gripRequire (cplPrivatePaintPath lab.physicsDocument first false==2) "Terrain first SDK stroke missed"
  cplSynchronize lab.physicsDocument
  local second=#([1.2,1,gripHeight kind 1.2 1],[1.4,1,gripHeight kind 1.4 1])
  gripRequire (cplPrivatePaintPath lab.physicsDocument second false==2) "Continuous terrain stroke rejected"
  cplSynchronize lab.physicsDocument
  lab.brushHeader.stopButton.pressed()
  local captured=cplPendingRows lab.physicsDocument
  lab.brushHeader.undoButton.pressed();lab.brushHeader.redoButton.pressed()
  gripRequire (captured==cplPendingRows lab.physicsDocument) "Terrain Undo/Redo changed poses or motion"
  lab.brushHeader.startButton.pressed()
  local count=(cplUIState lab.physicsDocument)[6]
  gripRequire (cplPrivatePaintPath lab.physicsDocument #([12,12,0],[14,14,0]) false==0) "Outside terrain hit"
  cplSynchronize lab.physicsDocument
  gripRequire ((cplUIState lab.physicsDocument)[6]==count) "Outside terrain emitted bodies"
  lab.brushHeader.stopButton.pressed()
  saveMaxFile (CPLTestDir+(kind as string)+"-pending.max") quiet:true
  gripRequire (loadMaxFile (CPLTestDir+(kind as string)+"-pending.max") quiet:true) "Pending terrain load failed"
  lab=getNodeByName "Grip_lab"
  gripRequire (lab.stickiness==80 and (cplUIState lab.physicsDocument)[6]==count) "Saved grip or preview lost"
  lab.startBrush();cplPause lab.physicsDocument
  gripFreeze lab
  local result=cplRows lab.physicsDocument
  gripRequire ((cplUIState lab.physicsDocument)[5]==count) "Terrain Freeze count changed"
  max undo
  gripRequire ((cplUIState lab.physicsDocument)[5]==0) "Result Undo failed"
  max redo
  gripRequire (cplRows lab.physicsDocument==result) "Result Redo failed"
  cplExportFile lab.physicsDocument (CPLTestDir+(kind as string)+"-result.json")
  combined+="PASS "+(kind as string)+": grip/friction controls, continuous SDK strokes, outside, live Undo/Redo, pending scene replay, Freeze and result Undo/Redo\n"
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") (combined+"Checks: "+CPLGripChecks as string)
)
