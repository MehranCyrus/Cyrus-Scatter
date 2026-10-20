-- Actual scene and SDK/rollout commands. No OS input, pixels or artist changes.
cplResetScene()
if not loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-mountain-017-20261018-01/Mountain Scene Brush Test.max" quiet:true do throw "Actual mountain copy failed to load"
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLMountainLab,CPLMountainMeshFingerprint,CPLMountainChecks=0
fn mountainNeed value message = (CPLMountainChecks+=1;if not value do throw message)
fn mountainPump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn mountainNumber text key = (((dotNetClass "System.Text.RegularExpressions.Regex").Match text ("\""+key+"\":([0-9]+)")).Groups.Item[1].Value as integer)
fn mountainHash lab = (CPLMountainLab=lab;python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/mountain-fixtures/mesh_hash.py";CPLMountainMeshFingerprint)
fn mountainShow lab =
(
 CPLMountainLab=lab;select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true;lab.collisionUI.open=true
 mountainPump 120;lab.refreshBindings()
)
fn mountainHit ground x y = (local hit=intersectRay ground (ray [x,y,100000] [0,0,-1]);mountainNeed (hit!=undefined) "Fixture point missed actual mountain";hit.pos)
fn mountainPath lab ground x y distance held:false =
(
 local path=#(mountainHit ground x y,mountainHit ground (x+distance) y)
 local hits=if held then cplPrivatePaintContinue lab.physicsDocument path else cplPrivatePaintPath lab.physicsDocument path false
 mountainNeed (hits==2) "Actual mountain SDK stroke missed";cplSynchronize lab.physicsDocument
)
(
 local ground=getNodeByName "Plane001",original=getNodeByName "Pyramid001",old=getNodeByName "Cyrus Physics Lab001"
 mountainNeed (ground!=undefined and original!=undefined and old!=undefined) "Actual scene bindings missing"
 local origin=old.pos
 hide old;hide original
 viewport.setLayout #layout_1;viewport.setType #view_top
 select ground;max zoomext sel all
 local t=teapot name:"Mountain_Test_Teapot" radius:120 segments:8 pos:[16000,0,0]
 local ring=torus name:"Mountain_Test_Torus" radius1:120 radius2:35 segments:32 sides:16 pos:[17000,0,0]
 local b=box name:"Mountain_Test_Box" width:120 length:80 height:450 pos:[18000,0,0]
 hide t;hide ring;hide b
 local kinds=#("original_pyramid","pyramid_original_radius","teapot","torus","tall_box")
 local models=#("Pyramid001","Pyramid001","Mountain_Test_Teapot","Mountain_Test_Torus","Mountain_Test_Box")
 local results=#(),blockedTotal=0
 for caseIndex=1 to kinds.count do
 (
  local kind=kinds[caseIndex],source=getNodeByName models[caseIndex]
  cplStage kind
  local lab=CyrusPhysicsLab name:("Mountain_017_"+kind)
  lab.pos=origin;lab.setReceiver ground;lab.addSource source
  lab.brushRadius=if caseIndex==1 then .001 else if caseIndex==2 then 5. else 2.
  lab.birthSpacing=if caseIndex<=2 then .08 else .8
  lab.emissionHeight=.4;lab.bodyLimit=1000
  mountainShow lab
  lab.collisionUI.showCollisionCheck.checked=true;lab.collisionUI.showCollisionCheck.changed true
  mountainNeed lab.showCollisionShapes "Collision checkbox did not own saved flag"
  if caseIndex==2 do (lab.collisionUI.showCollisionCheck.checked=false;lab.collisionUI.showCollisionCheck.changed false)
  mountainNeed (not theHold.Holding()) "Fixture left an authored Undo hold open"
  lab.brushHeader.startButton.pressed()
  mountainNeed ((cplUIState lab.physicsDocument)[1]) ("Start failed: "+lab.uiError)
  mountainNeed lab.collisionUI.showCollisionCheck.enabled "Collision toggle locked during live brushing"
  local y=4000-(caseIndex-1)*2000,distance=if caseIndex<=2 then 50 else 500
  mountainPath lab ground -5000 y distance held:true
  local first=cplStats lab.physicsDocument,poses=cplPendingRows lab.physicsDocument
  mountainPump 350;cplSynchronize lab.physicsDocument
  local moving=cplStats lab.physicsDocument,state=cplUIState lab.physicsDocument
  mountainNeed (state[6]>1) "Only one body was emitted"
  mountainNeed (not state[8] and state[7]=="") ("Crowding paused/error: "+moving)
  mountainNeed ((mountainNumber moving "step")>(mountainNumber first "step")) "Clock needs Finish"
  mountainNeed (cplPendingRows lab.physicsDocument!=poses) "Body animation needs Finish"
  blockedTotal+=state[16]
  cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument
  local count=(cplUIState lab.physicsDocument)[6]
  mountainPath lab ground -1500 y distance
  mountainNeed ((cplUIState lab.physicsDocument)[6]>count) "Second stroke rejected while bodies move"
  count=(cplUIState lab.physicsDocument)[6]
  mountainNeed (cplPrivatePaintPath lab.physicsDocument #([50000,50000,0],[51000,50000,0]) false==0) "Outside SDK hit receiver"
  cplSynchronize lab.physicsDocument
  mountainNeed ((cplUIState lab.physicsDocument)[6]==count) "Outside stroke emitted"
  mountainPath lab ground 2000 y distance
  mountainNeed ((cplUIState lab.physicsDocument)[6]>count) "Valid re-entry failed"
  lab.brushHeader.stopButton.pressed()
  local paused=cplStats lab.physicsDocument,before=cplPendingRows lab.physicsDocument,meshBefore=mountainHash lab
  if caseIndex==2 do
  (
   mountainNeed (findString (cplCollisionDisplayInfo lab.physicsDocument) "\"prepared\":false"!=undefined) "Cold-toggle case already had a display cache"
   lab.collisionUI.showCollisionCheck.checked=true;lab.collisionUI.showCollisionCheck.changed true
   mountainNeed (cplPendingRows lab.physicsDocument==before and (mountainNumber (cplStats lab.physicsDocument) "step")==mountainNumber paused "step") "Cold inspection changed physics"
  )
  redrawViews();local shown=cplCollisionDisplayInfo lab.physicsDocument
  mountainNeed ((mountainNumber shown "draws")>0 and (mountainNumber shown "model_lines")>0 and (mountainNumber shown "surface_lines")>0) "Redraw did not issue cooked collision wires"
  mountainNeed ((mountainNumber shown "model_lines")+(mountainNumber shown "surface_lines")<=200000) "Draw segment limit exceeded"
  local builds=mountainNumber shown "builds"
  lab.collisionUI.showCollisionCheck.checked=false;lab.collisionUI.showCollisionCheck.changed false;redrawViews()
  local offInfo=cplCollisionDisplayInfo lab.physicsDocument
  mountainNeed (findString offInfo "\"enabled\":false"!=undefined and (mountainNumber offInfo "model_lines")==0) "Overlay did not turn off"
  lab.collisionUI.showCollisionCheck.checked=true;lab.collisionUI.showCollisionCheck.changed true;redrawViews()
  mountainNeed ((mountainNumber (cplCollisionDisplayInfo lab.physicsDocument) "builds")==builds) "Visibility toggle recooked geometry"
  mountainNeed (cplPendingRows lab.physicsDocument==before and (mountainNumber (cplStats lab.physicsDocument) "step")==mountainNumber paused "step") "Overlay changed solver state/time"
  mountainNeed (mountainHash lab==meshBefore) "Overlay changed render mesh"
  count=(cplUIState lab.physicsDocument)[6]
  lab.brushHeader.undoButton.pressed()
  mountainNeed ((cplUIState lab.physicsDocument)[6]<count) "Live Undo failed"
  lab.brushHeader.redoButton.pressed()
  mountainNeed (cplPendingRows lab.physicsDocument==before) "Redo changed full motion state"
  local file=CPLTestDir+kind+"-pending.max"
  mountainNeed (saveMaxFile file quiet:true) "Pending save failed"
  mountainNeed (loadMaxFile file quiet:true) "Pending load failed"
  lab=getNodeByName ("Mountain_017_"+kind);ground=getNodeByName "Plane001";mountainShow lab
  mountainNeed lab.showCollisionShapes "Scene lost display flag"
  mountainNeed ((cplUIState lab.physicsDocument)[6]==count) "Scene lost preview bodies"
  mountainNeed (mountainHash lab==meshBefore) "Scene changed cached render mesh"
  lab.brushHeader.startButton.pressed();mountainPump 100;cplSynchronize lab.physicsDocument
  mountainNeed ((cplUIState lab.physicsDocument)[1] and not (cplUIState lab.physicsDocument)[8]) ("Saved Resume failed: "+lab.uiError)
  mountainNeed (not theHold.Holding()) "Fixture holds Undo before Finish"
  lab.brushHeader.finishButton.pressed()
  local until=timeStamp()+33000
  while (cplUIState lab.physicsDocument)[2] and not (cplUIState lab.physicsDocument)[4] and timeStamp()<until do (cplTick lab.physicsDocument 1;mountainPump 20)
  local settled=not (cplUIState lab.physicsDocument)[2]
  if not settled do
  (
   mountainNeed ((cplUIState lab.physicsDocument)[4]) ("Finish failed outside its explicit bound: "+cplStats lab.physicsDocument)
   lab.brushHeader.keepButton.pressed();until=timeStamp()+5000
   while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;mountainPump 20)
  )
  mountainNeed (not (cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[5]>1) "Finish/Freeze lost composition"
  mountainNeed ((cplUIState lab.physicsDocument)[5]==count) "Interior mountain test lost an accepted body"
  local saved=cplRows lab.physicsDocument
  max undo;max redo
  mountainNeed (cplRows lab.physicsDocument==saved) "Result Undo/Redo changed poses"
  cplExportFile lab.physicsDocument (CPLTestDir+kind+"-result.json")
  local record="{\"kind\":\""+kind+"\",\"first\":"+first+",\"live\":"+moving+",\"overlay\":"+shown+",\"mesh_sha256\":\""+meshBefore+"\",\"finish_settled\":"+(if settled then "true" else "false")+",\"final\":"+(cplStats lab.physicsDocument)+"}"
  append results record
  (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+kind+"-checks.json") record
  delete lab;redrawViews()
  mountainNeed (not isValidNode lab) "Owner deletion failed"
 )
 mountainNeed (blockedTotal>0) "Matrix did not exercise blocked births"
 local info=cplDiagnosticInfo()
 mountainNeed (findString info "\"recording\":true"!=undefined and findString info "\"watcher_alive\":true"!=undefined) "Crash recorder/watcher missing"
 local content="{\"pass\":true,\"checks\":"+(CPLMountainChecks as string)+",\"cases\":["
 for i=1 to results.count do content+=(if i>1 then "," else "")+results[i]
 content+="],\"diagnostics\":"+info+"}"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"mountain-results.json") content
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") ("PASS "+(CPLMountainChecks as string)+" actual-mountain/shape/continuous/overlay/Undo/recovery checks")
)
