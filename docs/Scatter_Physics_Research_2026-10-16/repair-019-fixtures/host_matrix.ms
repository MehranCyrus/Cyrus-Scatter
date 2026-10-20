cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLQChecks=0,CPLQUnits=1
fn qNeed value message=(CPLQChecks+=1;if not value do throw message)
fn qPump duration=(local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn qShow lab=(select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;lab.objectsUI.open=true;lab.collisionUI.open=true;qPump 100;lab.refreshBindings())
fn qFreeze lab=(lab.brushHeader.keepButton.pressed();local until=timeStamp()+10000;while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;qPump 10);qNeed (not (cplUIState lab.physicsDocument)[2]) ("Freeze failed "+cplStats lab.physicsDocument))
fn qHit ground x y=(local rayHit=intersectRay ground (ray ([x,y,100000]*CPLQUnits) [0,0,-1]);qNeed (rayHit!=undefined) "Test point missed terrain";rayHit.pos)
fn qPath lab ground x y=(local points=#((qHit ground x y),(qHit ground (x+450) y));qNeed (cplPrivatePaintPath lab.physicsDocument points false==2) "Painter SDK path failed";cplSynchronize lab.physicsDocument)
fn qWrite name data=((dotNetClass "System.IO.File").WriteAllText (CPLTestDir+name) data)
qNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-quality-018-20261018-01/Mountain Scene Brush Test.max" quiet:true) "Mountain copy failed"
(
 local ground=getNodeByName "Plane001",pyramid=getNodeByName "Pyramid001",old=getNodeByName "Cyrus Physics Lab001"
 CPLQUnits=(units.decodeValue "1m")/100.0
 local origin=[0,0,1400]*CPLQUnits
 local foreign=for node in objects where node!=ground and node!=pyramid collect node
 delete foreign
 hide pyramid
 ground.material=standardMaterial name:"Mountain_Grey" diffuse:(color 125 125 125)
 pyramid.material=standardMaterial name:"Pyramid_Orange" diffuse:(color 220 140 60)
 viewport.setLayout #layout_1;viewport.setType #view_top;select ground;max zoomext sel all
 local ball=sphere name:"Q019_Sphere32" radius:(60*CPLQUnits) segments:32 pos:([16000,0,0]*CPLQUnits)
 local tea=teapot name:"Q019_Teapot" radius:(120*CPLQUnits) segments:8 pos:([17000,0,0]*CPLQUnits)
 ball.material=standardMaterial name:"Sphere_Blue" diffuse:(color 70 140 220)
 tea.material=standardMaterial name:"Teapot_Green" diffuse:(color 105 190 100)
 hide ball;hide tea
 local sources=#(pyramid,ball,tea),labs=#(),kindNames=#("pyramid","sphere","teapot")
 for sourceSlot=1 to 3 do for quality=0 to 2 do
 (
  local kind=kindNames[sourceSlot]+"_q"+(quality as string),source=sources[sourceSlot]
  cplStage kind
  local lab=CyrusPhysicsLab name:("Q019_"+kind)
  lab.pos=origin;lab.viewportIconSize=2;lab.setReceiver ground;lab.addSource source
  lab.brushRadius=.08;lab.birthSpacing=1.5;lab.emissionHeight=.6;lab.bodyLimit=1000
  lab.showCollisionShapes=true;qShow lab
  qNeed lab.objectsUI.controlsReady "Checked model list failed to initialize"
  qNeed (lab.objectsUI.sourceList.Items.Count==1) "Model list missing row"
  lab.collisionUI.qualityList.selection=quality+1
  lab.collisionUI.selectQuality (quality+1)
  qNeed ((cplSourceOptions lab.physicsDocument 1)[2]==quality) "Quality handler failed"
  lab.brushHeader.startButton.pressed()
  qNeed ((cplUIState lab.physicsDocument)[1]) ("Start failed "+lab.uiError+" "+cplStats lab.physicsDocument)
  local y=6000-sourceSlot*2300-quality*450
  qPath lab ground -5000 y
  local first=(cplUIState lab.physicsDocument)[6],poses=cplPendingRows lab.physicsDocument
  (dotNetClass "System.Threading.Thread").Sleep 230
  cplSynchronize lab.physicsDocument
  qNeed (first>1) "One-body stall returned"
  qNeed (cplPendingRows lab.physicsDocument!=poses) "Bodies wait for Finish to animate"
  qPath lab ground -1500 y
  qNeed ((cplUIState lab.physicsDocument)[6]>first) "Second stroke while moving failed"
  local count=(cplUIState lab.physicsDocument)[6]
  qNeed (cplPrivatePaintPath lab.physicsDocument #([50000,50000,0]*CPLQUnits,[51000,50000,0]*CPLQUnits) false==0) "Outside path hit terrain"
  cplSynchronize lab.physicsDocument;qNeed ((cplUIState lab.physicsDocument)[6]==count) "Outside brush emitted"
  qPath lab ground 2000 y
  lab.brushHeader.stopButton.pressed();local pending=cplPendingRows lab.physicsDocument
  lab.brushHeader.undoButton.pressed();qNeed ((cplUIState lab.physicsDocument)[6]<count+4) "Undo did not remove a stroke"
  lab.brushHeader.redoButton.pressed();qNeed (cplPendingRows lab.physicsDocument==pending) "Redo changed full body state"
  qNeed (not lab.collisionUI.qualityList.enabled) "Quality must lock with pending session"
  local rejected=false
  try(cplSetSourceOptions lab.physicsDocument 1 0 16 1)catch(rejected=true)
  qNeed rejected "Native pending quality edit was accepted"
  redrawViews();qWrite (kind+"-overlay.json") (cplCollisionDisplayInfo lab.physicsDocument)
  if quality==2 then
  (
   lab.brushHeader.finishButton.pressed()
   local until=timeStamp()+35000
   while (cplUIState lab.physicsDocument)[2] and not (cplUIState lab.physicsDocument)[4] and timeStamp()<until do (cplTick lab.physicsDocument 1;qPump 20)
   if (cplUIState lab.physicsDocument)[2] do (qNeed ((cplUIState lab.physicsDocument)[4]) "Finish failed to reach settle/timeout bound";qFreeze lab)
  )else qFreeze lab
  qNeed ((cplUIState lab.physicsDocument)[5]>=count) "Accepted bodies lost on mountain"
  cplExportFile lab.physicsDocument (CPLTestDir+kind+"-result.json")
  qWrite (kind+"-stats.json") (cplStats lab.physicsDocument)
  -- Starting again must reuse the numeric source cook and preserve the completed result.
  local cookCount=(cplSourceOptions lab.physicsDocument 1)[6],rows=cplRows lab.physicsDocument
  lab.brushHeader.startButton.pressed();qNeed ((cplUIState lab.physicsDocument)[1]) "Second session Start failed"
  qNeed ((cplSourceOptions lab.physicsDocument 1)[6]==cookCount) "Unchanged model decomposed again"
  lab.brushHeader.cancelButton.pressed();qNeed (cplRows lab.physicsDocument==rows) "Cancel changed saved bodies"
  local saved=cplRows lab.physicsDocument
  max undo;max redo
  qNeed (cplRows lab.physicsDocument==saved) "Completed result Undo/Redo failed"
  append labs lab;hide lab
 )
 cplStage "checked palette"
 local mixed=CyrusPhysicsLab name:"Q019_Mixed_Palette"
 mixed.pos=origin;mixed.viewportIconSize=2;mixed.setReceiver ground
 for source in sources do mixed.addSource source
 mixed.brushRadius=.08;mixed.birthSpacing=1.5;mixed.emissionHeight=.6;mixed.showCollisionShapes=true
 qShow mixed
 qNeed (mixed.objectsUI.sourceList.Items.Count==3) "Checked list did not expose all models"
 for i=1 to 3 do cplSetSourceOptions mixed.physicsDocument i 2 16 1
 mixed.refreshBindings()
 mixed.objectsUI.sourceList.SetItemChecked 0 false
 mixed.objectsUI.sourceList.SetItemChecked 2 false
 qNeed ((cplSourceOptions mixed.physicsDocument 1)[1]==false and (cplSourceOptions mixed.physicsDocument 2)[1] and (cplSourceOptions mixed.physicsDocument 3)[1]==false) "Actual ItemCheck handler failed"
 mixed.brushHeader.startButton.pressed();qPath mixed ground -5000 -6000;mixed.brushHeader.stopButton.pressed();qFreeze mixed
 cplExportFile mixed.physicsDocument (CPLTestDir+"palette-sphere-result.json")
 mixed.objectsUI.sourceList.SelectedIndex=2;mixed.objectsUI.setChecked #(false,false,true)
 qNeed ((cplSourceOptions mixed.physicsDocument 3)[1] and not (cplSourceOptions mixed.physicsDocument 2)[1]) "Exclusive checked mask failed"
 max undo
 qNeed ((cplSourceOptions mixed.physicsDocument 2)[1] and not (cplSourceOptions mixed.physicsDocument 3)[1]) "Palette Undo failed"
 max redo
 qNeed ((cplSourceOptions mixed.physicsDocument 3)[1]) "Palette Redo failed"
 mixed.objectsUI.setChecked #(true,true,true)
 mixed.brushHeader.startButton.pressed();qPath mixed ground -1500 -6000;qPath mixed ground 2000 -6000;mixed.brushHeader.stopButton.pressed();qFreeze mixed
 cplExportFile mixed.physicsDocument (CPLTestDir+"palette-mixed-result.json")
 mixed.objectsUI.setChecked #(false,false,false);qNeed (not mixed.brushHeader.startButton.enabled) "Start enabled with all models unchecked"
 local rejected=false;try(mixed.startBrush())catch(rejected=true)
 qNeed rejected "Native all-disabled palette was admitted"
 mixed.objectsUI.setChecked #(true,true,true)
 -- Quality edit Undo must restore the authored slot without touching its published bodies.
 local rows=cplRows mixed.physicsDocument
 cplSetSourceOptions mixed.physicsDocument 3 1 8 2
 max undo;qNeed ((cplSourceOptions mixed.physicsDocument 3)[2]==2) "Quality Undo failed"
 max redo;qNeed ((cplSourceOptions mixed.physicsDocument 3)[2]==1) "Quality Redo failed"
 max undo;qNeed (cplRows mixed.physicsDocument==rows) "Authored option Undo changed saved output"
 qWrite "mixed-final-stats.json" (cplStats mixed.physicsDocument)
 -- Save a self-contained artist scene with editable setups and model references.
 for lab in labs do hide lab
 unhide mixed
 mixed.pos=origin
 qShow mixed
 qNeed (saveMaxFile (CPLTestDir+"PhysicsLab-0.1.9-Mountain-Test.max") quiet:true) "Artist test scene save failed"
 local cloneNode=copy mixed
 qNeed ((cplSourceOptions cloneNode.physicsDocument 3)[2]==2) "Clone lost per-model quality"
 qNeed (cplRows cloneNode.physicsDocument==rows) "Clone lost physical result"
 delete cloneNode
 global CPLUILab=mixed.baseObject
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 local info=cplDiagnosticInfo()
 qNeed (findString info "\"watcher_alive\":true"!=undefined) "Crash watcher missing"
 qWrite "diagnostics-status.json" info
 local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
 qWrite "memory.json" (substituteString ("{\"peak_working_set_bytes\":"+(process.PeakWorkingSet64 as string)+",\"working_set_bytes\":"+(process.WorkingSet64 as string)+"}") "L" "")
 qWrite "assertions.txt" ("PASS "+(CPLQChecks as string)+" actual mountain/quality/palette/history/cache/layout checks")
)

fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/host_palette.ms"
