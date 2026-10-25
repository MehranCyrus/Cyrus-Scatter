(
fn cvlRequire condition message = (if not condition do throw message)
fn cvlMeshSame a b =
(
    if a.numverts!=b.numverts or a.numfaces!=b.numfaces do return false
    for i=1 to a.numverts do if distance (getVert a i) (getVert b i)>1e-5 do return false
    for i=1 to a.numfaces do if getFace a i!=getFace b i do return false
    true
)
fn cvlRecord name grass = ((dotNetClass "System.IO.File").AppendAllText (CVLTestDir+"stats.jsonl") ("{\"case\":\""+name+"\",\"stats\":"+(cvlStats grass.nativeState)+"}\n"))
cvlResetScene()
cvlStage "create demo"
CVLOpen()
CVLLauncher.createButton.pressed()
try(destroyDialog CVLLauncher)catch()
global cvlGrass=$CVL_Grass001
if cvlGrass==undefined do cvlGrass=(for node in objects where classof node==CyrusVegetationLab collect node)[1]
global cvlStone=cvlGrass.stoneNode
cvlRequire (isValidNode cvlGrass and isValidNode cvlStone) "Demo button did not create grass and stone."
cvlRequire (objects.count==3) "Demo created unexpected nodes."
cvlRequire ((snapshotAsMesh cvlGrass).numfaces==112) "Rest mesh topology differs."
local restMesh=snapshotAsMesh cvlGrass
cvlStage "fit button"
select cvlGrass;max modify mode
modPanel.setCurrentObject cvlGrass
cvlGrass.labUI.fitButton.pressed()
cvlRequire ((findString (cvlStats cvlGrass.nativeState) "\"fitted\":true")!=undefined) "Fit button did not publish."
global cvlFitMesh=snapshotAsMesh cvlGrass
cvlRequire (not cvlMeshSame restMesh cvlFitMesh) "Fit left the intersecting rest mesh unchanged."
cvlRequire ((meshop.getNumMapVerts cvlFitMesh 1)==126) "UVs were lost."
cvlRequire (cvlFitMesh.numverts==126 and cvlFitMesh.numfaces==112) "Fitted topology differs."
cvlRecord "fit_button" cvlGrass
cvlStage "undo redo"
max undo
cvlRequire (cvlMeshSame restMesh (snapshotAsMesh cvlGrass)) "Undo did not restore rest geometry."
max redo
cvlRequire (cvlMeshSame cvlFitMesh (snapshotAsMesh cvlGrass)) "Redo did not restore accepted geometry."
cvlStage "cached reads"
for i=1 to 30 do (local m=snapshotAsMesh cvlGrass;redrawViews())
cvlRecord "cached_reads" cvlGrass
cvlStage "manual stone update"
local originalStone=cvlStone.pos
cvlStone.pos.x+=.03*(units.decodeValue "1m")
cvlRequire (cvlMeshSame cvlFitMesh (snapshotAsMesh cvlGrass)) "Moving a stone unexpectedly refitted static grass."
cvlGrass.fitNow()
cvlRequire (not cvlMeshSame cvlFitMesh (snapshotAsMesh cvlGrass)) "Explicit refit did not change mesh."
cvlRecord "moved_stone" cvlGrass
cvlStage "failure retains mesh"
local accepted=snapshotAsMesh cvlGrass
cvlStone.pos=[-.2*(units.decodeValue "1m"),0,0]
local failed=false
try(cvlGrass.fitNow())catch(failed=true)
cvlRequire failed "Stone blocking the roots was accepted."
cvlRequire (cvlMeshSame accepted (snapshotAsMesh cvlGrass)) "Rejected fit replaced accepted mesh."
cvlRecord "blocked_root" cvlGrass
cvlStone.pos=originalStone
cvlGrass.lockBase=true;failed=false
try(cvlGrass.fitNow())catch(failed=true)
cvlRequire failed "Blocked clamped root was accepted."
cvlRequire (cvlMeshSame accepted (snapshotAsMesh cvlGrass)) "Clamped failure replaced accepted mesh."
cvlGrass.lockBase=false
cvlStage "unsupported collider"
cvlStone.scale=[1,2,1];failed=false
try(cvlGrass.fitNow())catch(failed=true)
cvlRequire failed "Nonuniform stone scale was accepted."
cvlStone.scale=[1,1,1]
local other=box width:1 length:1 height:1
cvlGrass.stoneNode=other;failed=false
try(cvlGrass.fitNow())catch(failed=true)
cvlRequire failed "Arbitrary box was admitted as a sphere."
cvlGrass.stoneNode=cvlStone;delete other
cvlRequire (cvlMeshSame accepted (snapshotAsMesh cvlGrass)) "Unsupported collider changed mesh."
cvlStage "admission and rigid transforms"
cvlStone.hemisphere=.2;failed=false
try(cvlGrass.fitNow())catch(failed=true)
cvlRequire failed "Hemisphere was admitted as a complete sphere."
cvlStone.hemisphere=0
cvlGrass.scale=[2,2,2];failed=false
try(cvlGrass.fitNow())catch(failed=true)
cvlRequire failed "Scaled grass owner was accepted."
cvlGrass.scale=[1,1,1]
local instanced=instance cvlGrass;failed=false
try(cvlGrass.fitNow())catch(failed=true)
cvlRequire failed "Instanced owner ambiguity was accepted."
delete instanced
local savedUnit=units.SystemType
units.SystemType=if savedUnit==#meters then #millimeters else #meters
failed=false
try(cvlGrass.fitNow())catch(failed=true)
units.SystemType=savedUnit
cvlRequire failed "Changed system units were admitted without a new demo."
cvlRequire (cvlMeshSame accepted (snapshotAsMesh cvlGrass)) "Admission failure changed accepted numeric mesh."
-- Move and rotate both together: the patch-local solver inputs stay equivalent.
local ownerTM=cvlGrass.transform,stoneTM=cvlStone.transform
local groupTM=(rotateZMatrix 25)*(transMatrix [120,80,0])
cvlGrass.transform=ownerTM*groupTM;cvlStone.transform=stoneTM*groupTM
cvlGrass.fitNow()
cvlRequire ((findString (cvlStats cvlGrass.nativeState) "\"fitted\":true")!=undefined) "Rigid transformed fit failed."
cvlRecord "rigid_transform" cvlGrass
cvlGrass.transform=ownerTM;cvlStone.transform=stoneTM
cvlStage "reset button"
cvlGrass.labUI.resetButton.pressed()
cvlRequire (cvlMeshSame restMesh (snapshotAsMesh cvlGrass)) "Reset changed source roots or rest geometry."
cvlGrass.fitNow()
cvlStage "copy independence"
local duplicate=copy cvlGrass
cvlRequire (duplicate.nativeState!=cvlGrass.nativeState) "Copy shares a mutable native document."
cvlRequire (cvlMeshSame (snapshotAsMesh duplicate) (snapshotAsMesh cvlGrass)) "Copy lost geometry."
duplicate.resetNow()
cvlRequire (not cvlMeshSame (snapshotAsMesh duplicate) (snapshotAsMesh cvlGrass)) "Copy reset changed original state."
delete duplicate
cvlStage "bake button"
local beforeCount=objects.count
select cvlGrass;modPanel.setCurrentObject cvlGrass
cvlGrass.labUI.bakeButton.pressed()
local baked=selection[1]
cvlRequire (objects.count==beforeCount+1 and classof baked==Editable_mesh) "Bake button did not create an ordinary mesh."
cvlRequire (cvlMeshSame (snapshotAsMesh baked) (snapshotAsMesh cvlGrass)) "Baked mesh differs from visible grass."
cvlRequire (baked.material==cvlGrass.material) "Bake lost material."
delete baked
cvlStage "save reopen"
global cvlSavedMesh=snapshotAsMesh cvlGrass
global cvlGrassName=cvlGrass.name
cvlRequire (saveMaxFile (CVLTestDir+"Grass_Stone_Max2027.max") quiet:true) "Scene save failed."
loadMaxFile (CVLTestDir+"Grass_Stone_Max2027.max") quiet:true
cvlGrass=getNodeByName cvlGrassName
cvlStone=cvlGrass.stoneNode
cvlRequire (isValidNode cvlStone) "Sphere reference lost after reopening."
cvlRequire (cvlMeshSame cvlSavedMesh (snapshotAsMesh cvlGrass)) "Saved native mesh changed on reopening."
cvlRecord "reopened" cvlGrass
cvlStage "renderer"
local meter=units.decodeValue "1m"
local camera=targetCamera name:"CVL_TestCamera" pos:[-.9*meter,-1.2*meter,.72*meter] target:(targetObject pos:[-.1*meter,0,.28*meter]) fov:38
renderers.current=Default_Scanline_Renderer()
render camera:camera outputfile:(CVLTestDir+"Grass_Stone_Preview.png") vfb:false outputwidth:900 outputheight:700
cvlRecord "after_render" cvlGrass
cvlRequire (cvlMeshSame cvlSavedMesh (snapshotAsMesh cvlGrass)) "Rendering changed the accepted mesh."
local cameraTarget=camera.target
delete camera
if isValidNode cameraTarget do delete cameraTarget
cvlStage "21 blade patch"
local maximum=CVLCreateDemo count:21
maximum[1].fitNow()
cvlRequire ((snapshotAsMesh maximum[1]).numfaces==336) "21-blade host fit failed."
cvlRecord "21_blades" maximum[1]
cvlStage "done"
)
