-- Reproduce 0.1.6 using the owned copy of the artist's actual mountain scene.
cplResetScene()
if not loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-mountain-017-20261018-01/Mountain Scene Brush Test.max" quiet:true do throw "Mountain copy failed to open"
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
(
 local lab=getNodeByName "Cyrus Physics Lab001",ground=getNodeByName "Plane001"
 if lab==undefined or ground==undefined do throw "Actual scene bindings missing"
 cplClear lab.physicsDocument
 lab.brushRadius=.001;lab.birthSpacing=.08;lab.emissionHeight=.4
 viewport.setLayout #layout_1;viewport.setType #view_top
 select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true;lab.collisionUI.open=true
 lab.refreshBindings();lab.brushHeader.startButton.pressed()
 local origin=[-5000,5000,0]
 if cplPrivatePaintPath lab.physicsDocument #(origin,origin+[50,0,0]) false!=2 do throw "Actual mountain SDK path missed"
 cplSynchronize lab.physicsDocument
 local initial=cplStats lab.physicsDocument,poses=cplPendingRows lab.physicsDocument
 local until=timeStamp()+300
 while timeStamp()<until do (windows.processPostedMessages();sleep .01)
 local after=cplStats lab.physicsDocument
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-initial.json") initial
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-after.json") after
 if findString after "Spawn separation exceeds five metres"==undefined do throw ("Old failure not reproduced: "+after)
 if not (cplUIState lab.physicsDocument)[8] do throw "Old worker did not pause"
 if cplPendingRows lab.physicsDocument!=poses do throw "Old worker continued moving despite pause"
 lab.brushHeader.finishButton.pressed()
 until=timeStamp()+300
 while timeStamp()<until do (cplTick lab.physicsDocument 1;windows.processPostedMessages();sleep .01)
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"before-finish.json") (cplStats lab.physicsDocument)
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS reproduced 0.1.6 actual mountain: one birth, five-metre spawn failure, stalled poses before Finish"
)
