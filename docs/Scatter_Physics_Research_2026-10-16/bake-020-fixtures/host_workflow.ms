cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global BChecks=0,CPLUILab
fn bNeed value message=(BChecks+=1;if not value do throw message)
fn bPump ms=(local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn bShow lab=(select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;lab.brushHeader.open=true;lab.objectsUI.open=true;lab.collisionUI.open=true;bPump 100;lab.refreshBindings())
fn bWait lab=(local until=timeStamp()+40000;while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 4;bPump 10);bNeed (not (cplUIState lab.physicsDocument)[2]) ("Finish/bake failed: "+cplStats lab.physicsDocument+lab.uiError))
fn bPath lab points=(bNeed (cplPrivatePaintPath lab.physicsDocument points false==points.count) "Painter SDK hit mismatch";cplSynchronize lab.physicsDocument)
fn bWrite name value=((dotNetClass "System.IO.File").WriteAllText (CPLTestDir+name) value)
(
 units.SystemType=#meters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane name:"Bake_Ground_020" length:8 width:8
 local source=box name:"Colour_Box_020" width:.12 length:.12 height:.12 pos:[10,0,0] wirecolor:(color 230 90 30)
 local ball=sphere name:"Assigned_Sphere_020" radius:.07 segments:16 pos:[11,0,0]
 local blue=standardMaterial name:"Assigned_Blue_020" diffuse:(color 30 100 230)
 ball.material=blue;hide source;hide ball
 local lab=CyrusPhysicsLab name:"Bake_Lab_020"
 lab.setReceiver ground;lab.addSource source;lab.addSource ball
 lab.brushRadius=.005;lab.birthSpacing=.25;lab.emissionHeight=.8;lab.scaleMinimum=1;lab.scaleMaximum=1
 select ground;max zoomext sel all;bShow lab
 bNeed (source.material==undefined) "Fallback mutated the source"
 bNeed (classOf lab.material==MultiMaterial and lab.material.numsubs==2) "Lab material container missing"
 bNeed (lab.material.materialList[1].diffuse==source.wirecolor) "Wire-colour fallback incorrect"
 bNeed (lab.material.materialList[2]==blue) "Assigned material was replaced"
 local ui=lab.objectsUI,list=ui.sourceList
 bNeed (not list.CheckOnClick) "Default check-on-row still enabled"
 local before=for i=1 to 2 collect (cplSourceOptions lab.physicsDocument i)[1]
 list.SelectedIndex=1;list.SetItemChecked 1 false
 bNeed ((cplSourceOptions lab.physicsDocument 2)[1]) "Row/native ItemCheck toggled source"
 list.SetItemChecked 0 false;bNeed (list.GetItemChecked 0) "Native check change escaped guard"
 list.SelectedIndex=0;list.SelectedIndex=-1
 bNeed (list.SelectedIndex==0) "Blank selection changed highlighted model"
 local rect=list.GetItemRectangle 0,x=rect.X+5,y=rect.Y+(rect.Height/2) as integer
 bNeed (ui.checkboxAt x y==0) "Glyph hit test failed"
 bNeed (ui.checkboxAt (x+50) y== -1) "Name counted as checkbox"
 bNeed (ui.checkboxAt x 100== -1) "Blank counted as checkbox"
 ui.checkPointerDown (x+50) y;ui.checkPointerUp (x+50) y
 bNeed ((cplSourceOptions lab.physicsDocument 1)[1]) "Text click toggled source"
 ui.checkPointerDown x 100;ui.checkPointerUp x 100
 bNeed ((cplSourceOptions lab.physicsDocument 1)[1]) "Blank click toggled source"
 ui.checkPointerDown x y;ui.checkPointerUp (x+50) y
 bNeed ((cplSourceOptions lab.physicsDocument 1)[1]) "Dragging out of glyph toggled source"
 ui.checkPointerDown x y;ui.checkPointerUp x y
 bNeed (not (cplSourceOptions lab.physicsDocument 1)[1]) "Glyph did not disable source"
 max undo;lab.refreshBindings();bNeed ((cplSourceOptions lab.physicsDocument 1)[1]) "Checkbox Undo failed"
 max redo;lab.refreshBindings();bNeed (not (cplSourceOptions lab.physicsDocument 1)[1]) "Checkbox Redo failed"
 ui.setChecked #(true,false)
 cplStage "continuous outside and live undo"
 lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Start failed: "+lab.uiError)
 bPath lab #([-.8,0,0],[-.3,0,0])
 local count=(cplUIState lab.physicsDocument)[6],pose=cplPendingRows lab.physicsDocument
 (dotNetClass "System.Threading.Thread").Sleep 220
 bNeed (cplPendingRows lab.physicsDocument!=pose) "Physics stopped between strokes"
 bPath lab #([.3,0,0],[.8,0,0])
 bNeed ((cplUIState lab.physicsDocument)[6]>count) "Cannot brush while bodies move"
 count=(cplUIState lab.physicsDocument)[6]
 bNeed (cplPrivatePaintPath lab.physicsDocument #([20,20,0],[21,20,0]) false==0) "Outside stroke hit"
 cplSynchronize lab.physicsDocument;bNeed ((cplUIState lab.physicsDocument)[6]==count) "Outside stroke emitted"
 lab.brushHeader.stopButton.pressed();pose=cplPendingRows lab.physicsDocument
 lab.brushHeader.undoButton.pressed();bNeed ((cplUIState lab.physicsDocument)[6]<count) "Live Undo failed"
 lab.brushHeader.redoButton.pressed();bNeed (cplPendingRows lab.physicsDocument==pose) "Live Redo changed full state"
 ui.checkPointerDown x y;ui.checkPointerUp x y
 bNeed ((cplSourceOptions lab.physicsDocument 1)[1]) "Pending checkbox mutation admitted"
 lab.uiError=""
 local originalNodes=objects.count
 cplStage "finish poly and atomic undo"
 lab.brushHeader.finishButton.pressed();bWait lab
 bNeed ((cplUIState lab.physicsDocument)[5]==0 and cplRows lab.physicsDocument=="[]") "Procedural rows not retired"
 local colliders=cplColliderNodes lab.physicsDocument
 bNeed (colliders.count==1 and objects.count==originalNodes+1) "Finish did not create exactly one collider"
 local baked=colliders[1],bakedHandle=getHandleByAnim colliders[1]
 bNeed (classOf baked.baseObject==Editable_Poly) "Finish is not Editable Poly"
 bNeed ((getUserProp baked "CyrusPhysicsLabBodies")==count) "Baked body count lost"
 bNeed (baked.material.materialList[1].diffuse==source.wirecolor) "Baked fallback material lost"
 local bakedMesh=snapshotAsMesh baked,vertices=getNumVerts bakedMesh,faces=getNumFaces bakedMesh
 local first=getVert bakedMesh 1,oldMaterial=baked.material,tm=baked.transform
 bNeed (faces==count*12) "Baked faces lost"
 bNeed (getFaceMatID bakedMesh 1==1) "Baked material ID wrong"
 max undo;bNeed (not isValidNode baked and (cplColliderNodes lab.physicsDocument).count==0) "Undo left baked node/collider"
 max redo
 colliders=cplColliderNodes lab.physicsDocument;bNeed (colliders.count==1 and isValidNode colliders[1]) "Redo failed to restore batch"
 baked=colliders[1];bakedMesh=snapshotAsMesh baked
 bNeed (getNumFaces bakedMesh==faces and getVert bakedMesh 1==first and baked.transform==tm) "Redo changed geometry"
 bNeed (baked.material==oldMaterial) "Redo changed material assignment"
 cplStage "quality affects new strokes only"
 source.wirecolor=color 40 210 80
 lab.collisionUI.selectQuality 3
 lab.startBrush();bNeed ((cplUIState lab.physicsDocument)[1]) ("Detailed after Fast failed: "+lab.uiError+" "+cplStats lab.physicsDocument)
 bNeed (lab.material.materialList[1].diffuse==source.wirecolor) "New fallback did not refresh"
 bNeed (baked.material==oldMaterial and baked.material.materialList[1].diffuse==(color 230 90 30)) "New material changed baked batch"
 bNeed (getNumFaces (snapshotAsMesh baked)==faces and getVert (snapshotAsMesh baked) 1==first) "Quality changed baked geometry"
 bPath lab #([-.8,0,0],[-.3,0,0])
 lab.brushHeader.finishButton.pressed();bWait lab
 bNeed ((cplColliderNodes lab.physicsDocument).count==2) "Second batch missing"
 bNeed (baked.transform==tm) "Static baked batch moved"
 cplStage "editable collider recapture and cancel"
 baked.pos.z+=.1
 lab.startBrush();bNeed ((cplUIState lab.physicsDocument)[1]) "Edited baked collider could not recapture"
 cplExportFile lab.physicsDocument (CPLTestDir+"before-recature-base.json")
 bPath lab #([1,1,0],[1.5,1,0]);lab.brushHeader.cancelButton.pressed()
 bNeed ((cplColliderNodes lab.physicsDocument).count==2) "Cancel deleted baked geometry"
 bNeed (baked.pos.z==tm.translation.z+.1) "Collider edit was overwritten"
 local other=(cplColliderNodes lab.physicsDocument)[2]
 delete other
 lab.startBrush();bNeed ((cplUIState lab.physicsDocument)[1]) "Deleted collider blocked subsequent Start"
 lab.stopBrush();bNeed ((cplColliderNodes lab.physicsDocument).count==1) "Deleted collider remains bound"
 local clone=copy lab;lab.startBrush();lab.stopBrush()
 bNeed ((cplColliderNodes clone.physicsDocument).count==1) "Clone lost collider binding"
 delete clone
 cplClear lab.physicsDocument
 bNeed (isValidNode baked and (cplColliderNodes lab.physicsDocument).count==1) "Clear deleted baked batch"
 bShow lab;CPLUILab=lab.baseObject
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 bNeed (saveMaxFile (CPLTestDir+"baked-workflow.max") quiet:true) "Save baked scene failed"
 bWrite "workflow-count.txt" (BChecks as string)
 bWrite "workflow-stats.json" (cplStats lab.physicsDocument)
 bWrite "workflow-collisions.json" (cplCollisionDisplayInfo lab.physicsDocument)
)
